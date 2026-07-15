import 'package:flutter/widgets.dart';

import '../controller/popup_handle.dart';
import '../controller/popup_lifecycle_callbacks.dart';
import '../controller/popup_ownership.dart';
import 'popup_animation_config.dart';
import 'popup_barrier_config.dart';
import 'popup_behavior_config.dart';
import 'popup_position.dart';
import 'popup_visual_config.dart';

abstract class CustomPopupConfigBase implements PopupVisualConfig {
  Widget buildContent(BuildContext context, PopupHandleBase handle);
}

final class CustomPopupConfig<T> extends CustomPopupConfigBase {
  CustomPopupConfig({
    required this.builder,
    this.behavior = const PopupBehaviorConfig(),
    this.ownership = const PopupOwnership(),
    this.barrier = const PopupBarrierConfig(),
    this.position = PopupPosition.center,
    this.animationConfig = const PopupAnimationConfig(),
    PopupLifecycleCallbacks<T>? lifecycle,
  }) : lifecycle = lifecycle ?? PopupLifecycleCallbacks<T>();

  final Widget Function(BuildContext context, PopupHandle<T> handle) builder;
  final PopupBehaviorConfig behavior;
  final PopupOwnership ownership;
  @override
  final PopupBarrierConfig barrier;
  @override
  final PopupPosition position;
  @override
  final PopupAnimationConfig animationConfig;
  final PopupLifecycleCallbacks<T> lifecycle;

  @override
  Widget buildContent(BuildContext context, PopupHandleBase handle) {
    return builder(context, handle as PopupHandle<T>);
  }
}
