import 'package:flutter/widgets.dart';

final class PopupAnchorController {
  PopupAnchorController();

  final LayerLink layerLink = LayerLink();
  final GlobalKey anchorKey = GlobalKey();
  final ValueNotifier<bool> attached = ValueNotifier<bool>(false);

  Rect? get globalRect {
    final box = anchorKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

class PopupAnchor extends StatefulWidget {
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
