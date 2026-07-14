import 'package:flutter/widgets.dart';

import '../../configs/sheet_types.dart';
import '../contracts/flow_sheet_navigator.dart';
import '../lifecycle/flow_sheet_lifecycle_controller.dart';

/// FlowSheet 中的一个页面。
///
/// 负责声明 page id、保活策略和 pop 结果类型。业务页面统一继承它，
/// State 统一继承 [FlowSheetPageState]。
abstract class FlowSheetPage<T> extends StatefulWidget {
  const FlowSheetPage({
    super.key,
    required this.id,
    this.maintainState = false,
    this.dragDismissMode,
  });

  /// 页面标识，便于调试。
  final String id;

  /// 是否在被上层页面覆盖时保活。
  final bool maintainState;

  /// 当前页面作为 FlowSheet 顶层页时使用的拖动关闭策略。
  ///
  /// 为 null 时使用 FlowSheet 打开时传入的默认策略。
  final SheetDragDismissMode? dragDismissMode;
}

/// FlowSheet 页面 State 基类。
///
/// 基础能力是 [nav] 和 [isFlowSheetVisible]。生命周期 hook 是可选能力：
/// 需要时 override [onLoad]、[onShow]、[onHide]、[onRemove]、[onClose]，
/// 不需要时只实现普通 [build] 即可。
///
/// 生命周期顺序：
/// - 首次成为当前页：onLoad -> onShow
/// - 被新页面覆盖：onHide
/// - 上层页面 pop 后重新露出：onShow
/// - 页面从栈移除：onHide（若当前可见）-> onRemove
/// - 整个 sheet 关闭：onHide（若当前可见）-> onClose
abstract class FlowSheetPageState<W extends FlowSheetPage<T>, T>
    extends State<W> implements FlowSheetLifecycleObserver {
  FlowSheetPageLifecycleController? _lifecycleController;
  FlowSheetNavigator? _navigator;
  bool _loaded = false;
  bool _visible = false;
  bool _endedByFlowSheet = false;

  /// FlowSheet 内部导航器。
  FlowSheetNavigator get nav {
    final navigator = _navigator;
    if (navigator == null) {
      throw StateError(
        'FlowSheetPageState.nav is unavailable before didChangeDependencies.',
      );
    }
    return navigator;
  }

  /// 当前 FlowSheet 页面是否处于有效可见状态。
  bool get isFlowSheetVisible => _lifecycleController?.isVisible ?? false;

  /// 页面实例第一次进入 FlowSheet 生命周期，只触发一次。
  void onLoad() {}

  /// 页面成为当前有效可见页，首次显示和返回露出都会触发。
  void onShow() {}

  /// 页面不再是当前有效可见页，例如被覆盖、替换、pop 或 sheet 关闭。
  void onHide() {}

  /// 页面被 pop 或 replace，从 FlowSheet 栈移除。
  void onRemove() {}

  /// 整个 FlowSheet 关闭，导致页面结束。
  void onClose() {}

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
