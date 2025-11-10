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
  final String? customImagePath;
  final double? imageSize;
  final Color? imgColor;
  final Axis layoutDirection;

  const ToastWidget({
    super.key,
    required this.message,
    this.toastType,
    this.customImagePath,
    this.imageSize,
    this.imgColor,
    this.layoutDirection = Axis.horizontal,
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
    const defaultImageSize = 24.0;
    
    // 确定图片路径：如果提供了自定义图片，优先使用；否则使用 toastType 对应的图标
    String? imgPath;
    bool shouldShowImage = false;
    
    if (customImagePath != null) {
      // 使用自定义图片
      imgPath = customImagePath;
      shouldShowImage = true;
    } else {
      // 使用 toastType 对应的图标
      switch (toastType) {
        case ToastType.success:
          imgPath = "assets/images/success.png";
          shouldShowImage = true;
          break;
        case ToastType.error:
          imgPath = "assets/images/error.png";
          shouldShowImage = true;
          break;
        case ToastType.warn:
          imgPath = "assets/images/warn.png";
          shouldShowImage = true;
          break;
        case null:
        case ToastType.none:
          shouldShowImage = false;
          break;
      }
    }
    
    final effectiveImageSize = imageSize ?? defaultImageSize;
    
    // 构建图片 Widget
    Widget? imageWidget;
    if (shouldShowImage && imgPath != null) {
      imageWidget = Image.asset(
        imgPath,
        package: customImagePath != null ? null : "unified_popups",
        height: effectiveImageSize,
        width: effectiveImageSize,
        color: customImagePath != null ? imgColor : null,
      );
    }
    
    // 构建文字 Widget
    final textWidget = Flexible(
      child: Text(
        message,
        style: style ?? defaultStyle,
        textAlign: textAlign ?? TextAlign.start,
        maxLines: null,
        overflow: TextOverflow.visible,
      ),
    );
    
    // 根据布局方向决定使用 Row 还是 Column
    Widget content;
    if (layoutDirection == Axis.vertical) {
      // Column 布局：图片在上，文字在下
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageWidget != null) ...[
            imageWidget,
            const SizedBox(height: 12),
          ],
          textWidget,
        ],
      );
    } else {
      // Row 布局：图片在左，文字在右（保持原有行为）
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageWidget != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: imageWidget,
            ),
          ],
          textWidget,
        ],
      );
    }
    
    return Container(
      margin: margin ?? defaultMargin,
      padding: padding ?? defaultPadding,
      decoration: decoration ?? defaultDecoration,
      child: content,
    );
  }
}
