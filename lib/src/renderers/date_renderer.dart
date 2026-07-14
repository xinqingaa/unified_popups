import 'package:flutter/material.dart';

import '../configs/date_config.dart';
import '../runtime/popup_runtime.dart';
import '../widgets/date_picker_widget.dart';

class DateRenderer extends StatelessWidget {
  const DateRenderer({
    required this.runtime,
    required this.entryId,
    required this.config,
    super.key,
  });

  final PopupRuntime runtime;
  final String entryId;
  final DateConfig config;

  @override
  Widget build(BuildContext context) {
    final range = config.range;
    final labels = config.labels;
    final style = config.style;
    return DatePickerWidget(
      initialDate: range.initialDate,
      minDate: range.minDate,
      maxDate: range.maxDate,
      title: labels.title,
      confirmText: labels.confirm,
      cancelText: labels.cancel,
      activeColor: style.activeColor ?? Theme.of(context).colorScheme.primary,
      noActiveColor:
          style.inactiveColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
      headerBg:
          style.headerBackgroundColor ?? Theme.of(context).colorScheme.primary,
      height: style.height,
      radius: style.radius,
      onConfirm: (date) {
        final selected = date.isBefore(range.minDate)
            ? range.minDate
            : date.isAfter(range.maxDate)
                ? range.maxDate
                : date;
        runtime.controller.completeEntry<DateTime>(entryId, selected);
      },
      onCancel: () => runtime.controller.completeEntry<DateTime>(entryId),
    );
  }
}
