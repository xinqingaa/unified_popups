// lib/src/widgets/loading_widget.dart
import 'package:flutter/material.dart';

class LoadingWidget extends StatefulWidget {
  final String? message;
  final Color? backgroundColor;
  final double? borderRadius;
  final Color? indicatorColor;
  final double? indicatorStrokeWidth;
  final TextStyle? textStyle;
  final Widget? customIndicator;
  final Duration rotationDuration;

  const LoadingWidget({
    super.key,
    this.message,
    this.backgroundColor,
    this.borderRadius,
    this.indicatorColor,
    this.indicatorStrokeWidth,
    this.textStyle,
    this.customIndicator,
    this.rotationDuration = const Duration(seconds: 1),
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.rotationDuration,
      vsync: this,
    );
    // 如果提供了自定义指示器，开始旋转动画
    if (widget.customIndicator != null) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(LoadingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果 rotationDuration 改变，更新动画控制器
    if (oldWidget.rotationDuration != widget.rotationDuration) {
      _controller.duration = widget.rotationDuration;
    }
    // 如果 customIndicator 从无到有或从有到无，更新动画状态
    if (oldWidget.customIndicator == null && widget.customIndicator != null) {
      _controller.repeat();
    } else if (oldWidget.customIndicator != null &&
        widget.customIndicator == null) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const defaultStyle = TextStyle(color: Colors.white, fontSize: 16);
    const defaultPadding = EdgeInsets.all(24.0);

    // 构建指示器 Widget
    Widget indicator;
    if (widget.customIndicator != null) {
      // 使用自定义指示器，并添加旋转动画
      indicator = RotationTransition(
        turns: _controller,
        child: widget.customIndicator!,
      );
    } else {
      // 使用默认的 CircularProgressIndicator
      indicator = CircularProgressIndicator(
        color: widget.indicatorColor ?? Colors.white,
        strokeWidth: widget.indicatorStrokeWidth ?? 2.0,
      );
    }

    // 构建内容
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        indicator,
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Flexible(
            child: Text(
              widget.message!,
              style: widget.textStyle ?? defaultStyle,
              maxLines: null,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );

    // 构建 Container
    Widget container = Container(
      padding: defaultPadding,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.black.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12.0),
      ),
      child: content,
    );

    // 当有 message 时（不管是 customIndicator 还是默认的），确保 Container 为正方形且自适应
    if (widget.message != null) {
      // 使用 LayoutBuilder 获取屏幕宽度，限制最大宽度为屏幕的 32%
      // 然后使用 AspectRatio 确保正方形
      container = LayoutBuilder(
        builder: (context, constraints) {
          // 计算最大宽度：屏幕宽度的 32%，但不超过 160
          final maxWidth = constraints.maxWidth.isInfinite
              ? 300.0
              : (constraints.maxWidth * 0.32).clamp(80.0, 160.0);
          
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxWidth, // 最大高度等于最大宽度，确保正方形
            ),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                padding: defaultPadding,
                decoration: BoxDecoration(
                  color: widget.backgroundColor ??
                      Colors.black.withValues(alpha: 0.80),
                  borderRadius:
                      BorderRadius.circular(widget.borderRadius ?? 12.0),
                ),
                child: content,
              ),
            ),
          );
        },
      );
    }

    return container;
  }
}
