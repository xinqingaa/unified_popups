part of 'pop.dart';

void _toastImpl(
  String message, {
  // Popup 级别的配置
  required PopupPosition position,
  Duration duration = const Duration(milliseconds: 1200),
  bool showBarrier = false,
  bool barrierDismissible = false,
  ToastType toastType = ToastType.none,
  // Widget 级别的样式配置
  EdgeInsetsGeometry? padding,
  EdgeInsetsGeometry? margin,
  Decoration? decoration,
  TextStyle? style,
  TextAlign? textAlign,
}) {
  // 根据位置决定一个更合适的默认动画
  final animation = (position == PopupPosition.top)
      ? PopupAnimation.slideDown
      : (position == PopupPosition.bottom)
          ? PopupAnimation.slideUp
          : PopupAnimation.fade;

  PopupManager.show(
    PopupConfig(
      child: ToastWidget(
        toastType: toastType,
        message: message,
        padding: padding,
        margin: margin,
        decoration: decoration,
        style: style,
        textAlign: textAlign,
      ),
      position: position,
      duration: duration,
      animation: animation,
      showBarrier: showBarrier,
      barrierDismissible: barrierDismissible,
    ),
  );
}
