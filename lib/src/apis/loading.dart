part of 'pop.dart';

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

void _hideLoadingImpl(String id) {
  PopupManager.hide(id);
}
