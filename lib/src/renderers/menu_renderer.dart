import 'package:flutter/material.dart';

import '../configs/menu_config.dart';
import '../controller/popup_dismiss_reason.dart';
import '../controller/popup_handle.dart';
import 'popup_renderer_delegate.dart';

class MenuRenderer extends StatefulWidget {
  const MenuRenderer({
    required this.config,
    required this.handle,
    required this.motion,
    super.key,
  });

  final MenuConfigBase config;
  final PopupHandleBase handle;
  final PopupMotionController motion;

  @override
  State<MenuRenderer> createState() => _MenuRendererState();
}

class _MenuRendererState extends State<MenuRenderer> {
  Widget? _content;

  @override
  void initState() {
    super.initState();
    widget.config.anchor.attached.addListener(_onAnchorChanged);
  }

  @override
  void dispose() {
    widget.config.anchor.attached.removeListener(_onAnchorChanged);
    super.dispose();
  }

  void _onAnchorChanged() {
    if (!widget.config.anchor.attached.value && widget.handle.isActive) {
      widget.motion.dismiss(reason: PopupDismissReason.anchorDetached);
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    _content ??= config.buildContent(context, widget.handle);
    final placement = _resolvePlacement(context);
    final anchors = switch (placement) {
      MenuPlacement.belowStart => (Alignment.bottomLeft, Alignment.topLeft),
      MenuPlacement.belowEnd => (Alignment.bottomRight, Alignment.topRight),
      MenuPlacement.aboveStart => (Alignment.topLeft, Alignment.bottomLeft),
      MenuPlacement.aboveEnd => (Alignment.topRight, Alignment.bottomRight),
      MenuPlacement.auto => (Alignment.bottomLeft, Alignment.topLeft),
    };
    final decoration = config.style.decoration ??
        BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const <BoxShadow>[
            BoxShadow(
                color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
          ],
        );
    // Keep the follower's hit-test parent full-screen. A transformed child can
    // otherwise paint outside a shrink-wrapped Align while taps fall through
    // to the modal barrier behind it.
    return SizedBox.expand(
      child: Stack(
        children: <Widget>[
          CompositedTransformFollower(
            link: config.anchor.layerLink,
            showWhenUnlinked: false,
            targetAnchor: anchors.$1,
            followerAnchor: anchors.$2,
            offset: config.offset,
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: config.style.constraints,
                child: DecoratedBox(
                  decoration: decoration,
                  child: Padding(
                    padding: config.style.padding,
                    child: _content!,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  MenuPlacement _resolvePlacement(BuildContext context) {
    if (widget.config.placement != MenuPlacement.auto) {
      return widget.config.placement;
    }
    final rect = widget.config.anchor.globalRect;
    if (rect == null) return MenuPlacement.belowStart;
    final screen = MediaQuery.sizeOf(context);
    final above = screen.height - rect.bottom <
        widget.config.style.constraints.maxHeight.clamp(120, 320);
    final end = rect.center.dx > screen.width / 2;
    if (above) return end ? MenuPlacement.aboveEnd : MenuPlacement.aboveStart;
    return end ? MenuPlacement.belowEnd : MenuPlacement.belowStart;
  }
}
