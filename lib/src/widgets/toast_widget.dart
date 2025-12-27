// lib/src/widgets/toast_widget.dart
import 'package:flutter/material.dart';
import '../core/popup_manager.dart';

class ToastWidget extends StatefulWidget {
  final String? message;
  final Widget? messageWidget;
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
  
  // 切换功能相关参数
  final String? tMessage;
  final String? tImagePath;
  final ToastType? tToastType;
  final Color? tImgColor;
  final VoidCallback? onTap;
  final bool toggleable;

  const ToastWidget({
    super.key,
    this.message,
    this.messageWidget,
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
    // 切换功能参数
    this.tMessage,
    this.tImagePath,
    this.tToastType,
    this.tImgColor,
    this.onTap,
    this.toggleable = false,
  });

  @override
  State<ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget> {
  bool _isFirstState = true;

  void _handleTap() {
    if (widget.toggleable && (widget.tMessage != null || widget.tImagePath != null)) {
      setState(() {
        _isFirstState = !_isFirstState;
      });
    }
    widget.onTap?.call();
  }



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
    
    // 根据当前状态选择显示的内容
    final currentMessage = _isFirstState 
        ? widget.message 
        : (widget.tMessage ?? widget.message);
    final currentImagePath = _isFirstState 
        ? widget.customImagePath 
        : (widget.tImagePath ?? widget.customImagePath);
    final currentToastType = _isFirstState 
        ? widget.toastType 
        : (widget.tToastType ?? widget.toastType);
    final currentImgColor = _isFirstState 
        ? widget.imgColor 
        : (widget.tImgColor ?? widget.imgColor);
    
    // 确定图片路径：如果提供了自定义图片，优先使用；否则使用 toastType 对应的图标
    String? imgPath;
    bool shouldShowImage = false;
    
    if (currentImagePath != null) {
      // 使用自定义图片
      imgPath = currentImagePath;
      shouldShowImage = true;
    } else {
      // 使用 toastType 对应的图标
      switch (currentToastType) {
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
    
    final effectiveImageSize = widget.imageSize ?? defaultImageSize;
    
    // 构建图片 Widget
    Widget? imageWidget;
    if (shouldShowImage && imgPath != null) {
      imageWidget = Image.asset(
        imgPath,
        package: currentImagePath != null ? null : "unified_popups",
        height: effectiveImageSize,
        width: effectiveImageSize,
        color: currentImagePath != null ? currentImgColor : null,
      );
    }
    
    // 构建内容 Widget：优先使用 messageWidget，否则使用 message（String）
    Widget contentWidget;
    if (widget.messageWidget != null) {
      // 使用自定义 Widget
      contentWidget = Flexible(child: widget.messageWidget!);
    } else if (currentMessage != null) {
      // 使用 String 文本
      contentWidget = Flexible(
        child: Text(
          currentMessage,
          style: widget.style ?? defaultStyle,
          textAlign: widget.textAlign ?? TextAlign.start,
          maxLines: null,
          overflow: TextOverflow.visible,
        ),
      );
    } else {
      // 如果都没有提供，显示空内容
      contentWidget = const SizedBox.shrink();
    }
    
    // 根据布局方向决定使用 Row 还是 Column
    Widget content;
    if (widget.layoutDirection == Axis.vertical) {
      // Column 布局：图片在上，内容在下
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageWidget != null) ...[
            imageWidget,
            const SizedBox(height: 12),
          ],
          contentWidget,
        ],
      );
    } else {
      // Row 布局：图片在左，内容在右（保持原有行为）
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageWidget != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: imageWidget,
            ),
          ],
          contentWidget,
        ],
      );
    }
    
    Widget container = Container(
      margin: widget.margin ?? defaultMargin,
      padding: widget.padding ?? defaultPadding,
      decoration: widget.decoration ?? defaultDecoration,
      child: content,
    );
    
    // 如果可切换，添加点击手势
    if (widget.toggleable && (widget.tMessage != null || widget.tImagePath != null)) {
      container = GestureDetector(
        onTap: _handleTap,
        child: container,
      );
    }
    
    return container;
  }
}
