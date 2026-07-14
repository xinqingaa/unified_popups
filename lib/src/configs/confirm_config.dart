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

final class ConfirmStyle {
  const ConfirmStyle({
    this.titleStyle,
    this.contentStyle,
    this.confirmStyle,
    this.cancelStyle,
    this.padding = const EdgeInsets.all(24),
    this.margin = const EdgeInsets.symmetric(horizontal: 32),
    this.decoration,
    this.textAlign = TextAlign.center,
    this.buttonBorderRadius = const BorderRadius.all(Radius.circular(10)),
    this.confirmBackgroundColor,
    this.cancelBackgroundColor,
    this.confirmBorder,
    this.cancelBorder,
  });

  final TextStyle? titleStyle;
  final TextStyle? contentStyle;
  final TextStyle? confirmStyle;
  final TextStyle? cancelStyle;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Decoration? decoration;
  final TextAlign textAlign;
  final BorderRadiusGeometry buttonBorderRadius;
  final Color? confirmBackgroundColor;
  final Color? cancelBackgroundColor;
  final BoxBorder? confirmBorder;
  final BoxBorder? cancelBorder;
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
