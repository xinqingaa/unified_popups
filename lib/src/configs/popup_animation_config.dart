import 'package:flutter/animation.dart';

/// 弹窗的进入与退出动画样式。
enum PopupAnimationType {
  none,
  fade,
  slideDown,
  slideUp,
  slideLeft,
  slideRight,
  scale,
}

/// 弹窗显示与隐藏动画的时长、曲线与样式。
final class PopupAnimationConfig {
  /// 创建一个动画配置。
  ///
  /// [slideOffset] 是滑动类动画使用的滑动距离，以弹窗尺寸的比例表示
  /// （默认 0.15）。
  const PopupAnimationConfig({
    this.type = PopupAnimationType.fade,
    this.duration = const Duration(milliseconds: 200),
    this.reverseDuration,
    this.curve = Curves.easeOutCubic,
    this.reverseCurve = Curves.easeInCubic,
    this.slideOffset = 0.15,
  });

  final PopupAnimationType type;
  final Duration duration;
  final Duration? reverseDuration;
  final Curve curve;
  final Curve reverseCurve;
  final double slideOffset;
}
