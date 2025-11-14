// lib/src/models/popup_config.dart
part of '../core/popup_manager.dart';

/// 弹出层配置类，用于配置弹出层的行为和样式。
/// 参数：
/// - [child]：弹出层要显示的子 Widget。
/// - [position]：弹出位置，默认为 [PopupPosition.center]。
/// - [anchorKey]：依附于某个 Widget 进行定位。
/// - [anchorOffset]：当使用 [anchorKey] 定位时，提供的偏移量。
/// - [animation]：弹出动画，默认为 [PopupAnimation.fade]。
/// - [animationDuration]：动画持续时间，默认为 300 毫秒。
/// - [showBarrier]：是否显示遮盖层，默认为 true。
/// - [barrierColor]：遮盖层颜色，默认为 Colors.black54。
/// - [barrierDismissible]：点击遮盖层是否关闭弹出层，默认为 true。
/// - [duration]：自动关闭的倒计时。如果为 null，则不会自动关闭（例如 Confirm 场景）。
/// - [onShow]：弹出层显示时的回调。
/// - [onDismiss]：弹出层关闭时的回调。
/// - [useSafeArea]：控制安全区域 默认在安全区域内
/// - [type]：弹层类型，驱动系统返回键拦截等策略
/// - [showBarrier]：是否显示遮盖层，默认为 true。
/// - [barrierColor]：遮盖层颜色，默认为 Colors.black54。
/// - [clipDuringAnimation]：在锚点模式下是否裁剪动画超出区域，默认 false
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

  /// [可选] 动画持续时间，默认为 300 毫秒
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

  /// [必填] 弹层类型，驱动系统返回键拦截等策略
  final PopupType type;

  /// [可选] 是否在弹窗方向上为底部/侧边导航留白
  final bool dockToEdge;

  /// [可选] 预留的边缘间距
  final double edgeGap;

  /// [可选] 在锚点模式下是否裁剪动画超出区域，默认 false
  final bool clipDuringAnimation;

  static const double defaultEdgeGap = kBottomNavigationBarHeight + 4;

  PopupConfig({
    required this.child,
    this.position = PopupPosition.center,
    this.anchorKey,
    this.anchorOffset = Offset.zero,
    this.animation = PopupAnimation.fade,
    this.animationDuration = const Duration(milliseconds: 300),
    this.showBarrier = true,
    this.barrierColor = Colors.black54,
    this.barrierDismissible = true,
    this.useSafeArea = true,
    this.duration,
    this.onShow,
    this.onDismiss,
    this.type = PopupType.other,
    this.dockToEdge = false,
    this.edgeGap = defaultEdgeGap,
    this.clipDuringAnimation = false,
  });
}
