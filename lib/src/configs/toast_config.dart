import 'package:flutter/material.dart';

import '../controller/popup_lifecycle_callbacks.dart';
import '../controller/popup_lifetime.dart';
import '../controller/popup_ownership.dart';
import 'popup_animation_config.dart';
import 'popup_back_policy.dart';
import 'popup_barrier_config.dart';
import 'popup_behavior_config.dart';
import 'popup_position.dart';
import 'popup_visual_config.dart';

enum ToastType {
  success,
  warn,
  error,
  none,
}

final class ToastIconConfig {
  const ToastIconConfig({
    this.assetPath,
    this.size = 24,
    this.color,
  });

  final String? assetPath;
  final double size;
  final Color? color;
}

final class ToastStyle {
  const ToastStyle({
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
    this.decoration,
    this.textStyle = const TextStyle(color: Colors.white, fontSize: 16),
    this.textAlign = TextAlign.start,
    this.spacing = 12,
  });

  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Decoration? decoration;
  final TextStyle textStyle;
  final TextAlign textAlign;
  final double spacing;
}

final class ToastToggleConfig {
  const ToastToggleConfig({
    this.message,
    this.icon,
    this.type,
  });

  final String? message;
  final ToastIconConfig? icon;
  final ToastType? type;
}

final class ToastConfig implements PopupVisualConfig {
  const ToastConfig.text(
    String this.message, {
    this.position = PopupPosition.center,
    this.type = ToastType.none,
    this.icon,
    this.layoutDirection = Axis.horizontal,
    this.style = const ToastStyle(),
    this.toggle,
    this.onTap,
    this.behavior = const PopupBehaviorConfig(
      backPolicy: PopupBackPolicy.ignore,
    ),
    this.ownership = const PopupOwnership(),
    this.barrier = const PopupBarrierConfig.hidden(),
    this.animation,
    this.lifetime = const PopupLifetime.after(
      Duration(milliseconds: 1200),
    ),
    this.lifecycle = const PopupLifecycleCallbacks<void>(),
  }) : content = null;

  const ToastConfig.content(
    Widget this.content, {
    this.position = PopupPosition.center,
    this.type = ToastType.none,
    this.icon,
    this.layoutDirection = Axis.horizontal,
    this.style = const ToastStyle(),
    this.toggle,
    this.onTap,
    this.behavior = const PopupBehaviorConfig(
      backPolicy: PopupBackPolicy.ignore,
    ),
    this.ownership = const PopupOwnership(),
    this.barrier = const PopupBarrierConfig.hidden(),
    this.animation,
    this.lifetime = const PopupLifetime.after(
      Duration(milliseconds: 1200),
    ),
    this.lifecycle = const PopupLifecycleCallbacks<void>(),
  }) : message = null;

  final String? message;
  final Widget? content;
  @override
  final PopupPosition position;
  final ToastType type;
  final ToastIconConfig? icon;
  final Axis layoutDirection;
  final ToastStyle style;
  final ToastToggleConfig? toggle;
  final VoidCallback? onTap;
  final PopupBehaviorConfig behavior;
  final PopupOwnership ownership;
  @override
  final PopupBarrierConfig barrier;
  final PopupAnimationConfig? animation;
  final PopupLifetime lifetime;
  final PopupLifecycleCallbacks<void> lifecycle;

  PopupAnimationConfig get resolvedAnimation =>
      animation ??
      PopupAnimationConfig(
        type: switch (position) {
          PopupPosition.top => PopupAnimationType.slideDown,
          PopupPosition.bottom => PopupAnimationType.slideUp,
          PopupPosition.left => PopupAnimationType.slideLeft,
          PopupPosition.right => PopupAnimationType.slideRight,
          PopupPosition.center => PopupAnimationType.fade,
        },
      );

  @override
  PopupAnimationConfig get animationConfig => resolvedAnimation;
}
