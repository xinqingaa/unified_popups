// lib/src/widgets/toast_widget.dart
import 'package:flutter/material.dart';

class ToastWidget extends StatelessWidget {
  final String message;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final TextStyle? style;
  final TextAlign? textAlign;

  const ToastWidget({
    super.key,
    required this.message,
    this.padding,
    this.margin,
    this.decoration,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 在这里定义好默认样式
    final defaultDecoration = BoxDecoration(
      color: Colors.black.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(12.0),
    );
    const defaultStyle = TextStyle(color: Colors.white, fontSize: 16);
    const defaultPadding = EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0);
    const defaultMargin = EdgeInsets.symmetric(horizontal: 20, vertical: 40);

    return Container(
      // 2. 使用传入的样式，如果为 null，则使用默认样式
      margin: margin ?? defaultMargin,
      padding: padding ?? defaultPadding,
      decoration: decoration ?? defaultDecoration,
      child: Text(
        message,
        style: style ?? defaultStyle,
        textAlign: textAlign ?? TextAlign.center,
      ),
    );
  }
}
