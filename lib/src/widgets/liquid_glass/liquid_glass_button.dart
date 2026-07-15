import 'package:flutter/material.dart';

import 'liquid_glass_style.dart';

/// Interactive region intended for placement inside a liquid-glass surface.
class LiquidGlassButton extends StatefulWidget {
  const LiquidGlassButton({
    required this.child,
    required this.onTap,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.alignment = Alignment.center,
    this.style = LiquidGlassStyle.standard,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final AlignmentGeometry alignment;
  final LiquidGlassStyle style;

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final resolved = widget.style.resolve(context);
    Widget result = SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : widget.style.pressColorDuration,
              color:
                  _pressed ? resolved.pressHighlightColor : Colors.transparent,
            ),
          ),
          Align(
            alignment: widget.alignment,
            child: Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: AnimatedScale(
                scale: _pressed ? widget.style.pressScale : 1,
                duration: reduceMotion
                    ? Duration.zero
                    : widget.style.pressScaleDuration,
                curve: widget.style.pressCurve,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
    if (widget.borderRadius != null) {
      result = ClipRRect(borderRadius: widget.borderRadius!, child: result);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTap: widget.onTap,
      child: result,
    );
  }
}
