part of 'pop.dart';

String _loadingImpl({
  String? message,
  // 样式参数
  Color? backgroundColor,
  double? borderRadius,
  Color? indicatorColor,
  double? indicatorStrokeWidth,
  TextStyle? textStyle,
  // 自定义指示器参数
  Widget? customIndicator,
  Duration rotationDuration = const Duration(seconds: 1),
  // 遮罩层参数
  bool showBarrier = true,
  bool barrierDismissible = false,
  Color barrierColor = Colors.black54,
  Duration animationDuration = const Duration(milliseconds: 150),
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
        customIndicator: customIndicator,
        rotationDuration: rotationDuration,
      ),
      position: PopupPosition.center,
      showBarrier: showBarrier,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      duration: null,
      animationDuration: animationDuration,
      type: PopupType.loading,
    ),
  );
}

void _hideLoadingImpl(String id) {
  PopupManager.hide(id);
}
