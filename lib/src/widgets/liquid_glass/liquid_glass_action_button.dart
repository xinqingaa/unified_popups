import 'package:flutter/material.dart';

import 'liquid_glass.dart';
import 'liquid_glass_button.dart';
import 'liquid_glass_style.dart';

/// 一个自带液态玻璃外观的独立可点击控件。
///
/// 将 [LiquidGlass] 与 [LiquidGlassButton] 组合成单一组件。当只需要一个磨砂质感的
/// 操作控件时，优先使用该组件而非手动组合两者。
class LiquidGlassActionButton extends StatelessWidget {
  /// 创建一个在按下时调用 [onTap] 的液态玻璃按钮。
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
