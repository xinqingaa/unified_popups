import 'package:flutter/animation.dart';

enum PopupAnimationType {
  none,
  fade,
  slideDown,
  slideUp,
  slideLeft,
  slideRight,
  scale,
}

final class PopupAnimationConfig {
  const PopupAnimationConfig({
    this.type = PopupAnimationType.fade,
    this.duration = const Duration(milliseconds: 200),
    this.reverseDuration,
    this.curve = Curves.easeOutCubic,
    this.reverseCurve = Curves.easeInCubic,
  });

  final PopupAnimationType type;
  final Duration duration;
  final Duration? reverseDuration;
  final Curve curve;
  final Curve reverseCurve;
}
