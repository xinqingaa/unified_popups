// lib/src/widgets/popup_layout.dart
// import 'package:flutter/material.dart';
// import '../models/popup_config.dart';
// import '../models/popup_enums.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.config.anchorKey != null) {
      // 在下一帧计算位置，确保 anchor widget 已经渲染
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateAnchorPosition();
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 遮盖层
        if (widget.config.showBarrier)
          GestureDetector(
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

        // 内容层
        _buildPopupContent(),
      ],
    );
  }

  Widget _buildPopupContent() {
    Widget content = Material(
      color: Colors.transparent,
      child: _buildAnimatedChild(widget.config.child),
    );

    if (widget.config.anchorKey != null) {
      if (_anchorPosition == null || _anchorSize == null) {
        // 在计算出位置前，先不显示内容，避免闪烁
        return const SizedBox.shrink();
      }
      return Positioned(
        top: _anchorPosition!.dy + _anchorSize!.height + widget.config.anchorOffset.dy,
        left: _anchorPosition!.dx + widget.config.anchorOffset.dx,
        child: content,
      );
    } else {
      // 先创建对齐后的内容
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
    switch (widget.config.animation) {
      case PopupAnimation.fade:
        return FadeTransition(opacity: widget.animation, child: child);
      case PopupAnimation.slideUp:
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(widget.animation),
          child: child,
        );
      case PopupAnimation.slideDown:
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(widget.animation),
          child: child,
        );
      case PopupAnimation.slideLeft:
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(widget.animation),
          child: child,
        );
      case PopupAnimation.slideRight:
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(widget.animation),
          child: child,
        );
      case PopupAnimation.none:
      return child;
    }
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
