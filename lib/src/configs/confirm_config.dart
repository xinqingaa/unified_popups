import 'package:flutter/material.dart';

import '../controller/popup_lifecycle_callbacks.dart';
import '../controller/popup_ownership.dart';
import 'popup_animation_config.dart';
import 'popup_back_policy.dart';
import 'popup_barrier_config.dart';
import 'popup_behavior_config.dart';
import 'popup_channel.dart';
import 'popup_position.dart';
import 'popup_owner_policy.dart';
import 'popup_route_policy.dart';
import 'popup_visual_config.dart';

enum ConfirmButtonLayout {
  row,
  column,
}

/// Confirm 底部按钮视觉风格。
///
/// - [divider]：贴底分割线按钮（默认，对齐常见「线条」确认框）
/// - [filled]：圆角填充 / 胶囊按钮
enum ConfirmButtonStyle {
  divider,
  filled,
}

final class ConfirmStyle {
  const ConfirmStyle({
    this.buttonStyle = ConfirmButtonStyle.divider,
    this.titleStyle,
    this.contentStyle,
    this.confirmStyle,
    this.cancelStyle,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 16),
    this.margin = const EdgeInsets.symmetric(horizontal: 32),
    this.decoration,
    this.textAlign = TextAlign.center,
    this.buttonBorderRadius = const BorderRadius.all(Radius.circular(10)),
    this.confirmBackgroundColor,
    this.cancelBackgroundColor,
    this.confirmBorder,
    this.cancelBorder,
    this.dividerColor,
    this.dividerWidth = 0.5,
    this.buttonSpacing = 12,
  });

  /// 按钮风格；默认 [ConfirmButtonStyle.divider]。
  final ConfirmButtonStyle buttonStyle;
  final TextStyle? titleStyle;
  final TextStyle? contentStyle;
  final TextStyle? confirmStyle;
  final TextStyle? cancelStyle;

  /// 内容区内边距（标题 / 正文 / 扩展区）。
  ///
  /// [ConfirmButtonStyle.divider] 下不作用于按钮区（按钮贴底铺满）。
  /// [ConfirmButtonStyle.filled] 下同时包住按钮区。
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Decoration? decoration;
  final TextAlign textAlign;

  /// 填充按钮圆角；线条风格下按钮本身无圆角（由卡片裁剪）。
  final BorderRadiusGeometry buttonBorderRadius;
  final Color? confirmBackgroundColor;
  final Color? cancelBackgroundColor;
  final BoxBorder? confirmBorder;
  final BoxBorder? cancelBorder;

  /// 线条风格分割线颜色；默认使用主题 `dividerColor`。
  final Color? dividerColor;

  /// 线条风格分割线宽度。
  final double dividerWidth;

  /// 填充风格下按钮间距（横排为水平间距，竖排为垂直间距）。
  final double buttonSpacing;
}

final class ConfirmConfig implements PopupVisualConfig {
  const ConfirmConfig({
    this.title,
    this.titleWidget,
    this.content,
    this.contentWidget,
    this.bodyExtension,
    this.confirmText = 'confirm',
    this.confirmButton,
    this.cancelText,
    this.cancelButton,
    this.showCloseButton = true,
    this.imagePath,
    this.imageWidth,
    this.imageHeight = 80,
    this.buttonLayout = ConfirmButtonLayout.row,
    this.style = const ConfirmStyle(),
    this.onConfirm,
    this.onCancel,
    this.behavior = const PopupBehaviorConfig(
      channel: PopupChannel.confirm,
      routePolicy: PopupRoutePolicy.dismissWhenOwnerRouteChanges,
      backPolicy: PopupBackPolicy.dismiss,
    ),
    this.ownership = const PopupOwnership(
      policy: PopupOwnerPolicy.dismissWithParent,
    ),
    this.barrier = const PopupBarrierConfig(),
    this.position = PopupPosition.center,
    this.animationConfig = const PopupAnimationConfig(
      type: PopupAnimationType.scale,
      duration: Duration(milliseconds: 250),
    ),
    this.lifecycle = const PopupLifecycleCallbacks<bool>(),
  }) : assert(content != null || contentWidget != null);

  final String? title;
  final Widget? titleWidget;
  final String? content;
  final Widget? contentWidget;
  final Widget? bodyExtension;
  final String confirmText;
  final Widget? confirmButton;
  final String? cancelText;
  final Widget? cancelButton;
  final bool showCloseButton;
  final String? imagePath;
  final double? imageWidth;
  final double? imageHeight;
  final ConfirmButtonLayout buttonLayout;
  final ConfirmStyle style;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final PopupBehaviorConfig behavior;
  final PopupOwnership ownership;
  @override
  final PopupBarrierConfig barrier;
  @override
  final PopupPosition position;
  @override
  final PopupAnimationConfig animationConfig;
  final PopupLifecycleCallbacks<bool> lifecycle;
}
