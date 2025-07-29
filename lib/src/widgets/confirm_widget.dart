// lib/src/widgets/confirm_widget.dart
import 'package:flutter/material.dart';

class ConfirmWidget extends StatelessWidget {
  final String? title;
  final String content;
  final String confirmText;
  final String? cancelText;
  final bool showCloseButton;

  final TextStyle? titleStyle;
  final TextStyle? contentStyle;
  final TextStyle? confirmStyle;
  final TextStyle? cancelStyle;
  final Color? confirmBgColor;
  final Color? cancelBgColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;

  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onClose;

  const ConfirmWidget({
    super.key,
    this.title,
    required this.content,
    required this.confirmText,
    this.cancelText,
    this.showCloseButton = false,
    required this.onConfirm,
    this.onCancel,
    this.onClose,
    this.padding,
    this.margin,
    this.decoration,
    this.titleStyle,
    this.contentStyle,
    this.cancelStyle,
    this.confirmStyle,
    this.cancelBgColor,
    this.confirmBgColor,
  }) : assert(cancelText == null || onCancel != null,
  'onCancel must be provided if cancelText is not null.');


  @override
  Widget build(BuildContext context) {
    const defaultPadding = EdgeInsets.fromLTRB(24.0, 28.0, 24.0, 24.0);
    const defaultMargin = EdgeInsets.all(24);
    const defaultTitleStyle = TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold, height: 1.4);
    const defaultContentStyle = TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500, height: 1.5);
    final defaultDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.0),
    );

    // 内部内容
    final contentWidget = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Text(title!, style: titleStyle ?? defaultTitleStyle, textAlign: TextAlign.center),
          const SizedBox(height: 12),
        ],
        Text(content, style: contentStyle ?? defaultContentStyle, textAlign: TextAlign.center),
        const SizedBox(height: 28),
        _buildButtons(),
      ],
    );

    return Container(
      margin: margin ?? defaultMargin,
      decoration: decoration ?? defaultDecoration,
      child: Stack(
        children: [
          Padding(
            padding: padding ?? defaultPadding,
            child: contentWidget,
          ),
          // 如果显示关闭按钮，则在右上角添加一个 Positioned 的 IconButton
          if (showCloseButton)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black45, size: 20),
                onPressed: onClose,
                splashRadius: 20,
              ),
            ),
        ],
      ),
    );
  }

  /// 根据是否有 cancelText 来构建不同的按钮布局
  Widget _buildButtons() {
    const defaultCancelStyle = TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500);
    const defaultConfirmStyle = TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold);
    final confirmButton = TextButton(
      onPressed: onConfirm,
      style: TextButton.styleFrom(
        backgroundColor: confirmBgColor ?? Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(confirmText, style: confirmStyle ?? defaultConfirmStyle),
    );

    // 如果 cancelText 为 null，只显示一个居中的确认按钮
    if (cancelText == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: confirmButton),
        ],
      );
    }

    // 否则，显示两个按钮
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              backgroundColor: cancelBgColor ?? Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(cancelText!, style: cancelStyle ?? defaultCancelStyle),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: confirmButton,
        )
      ],
    );
  }
}