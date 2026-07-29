import 'package:flutter/widgets.dart';

import '../../configs/sheet_types.dart';
import '../../controller/popup_handle.dart';
import '../contracts/flow_sheet_entry.dart';
import '../contracts/flow_sheet_host_delegate.dart';
import '../contracts/flow_sheet_navigator.dart';
import '../lifecycle/flow_sheet_lifecycle_controller.dart';
import '../pages/flow_sheet_page.dart';

/// FlowSheet 内部页面栈、结果与生命周期的控制器。
///
/// 展示层由内嵌在 sheet 中的 [Navigator]（Pages API + Cupertino 风格转场）承载。
/// 每个入栈页面都持有独立的 [Completer] 来管理结果，与路由 future 解耦，因此即使页面仍在
/// 播放动画，[closeAll] 也不会造成未完成 future 的泄漏。
///
/// 生命周期分为两个独立阶段：
/// 1. **业务关闭**：完成所有待处理 future，并触发页面的
///    [FlowSheetPageState.onHide]/[FlowSheetPageState.onClose] 钩子。当 [closeAll]
///    完成或外层弹窗结果落定时会同步执行。
/// 2. **对象销毁**（[dispose]）：释放各类 notifier。FlowSheet 宿主组件在退出动画期间可能仍持有
///    该控制器，因此销毁会推迟到弹窗被移除且宿主已卸载之后，以避免出现“已销毁后仍被使用”的错误。
///
/// [R] 是通过 [closeAll] 返回给打开该 sheet 调用方的最终结果类型。
///
/// 控制器是**一次性会话**：每次通过公开 API 打开 flow sheet 时都应创建新实例。
/// 复用已关闭或已被绑定的控制器会抛出 [StateError]。
class FlowSheetController<R> extends ChangeNotifier
    implements FlowSheetNavigator, FlowSheetHostDelegate {
  final List<FlowSheetEntry> _stack = <FlowSheetEntry>[];
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  final ValueNotifier<SheetDragDismissMode> dragDismissModeNotifier =
      ValueNotifier<SheetDragDismissMode>(SheetDragDismissMode.fullBody);

  PopupHandle<R>? _popupHandle;
  bool _sessionClaimed = false;
  SheetDragDismissMode _defaultDragDismissMode = SheetDragDismissMode.fullBody;

  bool _closed = false;

  bool _disposed = false;

  /// 该控制器是否已被销毁；销毁后不可再使用。
  @override
  bool get isDisposed => _disposed;

  /// 内部页面栈条目的一个不可修改视图。
  @override
  List<FlowSheetEntry> get entries => List<FlowSheetEntry>.unmodifiable(_stack);

  /// 用于渲染页面栈的内嵌 [Navigator] 对应的 key。
  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  /// 以 [FlowSheetNavigator] 形式暴露的当前控制器。
  @override
  FlowSheetNavigator get navigator => this;

  bool _popupDismissed = false;

  bool _hostAttached = false;
  bool _hostDetached = false;
  bool _isHandlingBack = false;
  Object? _host;

  /// 为单个弹窗会话保留此控制器。
  ///
  /// 在外层 sheet 展示之前调用。若会话已被占用，或控制器已关闭/已销毁，则抛出 [StateError]。
  void claimPopupSession() {
    if (_sessionClaimed || _disposed || _closed) {
      throw StateError('FlowSheetController is a one-shot session.');
    }
    _sessionClaimed = true;
  }

  /// 当外层弹窗请求在绑定 handle 之前被拒绝或取消时，释放会话占用。
  void releasePopupSessionClaim() {
    if (_popupHandle == null && !_closed && !_disposed) {
      _sessionClaimed = false;
    }
  }

  /// 将该一次性会话绑定到统一的外层弹窗 [handle]。
  ///
  /// 当 handle 的 outcome 完成时会自动执行业务关闭；当 handle 被 dismiss（退出动画结束）后，
  /// 一旦宿主卸载即可进行销毁。
  ///
  /// 若控制器已关闭、已销毁，或已绑定到另一个 handle，则抛出 [StateError]。
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
      _popupDismissed = true;
      _maybeDispose();
    });
  }

  /// 在 FlowSheet 宿主组件挂载时调用。
  @override
  void attachHost(Object host) {
    _host = host;
    _hostAttached = true;
    _hostDetached = false;
  }

  /// 在 FlowSheet 宿主组件卸载时调用。
  ///
  /// 通过身份比较来避免旧宿主实例的延迟 detach 在新宿主仍处于活跃状态时错误地销毁控制器。
  @override
  void detachHost(Object host) {
    if (!identical(_host, host)) return;
    _host = null;
    _hostDetached = true;
    _maybeDispose();
  }

  /// 完成所有待处理 future 并触发生命周期关闭钩子；具备幂等性。
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

  /// 仅在弹窗已被移除且宿主已卸载（或从未挂载）之后才销毁控制器。
  void _maybeDispose() {
    if (_disposed) return;
    if (!_popupDismissed) return;
    if (_hostAttached && !_hostDetached) return;
    dispose();
  }

  /// 设置默认的 [SheetDragDismissMode]，在栈顶页面未指定
  /// [FlowSheetPage.dragDismissMode] 时使用。
  ///
  /// 会立即更新 [dragDismissModeNotifier]。
  void configureDragDismissMode(SheetDragDismissMode mode) {
    _defaultDragDismissMode = mode;
    _syncDragDismissMode();
  }

  @override
  void updateDragDismissMode(SheetDragDismissMode mode) {
    if (_disposed || dragDismissModeNotifier.value == mode) return;
    dragDismissModeNotifier.value = mode;
  }

  /// 当栈仍为空时，将 [page] 注入为根条目。
  ///
  /// 由 FlowSheet 宿主组件在首帧调用。若控制器已关闭、已销毁，或栈中已有页面，则不做任何操作。
  @override
  void ensureInitial(FlowSheetPage page) {
    if (_closed || _disposed) return;
    if (_stack.isNotEmpty) return;
    final entry = FlowSheetEntry(page);
    _stack.add(entry);
    _syncDragDismissMode();
    _scheduleShow(entry);
  }

  /// 是否可以进行内部回退导航。
  ///
  /// 参见 [FlowSheetNavigator.canPop]。
  @override
  bool get canPop => _stack.length > 1;

  /// 将 [page] 推入内部栈。
  ///
  /// 语义参见 [FlowSheetNavigator.push]。若控制器已关闭，则返回一个立即完成的 future。
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

  /// 用 [page] 替换栈顶页面。
  ///
  /// 语义参见 [FlowSheetNavigator.replace]。
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

  /// 弹出栈顶的内部页面。
  ///
  /// 语义参见 [FlowSheetNavigator.pop]。根页面不能被弹出，请改用 [closeAll]。
  @override
  void pop<T>([T? result]) {
    if (_closed) return;
    // The root page cannot be popped; use closeAll to dismiss the sheet.
    if (_stack.length <= 1) return;
    final entry = _stack.last;
    entry.pendingResult = result;
    // Complete the business future immediately; route removal handles stack
    // bookkeeping and lifecycle (completeIfPending is idempotent).
    entry.completeIfPending(result);
    final nav = _navigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      // Let Navigator play the exit animation; onDidRemovePage finalizes.
      nav.pop();
    } else {
      // Navigator not ready yet; finalize directly.
      handlePageRemoved(entry);
      notifyListeners();
    }
  }

  /// 完成当前页面的结果，但不执行弹出操作。
  ///
  /// 语义参见 [FlowSheetNavigator.completeCurrent]。
  @override
  void completeCurrent<T>([T? result]) {
    if (_closed) return;
    if (_stack.isEmpty) return;
    final entry = _stack.last;
    entry.pendingResult = result;
    entry.completeIfPending(result);
  }

  /// 处理 FlowSheet 的系统返回与边缘滑动返回手势。
  ///
  /// 外层弹窗的返回桥接会委托到此处，使多页面流程在关闭 sheet 之前先弹出内部页面。
  /// 返回 `true` 表示返回事件已被消费。
  @override
  bool handleBack([Object? result]) {
    if (_closed) return true;
    if (_isHandlingBack) return true;
    if (handleCurrentPageBack()) return true;
    _isHandlingBack = true;
    if (canPop) {
      pop();
    } else {
      closeAll(result);
    }
    return true;
  }

  /// 仅询问当前页面是否消费返回，不执行默认的内部 pop 或关闭。
  bool handleCurrentPageBack() {
    return _stack.isNotEmpty && _stack.last.lifecycleController.handleBack();
  }

  /// 关闭整个 FlowSheet 并完成外层弹窗。
  ///
  /// 语义参见 [FlowSheetNavigator.closeAll]。
  @override
  void closeAll([Object? result]) {
    if (_closed) return;
    _closeBusiness();
    _popupHandle?.complete(result as R?);
  }

  /// 当路由真正从内嵌 navigator 中被移除时调用。
  ///
  /// 在同一处统一处理程序化 pop、系统返回以及 iOS 交互式返回手势。
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

  /// 释放资源并关闭任何尚未结束的业务状态。
  ///
  /// 具备幂等性；若被直接调用，也会先执行业务关闭，避免遗漏待处理 future 与 [onClose] 钩子。
  @override
  void dispose() {
    // Idempotent: delayed-disposal handshakes and direct calls may coexist.
    if (_disposed) return;
    // Run business close first so pending futures / onClose are not dropped.
    _closeBusiness();
    _disposed = true;
    _stack.clear();
    dragDismissModeNotifier.dispose();
    super.dispose();
  }
}
