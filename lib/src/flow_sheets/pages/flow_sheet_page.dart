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
  /// [id] 用于调试，在同一个流程内应保持唯一。[maintainState] 决定该页面被其他页面覆盖时
  /// 是否保留状态。[dragDismissMode] 在该页面位于栈顶时覆盖整体的拖拽关闭模式；为 null 时
  /// 使用打开 sheet 时配置的模式。
  const FlowSheetPage({
    super.key,
    required this.id,
    this.maintainState = false,
    this.dragDismissMode,
  });

  final String id;

  final bool maintainState;

  final SheetDragDismissMode? dragDismissMode;
}

/// [FlowSheetPage] 子类对应的基础 [State]。
///
/// 提供 [nav] 用于栈内导航，[isFlowSheetVisible] 用于查询可见性。生命周期钩子
/// （[onLoad]、[onShow]、[onHide]、[onRemove]、[onClose]）均为可选，按需重写即可。
///
/// 生命周期触发顺序：
/// - 页面首次成为当前页：[onLoad] → [onShow]
/// - 被新入栈的页面覆盖：[onHide]
/// - 上方页面弹出后再次显示：[onShow]
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
  void dispose() {
    _lifecycleController?.removeObserver(this);
    super.dispose();
  }
}
