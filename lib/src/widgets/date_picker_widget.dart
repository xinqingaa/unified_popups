// lib/widgets/date_picker_widget.dart
import 'package:flutter/material.dart';

class DatePickerWidget extends StatefulWidget {
  final DateTime initialDate;
  final DateTime minDate;
  final DateTime maxDate;
  final String title;
  final String confirmText;
  final String? cancelText;
  final Color? activeColor;
  final Color? noActiveColor;
  final Color? headerBg;
  final double? height;
  final ValueChanged<DateTime> onConfirm;
  final VoidCallback onCancel;

  const DatePickerWidget({
    super.key,
    required this.initialDate,
    required this.minDate,
    required this.maxDate,
    required this.title,
    required this.confirmText,
    this.cancelText,
    this.activeColor,
    this.noActiveColor,
    this.headerBg,
    this.height,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<DatePickerWidget> createState() => _DatePickerWidgetState();
}

class _DatePickerWidgetState extends State<DatePickerWidget> {
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  // 月份英文缩写列表
  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _selectedDay = widget.initialDate.day;
  }

  /// 核心逻辑：获取指定年月的总天数
  int _getDaysInMonth(int year, int month) {
    // DateTime(year, month + 1, 0) 会返回上一个月的最后一天
    return DateTime(year, month + 1, 0).day;
  }

  /// 核心逻辑：当 年 或 月 变动时，验证并修正日期
  void _handleDateChange({int? year, int? month, int? day}) {
    setState(() {
      _selectedYear = year ?? _selectedYear;
      _selectedMonth = month ?? _selectedMonth;

      // 关键步骤：检查当前选中的 '日' 在新的 '年/月' 组合下是否有效
      final daysInNewMonth = _getDaysInMonth(_selectedYear, _selectedMonth);
      if (_selectedDay > daysInNewMonth) {
        _selectedDay = daysInNewMonth; // 如果无效（例如从1月31日切到2月），则修正为新月份的最后一天
      }

      // 如果外部传入了 day，则直接使用
      if (day != null) {
        _selectedDay = day;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildPickers(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: widget.headerBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        )
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.cancelText != null)
            _buildButton(
              onTap: widget.onCancel,
              text: widget.cancelText!,
              textAlign: TextAlign.left
            ),
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          _buildButton(
            onTap: () {
              final selectedDateTime = DateTime(
                _selectedYear,
                _selectedMonth,
                _selectedDay,
              );
              widget.onConfirm(selectedDateTime);
            },
            textAlign: TextAlign.right,
            text: widget.confirmText
          )
        ],
      ),
    );
  }

  Widget _buildButton ({
    required VoidCallback onTap ,
    required String text,
    required TextAlign textAlign
  }){
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            text ,
            textAlign: textAlign,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickers() {
    return SizedBox(
      height: widget.height, // 给予足够的高度以显示滚轮
      child: Row(
        children: [
          // 月份选择器
          Expanded(
            child: CustomPicker(
              key: ValueKey('month_$_selectedYear'), // 年份变化时重建，以防月份范围变化
              height: widget.height!,
              startValue: 1,
              endValue: 12,
              initialValue: _selectedMonth,
              onValueChanged: (newMonth) => _handleDateChange(month: newMonth),
              itemBuilder: (context, value, isSelected) {
                return Center(
                  child: Text(
                    _monthNames[value - 1],
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected ? widget.activeColor : widget.noActiveColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          // 日期选择器
          Expanded(
            child: CustomPicker(
              // 使用 ValueKey 确保在 年/月 变化时，此组件能正确重建并更新其范围
              key: ValueKey('day_$_selectedYear$_selectedMonth'),
              height: widget.height!,
              startValue: 1,
              endValue: _getDaysInMonth(_selectedYear, _selectedMonth),
              initialValue: _selectedDay,
              onValueChanged: (newDay) => _handleDateChange(day: newDay),
              itemBuilder: (context, value, isSelected) {
                return Center(
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected ? widget.activeColor : widget.noActiveColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          // 年份选择器
          Expanded(
            child: CustomPicker(
              startValue: widget.minDate.year,
              endValue: widget.maxDate.year,
              initialValue: _selectedYear,
              height: widget.height!,
              onValueChanged: (newYear) => _handleDateChange(year: newYear),
              itemBuilder: (context, value, isSelected) {
                return Center(
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected ? widget.activeColor : widget.noActiveColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class CustomPicker extends StatefulWidget {
  final double height;
  final int startValue;
  final int endValue;
  final int initialValue;
  final ValueChanged<int> onValueChanged;
  final Widget Function(BuildContext context, int value, bool isSelected) itemBuilder;

  const CustomPicker({
    super.key,
    required this.height,
    required this.startValue,
    required this.endValue,
    required this.initialValue,
    required this.onValueChanged,
    required this.itemBuilder,
  });

  @override
  State<CustomPicker> createState() => _CustomPickerState();
}

class _CustomPickerState extends State<CustomPicker> {
  late FixedExtentScrollController _scrollController;
  late int _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    _scrollController = FixedExtentScrollController(
      initialItem: _calculateInitialItem(),
    );
  }

  int _calculateInitialItem() {
    // 确保 initialValue 在有效范围内
    final value = widget.initialValue.clamp(widget.startValue, widget.endValue);
    return value - widget.startValue;
  }

  @override
  void didUpdateWidget(CustomPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当外部传入的值发生变化时（例如，日期修正），平滑滚动到新位置
    if (widget.initialValue != oldWidget.initialValue ||
        widget.startValue != oldWidget.startValue ||
        widget.endValue != oldWidget.endValue) {

      _selectedValue = widget.initialValue;
      final targetItem = _calculateInitialItem();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && _scrollController.selectedItem != targetItem) {
          _scrollController.animateToItem(
            targetItem,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int itemCount = widget.endValue - widget.startValue + 1;

    return SizedBox(
      height: widget.height,
      child: ListWheelScrollView.useDelegate(
        controller: _scrollController,
        itemExtent: 40,
        physics: const FixedExtentScrollPhysics(),
        magnification: 1.1,
        useMagnifier: false,
        overAndUnderCenterOpacity: 0.5,
        perspective: 0.003,
        onSelectedItemChanged: (index) {
          final newValue = widget.startValue + index;
          setState(() {
            _selectedValue = newValue;
          });
          widget.onValueChanged(newValue);
        },
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            if (index < 0 || index >= itemCount) {
              return const SizedBox.shrink();
            }
            final int value = widget.startValue + index;
            final bool isSelected = (value == _selectedValue);
            return widget.itemBuilder(context, value, isSelected);
          },
          childCount: itemCount,
        ),
      ),
    );
  }
}
