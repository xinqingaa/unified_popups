// lib/src/models/popup_config.dart
part of '../core/popup_manager.dart';

/// 弹出层的配置类
class PopupConfig {
  /// [必填] 弹出层要显示的子 Widget
  final Widget child;

  /// [可选] 弹出位置，默认为 [PopupPosition.center]
  final PopupPosition position;

  /// [可选] 依附于某个 Widget 进行定位。
  /// 如果设置了此项，[position] 将被忽略。
  final GlobalKey? anchorKey;

  /// [可选] 当使用 [anchorKey] 定位时，提供的偏移量。
  final Offset anchorOffset;

  /// [可选] 弹出动画，默认为 [PopupAnimation.fade]
  final PopupAnimation animation;

  /// [可选] 动画持续时间，默认为 250 毫秒
  final Duration animationDuration;

  /// [可选] 是否显示遮盖层，默认为 true
  final bool showBarrier;

  /// [可选] 遮盖层颜色，默认为 Colors.black54
  final Color barrierColor;

  /// [可选] 点击遮盖层是否关闭弹出层，默认为 true
  final bool barrierDismissible;

  /// [可选] 自动关闭的倒计时。如果为 null，则不会自动关闭（例如 Confirm 场景）。
  /// 主要用于 Toast 场景。
  final Duration? duration;

  /// [可选] 弹出层显示时的回调
  final VoidCallback? onShow;

  /// [可选] 弹出层关闭时的回调
  final VoidCallback? onDismiss;

  /// [可选] 控制安全区域 默认在安全区域内
  final bool useSafeArea;

  PopupConfig({
    required this.child,
    this.position = PopupPosition.center,
    this.anchorKey,
    this.anchorOffset = Offset.zero,
    this.animation = PopupAnimation.fade,
    this.animationDuration = const Duration(milliseconds: 320),
    this.showBarrier = true,
    this.barrierColor = Colors.black54,
    this.barrierDismissible = true,
    this.useSafeArea = true,
    this.duration,
    this.onShow,
    this.onDismiss,
  });
}
