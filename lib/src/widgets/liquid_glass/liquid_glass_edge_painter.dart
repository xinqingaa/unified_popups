import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'liquid_glass_style.dart';

final class LiquidGlassEdgePainter extends CustomPainter {
  const LiquidGlassEdgePainter({
    required this.borderRadius,
    required this.style,
  });

  final BorderRadius borderRadius;
  final ResolvedLiquidGlassStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final source = style.source;
    final maxStrokeWidth = math.max(source.topStrokeWidth, source.outlineWidth);
    final rect = Rect.fromLTWH(
      maxStrokeWidth / 2,
      maxStrokeWidth / 2,
      size.width - maxStrokeWidth,
      size.height - maxStrokeWidth,
    );
    if (rect.width <= 0 || rect.height <= 0) return;

    final rrect = _safeRRect(rect);
    if (source.topStrokeWidth > 0) {
      final transparent = style.borderColor.withAlpha(0);
      final paint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = source.topStrokeWidth
        ..shader = ui.Gradient.linear(
          Offset(rect.left, rect.top),
          Offset(rect.right, rect.top),
          <Color>[
            transparent,
            style.borderColor,
            style.borderColor,
            transparent,
          ],
          const <double>[0, 0.2, 0.8, 1],
        );
      canvas.drawPath(_topEdgePath(rect, rrect), paint);
    }
    if (source.outlineWidth > 0) {
      final paint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = source.outlineWidth
        ..color = style.borderColor;
      canvas.drawRRect(rrect, paint);
    }
  }

  Path _topEdgePath(Rect rect, RRect rrect) {
    final path = Path()..moveTo(rect.left, rect.top + rrect.tlRadius.y);
    if (rrect.tlRadius.x > 0 && rrect.tlRadius.y > 0) {
      path.arcTo(
        Rect.fromLTWH(
          rect.left,
          rect.top,
          rrect.tlRadius.x * 2,
          rrect.tlRadius.y * 2,
        ),
        math.pi,
        math.pi / 2,
        false,
      );
    } else {
      path.lineTo(rect.left, rect.top);
    }
    path.lineTo(rect.right - rrect.trRadius.x, rect.top);
    if (rrect.trRadius.x > 0 && rrect.trRadius.y > 0) {
      path.arcTo(
        Rect.fromLTWH(
          rect.right - rrect.trRadius.x * 2,
          rect.top,
          rrect.trRadius.x * 2,
          rrect.trRadius.y * 2,
        ),
        -math.pi / 2,
        math.pi / 2,
        false,
      );
    } else {
      path.lineTo(rect.right, rect.top);
    }
    return path;
  }

  RRect _safeRRect(Rect rect) {
    Radius clamp(Radius radius) {
      return Radius.elliptical(
        radius.x.clamp(0.0, rect.width / 2).toDouble(),
        radius.y.clamp(0.0, rect.height / 2).toDouble(),
      );
    }

    return RRect.fromRectAndCorners(
      rect,
      topLeft: clamp(borderRadius.topLeft),
      topRight: clamp(borderRadius.topRight),
      bottomLeft: clamp(borderRadius.bottomLeft),
      bottomRight: clamp(borderRadius.bottomRight),
    );
  }

  @override
  bool shouldRepaint(covariant LiquidGlassEdgePainter oldDelegate) {
    return borderRadius != oldDelegate.borderRadius ||
        style != oldDelegate.style;
  }
}
