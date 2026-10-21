import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'liquid_glass_edge_painter.dart';
import 'liquid_glass_style.dart';

/// 一个可复用、感知主题的磨砂玻璃表面，支持可选的背景模糊效果。
///
/// 使用 [LiquidGlassStyle] 提供的颜色，将 [child] 包裹在一个可裁剪、可选模糊的容器中。
/// 如需在表面内加入按压反馈，请使用 [LiquidGlassButton] 或 [LiquidGlassActionButton]。
///
/// 颜色和模糊用 [LiquidGlassStyle]。描边默认是 [LiquidGlassEdgePainter]，
/// 可继承该类，或通过 [edgePainterBuilder] 换掉。未传 [borderRadius] 时为胶囊形。
class LiquidGlass extends StatefulWidget {
  /// 围绕 [child] 创建一个液态玻璃容器。
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
    this.edgePainterBuilder,
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

  final BlendMode backdropBlendMode;

  final bool enableShadow;

  /// 替换默认描边。返回的 painter 应在样式变化时自行 [CustomPainter.shouldRepaint]。
  final LiquidGlassEdgePainterBuilder? edgePainterBuilder;

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

/// 按当前圆角和已解析样式创建玻璃描边。
typedef LiquidGlassEdgePainterBuilder = CustomPainter Function(
  BorderRadius borderRadius,
  ResolvedLiquidGlassStyle style,
);

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
              painter: widget.edgePainterBuilder?.call(radius, resolved) ??
                  LiquidGlassEdgePainter(
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
