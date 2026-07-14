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
import 'popup_channel.dart';
import 'popup_position.dart';
import 'popup_route_policy.dart';
import 'popup_visual_config.dart';
import 'sheet_types.dart';

typedef SheetContentBuilder<T> = Widget Function(
  BuildContext context,
  PopupHandle<T> handle,
);

final class SheetSizeConfig {
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

final class SheetHeaderConfig {
  const SheetHeaderConfig({
    this.title,
    this.titleWidget,
    this.showCloseButton = false,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
    this.titleStyle,
    this.titleAlign = TextAlign.center,
  });

  final String? title;
  final Widget? titleWidget;
  final bool showCloseButton;
  final EdgeInsetsGeometry padding;
  final TextStyle? titleStyle;
  final TextAlign titleAlign;
}

final class SheetStyle {
  const SheetStyle({
    this.backgroundColor,
    this.borderRadius,
    this.boxShadow,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

final class SheetDockConfig {
  const SheetDockConfig({
    this.enabled = false,
    this.edgeGap = 16,
  }) : assert(edgeGap >= 0);

  final bool enabled;
  final double edgeGap;
}

final class SheetDragConfig {
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

final class SheetKeyboardConfig {
  const SheetKeyboardConfig({
    this.adjustForKeyboard = true,
    this.animationDuration = kThemeAnimationDuration,
  });

  final bool adjustForKeyboard;
  final Duration animationDuration;
}

abstract class SheetConfigBase implements PopupVisualConfig {
  SheetDirection get direction;
  SheetHeaderConfig get header;
  SheetSizeConfig get size;
  SheetStyle get style;
  SheetDockConfig get dock;
  SheetDragConfig get drag;
  SheetKeyboardConfig get keyboard;
  bool get resolvedUseSafeArea;

  Widget buildContent(BuildContext context, PopupHandleBase handle);
}

final class SheetConfig<T> extends SheetConfigBase {
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
      channel: PopupChannel.sheet,
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
