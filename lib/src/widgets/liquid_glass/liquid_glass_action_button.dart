import 'package:flutter/material.dart';

import 'liquid_glass.dart';
import 'liquid_glass_button.dart';
import 'liquid_glass_style.dart';

/// A complete standalone liquid-glass action button.
class LiquidGlassActionButton extends StatelessWidget {
  const LiquidGlassActionButton({
    required this.child,
    required this.onTap,
    this.size,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.alignment = Alignment.center,
    this.style = LiquidGlassStyle.standard,
    this.blurSigma,
    this.blurDelay = Duration.zero,
    this.enableShadow = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double? size;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final AlignmentGeometry alignment;
  final LiquidGlassStyle style;
  final double? blurSigma;
  final Duration blurDelay;
  final bool enableShadow;

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width ?? size;
    final effectiveHeight = height ?? size;
    final radius = borderRadius ??
        (effectiveWidth != null && effectiveHeight != null
            ? BorderRadius.circular(
                effectiveWidth < effectiveHeight
                    ? effectiveWidth / 2
                    : effectiveHeight / 2,
              )
            : null);
    return LiquidGlass(
      width: effectiveWidth,
      height: effectiveHeight,
      margin: margin,
      borderRadius: radius,
      style: style,
      blurSigma: blurSigma,
      blurDelay: blurDelay,
      enableShadow: enableShadow,
      child: LiquidGlassButton(
        onTap: onTap,
        padding: padding,
        borderRadius: radius,
        alignment: alignment,
        style: style,
        child: child,
      ),
    );
  }
}
