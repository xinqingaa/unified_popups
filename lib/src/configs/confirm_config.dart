import 'package:flutter/material.dart';

import '../controller/popup_lifecycle_callbacks.dart';
import '../controller/popup_ownership.dart';
import 'popup_animation_config.dart';
import 'popup_back_policy.dart';
import 'popup_barrier_config.dart';
import 'popup_behavior_config.dart';
import 'popup_position.dart';
import 'popup_owner_policy.dart';
import 'popup_route_policy.dart';
import 'popup_visual_config.dart';

/// 确认弹窗底部确认/取消按钮的排列方式。
enum ConfirmButtonLayout {
  row,
  column,
}

/// 确认弹窗操作按钮的视觉样式。
///
/// - [divider]：通栏分隔线按钮（常见的“分割线”确认样式）
/// - [filled]：圆角填充/描边药丸按钮
enum ConfirmButtonStyle {
  divider,
  filled,
}

/// 一个确认弹窗操作按钮的内容载荷。
///
/// 文本与自定义 Widget 两种形式在结构上互斥，调用方无需关心优先级。
final class ConfirmAction {
  /// 使用纯文本 [text] 标注的操作。
  const ConfirmAction.text(String this.text) : child = null;

  /// 使用自定义 [child] 组件渲染的操作。
  const ConfirmAction.content(Widget this.child) : text = null;

  final String? text;
  final Widget? child;
}

/// 确认弹窗的视觉与布局样式。
final class ConfirmStyle {
  /// 创建确认弹窗外观默认值。
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

  final ConfirmButtonStyle buttonStyle;
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
  final Color? dividerColor;
  final double dividerWidth;
  final double buttonSpacing;
}

/// [Pop.confirm] 的配置：带确认/取消操作的模态对话框。
final class ConfirmConfig implements PopupVisualConfig {
  /// 创建一个确认弹窗。
  ///
  /// [content] 与 [contentWidget] 至少需要提供一个；[title] 与 [titleWidget]
  /// 互斥，[content] 与 [contentWidget] 同样互斥。
  const ConfirmConfig({
    this.title,
    this.titleWidget,
    this.content,
    this.contentWidget,
    this.bodyExtension,
    this.confirmAction = const ConfirmAction.text('confirm'),
    this.cancelAction,
    this.showCloseButton = true,
    this.imagePath,
    this.imageWidth,
    this.imageHeight = 80,
    this.buttonLayout = ConfirmButtonLayout.row,
    this.style = const ConfirmStyle(),
    this.onConfirm,
    this.onCancel,
    this.behavior = const PopupBehaviorConfig(
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
  })  : assert(title == null || titleWidget == null),
        assert(content == null || contentWidget == null),
        assert(content != null || contentWidget != null);

  final String? title;
  final Widget? titleWidget;
  final String? content;
  final Widget? contentWidget;
  final Widget? bodyExtension;
  final ConfirmAction confirmAction;
  final ConfirmAction? cancelAction;
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
