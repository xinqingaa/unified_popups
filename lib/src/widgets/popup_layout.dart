part of '../core/popup_manager.dart';

class _PopupLayout extends StatefulWidget {
  final PopupConfig config;
  final Animation<double> animation;
  final VoidCallback onDismiss;

  const _PopupLayout({
    required this.config,
    required this.animation,
    required this.onDismiss,
  });

  @override
  State<_PopupLayout> createState() => _PopupLayoutState();
}

class _PopupLayoutState extends State<_PopupLayout> {
  Offset? _anchorPosition;
  Size? _anchorSize;
  // 用于获取菜单内容的实际大小
  final GlobalKey _contentKey = GlobalKey();
  // 智能计算后的位置
  Offset? _smartPosition;
  // 原始计算的初始位置（未调整前）
  Offset? _originalPosition;
  // 屏幕尺寸
  Size? _screenSize;
  // 最小边距
  static const double _minMargin = 8.0;

  @override
  void initState() {
    super.initState();
    if (widget.config.anchorKey != null) {
      // 在下一帧计算位置，确保 anchor widget 已经渲染
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateAnchorPosition();
        // 对于菜单类型，需要等待内容渲染后再计算智能位置
        if (widget.config.type == PopupType.menu) {
          _tryCalculateSmartPosition();
        }
      });
    }
  }

  // 尝试计算智能位置，如果内容还未渲染则延迟重试
  void _tryCalculateSmartPosition({int retryCount = 0}) {
    if (_calculateSmartPosition()) {
      // 计算成功，不需要重试
      return;
    }
    // 内容还未渲染，延迟重试（最多重试5次，避免无限循环）
    if (retryCount < 5 && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tryCalculateSmartPosition(retryCount: retryCount + 1);
        }
      });
    }
  }

  void _calculateAnchorPosition() {
    final key = widget.config.anchorKey;
    if (key?.currentContext != null) {
      final renderBox = key!.currentContext!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      if (mounted) {
        setState(() {
          _anchorPosition = position;
          _anchorSize = size;
        });
      }
    }
  }

  // 计算智能位置，返回 true 表示计算成功，false 表示需要重试
  bool _calculateSmartPosition() {
    if (_anchorPosition == null || _anchorSize == null || _screenSize == null) {
      return false;
    }
    
    // 获取菜单内容的实际大小
    final context = _contentKey.currentContext;
    if (context == null) {
      return false;
    }
    
    final contentRenderBox = context.findRenderObject() as RenderBox?;
    if (contentRenderBox == null || !contentRenderBox.hasSize) {
      return false;
    }
    
    final contentSize = contentRenderBox.size;
    
    // 计算初始位置（保持左对齐）
    double left = _anchorPosition!.dx + widget.config.anchorOffset.dx;
    double top = _anchorPosition!.dy + _anchorSize!.height + widget.config.anchorOffset.dy;
    
    // 保存原始位置，用于后续动画方向计算
    _originalPosition = Offset(left, top);
    
    // 检查右边缘是否溢出
    if (left + contentSize.width > _screenSize!.width - _minMargin) {
      // 右边缘会溢出，调整位置
      // 优先尝试：将菜单向右移动到不溢出（保持左对齐）
      final maxLeft = _screenSize!.width - contentSize.width - _minMargin;
      if (maxLeft >= _minMargin) {
        // 有足够空间，调整到不溢出的位置
        left = maxLeft;
      } else {
        // 空间不足，保持最小边距
        left = _minMargin;
      }
    } else if (left < _minMargin) {
      // 左边缘太靠左，调整到最小边距
      left = _minMargin;
    }
    
    // 检查底部是否溢出
    if (top + contentSize.height > _screenSize!.height - _minMargin) {
      // 底部会溢出，向上调整
      // 优先尝试：将菜单向上移动到不溢出
      final maxTop = _screenSize!.height - contentSize.height - _minMargin;
      if (maxTop >= _minMargin) {
        top = maxTop;
      } else {
        // 空间不足，保持在顶部最小边距
        top = _minMargin;
      }
    } else if (top < _minMargin) {
      // 顶部太靠上，调整到最小边距
      top = _minMargin;
    }
    
    if (mounted) {
      setState(() {
        _smartPosition = Offset(left, top);
      });
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕尺寸
    final mediaQuery = MediaQuery.of(context);
    _screenSize = mediaQuery.size;
    
    final bool dockToEdge = widget.config.dockToEdge;
    final bool allowDock = dockToEdge && widget.config.position != PopupPosition.top;
    final double edgeGap = allowDock ? widget.config.edgeGap : 0;

    final bool reserveBottom = allowDock && widget.config.position == PopupPosition.bottom;
    final bool reserveLeft = allowDock && widget.config.position == PopupPosition.left;
    final bool reserveRight = allowDock && widget.config.position == PopupPosition.right;

    return Stack(
      children: [
        // 遮盖层
        if (widget.config.showBarrier)
          Positioned.fill(
            top: 0,
            bottom: reserveBottom ? edgeGap : 0,
            left: reserveLeft ? edgeGap : 0,
            right: reserveRight ? edgeGap : 0,
            child: GestureDetector(
              onTap: () {
                if (widget.config.barrierDismissible) {
                  widget.onDismiss();
                }
              },
              child: FadeTransition(
                opacity: widget.animation,
                child: Container(
                  color: widget.config.barrierColor,
                ),
              ),
            ),
          ),

        // 内容层
        _buildPopupContent(),
      ],
    );
  }

  Widget _buildPopupContent() {
    final config = widget.config;
    final bool dockToEdge = config.dockToEdge && config.position != PopupPosition.top;
    final double edgeGap = dockToEdge ? config.edgeGap : 0;

    Widget content = Material(
      color: Colors.transparent,
      child: _buildAnimatedChild(widget.config.child),
    );

    EdgeInsets edgePadding = EdgeInsets.zero;
    if (dockToEdge) {
      switch (config.position) {
        case PopupPosition.bottom:
          edgePadding = EdgeInsets.only(bottom: edgeGap);
          break;
        case PopupPosition.left:
          edgePadding = EdgeInsets.only(left: edgeGap);
          break;
        case PopupPosition.right:
          edgePadding = EdgeInsets.only(right: edgeGap);
          break;
        case PopupPosition.top:
        case PopupPosition.center:
          break;
      }
    }

    if (edgePadding != EdgeInsets.zero) {
      content = Padding(
        padding: edgePadding,
        child: content,
      );
    }

    if (widget.config.anchorKey != null) {
      if (_anchorPosition == null || _anchorSize == null) {
        // 在计算出位置前，先不显示内容，避免闪烁
        return const SizedBox.shrink();
      }
      
      // 给内容添加 GlobalKey 用于获取实际大小（仅在锚定模式下）
      final keyedContent = widget.config.type == PopupType.menu
          ? KeyedSubtree(key: _contentKey, child: content)
          : content;
      
      // 使用智能计算的位置，如果没有则使用原始位置
      final position = _smartPosition ?? Offset(
        _anchorPosition!.dx + widget.config.anchorOffset.dx,
        _anchorPosition!.dy + _anchorSize!.height + widget.config.anchorOffset.dy,
      );
      
      return Positioned(
        top: position.dy,
        left: position.dx,
        child: keyedContent,
      );
    } else {
      // 对于loading类型且center位置，使用稳定的屏幕尺寸来计算位置
      // 避免键盘弹出/收起时位置跳动
      if (widget.config.type == PopupType.loading && 
          widget.config.position == PopupPosition.center) {
        // 使用Builder来获取MediaQuery，确保能获取到最新的context
        return Builder(
          builder: (context) {
            final mediaQuery = MediaQuery.of(context);
            // 计算完整的屏幕尺寸（不受键盘影响）
            // 完整屏幕高度 = size.height + viewInsets.bottom
            // 完整屏幕宽度 = size.width + viewInsets.horizontal
            final fullScreenHeight = mediaQuery.size.height + mediaQuery.viewInsets.bottom;
            final fullScreenWidth = mediaQuery.size.width + mediaQuery.viewInsets.horizontal;
            
            // 创建一个不受键盘影响的MediaQuery
            // 使用copyWith来创建一个新的MediaQuery，其中size是完整的屏幕尺寸，viewInsets为0
            final stableMediaQuery = mediaQuery.copyWith(
              size: Size(fullScreenWidth, fullScreenHeight),
              viewInsets: EdgeInsets.zero,
            );
            
            // 在这个稳定的MediaQuery context内使用Center
            // 这样center位置就会基于稳定的屏幕尺寸，不受键盘影响
            return MediaQuery(
              data: stableMediaQuery,
              child: Center(
                child: content,
              ),
            );
          },
        );
      }
      
      // 其他情况使用标准的Align
      Widget alignedContent = Align(
        alignment: _getAlignmentFromPosition(widget.config.position),
        child: content,
      );

      if (widget.config.useSafeArea) {
        // 如果是底部弹窗，我们不希望 SafeArea 在底部产生间距，
        // 因为弹窗内容本身就在底部。但我们仍然需要顶部的安全区来避开状态栏。
        if (widget.config.position == PopupPosition.bottom) {
          return SafeArea(
            bottom: false,
            right: false,
            left: false,
            child: alignedContent,
          );
        } else {
          // 对于所有其他方向的弹窗，使用标准的 SafeArea
          return SafeArea(child: alignedContent);
        }
      } else {
        return alignedContent;
      }
    }
  }

  Widget _buildAnimatedChild(Widget child) {
    // 计算动态动画偏移（仅在锚定模式且有智能位置调整时）
    Offset? dynamicOffset;
    if (widget.config.anchorKey != null && 
        _smartPosition != null && 
        _originalPosition != null) {
      // 计算最终位置相对于原始位置的偏移
      final offsetDelta = _smartPosition! - _originalPosition!;
      dynamicOffset = offsetDelta;
    }
    late final Widget animatedChild;

    switch (widget.config.animation) {
      case PopupAnimation.fade:
        animatedChild = FadeTransition(opacity: widget.animation, child: child);
        break;
      case PopupAnimation.slideUp:
        // 如果有动态偏移，根据垂直方向调整
        Offset beginOffset = const Offset(0, 1);
        if (dynamicOffset != null && dynamicOffset.dy < 0) {
          // 最终位置在原始位置上方，从上方滑入
          beginOffset = const Offset(0, -1);
        }
        animatedChild = SlideTransition(
          position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(widget.animation),
          child: child,
        );
        break;
      case PopupAnimation.slideDown:
        // 如果有动态偏移，根据垂直方向调整
        Offset beginOffset = const Offset(0, -1);
        if (dynamicOffset != null && dynamicOffset.dy > 0) {
          // 最终位置在原始位置下方，从下方滑入
          beginOffset = const Offset(0, 1);
        }
        animatedChild = SlideTransition(
          position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(widget.animation),
          child: child,
        );
        break;
      case PopupAnimation.slideLeft:
        // 如果有动态偏移，根据水平方向调整
        Offset beginOffset = const Offset(-1, 0);
        if (dynamicOffset != null && dynamicOffset.dx > 0) {
          // 最终位置在原始位置右侧，从右侧滑入
          beginOffset = const Offset(1, 0);
        }
        animatedChild = SlideTransition(
          position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(widget.animation),
          child: child,
        );
        break;
      case PopupAnimation.slideRight:
        // 如果有动态偏移，根据水平方向调整
        Offset beginOffset = const Offset(1, 0);
        if (dynamicOffset != null && dynamicOffset.dx < 0) {
          // 最终位置在原始位置左侧，从左侧滑入
          beginOffset = const Offset(-1, 0);
        }
        animatedChild = SlideTransition(
          position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(widget.animation),
          child: child,
        );
        break;
      case PopupAnimation.none:
        animatedChild = child;
        break;
    }

    if (widget.config.anchorKey != null && widget.config.clipDuringAnimation) {
      return ClipRect(child: animatedChild);
    }

    return animatedChild;
  }

  Alignment _getAlignmentFromPosition(PopupPosition position) {
    switch (position) {
      case PopupPosition.top:
        return Alignment.topCenter;
      case PopupPosition.bottom:
        return Alignment.bottomCenter;
      case PopupPosition.left:
        return Alignment.centerLeft;
      case PopupPosition.right:
        return Alignment.centerRight;
      case PopupPosition.center:
      return Alignment.center;
    }
  }
}
