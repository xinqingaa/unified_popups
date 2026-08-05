import 'package:flutter/material.dart';

import '../configs/drop_menu_config.dart';
import '../configs/popup_animation_config.dart';
import '../configs/popup_barrier_config.dart';
import '../configs/popup_position.dart';
import '../configs/popup_visual_config.dart';
import '../configs/sheet_config.dart';
import '../configs/toast_config.dart';
import '../controller/popup_dismiss_reason.dart';
import '../controller/popup_entry_snapshot.dart';
import '../controller/popup_entry_state.dart';
import '../runtime/popup_runtime.dart';
import 'popup_entry_animation.dart';
import 'popup_renderer_delegate.dart';

/// Default declaration scene used by the global host.
///
/// Non-modal toasts share positional lanes. Modal entries keep their global
/// order below the transient toast layer.
class PopupScene extends StatelessWidget {
  const PopupScene({
    required this.runtime,
    required this.entries,
    this.registry,
    super.key,
  });

  final PopupRuntime runtime;
  final List<PopupEntrySnapshot> entries;
  final PopupRendererRegistry? registry;

  PopupRendererRegistry get _registry => registry ?? _defaultRegistry;

  static final PopupRendererRegistry _defaultRegistry =
      PopupRendererRegistry.builtIn();

  @override
  Widget build(BuildContext context) {
    final laneToasts = entries.where((entry) {
      final config = entry.config;
      return config is ToastConfig && !config.barrier.visible;
    }).toList(growable: false);
    final laneIds = laneToasts.map((entry) => entry.id).toSet();

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        for (final entry in entries)
          if (!laneIds.contains(entry.id)) _buildEntry(entry, fullScreen: true),
        if (laneToasts.isNotEmpty)
          _ToastLanes(
            runtime: runtime,
            entries: laneToasts,
            registry: _registry,
          ),
      ],
    );
  }

  Widget _buildEntry(
    PopupEntrySnapshot entry, {
    required bool fullScreen,
  }) {
    final config = entry.config;
    final delegate = config == null ? null : _registry.resolve(config);
    final Widget child;
    if (delegate == null) {
      child = _UnsupportedPopupEntry(
        key: ValueKey<String>(entry.id),
        runtime: runtime,
        entry: entry,
      );
    } else {
      child = _AnimatedPopupEntry(
        key: ValueKey<String>(entry.id),
        runtime: runtime,
        entry: entry,
        renderer: delegate,
        fullScreen: fullScreen,
      );
    }
    // Always wrap so pause/resume only flips flags — never remounts State
    // (FlowSheet internal Navigator / form fields must survive).
    return Offstage(
      offstage: entry.paused,
      child: IgnorePointer(
        ignoring: entry.paused,
        child: child,
      ),
    );
  }
}

class _ToastLanes extends StatelessWidget {
  const _ToastLanes({
    required this.runtime,
    required this.entries,
    required this.registry,
  });

  final PopupRuntime runtime;
  final List<PopupEntrySnapshot> entries;
  final PopupRendererRegistry registry;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        for (final position in PopupPosition.values)
          if (entries.any(
            (entry) => (entry.config! as ToastConfig).position == position,
          ))
            Align(
              alignment: _alignment(position),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final entry in entries)
                    if ((entry.config! as ToastConfig).position == position)
                      _buildEntry(entry),
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildEntry(PopupEntrySnapshot entry) {
    final config = entry.config!;
    final delegate = registry.resolve(config);
    final Widget child;
    if (delegate == null) {
      child = _UnsupportedPopupEntry(
        key: ValueKey<String>(entry.id),
        runtime: runtime,
        entry: entry,
      );
    } else {
      child = _AnimatedPopupEntry(
        key: ValueKey<String>(entry.id),
        runtime: runtime,
        entry: entry,
        renderer: delegate,
        fullScreen: false,
      );
    }
    return Offstage(
      offstage: entry.paused,
      child: IgnorePointer(
        ignoring: entry.paused,
        child: child,
      ),
    );
  }
}

class _AnimatedPopupEntry extends StatefulWidget {
  const _AnimatedPopupEntry({
    required this.runtime,
    required this.entry,
    required this.renderer,
    required this.fullScreen,
    super.key,
  });

  final PopupRuntime runtime;
  final PopupEntrySnapshot entry;
  final PopupRendererDelegate renderer;
  final bool fullScreen;

  @override
  State<_AnimatedPopupEntry> createState() => _AnimatedPopupEntryState();
}

class _AnimatedPopupEntryState extends State<_AnimatedPopupEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  FocusNode? _entryFocus;
  FocusNode? _previousFocus;

  PopupVisualConfig get _visual =>
      widget.renderer.visualConfig(widget.entry.config!);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _visual.animationConfig.duration,
      reverseDuration: _visual.animationConfig.reverseDuration,
    );
    if (widget.fullScreen && _visual.barrier.visible) {
      _previousFocus = FocusManager.instance.primaryFocus;
      _entryFocus = FocusNode(debugLabel: 'Popup ${widget.entry.id}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _entryFocus?.requestFocus();
      });
    }
    _syncState(initial: true);
  }

  @override
  void didUpdateWidget(_AnimatedPopupEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    final animation = _visual.animationConfig;
    _controller
      ..duration = animation.duration
      ..reverseDuration = animation.reverseDuration;
    if (oldWidget.entry.state != widget.entry.state) _syncState();
    if (!oldWidget.entry.paused && widget.entry.paused) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  void _syncState({bool initial = false}) {
    if (_visual.animationConfig.type == PopupAnimationType.none) {
      final entering = widget.entry.state == PopupEntryState.entering;
      final visible = widget.entry.state == PopupEntryState.visible;
      final exiting = widget.entry.state == PopupEntryState.exiting ||
          widget.entry.state == PopupEntryState.dismissRequested;
      // visible 必须保持 1：barrier 走 FadeTransition(opacity: animation)，
      // 若在 markPresented 后打成 0，会出现「内容在、蒙层消失」。
      _controller.value = (entering || visible) ? 1 : 0;
      if (entering || exiting) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (entering) {
            widget.runtime.controller.markPresented(widget.entry.id);
          } else {
            widget.runtime.controller.markDisposed(widget.entry.id);
          }
        });
      }
      return;
    }
    switch (widget.entry.state) {
      case PopupEntryState.entering:
        _controller
            .animateTo(
          1,
          duration: _visual.animationConfig.duration,
          curve: _visual.animationConfig.curve,
        )
            .whenCompleteOrCancel(() {
          if (mounted) {
            widget.runtime.controller.markPresented(widget.entry.id);
          }
        });
      case PopupEntryState.visible:
        _controller.value = 1;
      case PopupEntryState.dismissRequested:
      case PopupEntryState.exiting:
        _controller
            .animateBack(
          0,
          duration: _visual.animationConfig.reverseDuration ??
              _visual.animationConfig.duration,
          curve: _visual.animationConfig.reverseCurve,
        )
            .whenCompleteOrCancel(() {
          if (mounted) {
            widget.runtime.controller.markDisposed(widget.entry.id);
          }
        });
      case PopupEntryState.created:
      case PopupEntryState.pendingHost:
      case PopupEntryState.queued:
      case PopupEntryState.disposed:
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _entryFocus?.dispose();
    final previousFocus = _previousFocus;
    if (previousFocus?.context != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (previousFocus?.context != null) previousFocus?.requestFocus();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animationConfig = _visual.animationConfig;
    final animation = _controller;
    Widget content = widget.renderer.build(
      context,
      widget.runtime,
      widget.entry,
      _EntryMotionController(
        controller: _controller,
        animationConfig: animationConfig,
        onDismiss: (reason) => widget.runtime.controller.dismissEntry(
          widget.entry.id,
          reason: reason,
        ),
      ),
    );
    final entryFocus = _entryFocus;
    if (entryFocus != null) {
      content = Focus(focusNode: entryFocus, child: content);
    }
    content = PopupEntryAnimation(
      animation: animation,
      fadeContentOnly: widget.entry.config is DropMenuConfig &&
          animationConfig.type == PopupAnimationType.fade,
      child: content,
    );
    content = _transition(
      content,
      animation,
      animationConfig.type,
      config: widget.entry.config,
    );
    if (!widget.fullScreen) return content;

    final barrier = _visual.barrier;
    // Sheet: outer SafeArea shrinks the Align viewport (v1 popup_layout).
    // Bottom sheets pad top only so a full-height panel clears the status bar
    // without pushing a short panel's chrome away from the panel top edge.
    // Inner SheetRenderer still pads only the docked edge (e.g. home indicator).
    Widget aligned = Align(
      alignment: _alignment(_visual.position),
      child: content,
    );
    final config = widget.entry.config;
    if (config is SheetConfigBase && config.resolvedUseSafeArea) {
      aligned = _visual.position == PopupPosition.bottom
          ? SafeArea(
              bottom: false,
              left: false,
              right: false,
              child: aligned,
            )
          : SafeArea(child: aligned);
    }
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (barrier.visible)
          Positioned.fill(
            left: barrier.insets.left,
            top: barrier.insets.top,
            right: barrier.insets.right,
            bottom: barrier.insets.bottom,
            child: FadeTransition(
              opacity: animation,
              child: _buildBarrier(barrier),
            ),
          ),
        aligned,
      ],
    );
  }

  Widget _buildBarrier(PopupBarrierConfig barrier) {
    void dismiss() {
      widget.runtime.controller.dismissEntry(
        widget.entry.id,
        reason: PopupDismissReason.barrier,
      );
    }

    final modal = ModalBarrier(
      color: barrier.color,
      dismissible: barrier.dismissible,
      semanticsLabel: barrier.semanticsLabel,
      onDismiss: barrier.dismissible ? dismiss : null,
    );

    if (!barrier.dismissible || !barrier.dismissOnDrag) {
      return modal;
    }

    // 空白处拖动/滑动关闭：手势由 barrier 消费，不转发下层滚动。
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerMove: (event) {
        if (event.delta.distanceSquared < 0.25) return;
        dismiss();
      },
      child: modal,
    );
  }

  Widget _transition(
    Widget child,
    Animation<double> animation,
    PopupAnimationType type, {
    Object? config,
  }) {
    // DropMenu fades only its interior labels/icons. Wrapping BackdropFilter in
    // FadeTransition makes blur sample an OpacityLayer buffer until opacity
    // hits 1.0, which snaps the glass on the last frame.
    if (config is DropMenuConfig && type == PopupAnimationType.fade) {
      return child;
    }
    return switch (type) {
      PopupAnimationType.none => child,
      PopupAnimationType.fade => FadeTransition(
          opacity: animation,
          child: child,
        ),
      PopupAnimationType.scale => ScaleTransition(
          scale: animation,
          child: child,
        ),
      PopupAnimationType.slideDown => SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, -_visual.animationConfig.slideOffset),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      PopupAnimationType.slideUp => SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, _visual.animationConfig.slideOffset),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      PopupAnimationType.slideLeft => SlideTransition(
          position: Tween<Offset>(
            begin: Offset(-_visual.animationConfig.slideOffset, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      PopupAnimationType.slideRight => SlideTransition(
          position: Tween<Offset>(
            begin: Offset(_visual.animationConfig.slideOffset, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
    };
  }
}

final class _EntryMotionController implements PopupMotionController {
  const _EntryMotionController({
    required AnimationController controller,
    required PopupAnimationConfig animationConfig,
    required void Function(PopupDismissReason reason) onDismiss,
  })  : _controller = controller,
        _animationConfig = animationConfig,
        _onDismiss = onDismiss;

  final AnimationController _controller;
  final PopupAnimationConfig _animationConfig;
  final void Function(PopupDismissReason reason) _onDismiss;

  @override
  double get value => _controller.value;

  @override
  set value(double value) => _controller.value = value.clamp(0.0, 1.0);

  @override
  Future<void> animateToVisible() async {
    await _controller.animateTo(
      1,
      duration: _animationConfig.duration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dismiss({PopupDismissReason reason = PopupDismissReason.manual}) {
    _onDismiss(reason);
  }
}

class _UnsupportedPopupEntry extends StatefulWidget {
  const _UnsupportedPopupEntry({
    required this.runtime,
    required this.entry,
    super.key,
  });

  final PopupRuntime runtime;
  final PopupEntrySnapshot entry;

  @override
  State<_UnsupportedPopupEntry> createState() => _UnsupportedPopupEntryState();
}

class _UnsupportedPopupEntryState extends State<_UnsupportedPopupEntry> {
  @override
  void initState() {
    super.initState();
    assert(() {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: FlutterError(
            'No PopupRendererDelegate supports '
            '${widget.entry.config.runtimeType}.',
          ),
          library: 'unified_popups',
          context: ErrorDescription('while resolving a popup renderer'),
        ),
      );
      return true;
    }());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.runtime.controller.dismissEntry(
        widget.entry.id,
        reason: PopupDismissReason.rendererUnavailable,
      );
      // No renderer exists to acknowledge the end of an exit animation.
      widget.runtime.controller.markDisposed(widget.entry.id);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Alignment _alignment(PopupPosition position) => switch (position) {
      PopupPosition.top => Alignment.topCenter,
      PopupPosition.center => Alignment.center,
      PopupPosition.bottom => Alignment.bottomCenter,
      PopupPosition.left => Alignment.centerLeft,
      PopupPosition.right => Alignment.centerRight,
    };
