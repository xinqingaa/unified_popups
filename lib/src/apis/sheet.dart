part of 'pop.dart';

Future<T?> _sheetImpl<T>({
  required Widget Function(void Function([T? result]) dismiss) childBuilder,
  String? title,
  SheetDirection direction = SheetDirection.bottom,
  bool? useSafeArea,
  // Widget 级别的样式配置
  SheetDimension? width,
  SheetDimension? height,
  SheetDimension? maxWidth,
  SheetDimension? maxHeight,
  // 图片相关参数
  String? imgPath,
  double? imageSize,
  Offset? imageOffset,
  
  bool showCloseButton = false,
  Color? backgroundColor,
  BorderRadius? borderRadius,
  List<BoxShadow>? boxShadow,
  EdgeInsetsGeometry? padding,
  EdgeInsetsGeometry? titlePadding,
  TextStyle? titleStyle,
  TextAlign? titleAlign,
  Duration animationDuration = const Duration(milliseconds: 400),
}) {
  final completer = Completer<T?>();
  late String popupId;

  void dismiss([T? result]) {
    if (!completer.isCompleted) {
      completer.complete(result);
      PopupManager.hide(popupId);
    }
  }

  // 根据方向选择弹窗位置和动画
  PopupPosition position;
  PopupAnimation animation;
  switch (direction) {
    case SheetDirection.top:
      position = PopupPosition.top;
      animation = PopupAnimation.slideDown;
      break;
    case SheetDirection.left:
      position = PopupPosition.left;
      animation = PopupAnimation.slideLeft;
      break;
    case SheetDirection.right:
      position = PopupPosition.right;
      animation = PopupAnimation.slideRight;
      break;
    case SheetDirection.bottom:
      position = PopupPosition.bottom;
      animation = PopupAnimation.slideUp;
      break;
  }

  // 从 PopupManager 获取全局 context 和屏幕尺寸
  final context = PopupManager.navigatorKey.currentContext;
  if (context == null) {
    throw StateError(
        'PopupManager could not find a valid BuildContext. Is the navigatorKey set correctly?');
  }
  final screenSize = MediaQuery.of(context).size;

  // 定义一个辅助函数来解析 SheetDimension
  double? resolveDimension(SheetDimension? dimension, double fullSize) {
    if (dimension == null) return null;
    return switch (dimension) {
      Pixel(value: final v) => v,
      Fraction(value: final v) => v * fullSize,
    };
  }

  // 解析所有尺寸参数为具体的 double? 值
  final resolvedWidth = resolveDimension(width, screenSize.width);
  final resolvedHeight = resolveDimension(height, screenSize.height);
  final resolvedMaxWidth = resolveDimension(maxWidth, screenSize.width);
  final resolvedMaxHeight = resolveDimension(maxHeight, screenSize.height);

  // 如果用户没有指定 useSafeArea，则根据方向智能判断。
  final bool applySafeArea = useSafeArea ?? (direction == SheetDirection.bottom);

  popupId = PopupManager.show(
    PopupConfig(
      child: SheetWidget(
        title: title,
        direction: direction,
        showCloseButton: showCloseButton, // 传递新参数
        onClose: () => dismiss(null), // 传递关闭回调
        width: resolvedWidth,
        height: resolvedHeight,
        maxWidth: resolvedMaxWidth,
        maxHeight: resolvedMaxHeight,
        // 图片相关参数
        imgPath: imgPath,
        imageSize: imageSize ?? 60.0,
        imageOffset: imageOffset ?? const Offset(16, -40),
        // 样式相关参数
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
        padding: padding,
        titlePadding: titlePadding,
        titleStyle: titleStyle,
        titleAlign: titleAlign,
        // 使用 childBuilder 构建子 Widget，并传入 dismiss 函数
        child: childBuilder(dismiss),
      ),
      position: position,
      animation: animation,
      animationDuration: animationDuration,
      useSafeArea: applySafeArea,
      showBarrier: true,
      barrierDismissible: true,
      type: PopupType.sheet,
      onDismiss: () {
        // 点击蒙层关闭
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    ),
  );
  return completer.future;
}
