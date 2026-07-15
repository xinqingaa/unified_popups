import 'package:flutter/widgets.dart';

/// 保存用于将锚定弹窗（例如菜单）相对某个组件定位的锚点几何信息。
///
/// 每个锚点创建一个控制器实例并传给 [PopupAnchor]。打开锚定弹窗时读取
/// [layerLink] 与 [anchorKey]，并监听 [attached] 以获知锚点何时完成布局。
final class PopupAnchorController {
  /// 为单个 [PopupAnchor] 组件创建控制器。
  PopupAnchorController();

  final LayerLink layerLink = LayerLink();

  final GlobalKey anchorKey = GlobalKey();

  final ValueNotifier<bool> attached = ValueNotifier<bool>(false);

  /// 锚点在全局坐标系中的边界；若尚未完成布局，则为 `null`。
  Rect? get globalRect {
    final box = anchorKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

/// 为 [child] 包裹上锚定弹窗所需的 [LayerLink] 与 [GlobalKey]。
///
/// 配合 [PopupAnchorController] 使用，并将 `controller.anchorKey`（以及
/// `controller.layerLink`）传给锚定弹窗相关 API。
class PopupAnchor extends StatefulWidget {
  /// 围绕 [child] 创建一个锚点。
  const PopupAnchor({
    required this.controller,
    required this.child,
    super.key,
  });

  final PopupAnchorController controller;

  final Widget child;

  @override
  State<PopupAnchor> createState() => _PopupAnchorState();
}

class _PopupAnchorState extends State<PopupAnchor> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.attached.value = true;
    });
  }

  @override
  void didUpdateWidget(PopupAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.attached.value = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.controller.attached.value = true;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.attached.value = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: widget.controller.layerLink,
      child: KeyedSubtree(
        key: widget.controller.anchorKey,
        child: widget.child,
      ),
    );
  }
}
