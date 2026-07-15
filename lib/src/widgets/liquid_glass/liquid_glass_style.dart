import 'package:flutter/material.dart';

/// Theme-aware visual overrides for liquid-glass surfaces.
///
/// Colors left null are resolved from the ambient [ColorScheme].
@immutable
final class LiquidGlassStyle {
  const LiquidGlassStyle({
    this.backgroundColor,
    this.borderColor,
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

  static const LiquidGlassStyle standard = LiquidGlassStyle();

  final Color? backgroundColor;
  final Color? borderColor;
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

  LiquidGlassStyle copyWith({
    Color? backgroundColor,
    Color? borderColor,
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

@immutable
final class ResolvedLiquidGlassStyle {
  const ResolvedLiquidGlassStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.pressHighlightColor,
    required this.shadowColor,
    required this.source,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color pressHighlightColor;
  final Color shadowColor;
  final LiquidGlassStyle source;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ResolvedLiquidGlassStyle &&
            backgroundColor == other.backgroundColor &&
            borderColor == other.borderColor &&
            pressHighlightColor == other.pressHighlightColor &&
            shadowColor == other.shadowColor &&
            source == other.source;
  }

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        borderColor,
        pressHighlightColor,
        shadowColor,
        source,
      );
}

extension LiquidGlassStyleResolution on LiquidGlassStyle {
  /// Resolves nullable color overrides against the current Material theme.
  ResolvedLiquidGlassStyle resolve(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return ResolvedLiquidGlassStyle(
      backgroundColor:
          backgroundColor ?? colors.surface.withAlpha(dark ? 0xB8 : 0xD9),
      borderColor:
          borderColor ?? colors.onSurface.withAlpha(dark ? 0x2E : 0x24),
      pressHighlightColor:
          pressHighlightColor ?? colors.onSurface.withAlpha(dark ? 0x24 : 0x18),
      shadowColor: shadowColor ?? colors.shadow.withAlpha(dark ? 0x73 : 0x38),
      source: this,
    );
  }
}
