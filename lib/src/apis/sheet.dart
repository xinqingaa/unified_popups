part of 'pop.dart';


/// 显示一个从指定方向滑出的 Sheet 面板
///
/// [context] BuildContext，用于获取屏幕尺寸
/// [childBuilder] 内容构建器。它接收一个 dismiss 函数，你可以在你的 child widget 中调用它来关闭 sheet 并返回一个可选的结果。
///   例如：`onTap: () => dismiss('item1_selected')`
/// [title] 可选的标题
/// [direction] Sheet 的滑出方向，默认为底部
/// [width] Sheet 的宽度。对于左右方向，默认为屏幕宽度的 75%
/// [height] Sheet 的高度。对于上下方向，此参数通常不设置，由内容自适应
/// [backgroundColor], [borderRadius], [boxShadow] 等参数用于完全自定义 Sheet 的外观
///
/// returns [Future<T?>] 当 Sheet 关闭时返回。如果通过 dismiss([result]) 关闭，则返回 result；如果点击蒙层关闭，则返回 null。
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
  bool showCloseButton = false,
  Color? backgroundColor,
  BorderRadius? borderRadius,
  List<BoxShadow>? boxShadow,
  EdgeInsetsGeometry? padding,
  EdgeInsetsGeometry? titlePadding,
  TextStyle? titleStyle,
  TextAlign? titleAlign,
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
    throw StateError('PopupManager could not find a valid BuildContext. Is the navigatorKey set correctly?');
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
  // 底部弹窗通常不需要顶部安全区，而其他方向需要。
  final bool applySafeArea = useSafeArea ?? direction == SheetDirection.bottom ? true : false;
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
      useSafeArea: applySafeArea,
      showBarrier: true,
      barrierDismissible: true,
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

