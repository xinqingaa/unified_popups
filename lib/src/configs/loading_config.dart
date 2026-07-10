import 'package:flutter/material.dart';

import '../controller/popup_lifecycle_callbacks.dart';
import '../controller/popup_lifetime.dart';
import '../controller/popup_ownership.dart';
import 'popup_animation_config.dart';
import 'popup_back_policy.dart';
import 'popup_barrier_config.dart';
import 'popup_behavior_config.dart';
import 'popup_channel.dart';
import 'popup_conflict_policy.dart';
import 'popup_position.dart';
import 'popup_visual_config.dart';

abstract final class PopupKeys {
  static const globalLoading = 'unified_popups.global_loading';
}

final class LoadingStyle {
  const LoadingStyle({
    this.backgroundColor = const Color(0xCC000000),
    this.borderRadius = 12,
    this.padding = const EdgeInsets.all(24),
    this.textStyle = const TextStyle(color: Colors.white, fontSize: 16),
    this.indicatorColor = Colors.white,
    this.indicatorStrokeWidth = 2,
  });

  final Color backgroundColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final TextStyle textStyle;
  final Color indicatorColor;
  final double indicatorStrokeWidth;
}

final class LoadingIndicatorConfig {
  const LoadingIndicatorConfig({
    this.child,
    this.rotationDuration = const Duration(seconds: 1),
  });

  final Widget? child;
  final Duration rotationDuration;
}

final class LoadingConfig implements PopupVisualConfig {
  const LoadingConfig({
    this.message,
    this.content,
    this.style = const LoadingStyle(),
    this.indicator = const LoadingIndicatorConfig(),
    this.behavior = const PopupBehaviorConfig(
      channel: PopupChannel.loading,
      key: PopupKeys.globalLoading,
      conflictPolicy: PopupConflictPolicy.updateExisting,
      backPolicy: PopupBackPolicy.block,
    ),
    this.ownership = const PopupOwnership(),
    this.barrier = const PopupBarrierConfig(
      visible: true,
      dismissible: false,
    ),
    this.animation = const PopupAnimationConfig(
      duration: Duration(milliseconds: 150),
    ),
    this.lifetime = const PopupLifetime.manual(),
    this.lifecycle = const PopupLifecycleCallbacks<void>(),
  });

  final String? message;
  final Widget? content;
  final LoadingStyle style;
  final LoadingIndicatorConfig indicator;
  final PopupBehaviorConfig behavior;
  final PopupOwnership ownership;
  @override
  final PopupBarrierConfig barrier;
  final PopupAnimationConfig animation;
  final PopupLifetime lifetime;
  final PopupLifecycleCallbacks<void> lifecycle;

  @override
  PopupAnimationConfig get animationConfig => animation;

  @override
  PopupPosition get position => PopupPosition.center;
}
