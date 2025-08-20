import 'package:flutter/material.dart';

import '../apis/popup_apis.dart';

class SheetWidget extends StatelessWidget {
  final String? title;
  final Widget child;
  final SheetDirection direction;

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

  /// 根据方向获取默认的圆角
  BorderRadius _getDefaultBorderRadius() {
    const radius = Radius.circular(20);
    switch (direction) {
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

  @override
  Widget build(BuildContext context) {
    // 定义默认样式
    const defaultBackgroundColor = Colors.white;
    final defaultBoxShadow = [const BoxShadow(blurRadius: 10, color: Colors.black12, spreadRadius: 2)];
    const defaultPadding = EdgeInsets.symmetric(horizontal: 10.0 , vertical: 10);
    const defaultTitlePadding = EdgeInsets.only(bottom: 0);
    final defaultTitleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold);
    const defaultTitleAlign = TextAlign.center;

    // 判断是水平方向还是垂直方向的 Sheet
    bool isHorizontal = direction == SheetDirection.left || direction == SheetDirection.right;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? double.infinity,
        maxHeight: maxHeight ?? double.infinity,
      ),
      child: Container(
        width: width ,
        height: height ,
        decoration: BoxDecoration(
          color: backgroundColor ?? defaultBackgroundColor,
          borderRadius: borderRadius ?? _getDefaultBorderRadius(),
          boxShadow: boxShadow ?? defaultBoxShadow,
        ),
        child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: Padding(
                padding: padding ?? defaultPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title != null) ...[
                      Padding(
                        padding: titlePadding ?? defaultTitlePadding,
                        child: Text(
                          title!,
                          style: titleStyle ?? defaultTitleStyle,
                          textAlign: titleAlign ?? defaultTitleAlign,
                        ),
                      ),
                    ],
                    // 对于垂直方向的 Sheet，让 child 可以滚动
                    // 对于水平方向的 Sheet，让 child 占据剩余空间
                    if (isHorizontal)
                      Expanded(child: child)
                    else
                      Flexible(child: child),
                  ],
                ),
              ),
            )
        ),
      ),
    );
  }
}
