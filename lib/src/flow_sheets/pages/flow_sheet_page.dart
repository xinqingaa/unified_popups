import 'package:flutter/widgets.dart';

import '../../configs/sheet_types.dart';
import '../contracts/flow_sheet_navigator.dart';
import '../lifecycle/flow_sheet_lifecycle_controller.dart';

/// FlowSheet 内部的单个页面。
///
/// 为多页面 sheet 流程的每一步创建该组件的子类，并配合 [FlowSheetPageState] 子类实现
/// 导航与可选的生命周期钩子。
abstract class FlowSheetPage<T> extends StatefulWidget {
  /// 创建一个 FlowSheet 页面。
  ///
  /// [id] 是页种类键（同一类步骤/主页用同一个 [id]，如 `'trade-main'`）。
  /// 同一 [id] 在一场会话的栈内只允许一页：[FlowSheetNavigator.push] 遇到已有
  /// 同 `id` 时会卸掉旧页再放入新页（栈顶则 [FlowSheetNavigator.replace]）。
  /// [identity] 是可选的业务对象键（如 `symbol`、`orderNo`），供查找与日志使用，
  /// 不是栈内唯一键，也不能让同一 [id] 并存多份。
  ///
  /// [FlowSheetNavigator.contains] / [FlowSheetNavigator.popTo] 不传
  /// `identity` 时按 [id] 查找；传了再按对象键收窄。
  ///
  /// [maintainState] 决定该页面被其他页面覆盖时是否保留状态。[dragDismissMode]
  /// 在该页面位于栈顶时覆盖整体的拖拽关闭模式；为 null 时使用打开 sheet 时配置的模式。
  ///
  /// [enableSwipePop] 为 false 时，非首页不使用 [CupertinoPageRoute]，从而禁用 iOS 侧滑返回
  /// （侧滑会直接 pop 内嵌路由，绕过 [FlowSheetPageState.onBack]）。
  const FlowSheetPage({
    super.key,
    required this.id,
    this.identity,
    this.maintainState = false,
    this.dragDismissMode,
    this.enableSwipePop = true,
  });

  final String id;

  /// 可选业务对象键（日志 / [FlowSheetNavigator.contains] 收窄），不参与唯一性。
  final String? identity;

  /// `identity == null ? id : '$id#$identity'`，便于日志；栈内唯一按 [id]。
  String get instanceId => identity == null ? id : '$id#$identity';

  final bool maintainState;

  final SheetDragDismissMode? dragDismissMode;

  /// 非首页是否允许 iOS 侧滑返回（默认 true）。
  final bool enableSwipePop;
}

/// [FlowSheetPage] 子类对应的基础 [State]。
///
/// 提供 [nav] 用于栈内导航，[isFlowSheetVisible] 用于查询可见性。生命周期钩子
/// （[onLoad]、[onShow]、[onHide]、[onRemove]、[onClose]、[onPoppedTo]）均为可选，按需重写即可。
///
/// 生命周期触发顺序：
/// - 页面首次成为当前页：[onLoad] → [onShow]
/// - 被新入栈的页面覆盖：[onHide]
/// - 上方页面弹出后再次显示：[onShow]
/// - 因 [FlowSheetNavigator.popTo] 成为栈顶：[onShow]（若刚恢复可见）→ [onPoppedTo]
/// - 从栈中移除（pop 或 replace）：[onHide]（若可见）→ [onRemove]
/// - 整个 sheet 关闭：[onHide]（若可见）→ [onClose]
abstract class FlowSheetPageState<W extends FlowSheetPage<T>, T>
    extends State<W> implements FlowSheetLifecycleObserver {
  FlowSheetPageLifecycleController? _lifecycleController;
  FlowSheetNavigator? _navigator;
  bool _loaded = false;
  bool _visible = false;
  bool _endedByFlowSheet = false;

  /// FlowSheet 的内部导航器。
  ///
  /// 在 [didChangeDependencies] 执行之后才可用；提前访问会抛出 [StateError]。
  FlowSheetNavigator get nav {
    final navigator = _navigator;
    if (navigator == null) {
      throw StateError(
        'FlowSheetPageState.nav is unavailable before didChangeDependencies.',
      );
    }
    return navigator;
  }

  /// 该页面是否是 FlowSheet 栈中当前可见的页面。
  bool get isFlowSheetVisible => _lifecycleController?.isVisible ?? false;

  /// 该页面首次进入 FlowSheet 生命周期时调用一次。
  void onLoad() {}

  /// 当该页面成为可见的栈顶页面时调用。
  ///
  /// 首次显示以及上方页面被弹出后都会触发。
  void onShow() {}

  /// 当该页面不再是可见的栈顶页面时调用。
  ///
  /// 在被覆盖、替换、弹出，或整个 sheet 关闭时触发。
  void onHide() {}

  /// 当该页面通过 [pop] 或 [replace] 从栈中移除时调用。
  void onRemove() {}

  /// 当整个 FlowSheet 关闭而该页面仍在栈中时调用。
  void onClose() {}

  /// 因 [FlowSheetNavigator.popTo] 重新成为栈顶且携带业务结果时调用。
  ///
  /// 普通 [pop] / 系统返回只会 [onShow]，不会走这里。[result] 可能为 null。
  void onPoppedTo(Object? result) {}

  /// 当前页面处理返回事件；返回 true 时阻止默认的内部 pop/关闭行为。
  bool onBack() => false;

  @override
  bool handleBack() => onBack();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = FlowSheetPageScope.maybeOf(context);
    _navigator = scope?.navigator;
    final nextController = scope?.lifecycleController;
    if (identical(_lifecycleController, nextController)) return;
    _lifecycleController?.removeObserver(this);
    _lifecycleController = nextController;
    _loaded = false;
    _visible = false;
    _endedByFlowSheet = false;
    _lifecycleController?.addObserver(this);
  }

  @override
  void handleLoad() {
    if (_loaded || _endedByFlowSheet) return;
    _loaded = true;
    onLoad();
  }

  @override
  void handleShow() {
    if (_endedByFlowSheet) return;
    handleLoad();
    if (_visible) return;
    _visible = true;
    onShow();
  }

  @override
  void handleHide() {
    if (_endedByFlowSheet || !_visible) return;
    _visible = false;
    onHide();
  }

  @override
  void handleRemove() {
    if (_endedByFlowSheet) return;
    handleHide();
    _endedByFlowSheet = true;
    onRemove();
  }

  @override
  void handleClose() {
    if (_endedByFlowSheet) return;
    handleHide();
    _endedByFlowSheet = true;
    onClose();
  }

  @override
  void handlePoppedTo(Object? result) {
    if (_endedByFlowSheet) return;
    onPoppedTo(result);
  }

  @override
  void dispose() {
    _lifecycleController?.removeObserver(this);
    super.dispose();
  }
}
