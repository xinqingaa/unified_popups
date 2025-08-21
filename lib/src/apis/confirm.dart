part of 'pop.dart';


/// 显示一个确认对话框
///
/// [title] 标题
/// [content] 内容
/// [confirmText] 确认按钮文本
/// [cancelText] 取消按钮文本, 如果为 null，则只显示确认按钮
/// [showCloseButton] 是否显示右上角的关闭按钮, 默认为 true
/// [titleStyle] 标题样式
/// [contentStyle] 内容样式
/// [confirmStyle] 确认按钮文本样式
/// [cancelStyle] 取消按钮文本样式
/// [confirmBgColor] 确认按钮背景色
/// [cancelBgColor] 取消按钮背景色
/// [padding] 内部边距
/// [margin] 外部边距
/// [decoration] 容器的装饰（背景、圆角等）
/// returns [Future<bool?>] 用户点击确认返回 true，点击取消返回 false，点击遮罩层或关闭按钮返回 null

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