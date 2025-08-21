// lib/src/widgets/loading_widget.dart
import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;
  final double? borderRadius;
  final Color? indicatorColor;
  final double? indicatorStrokeWidth;
  final TextStyle? textStyle;

  const LoadingWidget({
    super.key,
    this.message,
    this.backgroundColor,
    this.borderRadius,
    this.indicatorColor,
    this.indicatorStrokeWidth,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    const defaultStyle = TextStyle(color: Colors.white, fontSize: 16);
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(borderRadius ?? 12.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: indicatorColor ?? Colors.white ,
            strokeWidth: indicatorStrokeWidth ?? 2.0,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: textStyle ?? defaultStyle,
            ),
          ],
        ],
      ),
    );
  }
}
