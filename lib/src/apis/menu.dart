part of 'pop.dart';

Future<T?> _menuImpl<T>({
  required GlobalKey anchorKey,
  Offset anchorOffset = Offset.zero,
  required Widget Function(void Function([T? result]) dismiss) builder,
  bool showBarrier = true,
  bool barrierDismissible = true,
  Color? barrierColor,
  EdgeInsetsGeometry? padding,
  BoxConstraints? constraints,
  BoxDecoration? decoration,
  PopupAnimation animation = PopupAnimation.fade,
  Duration animationDuration = const Duration(milliseconds: 200),
}) {
  final completer = Completer<T?>();
  late String popupId;

  void dismiss([T? result]) {
    if (!completer.isCompleted) {
      completer.complete(result);
      PopupManager.hide(popupId);
    }
  }

  popupId = PopupManager.show(
    PopupConfig(
      anchorKey: anchorKey,
      anchorOffset: anchorOffset,
      animation: animation,
      animationDuration: animationDuration,
      showBarrier: showBarrier,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      // 锚定菜单不使用 SafeArea
      useSafeArea: false,
      type: PopupType.menu,
      // 传入菜单内容
      child: MenuWidget(
        padding: padding,
        decoration: decoration,
        constraints: constraints,
        child: builder(dismiss),
      ),
      // 其他字段（position/duration）在锚定模式下不会生效
    ),
  );

  return completer.future;
}