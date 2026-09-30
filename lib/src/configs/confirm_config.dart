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
  /// 横向：取消在左、确认在右。
  row,

  /// 纵向：确认在上、取消在下。
  column,
}

/// 自定义确认按钮。库不包 [InkWell]；组件必须调用 [onTap] 才会完成该操作。
typedef ConfirmButtonBuilder = Widget Function(VoidCallback onTap);

/// 确认弹窗的容器外观与间距。不含按钮皮肤。
final class ConfirmStyle {
  /// 胶囊 inset 默认：内容带与按钮带分开 padding，中间 [contentButtonGap]。
  const ConfirmStyle({
    this.contentPadding = const EdgeInsets.fromLTRB(16, 16, 16, 0),
    this.buttonPadding = const EdgeInsets.fromLTRB(16, 0, 16, 16),
    this.margin = const EdgeInsets.symmetric(horizontal: 32),
    this.decoration,
    this.titleStyle,
    this.contentStyle,
    this.textAlign = TextAlign.center,
    this.imageGap = 16,
    this.titleGap = 12,
    this.bodyExtensionGap = 16,
    this.contentButtonGap = 24,
    this.buttonSpacing = 12,
  });

  /// 标题 / 正文 / 扩展区的内边距。
  final EdgeInsetsGeometry contentPadding;

  /// 按钮带的内边距。线条贴边时传 [EdgeInsets.zero]。
  final EdgeInsetsGeometry buttonPadding;
  final EdgeInsetsGeometry margin;
  final Decoration? decoration;
  final TextStyle? titleStyle;
  final TextStyle? contentStyle;
  final TextAlign textAlign;

  /// 通栏顶图 → 内容带（[contentPadding] 之前）。无顶图时不插入。
  final double imageGap;

  /// 标题 → 正文。无标题时不插入。
  final double titleGap;

  /// 正文 → [ConfirmConfig.bodyExtension]。无扩展时不插入。
  final double bodyExtensionGap;

  /// 内容带 → 按钮带（[ConfirmConfig.separator] 之前）。
  final double contentButtonGap;

  /// 两按钮之间的空隙。提供 [ConfirmConfig.buttonSeparator] 时忽略。
  final double buttonSpacing;
}

/// [Pop.confirm] 的配置：带确认/取消操作的模态对话框。
///
/// 默认是强交互：系统返回 / 侧滑与点遮罩都不会关闭；右上角关闭按钮默认隐藏。
/// 需要可取消关闭时，显式设置 [showCloseButton]、[barrier.dismissible] 与
/// [behavior.backPolicy]。
///
/// 按钮只有一条路径：自定义 [confirmButton] / [cancelButton]，或文案
/// [confirmText] / [cancelText] 走库默认胶囊按钮。
final class ConfirmConfig implements PopupVisualConfig {
  /// 创建一个确认弹窗。
  ///
  /// [content] 与 [contentWidget] 至少需要提供一个；[title] 与 [titleWidget]
  /// 互斥，[content] 与 [contentWidget] 同样互斥。
  ///
  /// 默认只能通过确认 / 取消按钮关闭。若需点遮罩或系统返回关闭，请显式传入：
  /// `barrier: PopupBarrierConfig(dismissible: true)`、
  /// `behavior: PopupBehaviorConfig(backPolicy: PopupBackPolicy.dismiss)`，
  /// 以及可选的 `showCloseButton: true`。
  const ConfirmConfig({
    this.title,
    this.titleWidget,
    this.content,
    this.contentWidget,
    this.bodyExtension,
    this.confirmButton,
    this.cancelButton,
    this.confirmText = 'confirm',
    this.cancelText,
    this.separator,
    this.buttonSeparator,
    this.showCloseButton = false,
    this.imagePath,
    this.imageWidth,
    this.imageHeight = 80,
    this.imageFit = BoxFit.cover,
    this.buttonLayout = ConfirmButtonLayout.row,
    this.style = const ConfirmStyle(),
    this.onConfirm,
    this.onCancel,
    this.behavior = const PopupBehaviorConfig(
      routePolicy: PopupRoutePolicy.dismissWhenOwnerRouteChanges,
      backPolicy: PopupBackPolicy.block,
    ),
    this.ownership = const PopupOwnership(
      policy: PopupOwnerPolicy.dismissWithParent,
    ),
    this.barrier = const PopupBarrierConfig(dismissible: false),
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

  /// 自定义主按钮。非空时忽略 [confirmText]。
  final ConfirmButtonBuilder? confirmButton;

  /// 自定义次按钮。非空时忽略 [cancelText]。
  final ConfirmButtonBuilder? cancelButton;

  /// 默认主按钮文案。提供 [confirmButton] 时忽略。
  final String confirmText;

  /// 默认次按钮文案。`null` 且未提供 [cancelButton] 时不显示取消。
  final String? cancelText;

  /// 内容带与按钮带之间的通栏分隔，不受左右 padding。
  final Widget? separator;

  /// 两按钮之间的分隔。非空时不使用 [ConfirmStyle.buttonSpacing]。
  final Widget? buttonSeparator;

  final bool showCloseButton;

  /// 本地 asset 顶图。非空时铺满容器宽度，位于标题之上、[ConfirmStyle.contentPadding]
  /// 之外；高度为 [imageHeight]，由容器 [Clip.antiAlias] + 圆角裁切。
  final String? imagePath;

  /// 已忽略：顶图始终通栏。保留字段以免破坏既有 Config。
  final double? imageWidth;

  /// 顶图高度。默认 80。
  final double? imageHeight;

  /// 顶图填充方式。默认 [BoxFit.cover]。
  final BoxFit imageFit;
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
