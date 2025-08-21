part of 'pop.dart';



Future<bool?> _confirmImpl({
  String? title,
  required String content,
  String confirmText = '确认',
  String? cancelText = '取消',
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
}) {
  final completer = Completer<bool?>();
  late String popupId;

  void dismiss(bool? result) {
    if (!completer.isCompleted) {
      completer.complete(result);
      PopupManager.hide(popupId);
    }
  }

  popupId = PopupManager.show(
    PopupConfig(
      child: ConfirmWidget(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        showCloseButton: showCloseButton,
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
      ),
      position: PopupPosition.center,
      barrierDismissible: true,
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