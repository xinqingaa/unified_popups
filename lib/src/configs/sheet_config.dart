import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../controller/popup_handle.dart';
import '../controller/popup_lifecycle_callbacks.dart';
import '../controller/popup_ownership.dart';
import '../utils/sheet_dimension.dart';
import 'popup_animation_config.dart';
import 'popup_back_policy.dart';
import 'popup_barrier_config.dart';
import 'popup_behavior_config.dart';
import 'popup_position.dart';
import 'popup_route_policy.dart';
import 'popup_visual_config.dart';
import 'sheet_types.dart';

/// 构建 sheet 主体内容，并提供带类型的关闭句柄。
typedef SheetContentBuilder<T> = Widget Function(
  BuildContext context,
  PopupHandle<T> handle,
);

/// Sheet 的宽高约束，取值为 [SheetDimension]。
final class SheetSizeConfig {
  /// 创建 sheet 的可选尺寸约束。
  const SheetSizeConfig({
    this.width,
    this.height,
    this.maxWidth,
    this.maxHeight,
  });

  final SheetDimension? width;
  final SheetDimension? height;
  final SheetDimension? maxWidth;
  final SheetDimension? maxHeight;
}

/// Sheet 顶部可选的标题行配置。
final class SheetHeaderConfig {
  /// 创建头部设置。
  ///
  /// [title] 与 [titleWidget] 互斥。
  const SheetHeaderConfig({
    this.title,
    this.titleWidget,
    this.showCloseButton = false,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
    this.titleStyle,
    this.titleAlign = TextAlign.center,
  }) : assert(title == null || titleWidget == null);

  final String? title;
  final Widget? titleWidget;
  final bool showCloseButton;
  final EdgeInsetsGeometry padding;
  final TextStyle? titleStyle;
  final TextAlign titleAlign;
}

/// Sheet 容器与可选头图的视觉样式。
final class SheetStyle {
  /// 创建 sheet 外观默认值。
  const SheetStyle({
    this.backgroundColor,
    this.borderRadius,
    this.boxShadow,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 8),
    this.imagePath,
    this.imageSize = 60,
    this.imageOffset = const Offset(16, -40),
  });

  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry padding;
  final String? imagePath;
  final double imageSize;
  final Offset imageOffset;
}

/// 将 sheet 贴靠在屏幕边缘并为导航栏等预留间隙的停靠配置。
final class SheetDockConfig {
  /// 创建停靠设置。
  ///
  /// [edgeGap] 必须非负；运行时仅支持贴靠底部、左侧与右侧。
  const SheetDockConfig({
    this.enabled = false,
    this.edgeGap = 16,
  }) : assert(edgeGap >= 0);

  final bool enabled;
  final double edgeGap;
}

/// Sheet 的拖拽关闭行为与拖拽把手外观。
final class SheetDragConfig {
  /// 创建拖拽设置。
  const SheetDragConfig({
    this.mode = SheetDragDismissMode.fullBody,
    this.modeListenable,
    this.showHandle = true,
    this.handleColor,
    this.dismissProgressThreshold = 0.28,
    this.dismissVelocity = 700,
  })  : assert(
          dismissProgressThreshold > 0 && dismissProgressThreshold < 1,
        ),
        assert(dismissVelocity >= 0);

  final SheetDragDismissMode mode;
  final ValueListenable<SheetDragDismissMode>? modeListenable;
  final bool showHandle;
  final Color? handleColor;
  final double dismissProgressThreshold;
  final double dismissVelocity;
}

/// 带文本输入框的底部 sheet 的键盘避让处理。
final class SheetKeyboardConfig {
  /// 创建键盘避让设置。
  const SheetKeyboardConfig({
    this.adjustForKeyboard = true,
    this.animationDuration = kThemeAnimationDuration,
  });

  final bool adjustForKeyboard;
  final Duration animationDuration;
}

/// [SheetConfig] 与 [FlowSheetConfig] 共享的契约。
abstract class SheetConfigBase implements PopupVisualConfig {
  /// Sheet 进入的边缘方向。
  SheetDirection get direction;

  /// 可选的标题头部配置。
  SheetHeaderConfig get header;

  /// 宽高约束。
  SheetSizeConfig get size;

  /// 容器与内容的视觉样式。
  SheetStyle get style;

  /// 边缘停靠与导航栏间隙设置。
  SheetDockConfig get dock;

  /// 拖拽关闭模式与把手设置。
  SheetDragConfig get drag;

  /// 软键盘的内边距避让行为。
  SheetKeyboardConfig get keyboard;

  /// 是否在 sheet 周围应用 [SafeArea] 内边距。
  bool get resolvedUseSafeArea;

  /// 为给定的 [handle] 构建 sheet 主体。
  Widget buildContent(BuildContext context, PopupHandleBase handle);
}

/// [Pop.sheet] 的配置：带可选头部、拖拽关闭与键盘避让的方向性浮层面板。
final class SheetConfig<T> extends SheetConfigBase {
  /// 创建一个 sheet 配置。
  SheetConfig({
    required this.builder,
    this.direction = SheetDirection.bottom,
    this.header = const SheetHeaderConfig(),
    this.size = const SheetSizeConfig(),
    this.style = const SheetStyle(),
    this.dock = const SheetDockConfig(),
    this.drag = const SheetDragConfig(),
    this.keyboard = const SheetKeyboardConfig(),
    this.useSafeArea,
    this.behavior = const PopupBehaviorConfig(
      routePolicy: PopupRoutePolicy.dismissWhenOwnerRouteChanges,
      backPolicy: PopupBackPolicy.dismiss,
    ),
    this.ownership = const PopupOwnership(),
    PopupBarrierConfig barrier = const PopupBarrierConfig(),
    PopupAnimationConfig? animation,
    PopupLifecycleCallbacks<T>? lifecycle,
    this.onBack,
  })  : _barrier = barrier,
        _animation = animation,
        lifecycle = lifecycle ?? PopupLifecycleCallbacks<T>();

  /// 构建 sheet 内容；调用 [PopupHandle.complete] 返回结果。
  final SheetContentBuilder<T> builder;

  @override
  final SheetDirection direction;

  @override
  final SheetHeaderConfig header;

  @override
  final SheetSizeConfig size;

  @override
  final SheetStyle style;

  @override
  final SheetDockConfig dock;

  @override
  final SheetDragConfig drag;

  @override
  final SheetKeyboardConfig keyboard;
  final bool? useSafeArea;
  final PopupBehaviorConfig behavior;
  final PopupOwnership ownership;
  final PopupBarrierConfig _barrier;
  final PopupAnimationConfig? _animation;
  final PopupLifecycleCallbacks<T> lifecycle;

  /// 自定义返回键处理；返回 `true` 表示已消费返回事件且不关闭 sheet。
  final Future<bool> Function()? onBack;

  @override
  Widget buildContent(BuildContext context, PopupHandleBase handle) {
    return builder(context, handle as PopupHandle<T>);
  }

  @override
  bool get resolvedUseSafeArea =>
      useSafeArea ?? direction == SheetDirection.bottom;

  @override
  PopupBarrierConfig get barrier {
    if (!dock.enabled || dock.edgeGap == 0) return _barrier;
    final gap = dock.edgeGap;
    return _barrier.copyWith(
      insets: switch (direction) {
        SheetDirection.top => EdgeInsets.only(top: gap),
        SheetDirection.bottom => EdgeInsets.only(bottom: gap),
        SheetDirection.left => EdgeInsets.only(left: gap),
        SheetDirection.right => EdgeInsets.only(right: gap),
      },
    );
  }

  @override
  PopupPosition get position => switch (direction) {
        SheetDirection.top => PopupPosition.top,
        SheetDirection.bottom => PopupPosition.bottom,
        SheetDirection.left => PopupPosition.left,
        SheetDirection.right => PopupPosition.right,
      };

  @override
  PopupAnimationConfig get animationConfig =>
      _animation ??
      PopupAnimationConfig(
        type: switch (direction) {
          SheetDirection.top => PopupAnimationType.slideDown,
          SheetDirection.bottom => PopupAnimationType.slideUp,
          SheetDirection.left => PopupAnimationType.slideLeft,
          SheetDirection.right => PopupAnimationType.slideRight,
        },
        duration: const Duration(milliseconds: 400),
        slideOffset: 1,
      );
}
