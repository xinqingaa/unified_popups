import 'package:flutter/widgets.dart';

import '../../configs/sheet_types.dart';
import '../../controller/popup_handle.dart';
import '../contracts/flow_sheet_entry.dart';
import '../contracts/flow_sheet_host_delegate.dart';
import '../contracts/flow_sheet_navigator.dart';
import '../lifecycle/flow_sheet_lifecycle_controller.dart';
import '../pages/flow_sheet_page.dart';

/// FlowSheet 控制器：维护内部页面栈、结果回传与生命周期。
///
/// 展示层由 [FlowSheetHost] 用内嵌 [Navigator]（Pages API + [CupertinoPage]）承载，
/// 转场默认由框架提供。结果回传走每个 entry 自己的 [Completer]，与路由 future 解耦，
/// 因此 [closeAll] 即使在有 pending 页面时也不会泄漏。
///
/// 生命周期分两个独立阶段：
/// 1. 业务关闭（[_closeBusiness]）：完成所有 pending Future、触发页面 onHide/onClose。
///    在 [closeAll] 或底层 sheet Future 完成时同步发生，不依赖任何动画/widget 回调。
/// 2. 对象销毁（[dispose]）：释放 notifier。底层 `Pop.sheet` 的 Future 在 dismiss 时
///    就会完成，而 overlay 退场动画期间 [FlowSheetHost] 仍持有本对象，因此销毁
///    延迟到「sheet Future 已完成」且「Host 已卸载」两个条件都满足时才执行，
///    避免 "used after being disposed"。
///
/// [R] 为整个 sheet（[closeAll]）的最终结果类型。
class FlowSheetController<R> extends ChangeNotifier
    implements FlowSheetNavigator, FlowSheetHostDelegate {
  final List<FlowSheetEntry> _stack = <FlowSheetEntry>[];
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final ValueNotifier<SheetDragDismissMode> dragDismissModeNotifier =
      ValueNotifier<SheetDragDismissMode>(SheetDragDismissMode.fullBody);

  void Function([R? result])? _dismiss;
  PopupHandle<R>? _popupHandle;
  bool _sessionClaimed = false;
  SheetDragDismissMode _defaultDragDismissMode = SheetDragDismissMode.fullBody;

  /// 业务是否已关闭（pending Future 已完成、onClose 已触发）。
  /// 只由 [_closeBusiness] 置位；内部页面 pop 永远不会碰它。
  bool _closed = false;

  /// 对象是否已销毁。只管 notifier 释放，不参与任何业务判断。
  bool _disposed = false;

  @override
  bool get isDisposed => _disposed;

  @override
  List<FlowSheetEntry> get entries => List<FlowSheetEntry>.unmodifiable(_stack);

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  @override
  FlowSheetNavigator get navigator => this;

  /// 底层 Pop.sheet 的 Future 是否已完成（dismiss 已发生，退场动画可能还在播）。
  bool _sheetDismissed = false;

  bool _hostAttached = false;
  bool _hostDetached = false;
  bool _isHandlingBack = false;
  Object? _host;

  /// 由 [FlowSheetHost] 注入底层 sheet 的 dismiss 回调。
  void attachDismiss(void Function([R? result]) dismiss) {
    if (!_sessionClaimed) _sessionClaimed = true;
    _dismiss = dismiss;
  }

  void claimPopupSession() {
    if (_sessionClaimed || _disposed || _closed) {
      throw StateError('FlowSheetController is a one-shot session.');
    }
    _sessionClaimed = true;
  }

  /// Transfers this one-shot session to the unified outer popup handle.
  void attachPopupHandle(PopupHandle<R> handle) {
    if (_disposed || _closed) {
      throw StateError('A closed FlowSheetController cannot be attached.');
    }
    if (_popupHandle != null && !identical(_popupHandle, handle)) {
      throw StateError('FlowSheetController is a one-shot session.');
    }
    _sessionClaimed = true;
    _popupHandle = handle;
    handle.outcome.then((_) => _closeBusiness());
    handle.dismissed.then((_) {
      _sheetDismissed = true;
      _maybeDispose();
    });
  }

  /// 由 [FlowSheetHost] 的 initState 调用。
  @override
  void attachHost(Object host) {
    _host = host;
    _hostAttached = true;
    _hostDetached = false;
  }

  /// 由 [FlowSheetHost] 的 dispose 调用：宿主已卸载，满足条件即可真正销毁。
  ///
  /// 用身份判断过滤「宿主重挂载」场景下旧 State 的迟到 detach，
  /// 避免新宿主还活着时就销毁 controller。
  @override
  void detachHost(Object host) {
    if (!identical(_host, host)) return;
    _host = null;
    _hostDetached = true;
    _maybeDispose();
  }

  /// 底层 `Pop.sheet` 的 Future 完成时由 `Pop.flowSheet` 调用。
  ///
  /// 兜底两类不经过 [closeAll] 的关闭路径（路由切换自动 dismiss、
  /// PopupManager.hideByType 等外部关闭）：先同步收口业务，
  /// 再按「Host 是否已卸载」决定是否立即销毁对象。
  void handleSheetDismissed() {
    _closeBusiness();
    _sheetDismissed = true;
    _maybeDispose();
  }

  /// 业务关闭：完成所有 pending Future、触发 onHide/onClose。幂等。
  void _closeBusiness() {
    if (_closed) return;
    _closed = true;
    _isHandlingBack = false;
    for (final entry in _stack.reversed) {
      entry.completeIfPending();
      _disposeEntry(entry, FlowSheetLifecycleEndReason.close);
    }
    _syncDragDismissMode();
  }

  /// 仅当「sheet Future 已完成」且「Host 已卸载（或从未挂载）」时销毁对象。
  void _maybeDispose() {
    if (_disposed) return;
    if (!_sheetDismissed) return;
    if (_hostAttached && !_hostDetached) return;
    dispose();
  }

  void configureDragDismissMode(SheetDragDismissMode mode) {
    _defaultDragDismissMode = mode;
    _syncDragDismissMode();
  }

  /// 由 [FlowSheetHost] 在首帧注入初始页面。
  @override
  void ensureInitial(FlowSheetPage page) {
    if (_closed || _disposed) return;
    if (_stack.isNotEmpty) return;
    final entry = FlowSheetEntry(page);
    _stack.add(entry);
    _syncDragDismissMode();
    _scheduleShow(entry);
  }

  @override
  bool get canPop => _stack.length > 1;

  @override
  Future<T?> push<T>(FlowSheetPage<T> page) {
    if (_closed) return Future<T?>.value();
    final previousTop = _stack.isNotEmpty ? _stack.last : null;
    final entry = FlowSheetEntry(page);
    previousTop?.lifecycleController.hide();
    _stack.add(entry);
    _syncDragDismissMode();
    notifyListeners();
    _scheduleShow(entry);
    return entry.completer.future.then((value) => value as T?);
  }

  @override
  Future<T?> replace<T>(FlowSheetPage<T> page) {
    if (_closed) return Future<T?>.value();
    if (_stack.isEmpty) return push<T>(page);
    final removed = _stack.removeLast();
    final entry = FlowSheetEntry(page);
    _stack.add(entry);
    _syncDragDismissMode();
    notifyListeners();
    removed.completeIfPending();
    _disposeEntry(removed, FlowSheetLifecycleEndReason.remove);
    _scheduleShow(entry);
    return entry.completer.future.then((value) => value as T?);
  }

  @override
  void pop<T>([T? result]) {
    if (_closed) return;
    // 栈底页面不通过 pop 关闭，使用 closeAll 关闭整个 sheet。
    if (_stack.length <= 1) return;
    final entry = _stack.last;
    entry.pendingResult = result;
    // 结果回传不依赖 Navigator 动画回调：程序化 pop 立即完成业务 Future，
    // onDidRemovePage 只负责栈簿记与生命周期（completeIfPending 幂等）。
    entry.completeIfPending(result);
    final nav = _navigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      // 交给 Navigator 播放出场动画，移除由 onDidRemovePage 收口。
      nav.pop();
    } else {
      // Navigator 尚不可用时直接收口。
      handlePageRemoved(entry);
      notifyListeners();
    }
  }

  @override
  void completeCurrent<T>([T? result]) {
    if (_closed) return;
    if (_stack.isEmpty) return;
    final entry = _stack.last;
    entry.pendingResult = result;
    entry.completeIfPending(result);
  }

  /// 处理系统返回/侧滑返回。
  ///
  /// FlowSheet 承载在 overlay sheet 中，外层页面也可能通过 PopupManager
  /// 拦截返回；这里提供一个幂等入口，确保多页时优先退内部页面。
  @override
  bool handleBack([Object? result]) {
    if (_closed) return true;
    if (_isHandlingBack) return true;
    _isHandlingBack = true;
    if (canPop) {
      pop();
    } else {
      closeAll(result);
    }
    return true;
  }

  @override
  void closeAll([Object? result]) {
    if (_closed) return;
    _closeBusiness();
    final popupHandle = _popupHandle;
    if (popupHandle != null) {
      popupHandle.complete(result as R?);
    } else {
      _dismiss?.call(result as R?);
    }
  }

  /// 路由真正从栈移除时调用（程序化 pop / 系统返回 / iOS 侧滑均收口于此）。
  @override
  void handlePageRemoved(FlowSheetEntry entry) {
    if (_closed) return;
    if (!_stack.remove(entry)) return;
    entry.completeIfPending(entry.pendingResult);
    _disposeEntry(entry, FlowSheetLifecycleEndReason.remove);
    if (_stack.isNotEmpty) _scheduleShow(_stack.last);
    _syncDragDismissMode();
    _isHandlingBack = false;
  }

  void _syncDragDismissMode() {
    if (_disposed) return;
    final nextMode = _stack.isEmpty
        ? _defaultDragDismissMode
        : (_stack.last.page.dragDismissMode ?? _defaultDragDismissMode);
    if (dragDismissModeNotifier.value != nextMode) {
      dragDismissModeNotifier.value = nextMode;
    }
  }

  void _scheduleShow(FlowSheetEntry entry) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_closed ||
          entry.disposed ||
          _stack.isEmpty ||
          !identical(_stack.last, entry)) {
        return;
      }
      entry.lifecycleController.show();
    });
  }

  void _disposeEntry(
    FlowSheetEntry entry,
    FlowSheetLifecycleEndReason reason,
  ) {
    if (entry.disposed) return;
    entry.disposed = true;
    entry.lifecycleController.disposeLifecycle(reason);
  }

  @override
  void dispose() {
    // 幂等：延迟销毁握手与业务侧兜底调用可能并存。
    if (_disposed) return;
    // 直接 dispose 时也先完成业务收口，保证 pending Future / onClose 不丢。
    _closeBusiness();
    _disposed = true;
    _stack.clear();
    dragDismissModeNotifier.dispose();
    super.dispose();
  }
}
