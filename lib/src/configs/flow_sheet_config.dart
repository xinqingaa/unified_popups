import 'package:flutter/material.dart';

import '../controller/popup_handle.dart';
import '../controller/popup_lifecycle_callbacks.dart';
import '../controller/popup_ownership.dart';
import '../flow_sheets/flow_sheet.dart';
import '../flow_sheets/widgets/flow_sheet_host.dart';
import 'popup_animation_config.dart';
import 'popup_back_policy.dart';
import 'popup_barrier_config.dart';
import 'popup_behavior_config.dart';
import 'popup_position.dart';
import 'popup_route_policy.dart';
import 'sheet_config.dart';
import 'sheet_types.dart';

final class FlowSheetConfig<R> extends SheetConfigBase {
  FlowSheetConfig({
    required this.controller,
    required this.initialPage,
    this.direction = SheetDirection.bottom,
    this.header = const SheetHeaderConfig(),
    this.size = const SheetSizeConfig(),
    this.style = const SheetStyle(),
    this.dock = const SheetDockConfig(),
    SheetDragConfig drag = const SheetDragConfig(),
    this.keyboard = const SheetKeyboardConfig(),
    this.useSafeArea,
    this.pageBackgroundColor,
    this.routeBuilder,
    this.behavior = const PopupBehaviorConfig(
      routePolicy: PopupRoutePolicy.dismissWhenOwnerRouteChanges,
      backPolicy: PopupBackPolicy.delegate,
    ),
    this.ownership = const PopupOwnership(),
    PopupBarrierConfig barrier = const PopupBarrierConfig(
      dismissible: false,
    ),
    PopupAnimationConfig? animation,
    PopupLifecycleCallbacks<R>? lifecycle,
  })  : _barrier = barrier,
        _animation = animation,
        drag = SheetDragConfig(
          mode: drag.mode,
          modeListenable: controller.dragDismissModeNotifier,
          showHandle: drag.showHandle,
          handleColor: drag.handleColor,
          dismissProgressThreshold: drag.dismissProgressThreshold,
          dismissVelocity: drag.dismissVelocity,
        ),
        lifecycle = lifecycle ?? PopupLifecycleCallbacks<R>();

  final FlowSheetController<R> controller;
  final FlowSheetPage initialPage;
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
  final Color? pageBackgroundColor;
  final FlowSheetRouteBuilder? routeBuilder;
  final PopupBehaviorConfig behavior;
  final PopupOwnership ownership;
  final PopupBarrierConfig _barrier;
  final PopupAnimationConfig? _animation;
  final PopupLifecycleCallbacks<R> lifecycle;

  @override
  bool get resolvedUseSafeArea =>
      useSafeArea ?? direction == SheetDirection.bottom;

  @override
  Widget buildContent(BuildContext context, PopupHandleBase handle) {
    controller.configureDragDismissMode(drag.mode);
    return FlowSheetHost(
      controller: controller,
      initialPage: initialPage,
      pageBackgroundColor: pageBackgroundColor,
      routeBuilder: routeBuilder,
    );
  }

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
