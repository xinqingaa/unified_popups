part of 'pop.dart';

/// 显示一个 Loading 加载指示器
///
/// [message] 加载时显示的文本，可选
/// returns [String] 弹窗的唯一 ID，用于手动关闭
String _loadingImpl({
  String? message,
  // 样式参数
  Color? backgroundColor,
  double? borderRadius,
  Color? indicatorColor,
  double? indicatorStrokeWidth,
  TextStyle? textStyle,
  // 遮罩层参数
  bool showBarrier = true,
  bool barrierDismissible = false,
  Color barrierColor = Colors.black54,
}) {
  return PopupManager.show(
    PopupConfig(
      child: LoadingWidget(
        message: message,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        indicatorColor: indicatorColor,
        indicatorStrokeWidth: indicatorStrokeWidth,
        textStyle: textStyle,
      ),
      position: PopupPosition.center,
      showBarrier: showBarrier,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      duration: null,
    ),
  );
}

/// 隐藏 Loading
///
/// [id] showLoading 返回的 ID
void _hideLoadingImpl(String id) {
  PopupManager.hide(id);
}