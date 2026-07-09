part of 'pop.dart';

Future<R?> _flowSheetImpl<R>({
  required FlowSheetController<R> controller,
  required FlowSheetPage initialPage,
  SheetDirection direction = SheetDirection.bottom,
  SheetDimension? maxHeight,
  SheetDimension? maxWidth,
  Color? backgroundColor,
  EdgeInsetsGeometry? padding,
  bool barrierDismissible = false,
  bool? showBarrier,
  Color? barrierColor,
  bool Function()? onBackPressed,
  bool showDragHandle = true,
  Color? dragHandleColor,
  bool adjustForKeyboard = true,
  Duration animationDuration = const Duration(milliseconds: 400),
  SheetDragDismissMode dragDismissMode = SheetDragDismissMode.fullBody,
  Color? pageBackgroundColor,
  FlowSheetRouteBuilder? routeBuilder,
}) {
  controller.configureDragDismissMode(dragDismissMode);
  return _sheetImpl<R>(
    direction: direction,
    maxHeight: maxHeight,
    maxWidth: maxWidth,
    backgroundColor: backgroundColor,
    padding: padding,
    barrierDismissible: barrierDismissible,
    showBarrier: showBarrier,
    barrierColor: barrierColor,
    onBackPressed: onBackPressed ?? controller.handleBack,
    showDragHandle: showDragHandle,
    dragHandleColor: dragHandleColor,
    adjustForKeyboard: adjustForKeyboard,
    dragDismissMode: dragDismissMode,
    dragDismissModeListenable: controller.dragDismissModeNotifier,
    animationDuration: animationDuration,
    childBuilder: (dismiss) {
      controller.attachDismiss(dismiss);
      return FlowSheetHost(
        controller: controller,
        initialPage: initialPage,
        pageBackgroundColor: pageBackgroundColor,
        routeBuilder: routeBuilder,
      );
    },
  ).whenComplete(controller.handleSheetDismissed);
}
