part of 'pop.dart';

void _loadingImpl({
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
  Curve? animationCurve,
}) {
  // 如果已有 loading，先关闭它（确保单例模式）
  if (PopupManager.getCountByType(PopupType.loading) > 0) {
    return;
  }
  
  // 创建新的 loading（使用最新配置）
  PopupManager.show(
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
      animationCurve: animationCurve,
      type: PopupType.loading,
    ),
  );
}

void _hideLoadingImpl() {
  // 只需要关闭一个即可（因为最多只有一个）
  PopupManager.hideByType(PopupType.loading);
}
