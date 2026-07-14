import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../configs/sheet_config.dart';
import '../configs/sheet_types.dart';
import '../controller/popup_dismiss_reason.dart';
import '../controller/popup_handle.dart';
import '../utils/sheet_dimension.dart';
import 'popup_renderer_delegate.dart';

abstract final class SheetRendererKeys {
  static const panel = ValueKey<String>('unified_popups.sheet.panel');
  static const dragHandle =
      ValueKey<String>('unified_popups.sheet.drag_handle');
}

class SheetRenderer extends StatefulWidget {
  const SheetRenderer({
    required this.config,
    required this.handle,
    required this.motion,
    super.key,
  });

  final SheetConfigBase config;
  final PopupHandleBase handle;
  final PopupMotionController motion;

  @override
  State<SheetRenderer> createState() => _SheetRendererState();
}

class _SheetRendererState extends State<SheetRenderer> {
  static const _handleLongSide = 40.0;
  static const _handleShortSide = 4.0;

  Widget? _businessContent;
  late SheetDragDismissMode _dragMode;
  double _dragExtent = 1;

  bool get _horizontal =>
      widget.config.direction == SheetDirection.left ||
      widget.config.direction == SheetDirection.right;

  @override
  void initState() {
    super.initState();
    _dragMode =
        widget.config.drag.modeListenable?.value ?? widget.config.drag.mode;
    widget.config.drag.modeListenable?.addListener(_onDragModeChanged);
  }

  @override
  void didUpdateWidget(SheetRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.config.drag.modeListenable,
        widget.config.drag.modeListenable)) {
      oldWidget.config.drag.modeListenable?.removeListener(_onDragModeChanged);
      widget.config.drag.modeListenable?.addListener(_onDragModeChanged);
    }
    if (!identical(oldWidget.config, widget.config) ||
        !identical(oldWidget.handle, widget.handle)) {
      _businessContent = null;
    }
    _dragMode =
        widget.config.drag.modeListenable?.value ?? widget.config.drag.mode;
  }

  @override
  void dispose() {
    widget.config.drag.modeListenable?.removeListener(_onDragModeChanged);
    super.dispose();
  }

  void _onDragModeChanged() {
    final next =
        widget.config.drag.modeListenable?.value ?? widget.config.drag.mode;
    if (_dragMode == next || !mounted) return;
    setState(() => _dragMode = next);
  }

  double _directedDelta(Offset delta) => switch (widget.config.direction) {
        SheetDirection.top => -delta.dy,
        SheetDirection.bottom => delta.dy,
        SheetDirection.left => -delta.dx,
        SheetDirection.right => delta.dx,
      };

  double _directedVelocity(Velocity velocity) =>
      _directedDelta(velocity.pixelsPerSecond);

  void _dragUpdate(DragUpdateDetails details) {
    final directed = _directedDelta(details.delta);
    widget.motion.value = widget.motion.value - directed / _dragExtent;
  }

  void _dragEnd(DragEndDetails details) {
    final dismissedProgress = 1 - widget.motion.value;
    final shouldDismiss =
        dismissedProgress >= widget.config.drag.dismissProgressThreshold ||
            _directedVelocity(details.velocity) >=
                widget.config.drag.dismissVelocity;
    if (shouldDismiss) {
      FocusManager.instance.primaryFocus?.unfocus();
      widget.motion.dismiss(reason: PopupDismissReason.drag);
    } else {
      unawaited(widget.motion.animateToVisible());
    }
  }

  void _dragCancel() => unawaited(widget.motion.animateToVisible());

  Widget _dragTarget(Widget child) {
    if (_horizontal) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: _dragUpdate,
        onHorizontalDragEnd: _dragEnd,
        onHorizontalDragCancel: _dragCancel,
        child: child,
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _dragUpdate,
      onVerticalDragEnd: _dragEnd,
      onVerticalDragCancel: _dragCancel,
      child: child,
    );
  }

  bool _atDismissEdge(ScrollMetrics metrics) {
    const tolerance = 0.5;
    return switch (widget.config.direction) {
      SheetDirection.bottom ||
      SheetDirection.right =>
        metrics.pixels <= metrics.minScrollExtent + tolerance,
      SheetDirection.top ||
      SheetDirection.left =>
        metrics.pixels >= metrics.maxScrollExtent - tolerance,
    };
  }

  bool _onScroll(ScrollNotification notification) {
    if (_dragMode != SheetDragDismissMode.contentWhenAtTop ||
        notification.depth != 0 ||
        notification.metrics.axis !=
            (_horizontal ? Axis.horizontal : Axis.vertical)) {
      return false;
    }
    if (notification is OverscrollNotification &&
        notification.dragDetails != null &&
        _atDismissEdge(notification.metrics)) {
      final physicalDelta = _horizontal
          ? Offset(-notification.overscroll, 0)
          : Offset(0, -notification.overscroll);
      if (_directedDelta(physicalDelta) > 0 || widget.motion.value < 1) {
        _dragUpdate(
          DragUpdateDetails(
            delta: physicalDelta,
            globalPosition: Offset.zero,
          ),
        );
        return true;
      }
    }
    if (notification is ScrollEndNotification && widget.motion.value < 1) {
      _dragEnd(
        DragEndDetails(
          velocity: notification.dragDetails?.velocity ?? Velocity.zero,
        ),
      );
    }
    return false;
  }

  double? _resolve(SheetDimension? dimension, double fullSize) {
    return switch (dimension) {
      null => null,
      Pixel(:final value) => value,
      Fraction(:final value) => value * fullSize,
    };
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final screen = MediaQuery.sizeOf(context);
    final width = _resolve(config.size.width, screen.width) ??
        (_horizontal ? screen.width * 0.75 : screen.width);
    final height = _resolve(config.size.height, screen.height) ??
        (_horizontal ? screen.height : null);
    final maxWidth =
        _resolve(config.size.maxWidth, screen.width) ?? screen.width;
    final maxHeight =
        _resolve(config.size.maxHeight, screen.height) ?? screen.height;
    _dragExtent = math.max(
      1,
      _horizontal
          ? math.min(width, maxWidth)
          : math.min(height ?? maxHeight, maxHeight),
    );
    _businessContent ??= config.buildContent(context, widget.handle);

    Widget body = _buildChrome(context, _businessContent!);
    if (_dragMode == SheetDragDismissMode.contentWhenAtTop) {
      body = NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: body,
      );
    }

    Widget panel = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: config.style.backgroundColor ??
                Theme.of(context).colorScheme.surface,
            borderRadius: config.style.borderRadius ?? _defaultRadius(),
            boxShadow: config.style.boxShadow ??
                const <BoxShadow>[
                  BoxShadow(
                      blurRadius: 10, color: Colors.black12, spreadRadius: 2),
                ],
          ),
          child: Material(
            color: Colors.transparent,
            child: config.resolvedUseSafeArea
                ? SafeArea(
                    // Only pad the docked edge. Full SafeArea would apply the
                    // opposite inset (e.g. status-bar top on a bottom sheet).
                    top: config.direction == SheetDirection.top,
                    bottom: config.direction == SheetDirection.bottom,
                    left: config.direction == SheetDirection.left,
                    right: config.direction == SheetDirection.right,
                    child: body,
                  )
                : body,
          ),
        ),
      ),
    );

    if (config.style.imagePath case final imagePath?) {
      panel = Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          panel,
          if (config.direction == SheetDirection.bottom)
            Positioned(
              left: config.style.imageOffset.dx,
              top: config.style.imageOffset.dy,
              child: Image.asset(
                imagePath,
                width: config.style.imageSize,
                height: config.style.imageSize,
              ),
            ),
        ],
      );
    }

    if (_dragMode == SheetDragDismissMode.fullBody) panel = _dragTarget(panel);
    panel = Padding(padding: _dockPadding(), child: panel);
    if (config.direction == SheetDirection.bottom &&
        config.keyboard.adjustForKeyboard) {
      panel = AnimatedPadding(
        duration: config.keyboard.animationDuration,
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: math.max(0, MediaQuery.viewInsetsOf(context).bottom),
        ),
        child: panel,
      );
    }
    return RepaintBoundary(key: SheetRendererKeys.panel, child: panel);
  }

  Widget _buildChrome(BuildContext context, Widget child) {
    final config = widget.config;
    final header = config.header;
    final hasHeader = header.title != null ||
        header.titleWidget != null ||
        header.showCloseButton;
    final expand = _horizontal ||
        config.size.height != null ||
        config.size.maxHeight != null;
    return Padding(
      padding: config.style.padding,
      child: Column(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (config.drag.showHandle) _dragTarget(_buildHandle(context)),
          if (hasHeader) _dragTarget(_buildHeader(context)),
          if (expand) Expanded(child: child) else Flexible(child: child),
        ],
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    final color = widget.config.drag.handleColor ??
        Theme.of(context).bottomSheetTheme.dragHandleColor ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: SizedBox(
          key: SheetRendererKeys.dragHandle,
          width: _horizontal ? _handleShortSide : _handleLongSide,
          height: _horizontal ? _handleLongSide : _handleShortSide,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final header = widget.config.header;
    return Padding(
      padding: header.padding,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          header.titleWidget ??
              (header.title == null
                  ? const SizedBox.shrink()
                  : Text(
                      header.title!,
                      style: header.titleStyle ??
                          Theme.of(context).textTheme.titleLarge,
                      textAlign: header.titleAlign,
                    )),
          if (header.showCloseButton)
            PositionedDirectional(
              end: 0,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: widget.handle.dismiss,
                icon: const Icon(Icons.close),
              ),
            ),
        ],
      ),
    );
  }

  BorderRadius _defaultRadius() {
    const radius = Radius.circular(20);
    return switch (widget.config.direction) {
      SheetDirection.top =>
        const BorderRadius.only(bottomLeft: radius, bottomRight: radius),
      SheetDirection.bottom =>
        const BorderRadius.only(topLeft: radius, topRight: radius),
      SheetDirection.left =>
        const BorderRadius.only(topRight: radius, bottomRight: radius),
      SheetDirection.right =>
        const BorderRadius.only(topLeft: radius, bottomLeft: radius),
    };
  }

  EdgeInsets _dockPadding() {
    final dock = widget.config.dock;
    if (!dock.enabled) return EdgeInsets.zero;
    return switch (widget.config.direction) {
      SheetDirection.top => EdgeInsets.only(top: dock.edgeGap),
      SheetDirection.bottom => EdgeInsets.only(bottom: dock.edgeGap),
      SheetDirection.left => EdgeInsets.only(left: dock.edgeGap),
      SheetDirection.right => EdgeInsets.only(right: dock.edgeGap),
    };
  }
}
