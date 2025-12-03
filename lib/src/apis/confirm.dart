part of 'pop.dart';

Future<bool?> _confirmImpl({
  String? title,
  required String content,
  required PopupPosition position,
  String? confirmText,
  String? cancelText,
  String? imagePath,
  double? imageHeight,
  double? imageWidth,
  TextAlign? textAlign,
  ConfirmButtonLayout? buttonLayout,
  BorderRadiusGeometry? buttonBorderRadius,
  BoxBorder? confirmBorder,
  BoxBorder? cancelBorder,
  bool showCloseButton = true,
  TextStyle? titleStyle,
  TextStyle? contentStyle,
  TextStyle? confirmStyle,
  TextStyle? cancelStyle,
  Color? confirmBgColor,
  Color? cancelBgColor,
  EdgeInsetsGeometry? padding,
  EdgeInsetsGeometry? margin,
  Decoration? decoration,
  Widget? confirmChild,
  Duration animationDuration = const Duration(milliseconds: 250),
  Curve? animationCurve,
}) {
  final completer = Completer<bool?>();
  late String popupId;

  void dismiss(bool? result) {
    if (!completer.isCompleted) {
      completer.complete(result);
      PopupManager.hide(popupId);
    }
  }

  final animation = (position == PopupPosition.top)
      ? PopupAnimation.slideDown
      : (position == PopupPosition.bottom)
          ? PopupAnimation.slideUp
          : PopupAnimation.fade;

  popupId = PopupManager.show(
    PopupConfig(
      child: ConfirmWidget(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        showCloseButton: showCloseButton,
        imagePath: imagePath,
        imageHeight: imageHeight,
        imageWidth: imageWidth,
        textAlign: textAlign,
        buttonLayout: buttonLayout,
        buttonBorderRadius: buttonBorderRadius,
        confirmBorder: confirmBorder,
        cancelBorder: cancelBorder,
        onConfirm: () => dismiss(true),
        onCancel: () => dismiss(false),
        onClose: () => dismiss(null), // 关闭按钮的回调
        // --- 传递样式参数 ---
        titleStyle: titleStyle,
        contentStyle: contentStyle,
        confirmStyle: confirmStyle,
        cancelStyle: cancelStyle,
        confirmBgColor: confirmBgColor,
        cancelBgColor: cancelBgColor,
        padding: padding,
        margin: margin,
        decoration: decoration,
        confirmChild: confirmChild,
      ),
      animation: animation,
      animationCurve: animationCurve,
      animationDuration: animationDuration,
      position: position,
      barrierDismissible: true,
      type: PopupType.confirm,
      onDismiss: () {
        // 如果是通过点击遮罩层关闭的，也需要 complete
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    ),
  );

  return completer.future;
}
