import 'package:flutter/material.dart';
import 'package:omni_calendar_view/omni_calendar_view.dart';
import 'package:omni_date_picker/omni_date_picker.dart';

class CalendarView extends StatelessWidget {
  final OmniCalendarController controller;
  final bool showLunar;
  final Locale locale;
  final bool showSurroundingDays;

  const CalendarView({
    super.key,
    required this.controller,
    required this.showLunar,
    required this.locale,
    required this.showSurroundingDays,
  });


  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: OmniCalendarView(
          controller: controller,
          showLunar: showLunar,
          showSurroundingDays: showSurroundingDays,
          locale: locale,
          onDateSelected: (date) {
            print('单选: ${date.toLocal()}');
          },
          onDateRangeSelected: (dateRange) {
            print('范围选择: ${dateRange.start.toLocal()} - ${dateRange.end.toLocal()}');
          },
          onMonthChanged: (date) {
            print('月份切换到: ${date.year}-${date.month}');
          },
          onHeaderTap: () async {
            OmniDatePicker.show(
              context: context,
              mode: PickerMode.filterDate,
              filterType: FilterType.month,
              isEn:locale == Locale("en" , "EN") ,
              initialDateTime: DateTime.now(),
              onConfirm: (dateTime) {
                int year = dateTime["year"];
                int month = dateTime["month"];
                controller.jumpToDate(DateTime(year , month));
              },
            );
          },
        ),
      ),
    );
  }
}
