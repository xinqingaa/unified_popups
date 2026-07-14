import 'package:flutter/material.dart';

import '../controller/popup_handle.dart';
import '../controller/popup_lifecycle_callbacks.dart';
import '../controller/popup_ownership.dart';
import '../widgets/popup_anchor.dart';
import 'popup_animation_config.dart';
import 'popup_back_policy.dart';
import 'popup_barrier_config.dart';
import 'popup_behavior_config.dart';
import 'popup_channel.dart';
import 'popup_position.dart';
import 'popup_route_policy.dart';
import 'popup_visual_config.dart';

enum MenuPlacement { auto, belowStart, belowEnd, aboveStart, aboveEnd }

final class PopupMenuStyle {
  const PopupMenuStyle({
    this.padding = EdgeInsets.zero,
    this.constraints = const BoxConstraints(minWidth: 120, maxWidth: 280),
    this.decoration,
  });

  final EdgeInsetsGeometry padding;
  final BoxConstraints constraints;
  final Decoration? decoration;
}

abstract class MenuConfigBase implements PopupVisualConfig {
  PopupAnchorController get anchor;
  MenuPlacement get placement;
  Offset get offset;
  PopupMenuStyle get style;
  Widget buildContent(BuildContext context, PopupHandleBase handle);
}

final class MenuConfig<T> extends MenuConfigBase {
  MenuConfig({
    required this.anchor,
    required this.builder,
    this.placement = MenuPlacement.auto,
    this.offset = Offset.zero,
    this.style = const PopupMenuStyle(),
    this.behavior = const PopupBehaviorConfig(
      channel: PopupChannel.menu,
      routePolicy: PopupRoutePolicy.dismissWhenOwnerRouteChanges,
      backPolicy: PopupBackPolicy.dismiss,
    ),
    this.ownership = const PopupOwnership(),
    this.barrier = const PopupBarrierConfig.hidden(),
    this.animationConfig = const PopupAnimationConfig(
      type: PopupAnimationType.fade,
    ),
    PopupLifecycleCallbacks<T>? lifecycle,
  }) : lifecycle = lifecycle ?? PopupLifecycleCallbacks<T>();

  @override
  final PopupAnchorController anchor;
  final Widget Function(BuildContext context, PopupHandle<T> handle) builder;
  @override
  final MenuPlacement placement;
  @override
  final Offset offset;
  @override
  final PopupMenuStyle style;
  final PopupBehaviorConfig behavior;
  final PopupOwnership ownership;
  @override
  final PopupBarrierConfig barrier;
  @override
  final PopupAnimationConfig animationConfig;
  final PopupLifecycleCallbacks<T> lifecycle;

  @override
  PopupPosition get position => PopupPosition.center;

  @override
  Widget buildContent(BuildContext context, PopupHandleBase handle) {
    return builder(context, handle as PopupHandle<T>);
  }
}
