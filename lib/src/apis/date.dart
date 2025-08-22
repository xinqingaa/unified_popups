part of 'pop.dart';

Future<DateTime?> _dateImpl({
  DateTime? initialDate,
  DateTime? minDate,
  DateTime? maxDate,
  required String title,
  required PopupPosition position,
  required String confirmText,
  String? cancelText,
  Color? activeColor,
  Color? noActiveColor,
  Color? headerBg,
  double? height
}) {
  final completer = Completer<DateTime?>();
  late String popupId;

  void dismiss(DateTime? result) {
    if (!completer.isCompleted) {
      completer.complete(result);
      PopupManager.hide(popupId);
    }
  }

  final animation = (position == PopupPosition.top)
      ? PopupAnimation.slideDown
      : (position == PopupPosition.bottom)
      ? PopupAnimation.slideUp
      : PopupAnimation.fade;

  popupId = PopupManager.show(
    PopupConfig(
      child: DatePickerWidget(
        initialDate: initialDate ?? DateTime.now(),
        // 默认年份范围：1960年1月1日 到 今天
        minDate: minDate ?? DateTime(1960),
        maxDate: maxDate ?? DateTime.now(),
        title: title,
        confirmText: confirmText,
        cancelText: cancelText,
        activeColor: activeColor,
        noActiveColor: noActiveColor,
        height: height,
        headerBg: headerBg,
        onConfirm: (selectedDate) => dismiss(selectedDate),
        onCancel: () => dismiss(null),
      ),
      animation: animation,
      position: position,
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