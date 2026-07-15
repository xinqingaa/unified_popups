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
  final GlobalKey _menuSurfaceKey = GlobalKey();
  MenuPlacement? _resolvedAutoPlacement;
  bool _measurementScheduled = false;

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
    final waitingForAutoMeasurement = config.placement == MenuPlacement.auto &&
        _resolvedAutoPlacement == null;
    if (waitingForAutoMeasurement) _scheduleAutoPlacementResolution();
    final placement = config.placement == MenuPlacement.auto
        ? _resolvedAutoPlacement ?? MenuPlacement.belowStart
        : config.placement;
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
            child: Opacity(
              opacity: waitingForAutoMeasurement ? 0 : 1,
              child: KeyedSubtree(
                key: _menuSurfaceKey,
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
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleAutoPlacementResolution() {
    if (_measurementScheduled) return;
    _measurementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementScheduled = false;
      if (!mounted || _resolvedAutoPlacement != null) return;
      final renderObject = _menuSurfaceKey.currentContext?.findRenderObject();
      final anchorRect = widget.config.anchor.globalRect;
      if (renderObject is! RenderBox ||
          !renderObject.attached ||
          !renderObject.hasSize ||
          anchorRect == null) {
        setState(() => _resolvedAutoPlacement = MenuPlacement.belowStart);
        return;
      }
      final media = MediaQuery.of(context);
      setState(() {
        _resolvedAutoPlacement = _resolveAutoPlacement(
          anchorRect: anchorRect,
          menuSize: renderObject.size,
          media: media,
          offset: widget.config.offset,
        );
      });
    });
  }
}

MenuPlacement _resolveAutoPlacement({
  required Rect anchorRect,
  required Size menuSize,
  required MediaQueryData media,
  required Offset offset,
}) {
  final top = media.padding.top;
  final bottom = media.size.height -
      (media.viewInsets.bottom > media.padding.bottom
          ? media.viewInsets.bottom
          : media.padding.bottom);
  final left = media.padding.left;
  final right = media.size.width - media.padding.right;

  final belowTop = anchorRect.bottom + offset.dy;
  final aboveTop = anchorRect.top + offset.dy - menuSize.height;
  final belowOverflow = _axisOverflow(
    start: belowTop,
    end: belowTop + menuSize.height,
    min: top,
    max: bottom,
  );
  final aboveOverflow = _axisOverflow(
    start: aboveTop,
    end: aboveTop + menuSize.height,
    min: top,
    max: bottom,
  );
  final placeBelow = belowOverflow == 0 ||
      (aboveOverflow != 0 && belowOverflow <= aboveOverflow);

  final startLeft = anchorRect.left + offset.dx;
  final endLeft = anchorRect.right + offset.dx - menuSize.width;
  final startOverflow = _axisOverflow(
    start: startLeft,
    end: startLeft + menuSize.width,
    min: left,
    max: right,
  );
  final endOverflow = _axisOverflow(
    start: endLeft,
    end: endLeft + menuSize.width,
    min: left,
    max: right,
  );
  final preferEnd = anchorRect.center.dx > media.size.width / 2;
  final alignEnd = switch ((startOverflow, endOverflow)) {
    (0, 0) => preferEnd,
    (_, 0) => true,
    (0, _) => false,
    _ => endOverflow < startOverflow,
  };

  if (placeBelow) {
    return alignEnd ? MenuPlacement.belowEnd : MenuPlacement.belowStart;
  }
  return alignEnd ? MenuPlacement.aboveEnd : MenuPlacement.aboveStart;
}

double _axisOverflow({
  required double start,
  required double end,
  required double min,
  required double max,
}) {
  final before = start < min ? min - start : 0.0;
  final after = end > max ? end - max : 0.0;
  return before + after;
}
