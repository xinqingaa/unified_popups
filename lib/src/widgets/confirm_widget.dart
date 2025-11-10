// lib/src/widgets/confirm_widget.dart
import 'package:flutter/material.dart';
import '../../unified_popups.dart';

class ConfirmWidget extends StatelessWidget {
  // 图片资源路径
  final String? imagePath;
  // 图片高度
  final double? imageHeight;
  // 图片宽度
  final double? imageWidth;
  // 文本对齐方式
  final TextAlign? textAlign;
  // 按钮布局方式
  final ConfirmButtonLayout? buttonLayout;
  // 按钮圆角
  final BorderRadiusGeometry? buttonBorderRadius;

  final String? title;
  final String content;
  final String? confirmText;
  final String? cancelText;
  final bool showCloseButton;

  final TextStyle? titleStyle;
  final TextStyle? contentStyle;
  final TextStyle? confirmStyle;
  final TextStyle? cancelStyle;
  final Color? confirmBgColor;
  final Color? cancelBgColor;
  final BoxBorder? confirmBorder;
  final BoxBorder? cancelBorder;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final Widget? confirmChild;

  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onClose;

  const ConfirmWidget({
    super.key,
    this.imagePath,
    this.imageHeight,
    this.imageWidth,
    this.title,
    required this.content,
    required this.confirmText,
    this.cancelText,
    this.showCloseButton = false,
    this.textAlign,
    this.buttonLayout ,
    this.buttonBorderRadius,
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
    this.confirmBorder,
    this.cancelBorder,
    this.confirmChild
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
      borderRadius: BorderRadius.circular(32.0),
    );

    // 焦点管理：在操作前收起键盘
    void handleConfirm() {
      FocusScope.of(context).unfocus();
      onConfirm();
    }

    void handleCancel() {
      FocusScope.of(context).unfocus();
      onCancel?.call();
    }

    void handleClose() {
      FocusScope.of(context).unfocus();
      onClose?.call();
    }

    // 内部内容
    final contentWidget = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (imagePath != null) ...[
          Image.asset(
            imagePath!,
            height: imageHeight,
            width: imageWidth,
          ),
          const SizedBox(height: 16),
        ],
        if (title != null) ...[
          // ?? TextAlign.center
          Text(title!, style: titleStyle ?? defaultTitleStyle, textAlign: textAlign, maxLines: null, overflow: TextOverflow.visible),
          const SizedBox(height: 12),
        ],
        Text(content, style: contentStyle ?? defaultContentStyle, textAlign: textAlign, maxLines: null, overflow: TextOverflow.visible),
        if (confirmChild != null) ...[
          const SizedBox(height: 12),
          confirmChild!,
        ],
        const SizedBox(height: 28),
        _buildButtons(
          onConfirmTap: handleConfirm,
          onCancelTap: handleCancel,
        ),
      ],
    );

    return AnimatedPadding(
      padding: MediaQuery.of(context).viewInsets,
      duration: kThemeAnimationDuration,
      curve: Curves.easeOut,
      child: Container(
        margin: margin ?? defaultMargin,
        decoration: decoration ?? defaultDecoration,
        child: Stack(
          children: [
            // 小屏或键盘弹出时可滚动
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: padding ?? defaultPadding,
                child: contentWidget,
              ),
            ),
            if (showCloseButton)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black45, size: 20),
                  onPressed: handleClose,
                  splashRadius: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 根据配置构建按钮布局
  Widget _buildButtons({required VoidCallback onConfirmTap, VoidCallback? onCancelTap}) {
    // 按钮圆角，提供默认值
    final effectiveBorderRadius = buttonBorderRadius ?? BorderRadius.circular(24.0);
    // 颜色逻辑
    final effectiveConfirmBgColor = confirmBgColor ?? Colors.black87;
    // 确认按钮文字固定为白色
    const defaultConfirmTextStyle = TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold);
    // 取消按钮文字颜色默认为确认按钮的背景色
    final defaultCancelTextStyle = TextStyle(color: effectiveConfirmBgColor, fontSize: 14, fontWeight: FontWeight.w500);

    // 包裹按钮并添加边框
    Widget wrapWithBorder(Widget button, BoxBorder? border) {
      if (border == null) {
        return button;
      }
      return DecoratedBox(
        decoration: BoxDecoration(
          border: border,
          borderRadius: effectiveBorderRadius,
        ),
        child: button,
      );
    }

    final confirmButton = TextButton(
      onPressed: onConfirmTap,
      style: TextButton.styleFrom(
        backgroundColor: effectiveConfirmBgColor,
        shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(confirmText!, style: confirmStyle ?? defaultConfirmTextStyle),
    );


    if (cancelText == null) {
      return wrapWithBorder(confirmButton, confirmBorder);
    }

    final cancelButton = TextButton(
      onPressed: onCancelTap,
      style: TextButton.styleFrom(
        backgroundColor: cancelBgColor ?? Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(cancelText!, style: cancelStyle ?? defaultCancelTextStyle),
    );

    // 根据 buttonLayout 返回不同的布局
    if (buttonLayout == ConfirmButtonLayout.column) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          wrapWithBorder(confirmButton, confirmBorder),
          const SizedBox(height: 12),
          wrapWithBorder(cancelButton, cancelBorder),
        ],
      );
    } else { // 默认为 Row 布局
      return Row(
        children: [
          Expanded(child: wrapWithBorder(cancelButton, cancelBorder)),
          const SizedBox(width: 12),
          Expanded(child: wrapWithBorder(confirmButton, confirmBorder)),
        ],
      );
    }
  }
}
