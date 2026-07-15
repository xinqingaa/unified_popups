import 'package:flutter/widgets.dart';

import '../controller/popup_handle.dart';
import '../controller/popup_lifecycle_callbacks.dart';
import '../controller/popup_ownership.dart';
import 'popup_animation_config.dart';
import 'popup_barrier_config.dart';
import 'popup_behavior_config.dart';
import 'popup_position.dart';
import 'popup_visual_config.dart';

/// [CustomPopupConfig] 承载的完全自定义弹窗内容共享的契约。
abstract class CustomPopupConfigBase implements PopupVisualConfig {
  /// 构建弹窗组件树，并提供带类型的关闭句柄。
  Widget buildContent(BuildContext context, PopupHandleBase handle);
}

/// [Pop.custom] 的配置：任意 widget 内容配合标准弹窗行为、遮罩、位置与动画。
final class CustomPopupConfig<T> extends CustomPopupConfigBase {
  /// 创建一个自定义弹窗配置。
  CustomPopupConfig({
    required this.builder,
    this.behavior = const PopupBehaviorConfig(),
    this.ownership = const PopupOwnership(),
    this.barrier = const PopupBarrierConfig(),
    this.position = PopupPosition.center,
    this.animationConfig = const PopupAnimationConfig(),
    PopupLifecycleCallbacks<T>? lifecycle,
  }) : lifecycle = lifecycle ?? PopupLifecycleCallbacks<T>();

  /// 构建弹窗内容；使用 [PopupHandle.complete] 或 [PopupHandle.dismiss]
  /// 关闭并可选地返回结果。
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
