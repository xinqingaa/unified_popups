import 'package:flutter/material.dart';
import '../core/popup_manager.dart';



class SheetWidget extends StatefulWidget {
  final String? title;
  final Widget child;
  final SheetDirection direction;
  final bool showCloseButton;
  final VoidCallback? onClose;

  // 尺寸控制
  final double? width;
  final double? height;

  // 样式控制
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? titlePadding;
  final TextStyle? titleStyle;
  final TextAlign? titleAlign;

  // 布局约束
  final double? maxWidth;
  final double? maxHeight;

  const SheetWidget({
    super.key,
    this.title,
    required this.child,
    this.direction = SheetDirection.bottom,
    this.showCloseButton = false, // 默认不显示
    this.onClose,
    this.width,
    this.height,
    this.maxWidth,
    this.maxHeight,
    this.backgroundColor,
    this.borderRadius,
    this.boxShadow,
    this.padding,
    this.titlePadding,
    this.titleStyle,
    this.titleAlign,
  });

  @override
  State<SheetWidget> createState() => _SheetWidgetState();
}

class _SheetWidgetState extends State<SheetWidget> {
  // 用于记录拖动的偏移量
  Offset _dragOffset = Offset.zero;
  // 定义关闭的阈值
  static const double _dismissThreshold = 75.0;

  BorderRadius _getDefaultBorderRadius() {
    const radius = Radius.circular(20);
    switch (widget.direction) {
      case SheetDirection.top:
        return const BorderRadius.only(bottomLeft: radius, bottomRight: radius);
      case SheetDirection.left:
        return const BorderRadius.only(topRight: radius, bottomRight: radius);
      case SheetDirection.right:
        return const BorderRadius.only(topLeft: radius, bottomLeft: radius);
      case SheetDirection.bottom:
        return const BorderRadius.only(topLeft: radius, topRight: radius);
    }
  }

  // 处理拖动更新
  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      // 累加拖动偏移
      final newOffset = _dragOffset + details.delta;

      // 根据方向限制拖动
      switch (widget.direction) {
        case SheetDirection.bottom:
          _dragOffset = Offset(0, newOffset.dy.clamp(0.0, double.infinity));
          break;
        case SheetDirection.top:
          _dragOffset = Offset(0, newOffset.dy.clamp(double.negativeInfinity, 0.0));
          break;
        case SheetDirection.left:
          _dragOffset = Offset(newOffset.dx.clamp(double.negativeInfinity, 0.0), 0);
          break;
        case SheetDirection.right:
          _dragOffset = Offset(newOffset.dx.clamp(0.0, double.infinity), 0);
          break;
      }
    });
  }

  // 处理拖动结束
  void _handleDragEnd(DragEndDetails details) {
    bool shouldDismiss = false;
    // 判断是否超过阈值
    switch (widget.direction) {
      case SheetDirection.bottom:
        shouldDismiss = _dragOffset.dy > _dismissThreshold;
        break;
      case SheetDirection.top:
        shouldDismiss = _dragOffset.dy < -_dismissThreshold;
        break;
      case SheetDirection.left:
        shouldDismiss = _dragOffset.dx < -_dismissThreshold;
        break;
      case SheetDirection.right:
        shouldDismiss = _dragOffset.dx > _dismissThreshold;
        break;
    }

    if (shouldDismiss) {
      widget.onClose?.call();
    } else {
      // 如果未超过阈值，弹回原位
      setState(() {
        _dragOffset = Offset.zero;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    // 定义默认样式
    const defaultBackgroundColor = Colors.white;
    final defaultBoxShadow = [const BoxShadow(blurRadius: 10, color: Colors.black12, spreadRadius: 2)];
    const defaultPadding = EdgeInsets.symmetric(horizontal: 16.0 , vertical: 10);
    const defaultTitlePadding = EdgeInsets.only(bottom: 8, top: 6);
    final defaultTitleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold);
    const defaultTitleAlign = TextAlign.center;

    bool isHorizontal = widget.direction == SheetDirection.left || widget.direction == SheetDirection.right;

    // 标题和关闭按钮的组合
    Widget? titleBar;
    if (widget.title != null || widget.showCloseButton) {
      titleBar = Padding(
        padding: widget.titlePadding ?? defaultTitlePadding,
        child: Stack(
          children: [
            // 标题占据主要空间
            widget.title != null ? Center(
              child: Text(
                widget.title!,
                style: widget.titleStyle ?? defaultTitleStyle,
                textAlign: widget.titleAlign ?? defaultTitleAlign,
              ),
            ) : const SizedBox.shrink(),

            if (widget.showCloseButton && widget.direction == SheetDirection.bottom)
              Positioned(
                right: 0,
                top: -10,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              )
          ],
        ),
      );
    }


    final sheetContent = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth ?? double.infinity,
        maxHeight: widget.maxHeight ?? double.infinity,
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? defaultBackgroundColor,
          borderRadius: widget.borderRadius ?? _getDefaultBorderRadius(),
          boxShadow: widget.boxShadow ?? defaultBoxShadow,
        ),
        child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: Padding(
                padding: widget.padding ?? defaultPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (titleBar != null) titleBar,
                    if (isHorizontal)
                      Expanded(child: widget.child)
                    else
                      Flexible(child: widget.child),
                  ],
                ),
              ),
            )
        ),
      ),
    );

    // 使用 GestureDetector 包裹整个内容以捕获拖动手势
    return GestureDetector(
      onVerticalDragUpdate: !isHorizontal ? _handleDragUpdate : null,
      onVerticalDragEnd: !isHorizontal ? _handleDragEnd : null,
      onHorizontalDragUpdate: isHorizontal ? _handleDragUpdate : null,
      onHorizontalDragEnd: isHorizontal ? _handleDragEnd : null,
      // 使用 Transform.translate 来根据拖动偏移量移动 Widget
      child: Transform.translate(
        offset: _dragOffset,
        child: sheetContent,
      ),
    );
  }
}
