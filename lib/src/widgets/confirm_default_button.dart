import 'package:flutter/material.dart';

import '../configs/confirm_config.dart';

/// 库默认胶囊按钮。主按钮实心、次按钮线框；不开放颜色 / 圆角参数。
abstract final class ConfirmDefaultButton {
  /// 主按钮：Theme [FilledButton] + 药丸。
  static ConfirmButtonBuilder filled(String label) =>
      (onTap) => _ConfirmDefaultButton(
            label: label,
            onTap: onTap,
            filled: true,
          );

  /// 次按钮：Theme [OutlinedButton] + 药丸。
  static ConfirmButtonBuilder outline(String label) =>
      (onTap) => _ConfirmDefaultButton(
            label: label,
            onTap: onTap,
            filled: false,
          );
}

class _ConfirmDefaultButton extends StatelessWidget {
  const _ConfirmDefaultButton({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    const style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size.fromHeight(40)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: WidgetStatePropertyAll(StadiumBorder()),
    );
    final child = Text(label);
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: filled
          ? FilledButton(onPressed: onTap, style: style, child: child)
          : OutlinedButton(onPressed: onTap, style: style, child: child),
    );
  }
}
