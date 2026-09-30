import 'dart:async';

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
/// 生命周期分为三个阶段：
/// 1. **结束业务会话**（[closeAll] / outcome）：完成 pending future，禁止再导航；
///    **保留页面树**供外层 Sheet 退出动画使用。
/// 2. **页面收尾**（dismissed）：触发 [FlowSheetPageState.onHide] /
///    [FlowSheetPageState.onClose]，卸生命周期。
/// 3. **对象销毁**（[dispose]）：释放 notifier。推迟到弹窗移除且宿主卸载之后。
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

  /// True while an animated [resetTo] is playing; back must not reveal the
  /// previous root (password / gate) underneath the incoming home page.
  bool _isResettingTo = false;
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

  /// 绑定外层弹窗 [handle]。
  ///
  /// - [PopupHandle.outcome] 落定时：结束业务会话（完成 pending future、禁止再导航），
  ///   **不立刻卸页面**，以便退出动画期间内容与 Sheet 一起滑走。
  /// - [PopupHandle.dismissed]（退出动画结束）后：触发页面 onClose / 卸生命周期，
  ///   再在宿主卸载后销毁控制器。
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
    handle.outcome.then((_) => _endSessionKeepPages());
    handle.dismissed.then((_) {
      _disposeStackForClose();
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

  /// 结束业务会话：完成 pending future、禁止再导航；页面留给退出动画。
  void _endSessionKeepPages() {
    if (_closed) return;
    _closed = true;
    _isHandlingBack = false;
    _isResettingTo = false;
    for (final entry in _stack.reversed) {
      entry.completeIfPending();
    }
  }

  /// 退出动画结束后卸页面生命周期（onHide → onClose）。
  void _disposeStackForClose() {
    for (final entry in _stack.reversed) {
      _disposeEntry(entry, FlowSheetLifecycleEndReason.close);
    }
    _syncDragDismissMode();
  }

  /// 结束业务会话并卸掉页面；供 [dispose] 等同步收尾路径使用。
  void _closeBusiness() {
    _endSessionKeepPages();
    _disposeStackForClose();
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

  @override
  bool contains(String id, {String? identity}) =>
      _indexOf(id, identity: identity) != null;

  /// 将 [page] 推入内部栈。同 [id] 只留一页：栈顶相同则 [replace]，
  /// 在下面则只卸那一页再压新页。语义参见 [FlowSheetNavigator.push]。
  @override
  Future<T?> push<T>(FlowSheetPage<T> page) {
    if (_closed) return Future<T?>.value();
    final existingIndex = _indexOf(page.id);
    if (existingIndex != null && existingIndex == _stack.length - 1) {
      return replace<T>(page);
    }
    if (existingIndex != null) {
      _spliceAt(existingIndex);
    }
    return _pushNew<T>(page);
  }

  Future<T?> _pushNew<T>(FlowSheetPage<T> page) {
    final previousTop = _stack.isNotEmpty ? _stack.last : null;
    final entry = FlowSheetEntry(page);
    previousTop?.lifecycleController.hide();
    _stack.add(entry);
    _syncDragDismissMode();
    notifyListeners();
    _scheduleShow(entry);
    return entry.completer.future.then((value) => value as T?);
  }

  /// 只卸掉 [index] 那一条，上面的页原位留下。
  void _spliceAt(int index) {
    final removed = _stack.removeAt(index);
    removed.completeIfPending();
    _disposeEntry(removed, FlowSheetLifecycleEndReason.remove);
  }

  /// 用 [page] 替换栈顶页面。
  ///
  /// 语义参见 [FlowSheetNavigator.replace]。
  @override
  Future<T?> replace<T>(FlowSheetPage<T> page) {
    if (_closed) return Future<T?>.value();
    if (_stack.isEmpty) return _pushNew<T>(page);
    final existingIndex = _indexOf(page.id);
    if (existingIndex != null && existingIndex < _stack.length - 1) {
      _spliceAt(existingIndex);
    }
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

  /// 弹出到根页面。
  ///
  /// 语义参见 [FlowSheetNavigator.popToRoot]。
  @override
  void popToRoot([Object? result]) {
    if (_closed) return;
    if (_stack.length <= 1) return;

    final root = _stack.first;
    final toRemove = _stack.sublist(1);
    _stack
      ..clear()
      ..add(root);

    // Topmost waiter gets [result]; intermediate pages complete with null.
    for (var i = toRemove.length - 1; i >= 0; i--) {
      final entry = toRemove[i];
      final entryResult = i == toRemove.length - 1 ? result : null;
      entry.pendingResult = entryResult;
      entry.completeIfPending(entryResult);
      _disposeEntry(entry, FlowSheetLifecycleEndReason.remove);
    }

    _syncDragDismissMode();
    notifyListeners();
    _scheduleShow(root);
    _isHandlingBack = false;
  }

  /// 弹出直到 [id] 成为栈顶。
  ///
  /// 语义参见 [FlowSheetNavigator.popTo]。
  @override
  void popTo(String id, [Object? result, String? identity]) {
    if (_closed) return;
    final index = _indexOf(id, identity: identity);
    assert(
      index != null,
      'FlowSheet has no page id="$id"'
      '${identity != null ? ' identity="$identity"' : ''}.',
    );
    if (index == null) return;
    if (index == _stack.length - 1) return;

    final target = _stack[index];
    final toRemove = _stack.sublist(index + 1);
    _stack.removeRange(index + 1, _stack.length);

    for (final entry in toRemove.reversed) {
      entry.completeIfPending();
      _disposeEntry(entry, FlowSheetLifecycleEndReason.remove);
    }

    _syncDragDismissMode();
    notifyListeners();
    _scheduleShow(target, poppedToResult: result, deliverPoppedTo: true);
    _isHandlingBack = false;
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

  /// 交付当前页结果并关闭整张 FlowSheet。
  ///
  /// 语义参见 [FlowSheetNavigator.completeAndCloseAll]。
  @override
  void completeAndCloseAll<T>([T? result]) {
    if (_closed) return;
    completeCurrent<T>(result);
    closeAll(result);
  }

  /// 将内部栈重置为单一 [page]。
  ///
  /// 语义参见 [FlowSheetNavigator.resetTo]。
  @override
  Future<T?> resetTo<T>(FlowSheetPage<T> page, {bool animate = false}) {
    if (_closed) return Future<T?>.value();
    if (animate && _stack.isNotEmpty) {
      return _resetToAnimated(page);
    }
    return _resetToImmediate(page);
  }

  Future<T?> _resetToImmediate<T>(FlowSheetPage<T> page) {
    final removing = List<FlowSheetEntry>.from(_stack);
    _stack.clear();
    for (final entry in removing) {
      entry.completeIfPending(entry.pendingResult);
      _disposeEntry(entry, FlowSheetLifecycleEndReason.remove);
    }
    final entry = FlowSheetEntry(page);
    _stack.add(entry);
    _syncDragDismissMode();
    notifyListeners();
    _scheduleShow(entry);
    return entry.completer.future.then((value) => value as T?);
  }

  Future<T?> _resetToAnimated<T>(FlowSheetPage<T> page) {
    _stack.last.lifecycleController.hide();
    final entry = FlowSheetEntry(page, suppressSwipePop: true);
    _stack.add(entry);
    _isResettingTo = true;
    _syncDragDismissMode();
    notifyListeners();
    _scheduleShow(entry);
    unawaited(_finishAnimatedResetTo(entry));
    return entry.completer.future.then((value) => value as T?);
  }

  Future<void> _finishAnimatedResetTo(FlowSheetEntry entry) async {
    try {
      await _waitForIncomingRouteAnimation(entry);
      if (!_closed && !entry.disposed) {
        _collapseBelow(entry);
      }
    } finally {
      _isResettingTo = false;
    }
  }

  /// Drop every page under [keep] after the incoming enter animation.
  ///
  /// [keep] stays the same [FlowSheetEntry] so the Navigator keeps its route
  /// and does not replay the enter transition.
  void _collapseBelow(FlowSheetEntry keep) {
    if (_closed || keep.disposed) return;
    if (_stack.isEmpty || !identical(_stack.last, keep)) return;
    if (_stack.length <= 1) return;
    final removing = _stack.sublist(0, _stack.length - 1);
    _stack
      ..clear()
      ..add(keep);
    _syncDragDismissMode();
    notifyListeners();
    for (final entry in removing) {
      entry.completeIfPending(entry.pendingResult);
      _disposeEntry(entry, FlowSheetLifecycleEndReason.remove);
    }
  }

  Future<void> _waitForIncomingRouteAnimation(FlowSheetEntry entry) async {
    final incoming = await _waitForIncomingRoute(entry);
    if (incoming == null) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return;
    }

    final animation = incoming.animation;
    if (animation == null || animation.isCompleted || animation.isDismissed) {
      return;
    }

    final done = Completer<void>();
    void listener(AnimationStatus status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        animation.removeStatusListener(listener);
        if (!done.isCompleted) done.complete();
      }
    }

    animation.addStatusListener(listener);
    if (animation.isCompleted || animation.isDismissed) {
      animation.removeStatusListener(listener);
      if (!done.isCompleted) done.complete();
    }
    await done.future;
  }

  Future<ModalRoute<dynamic>?> _waitForIncomingRoute(
      FlowSheetEntry entry) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      await _nextFrame();
      final top = _topModalRoute();
      if (top != null && _routeOwnsEntry(top, entry)) return top;
    }
    return null;
  }

  Future<void> _nextFrame() {
    final frame = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!frame.isCompleted) frame.complete();
    });
    return frame.future;
  }

  ModalRoute<dynamic>? _topModalRoute() {
    final nav = _navigatorKey.currentState;
    if (nav == null) return null;
    Route<dynamic>? top;
    nav.popUntil((route) {
      top = route;
      return true;
    });
    final route = top;
    return route is ModalRoute<dynamic> ? route : null;
  }

  bool _routeOwnsEntry(Route<dynamic> route, FlowSheetEntry entry) {
    final settings = route.settings;
    return settings is Page<dynamic> &&
        settings.key == ValueKey<FlowSheetEntry>(entry);
  }

  /// 卸掉栈顶已交付结果的页面。
  ///
  /// 语义参见 [FlowSheetNavigator.discardCompletedAbove]。
  @override
  void discardCompletedAbove() {
    if (_closed) return;
    var changed = false;
    while (_stack.length > 1 && _stack.last.completer.isCompleted) {
      final entry = _stack.removeLast();
      _disposeEntry(entry, FlowSheetLifecycleEndReason.remove);
      changed = true;
    }
    if (!changed) return;
    if (_stack.isNotEmpty) _scheduleShow(_stack.last);
    _syncDragDismissMode();
    notifyListeners();
  }

  /// 处理 FlowSheet 的系统返回与边缘滑动返回手势。
  ///
  /// 外层弹窗的返回桥接会委托到此处，使多页面流程在关闭 sheet 之前先弹出内部页面。
  /// 返回 `true` 表示返回事件已被消费。
  @override
  bool handleBack([Object? result]) {
    if (_closed) return true;
    if (_isHandlingBack) return true;
    if (_isResettingTo) return true;
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
  ///
  /// 结束业务会话并 complete 外层 handle；页面树保留到退出动画结束，
  /// 避免「内容先消失、空壳再下滑」。
  @override
  void closeAll([Object? result]) {
    if (_closed) return;
    _endSessionKeepPages();
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

  /// 不传 [identity] 时按 [FlowSheetPage.id]（种类）查找；
  /// 传了 [identity] 时再按对象键收窄。同 [id] 栈内最多一页。
  int? _indexOf(String id, {String? identity}) {
    for (var i = 0; i < _stack.length; i++) {
      final page = _stack[i].page;
      if (page.id != id) continue;
      if (identity != null && page.identity != identity) continue;
      return i;
    }
    return null;
  }

  void _scheduleShow(
    FlowSheetEntry entry, {
    Object? poppedToResult,
    bool deliverPoppedTo = false,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_closed ||
          entry.disposed ||
          _stack.isEmpty ||
          !identical(_stack.last, entry)) {
        return;
      }
      entry.lifecycleController.show();
      if (deliverPoppedTo) {
        entry.lifecycleController.poppedTo(poppedToResult);
      }
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
