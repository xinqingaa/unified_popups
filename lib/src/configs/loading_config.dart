import 'package:flutter/material.dart';

import '../controller/popup_lifecycle_callbacks.dart';
import '../controller/popup_lifetime.dart';
import '../controller/popup_ownership.dart';
import 'popup_animation_config.dart';
import 'popup_back_policy.dart';
import 'popup_barrier_config.dart';
import 'popup_behavior_config.dart';
import 'popup_conflict_policy.dart';
import 'popup_position.dart';
import 'popup_keys.dart';
import 'popup_visual_config.dart';

/// Loading 容器与转圈指示器的视觉样式。
final class LoadingStyle {
  /// 创建 loading 外观默认值。
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

/// [LoadingConfig] 的转圈指示器组件与旋转周期设置。
final class LoadingIndicatorConfig {
  /// 创建指示器设置。
  const LoadingIndicatorConfig({
    this.child,
    this.rotationDuration = const Duration(seconds: 1),
  });

  final Widget? child;
  final Duration rotationDuration;
}

/// [Pop.loading] 的配置：单例、阻塞交互的加载浮层。
final class LoadingConfig implements PopupVisualConfig {
  /// 仅显示转圈指示器（无文案）的 loading。
  const LoadingConfig.indicator({
    this.style = const LoadingStyle(),
    this.indicator = const LoadingIndicatorConfig(),
    this.behavior = const PopupBehaviorConfig(
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
    this.position = PopupPosition.center,
  })  : message = null,
        content = null;

  /// 在指示器下方显示文案 [message] 的 loading。
  const LoadingConfig.text(
    String this.message, {
    this.style = const LoadingStyle(),
    this.indicator = const LoadingIndicatorConfig(),
    this.behavior = const PopupBehaviorConfig(
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
    this.position = PopupPosition.center,
  }) : content = null;

  /// 使用完全自定义 [content] 替代默认布局的 loading。
  const LoadingConfig.content(
    Widget this.content, {
    this.style = const LoadingStyle(),
    this.indicator = const LoadingIndicatorConfig(),
    this.behavior = const PopupBehaviorConfig(
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
    this.position = PopupPosition.center,
  }) : message = null;

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
  final PopupPosition position;

  @override
  PopupAnimationConfig get animationConfig => animation;
}
