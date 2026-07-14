import 'package:flutter/material.dart';

import '../configs/popup_animation_config.dart';
import '../configs/popup_position.dart';
import '../configs/popup_visual_config.dart';
import '../configs/toast_config.dart';
import '../controller/popup_dismiss_reason.dart';
import '../controller/popup_entry_snapshot.dart';
import '../controller/popup_entry_state.dart';
import '../runtime/popup_runtime.dart';
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
    if (delegate == null) {
      return _UnsupportedPopupEntry(
        key: ValueKey<String>(entry.id),
        runtime: runtime,
        entry: entry,
      );
    }
    return _AnimatedPopupEntry(
      key: ValueKey<String>(entry.id),
      runtime: runtime,
      entry: entry,
      renderer: delegate,
      fullScreen: fullScreen,
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
    if (delegate == null) {
      return _UnsupportedPopupEntry(
        key: ValueKey<String>(entry.id),
        runtime: runtime,
        entry: entry,
      );
    }
    return _AnimatedPopupEntry(
      key: ValueKey<String>(entry.id),
      runtime: runtime,
      entry: entry,
      renderer: delegate,
      fullScreen: false,
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
  }

  void _syncState({bool initial = false}) {
    if (_visual.animationConfig.type == PopupAnimationType.none) {
      final entering = widget.entry.state == PopupEntryState.entering;
      final exiting = widget.entry.state == PopupEntryState.exiting ||
          widget.entry.state == PopupEntryState.dismissRequested;
      _controller.value = entering ? 1 : 0;
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
        _controller.forward(from: initial ? 0 : null).whenCompleteOrCancel(() {
          if (mounted) {
            widget.runtime.controller.markPresented(widget.entry.id);
          }
        });
      case PopupEntryState.visible:
        _controller.value = 1;
      case PopupEntryState.dismissRequested:
      case PopupEntryState.exiting:
        _controller.reverse().whenCompleteOrCancel(() {
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
    final animation = CurvedAnimation(
      parent: _controller,
      curve: animationConfig.curve,
      reverseCurve: animationConfig.reverseCurve,
    );
    Widget content = widget.renderer.build(
      context,
      widget.runtime,
      widget.entry,
    );
    final entryFocus = _entryFocus;
    if (entryFocus != null) {
      content = Focus(focusNode: entryFocus, child: content);
    }
    content = _transition(content, animation, animationConfig.type);
    if (!widget.fullScreen) return content;

    final barrier = _visual.barrier;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (barrier.visible)
          FadeTransition(
            opacity: animation,
            child: ModalBarrier(
              color: barrier.color,
              dismissible: barrier.dismissible,
              semanticsLabel: barrier.semanticsLabel,
              onDismiss: barrier.dismissible
                  ? () => widget.runtime.controller.dismissEntry(
                        widget.entry.id,
                        reason: PopupDismissReason.barrier,
                      )
                  : null,
            ),
          ),
        Align(alignment: _alignment(_visual.position), child: content),
      ],
    );
  }

  Widget _transition(
    Widget child,
    Animation<double> animation,
    PopupAnimationType type,
  ) {
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
            begin: const Offset(0, -0.15),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      PopupAnimationType.slideUp => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      PopupAnimationType.slideLeft => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.15, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      PopupAnimationType.slideRight => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.15, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
    };
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
