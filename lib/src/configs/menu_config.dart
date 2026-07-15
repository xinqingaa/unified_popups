import 'package:flutter/material.dart';

import '../controller/popup_handle.dart';
import '../controller/popup_lifecycle_callbacks.dart';
import '../controller/popup_ownership.dart';
import '../widgets/popup_anchor.dart';
import 'popup_animation_config.dart';
import 'popup_back_policy.dart';
import 'popup_barrier_config.dart';
import 'popup_behavior_config.dart';
import 'popup_position.dart';
import 'popup_route_policy.dart';
import 'popup_visual_config.dart';

/// 锚定菜单相对于锚点组件的首选摆放位置。
enum MenuPlacement {
  auto,
  belowStart,
  belowEnd,
  aboveStart,
  aboveEnd,
}

/// 锚定菜单浮层的容器约束与装饰。
final class PopupMenuStyle {
  /// 创建菜单面板外观默认值。
  const PopupMenuStyle({
    this.padding = EdgeInsets.zero,
    this.constraints = const BoxConstraints(minWidth: 120, maxWidth: 280),
    this.decoration,
  });

  final EdgeInsetsGeometry padding;
  final BoxConstraints constraints;
  final Decoration? decoration;
}

/// [MenuConfig] 与 [DropMenuConfig] 共享的契约。
abstract class MenuConfigBase implements PopupVisualConfig {
  /// 用于追踪锚点位置以进行摆放计算的锚点控制器。
  PopupAnchorController get anchor;

  /// 菜单相对锚点的摆放位置。
  MenuPlacement get placement;

  /// 摆放计算完成后附加的偏移量。
  Offset get offset;

  /// 面板的内边距、约束与装饰。
  PopupMenuStyle get style;

  /// 为给定的 [handle] 构建菜单内容。
  Widget buildContent(BuildContext context, PopupHandleBase handle);
}

/// [Pop.menu] 的配置：锚定在目标组件上的自定义 widget 菜单。
final class MenuConfig<T> extends MenuConfigBase {
  /// 创建一个锚定菜单配置。
  ///
  /// 默认 [barrier] 是透明可点击关闭的遮罩，会拦截菜单下方的滚动。传入
  /// [PopupBarrierConfig.hidden] 可允许滚动穿透。
  MenuConfig({
    required this.anchor,
    required this.builder,
    this.placement = MenuPlacement.auto,
    this.offset = Offset.zero,
    this.style = const PopupMenuStyle(),
    this.behavior = const PopupBehaviorConfig(
      routePolicy: PopupRoutePolicy.dismissWhenOwnerRouteChanges,
      backPolicy: PopupBackPolicy.dismiss,
    ),
    this.ownership = const PopupOwnership(),
    this.barrier = const PopupBarrierConfig(color: Colors.transparent),
    this.animationConfig = const PopupAnimationConfig(
      type: PopupAnimationType.fade,
    ),
    PopupLifecycleCallbacks<T>? lifecycle,
  }) : lifecycle = lifecycle ?? PopupLifecycleCallbacks<T>();

  @override
  final PopupAnchorController anchor;

  /// 构建菜单内容；调用 [PopupHandle.complete] 返回选中项。
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
