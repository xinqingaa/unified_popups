// lib/src/widgets/toast_widget.dart
import 'package:flutter/material.dart';
import '../core/popup_manager.dart';

class ToastWidget extends StatelessWidget {
  final String message;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final TextStyle? style;
  final TextAlign? textAlign;
  final ToastType? toastType;

  const ToastWidget({
    super.key,
    required this.message,
    this.toastType,
    this.padding,
    this.margin,
    this.decoration,
    this.style,
    this.textAlign,
  });



  @override
  Widget build(BuildContext context) {
    final defaultDecoration = BoxDecoration(
      color: Colors.black.withValues(alpha: 0.80),
      borderRadius: BorderRadius.circular(12.0),
    );
    const defaultStyle = TextStyle(color: Colors.white, fontSize: 16);
    const defaultPadding = EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0);
    const defaultMargin = EdgeInsets.symmetric(horizontal: 20, vertical: 40);
    late final String imgPath;
    switch (toastType) {
      case ToastType.success:
        imgPath = "assets/images/success.png";
        break;
      case ToastType.error:
        imgPath = "assets/images/error.png";
        break;
      case ToastType.warn:
        imgPath = "assets/images/warn.png";
        break;

      case null:

      case ToastType.none:

    }
    return Container(
      margin: margin ?? defaultMargin,
      padding: padding ?? defaultPadding,
      decoration: decoration ?? defaultDecoration,
      child: Row(
        mainAxisSize:MainAxisSize.min,
        children: [
          if(toastType != ToastType.none)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Image.asset(imgPath,  package: "unified_popups", height: 24,),
            ),
          Flexible(
            child: Text(
              message,
              style: style ?? defaultStyle,
              textAlign: textAlign ?? TextAlign.start,
              maxLines: null,
              overflow: TextOverflow.visible,
            ),
          )
        ],
      )
    );
  }
}
