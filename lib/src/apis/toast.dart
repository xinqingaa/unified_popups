part of 'pop.dart';


/// 显示一个 Toast 消息
///
/// [message] 消息内容
/// [position] 显示位置，默认居中
/// [duration] 显示时长，默认 1.2 秒
/// [showBarrier] 是否展示蒙层，默认不显示
/// [barrierDismissible] 点击蒙层是否关闭，默认关闭
/// [padding], [margin], [decoration], [style], [textAlign] 用于自定义 Toast 样式
void _toastImpl(
  String message, {
    // Popup 级别的配置
    PopupPosition position = PopupPosition.center,
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
        toastType:toastType,
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