import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'liquid_glass_edge_painter.dart';
import 'liquid_glass_style.dart';

/// A reusable, theme-aware liquid-glass surface.
class LiquidGlass extends StatefulWidget {
  const LiquidGlass({
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.style = LiquidGlassStyle.standard,
    this.blurSigma,
    this.blurDelay = Duration.zero,
    this.backdropBlendMode = BlendMode.srcOver,
    this.enableShadow = false,
    super.key,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final LiquidGlassStyle style;
  final double? blurSigma;
  final Duration blurDelay;

  /// Blend mode used when compositing the filtered backdrop.
  ///
  /// [BlendMode.src] avoids double blending when an ancestor uses an opacity
  /// save layer. The default keeps Flutter's broadly supported behavior.
  final BlendMode backdropBlendMode;
  final bool enableShadow;

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass> {
  Timer? _timer;
  late bool _blurActive;

  @override
  void initState() {
    super.initState();
    _configureBlur();
  }

  @override
  void didUpdateWidget(covariant LiquidGlass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blurDelay != widget.blurDelay) _configureBlur();
  }

  void _configureBlur() {
    _timer?.cancel();
    _blurActive = widget.blurDelay <= Duration.zero;
    if (!_blurActive) {
      _timer = Timer(widget.blurDelay, () {
        if (mounted) setState(() => _blurActive = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(9999);
    final resolved = widget.style.resolve(context);
    final sigma = widget.blurSigma ?? widget.style.blurSigma;
    final shadows = widget.enableShadow && widget.style.shadowBlurRadius > 0
        ? <BoxShadow>[
            BoxShadow(
              color: resolved.shadowColor,
              blurRadius: widget.style.shadowBlurRadius,
              offset: widget.style.shadowOffset,
            ),
          ]
        : null;

    Widget content = RepaintBoundary(child: widget.child);
    if (widget.padding != null) {
      content = Padding(padding: widget.padding!, child: content);
    }
    final interior = Stack(
      children: <Widget>[
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: resolved.backgroundColor,
              borderRadius: radius,
            ),
          ),
        ),
        content,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: LiquidGlassEdgePainter(
                borderRadius: radius,
                style: resolved,
              ),
            ),
          ),
        ),
      ],
    );
    final clipped = ClipRRect(
      borderRadius: radius,
      child: _blurActive && sigma > 0
          ? BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              blendMode: widget.backdropBlendMode,
              child: interior,
            )
          : interior,
    );
    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(borderRadius: radius, boxShadow: shadows),
      child: clipped,
    );
  }
}
