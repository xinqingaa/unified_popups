import 'package:flutter/material.dart';

/// 用于 [LiquidGlass] 表面与按压反馈的、感知主题的视觉参数集合。
///
/// 可为 null 的颜色会在调用 [LiquidGlassStyle.resolve] 时基于当前 [ColorScheme] 解析。
/// 使用 [LiquidGlassStyle.standard] 或 [copyWith] 来定制个别数值。
@immutable
final class LiquidGlassStyle {
  /// 创建一个带有指定覆盖值的液态玻璃样式。
  ///
  /// [blurSigma]、[outlineWidth]、[topStrokeWidth] 与 [shadowBlurRadius] 必须非负；
  /// [pressScale] 必须在 `(0, 1]` 范围内。
  const LiquidGlassStyle({
    this.backgroundColor,
    this.borderColor,
    this.topHighlightColor,
    this.pressHighlightColor,
    this.shadowColor,
    this.blurSigma = 24,
    this.outlineWidth = 0.5,
    this.topStrokeWidth = 1.8,
    this.shadowBlurRadius = 24,
    this.shadowOffset = const Offset(0, 8),
    this.pressColorDuration = const Duration(milliseconds: 160),
    this.pressScaleDuration = const Duration(milliseconds: 200),
    this.pressScale = 0.94,
    this.pressCurve = const Cubic(0.2, 0.8, 0.2, 1),
  })  : assert(blurSigma >= 0),
        assert(outlineWidth >= 0),
        assert(topStrokeWidth >= 0),
        assert(shadowBlurRadius >= 0),
        assert(pressScale > 0 && pressScale <= 1);

  /// 使用主题解析颜色、模糊适中的默认样式。
  static const LiquidGlassStyle standard = LiquidGlassStyle();

  final Color? backgroundColor;

  final Color? borderColor;

  final Color? topHighlightColor;

  final Color? pressHighlightColor;

  final Color? shadowColor;

  final double blurSigma;

  final double outlineWidth;

  final double topStrokeWidth;

  final double shadowBlurRadius;

  final Offset shadowOffset;

  final Duration pressColorDuration;

  final Duration pressScaleDuration;

  final double pressScale;

  final Curve pressCurve;

  /// 返回一个替换了指定字段的该样式副本。
  LiquidGlassStyle copyWith({
    Color? backgroundColor,
    Color? borderColor,
    Color? topHighlightColor,
    Color? pressHighlightColor,
    Color? shadowColor,
    double? blurSigma,
    double? outlineWidth,
    double? topStrokeWidth,
    double? shadowBlurRadius,
    Offset? shadowOffset,
    Duration? pressColorDuration,
    Duration? pressScaleDuration,
    double? pressScale,
    Curve? pressCurve,
  }) {
    return LiquidGlassStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      topHighlightColor: topHighlightColor ?? this.topHighlightColor,
      pressHighlightColor: pressHighlightColor ?? this.pressHighlightColor,
      shadowColor: shadowColor ?? this.shadowColor,
      blurSigma: blurSigma ?? this.blurSigma,
      outlineWidth: outlineWidth ?? this.outlineWidth,
      topStrokeWidth: topStrokeWidth ?? this.topStrokeWidth,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      pressColorDuration: pressColorDuration ?? this.pressColorDuration,
      pressScaleDuration: pressScaleDuration ?? this.pressScaleDuration,
      pressScale: pressScale ?? this.pressScale,
      pressCurve: pressCurve ?? this.pressCurve,
    );
  }
}

/// 在当前主题下完全解析后的 [LiquidGlassStyle] 颜色集合。
///
/// 由 [LiquidGlassStyle.resolve] 生成；传递给内部绘制器，并被 [LiquidGlassButton]
/// 用于按压反馈。
@immutable
final class ResolvedLiquidGlassStyle {
  /// 创建一个具备具体颜色并关联到 [source] 的已解析样式。
  const ResolvedLiquidGlassStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.topHighlightColor,
    required this.pressHighlightColor,
    required this.shadowColor,
    required this.source,
  });

  final Color backgroundColor;

  final Color borderColor;

  final Color topHighlightColor;

  final Color pressHighlightColor;

  final Color shadowColor;

  final LiquidGlassStyle source;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ResolvedLiquidGlassStyle &&
            backgroundColor == other.backgroundColor &&
            borderColor == other.borderColor &&
            topHighlightColor == other.topHighlightColor &&
            pressHighlightColor == other.pressHighlightColor &&
            shadowColor == other.shadowColor &&
            source == other.source;
  }

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        borderColor,
        topHighlightColor,
        pressHighlightColor,
        shadowColor,
        source,
      );
}

/// 基于 [ThemeData] 解析 [LiquidGlassStyle] 中可为 null 的颜色。
extension LiquidGlassStyleResolution on LiquidGlassStyle {
  /// 基于当前 Material 主题解析可为 null 的颜色覆盖值。
  ResolvedLiquidGlassStyle resolve(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return ResolvedLiquidGlassStyle(
      backgroundColor:
          backgroundColor ?? colors.surface.withAlpha(dark ? 0x8C : 0xB3),
      borderColor:
          borderColor ?? colors.onSurface.withAlpha(dark ? 0x3D : 0x30),
      topHighlightColor:
          topHighlightColor ?? Colors.white.withAlpha(dark ? 0x8F : 0xB8),
      pressHighlightColor:
          pressHighlightColor ?? colors.onSurface.withAlpha(dark ? 0x24 : 0x18),
      shadowColor: shadowColor ?? colors.shadow.withAlpha(dark ? 0x73 : 0x38),
      source: this,
    );
  }
}
