import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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

  /// 是否显示拖拽指示器（顶部横条）
  final bool showDragHandle;
  final Color? dragHandleColor;
  final bool adjustForKeyboard;

  /// 拖动关闭策略，默认整块可拖关。
  final SheetDragDismissMode dragDismissMode;
  final ValueListenable<SheetDragDismissMode>? dragDismissModeListenable;

  const SheetWidget({
    super.key,
    this.title,
    this.titleWidget,
    required this.child,
    this.direction = SheetDirection.bottom,
    this.showCloseButton = false,
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
    this.showDragHandle = true,
    this.dragHandleColor,
    this.adjustForKeyboard = true,
    this.dragDismissMode = SheetDragDismissMode.fullBody,
    this.dragDismissModeListenable,
  });

  @override
  State<SheetWidget> createState() => _SheetWidgetState();
}

class _SheetWidgetState extends State<SheetWidget> {
  Offset _dragOffset = Offset.zero;
  static const double _dismissThreshold = 75.0;
  static const double _dragHandleBottomGap = 7.0;
  static const double _dragHandleHitPadding = 8.0;
  static const double _dragHandleWidth = 40.0;
  static const double _dragHandleHeight = 4.0;
  static const double _dragHandleRadius = 3.0;

  bool _isDraggingSheet = false;
  late SheetDragDismissMode _effectiveDragDismissMode;

  bool get _isHorizontal =>
      widget.direction == SheetDirection.left ||
      widget.direction == SheetDirection.right;

  bool get _isVerticalSheet =>
      widget.direction == SheetDirection.top ||
      widget.direction == SheetDirection.bottom;

  bool get _useFullBodyDrag =>
      _effectiveDragDismissMode == SheetDragDismissMode.fullBody &&
      _isVerticalSheet;

  bool get _useContentAtTopDrag =>
      _effectiveDragDismissMode == SheetDragDismissMode.contentWhenAtTop &&
      _isVerticalSheet;

  @override
  void initState() {
    super.initState();
    _effectiveDragDismissMode =
        widget.dragDismissModeListenable?.value ?? widget.dragDismissMode;
    widget.dragDismissModeListenable
        ?.addListener(_handleDragDismissModeChanged);
  }

  @override
  void didUpdateWidget(covariant SheetWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(
      oldWidget.dragDismissModeListenable,
      widget.dragDismissModeListenable,
    )) {
      oldWidget.dragDismissModeListenable
          ?.removeListener(_handleDragDismissModeChanged);
      widget.dragDismissModeListenable
          ?.addListener(_handleDragDismissModeChanged);
    }
    final nextMode =
        widget.dragDismissModeListenable?.value ?? widget.dragDismissMode;
    if (_effectiveDragDismissMode != nextMode) {
      _setEffectiveDragDismissMode(nextMode);
    }
  }

  @override
  void dispose() {
    widget.dragDismissModeListenable
        ?.removeListener(_handleDragDismissModeChanged);
    super.dispose();
  }

  void _handleDragDismissModeChanged() {
    final nextMode =
        widget.dragDismissModeListenable?.value ?? widget.dragDismissMode;
    if (_effectiveDragDismissMode == nextMode) return;
    _setEffectiveDragDismissMode(nextMode);
  }

  void _setEffectiveDragDismissMode(SheetDragDismissMode nextMode) {
    setState(() {
      _effectiveDragDismissMode = nextMode;
      _dragOffset = Offset.zero;
      _isDraggingSheet = false;
    });
  }

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

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      final newOffset = _dragOffset + details.delta;
      _updateDragOffset(newOffset);
    });
  }

  void _updateDragOffset(Offset newOffset) {
    switch (widget.direction) {
      case SheetDirection.bottom:
        _dragOffset = Offset(0, newOffset.dy.clamp(0.0, double.infinity));
        break;
      case SheetDirection.top:
        _dragOffset =
            Offset(0, newOffset.dy.clamp(double.negativeInfinity, 0.0));
        break;
      case SheetDirection.left:
        _dragOffset =
            Offset(newOffset.dx.clamp(double.negativeInfinity, 0.0), 0);
        break;
      case SheetDirection.right:
        _dragOffset = Offset(newOffset.dx.clamp(0.0, double.infinity), 0);
        break;
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    bool shouldDismiss = false;
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
      FocusScope.of(context).unfocus();
      widget.onClose?.call();
    } else {
      setState(() {
        _dragOffset = Offset.zero;
      });
    }
    _isDraggingSheet = false;
  }

  bool _isAtScrollDismissEdge(ScrollMetrics metrics) {
    const tolerance = 0.5;
    switch (widget.direction) {
      case SheetDirection.bottom:
        return metrics.pixels <= metrics.minScrollExtent + tolerance;
      case SheetDirection.top:
        return metrics.pixels >= metrics.maxScrollExtent - tolerance;
      case SheetDirection.left:
      case SheetDirection.right:
        return false;
    }
  }

  bool _isOverscrollInDismissDirection(double overscroll) {
    switch (widget.direction) {
      case SheetDirection.bottom:
        return overscroll < 0;
      case SheetDirection.top:
        return overscroll > 0;
      case SheetDirection.left:
      case SheetDirection.right:
        return false;
    }
  }

  void _applySheetDragDelta(double delta) {
    if (delta == 0) return;
    setState(() {
      _updateDragOffset(_dragOffset + Offset(0, delta));
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!_useContentAtTopDrag) {
      return false;
    }
    if (notification.metrics.axis != Axis.vertical || notification.depth != 0) {
      return false;
    }

    if (notification is ScrollEndNotification) {
      if (_isDraggingSheet) {
        _handleDragEnd(DragEndDetails(
          velocity: notification.dragDetails?.velocity ?? Velocity.zero,
        ));
      }
      return false;
    }

    if (notification is OverscrollNotification) {
      if (notification.dragDetails == null) {
        return false;
      }
      if (!_isAtScrollDismissEdge(notification.metrics)) {
        return false;
      }
      if (!_isOverscrollInDismissDirection(notification.overscroll)) {
        return false;
      }

      _isDraggingSheet = true;
      _applySheetDragDelta(-notification.overscroll);
      return true;
    }

    if (notification is ScrollUpdateNotification) {
      final scrollDelta = notification.scrollDelta;
      if (_isDraggingSheet &&
          notification.dragDetails != null &&
          scrollDelta != null &&
          scrollDelta != 0) {
        _applySheetDragDelta(-scrollDelta);
        if (_dragOffset.dy <= 0) {
          setState(() {
            _dragOffset = Offset.zero;
            _isDraggingSheet = false;
          });
        }
      }
      return _isDraggingSheet;
    }

    return false;
  }

  Widget _wrapChromeDragTarget({
    required Widget child,
    required bool vertical,
  }) {
    if (vertical) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleDragEnd,
        child: child,
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    const defaultBackgroundColor = Colors.white;
    final defaultBoxShadow = [
      const BoxShadow(blurRadius: 10, color: Colors.black12, spreadRadius: 2)
    ];
    const defaultPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 10);
    const defaultTitlePadding = EdgeInsets.symmetric(vertical: 12);
    final defaultTitleStyle = Theme.of(context)
        .textTheme
        .titleLarge
        ?.copyWith(fontWeight: FontWeight.bold);
    const defaultTitleAlign = TextAlign.center;

    final bool isChildScrollable = widget.child is ListView ||
        widget.child is GridView ||
        widget.child is CustomScrollView ||
        widget.child is SingleChildScrollView;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final expandChild =
        widget.maxHeight != null && (isChildScrollable || _useContentAtTopDrag);

    Widget? titleBar;
    if (widget.title != null ||
        widget.titleWidget != null ||
        widget.showCloseButton) {
      final titleContent = Padding(
        padding: widget.titlePadding ?? defaultTitlePadding,
        child: Stack(
          children: [
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
            if (widget.showCloseButton &&
                widget.direction == SheetDirection.bottom)
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
      titleBar = _wrapChromeDragTarget(
        vertical: !_isHorizontal,
        child: titleContent,
      );
    }

    Widget buildDragHandle() {
      final bar = Center(
        child: Container(
          margin: const EdgeInsets.only(bottom: _dragHandleBottomGap),
          width: _dragHandleWidth,
          height: _dragHandleHeight,
          decoration: BoxDecoration(
            color: widget.dragHandleColor ??
                Theme.of(context).bottomSheetTheme.dragHandleColor ??
                const Color(0xFF333338),
            borderRadius: BorderRadius.circular(_dragHandleRadius),
          ),
        ),
      );
      if (_isVerticalSheet) {
        return _wrapChromeDragTarget(
          vertical: true,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: _dragHandleHitPadding),
            child: bar,
          ),
        );
      }
      return bar;
    }

    Widget buildChild() {
      final content = Column(
        mainAxisSize: expandChild ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showDragHandle) buildDragHandle(),
          if (titleBar != null) titleBar,
          if (_isHorizontal)
            Expanded(child: widget.child)
          else
            Flexible(
              fit: expandChild ? FlexFit.tight : FlexFit.loose,
              child: widget.child,
            ),
        ],
      );

      if (_useContentAtTopDrag) {
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
          ),
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: content,
          ),
        );
      }
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
        ),
      ),
    );

    Widget? imageWidget;
    if (widget.imgPath != null) {
      imageWidget = Positioned(
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

    final mainLayout = Stack(
      clipBehavior: Clip.none,
      children: [
        sheetContent,
        if (imageWidget != null && widget.direction == SheetDirection.bottom)
          imageWidget,
      ],
    );

    final animatedLayout = AnimatedPadding(
      padding:
          widget.direction == SheetDirection.bottom && widget.adjustForKeyboard
              ? EdgeInsets.only(bottom: math.max(0, viewInsets.bottom))
              : EdgeInsets.zero,
      duration: kThemeAnimationDuration,
      curve: Curves.easeOut,
      child: mainLayout,
    );

    return GestureDetector(
      onVerticalDragUpdate: _useFullBodyDrag ? _handleDragUpdate : null,
      onVerticalDragEnd: _useFullBodyDrag ? _handleDragEnd : null,
      onHorizontalDragUpdate: _isHorizontal ? _handleDragUpdate : null,
      onHorizontalDragEnd: _isHorizontal ? _handleDragEnd : null,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Transform.translate(
        offset: _dragOffset,
        child: animatedLayout,
      ),
    );
  }
}
