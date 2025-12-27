import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../core/popup_manager.dart';

class SheetWidget extends StatefulWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget child;
  final SheetDirection direction;
  final bool showCloseButton;
  final VoidCallback? onClose;

  // 图片路由和属性
  final String? imgPath;
  final double imageSize;
  final Offset imageOffset;

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

  // 遮罩相关参数
  final bool showBarrier;
  final bool barrierDismissible;
  final Color barrierColor;

  /// 是否在弹出方向上保留边缘空间
  final bool dockToEdge;
  final double? edgeGap;

  const SheetWidget({
    super.key,
    this.title,
    this.titleWidget,
    required this.child,
    this.direction = SheetDirection.bottom,
    this.showCloseButton = false, // 默认不显示
    this.imgPath,
    this.imageSize = 60.0,
    this.imageOffset = const Offset(16, -40),
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
    this.showBarrier = true,
    this.barrierDismissible = true,
    this.barrierColor = Colors.black54,
    this.dockToEdge = false,
    this.edgeGap,
  });

  @override
  State<SheetWidget> createState() => _SheetWidgetState();
}

class _SheetWidgetState extends State<SheetWidget> {
  // 用于记录拖动的偏移量
  Offset _dragOffset = Offset.zero;
  // 定义关闭的阈值
  static const double _dismissThreshold = 75.0;

  // 用于标记当前是否正在拖动整个 Sheet，以解决手势冲突
  bool _isDraggingSheet = false;

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
      _updateDragOffset(newOffset);
    });
  }

  // 更新拖动偏移量
  void _updateDragOffset(Offset newOffset) {
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
      // 键盘焦点管理：关闭前先收起键盘
      FocusScope.of(context).unfocus();
      widget.onClose?.call();
    } else {
      // 如果未超过阈值，弹回原位
      setState(() {
        _dragOffset = Offset.zero;
      });
    }
    // 重置拖动状态
    _isDraggingSheet = false;
  }

  // 处理滚动通知 
  bool _handleScrollNotification(ScrollNotification notification) {
    // 如果不是垂直方向的 Sheet，直接忽略滚动通知，交由 GestureDetector 处理
    if (widget.direction == SheetDirection.left || widget.direction == SheetDirection.right) {
      return false;
    }

    // 打印所有通知类型，方便观察事件流
    if (notification is ScrollEndNotification) {
      debugPrint("⏹️ 滚动结束. 当前是否在拖拽Sheet: $_isDraggingSheet");
      if (_isDraggingSheet) {
        // 使用 notification.dragDetails 来获取结束时的速度信息
        _handleDragEnd(DragEndDetails(velocity: notification.dragDetails?.velocity ?? Velocity.zero));
      }
      return false; // 返回 false 让其他监听器也能收到事件
    }


     // 2. 核心：处理越界滚动
    if (notification is OverscrollNotification) {
      // `overscroll` < 0 表示在顶部向下拖（或在左边向右拖）
      // `overscroll` > 0 表示在底部向上拖（或在右边向左拖）
      bool isDragInDismissDirection = false;
      switch(widget.direction) {
        case SheetDirection.bottom:
          isDragInDismissDirection = notification.overscroll < 0;
          break;
        case SheetDirection.top:
          isDragInDismissDirection = notification.overscroll > 0;
          break;
       default: break;
      }

      // 如果是在关闭方向上越界滚动，我们就开始拖拽Sheet
      if (isDragInDismissDirection) {
        // 标记我们正在拖拽 Sheet
        if (!_isDraggingSheet) {
          debugPrint("✅ 触发拖拽！(通过 OverscrollNotification)");
          _isDraggingSheet = true;
        }
        
        // 更新拖拽偏移量。overscroll 的方向与我们想要的偏移量方向相反，所以取反。
       final double delta = -notification.overscroll;
        final dragDelta = Offset(0, delta); 

        setState(() {
          // 在现有偏移量的基础上累加
          _updateDragOffset(_dragOffset + dragDelta);
        });

        // 返回 true，消费掉这个事件，防止列表出现默认的越界效果（如蓝色光晕）
        return true;
      }
    }

    // 3. 如果用户从拖拽Sheet的状态，又反向滚动回列表，我们需要重置状态
    if (_isDraggingSheet && notification is ScrollUpdateNotification) {
      // 如果滚动回正方向，并且偏移量已经归零，那么就停止拖拽Sheet，把控制权还给ListView
      if (_dragOffset.distance == 0) {
         debugPrint("↩️ 已返回列表滚动模式");
        _isDraggingSheet = false;
      }
    }

    // 对于其他所有情况，返回 false，让滚动视图正常处理事件
    return false;
  }


  @override
  Widget build(BuildContext context) {
    // 定义默认样式
    const defaultBackgroundColor = Colors.white;
    final defaultBoxShadow = [const BoxShadow(blurRadius: 10, color: Colors.black12, spreadRadius: 2)];
    const defaultPadding = EdgeInsets.symmetric(horizontal: 16.0 , vertical: 10);
    const defaultTitlePadding = EdgeInsets.symmetric(vertical: 12);
    final defaultTitleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold);
    const defaultTitleAlign = TextAlign.center;

    bool isHorizontal = widget.direction == SheetDirection.left || widget.direction == SheetDirection.right;
    final bool isChildScrollable = widget.child is ListView ||
        widget.child is GridView ||
        widget.child is CustomScrollView ||
        widget.child is SingleChildScrollView;
    final viewInsets = MediaQuery.of(context).viewInsets;

    // 标题和关闭按钮的组合
    Widget? titleBar;
    if (widget.title != null || widget.titleWidget != null || widget.showCloseButton) {
      final titleContent  = Padding(
        padding: widget.titlePadding ?? defaultTitlePadding,
        child: Stack(
          children: [
            // 标题占据主要空间：优先使用 titleWidget，否则使用 title
            if (widget.titleWidget != null)
              Center(child: widget.titleWidget!)
            else if (widget.title != null)
              Center(
                child: Text(
                  widget.title!,
                  style: widget.titleStyle ?? defaultTitleStyle,
                  textAlign: widget.titleAlign ?? defaultTitleAlign,
                  maxLines: null,
                  overflow: TextOverflow.visible,
                ),
              )
            else
              const SizedBox.shrink(),

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
              ),
          ],
        ),
      );
      titleBar = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: !isHorizontal ? _handleDragUpdate : null,
        onVerticalDragEnd: !isHorizontal ? _handleDragEnd : null,
        onHorizontalDragUpdate: isHorizontal ? _handleDragUpdate : null,
        onHorizontalDragEnd: isHorizontal ? _handleDragEnd : null,
        child: titleContent,
      );
    }

    // 将 child 的构建和包裹逻辑提取出来
    Widget buildChild() {
      final content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titleBar != null) titleBar,
          if (isHorizontal)
            Expanded(child: widget.child)
          else
            Flexible(
              fit: isChildScrollable && widget.maxHeight != null ? FlexFit.tight : FlexFit.loose,
              child: widget.child,
            ),
        ],
      );

      // 如果 child 本身是可滚动的，就用 NotificationListener 包裹它
        if (isChildScrollable) {
        // 使用 ClampingScrollPhysics 可以获得更统一、无光晕的体验
        final scrollableChild = ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(
            physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
          ),
          child: content,
        );
        return NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: scrollableChild,
        );
      }
      // 否则，返回原始内容（将由外部的 GestureDetector 处理）
      return content;
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
              child: buildChild(),
            ),
          ),
        )
      ),
    );

    // 创建一个单独的图片 Widget
    Widget? imageWidget;
    if (widget.imgPath != null) {
      imageWidget = Positioned(
        // 使用新的参数进行定位
        left: widget.imageOffset.dx,
        top: widget.imageOffset.dy,
        child: Image.asset(
          widget.imgPath!,
          width: widget.imageSize,
          height: widget.imageSize,
          fit: BoxFit.cover,
        ),
      );
    }

    // 使用一个新的 Stack 来组合面板和图片
    final mainLayout = Stack(
      // 关键！允许子组件绘制到 Stack 边界之外
      clipBehavior: Clip.none,
      children: [
        // 底层是白色面板
        sheetContent,
        // 顶层是图片（如果存在）
        if (imageWidget != null && widget.direction == SheetDirection.bottom) imageWidget,
      ],
    );

    final animatedLayout = AnimatedPadding(
      padding: widget.direction == SheetDirection.bottom
          ? EdgeInsets.only(bottom: math.max(0, viewInsets.bottom))
          : EdgeInsets.zero,
      duration: kThemeAnimationDuration,
      curve: Curves.easeOut,
      child: mainLayout,
    );

    // 使用 GestureDetector 包裹整个内容以捕获拖动手势
    return GestureDetector(
    // 当子组件是可滚动时，不处理这里的拖动，交由 NotificationListener
      onVerticalDragUpdate: !isChildScrollable && !isHorizontal ? _handleDragUpdate : null,
      onVerticalDragEnd: !isChildScrollable && !isHorizontal ? _handleDragEnd : null,
      onHorizontalDragUpdate: isHorizontal ? _handleDragUpdate : null,
      onHorizontalDragEnd: isHorizontal ? _handleDragEnd : null,
      onTap: () {
        // 轻触内容区域时也尝试收起键盘，避免遮挡
        FocusScope.of(context).unfocus();
      },
      // 使用 Transform.translate 来根据拖动偏移量移动 Widget
      child: Transform.translate(
        offset: _dragOffset,
        child: animatedLayout,
      ),
    );
  }
}
