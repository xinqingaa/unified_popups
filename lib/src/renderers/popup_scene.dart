import 'package:flutter/material.dart';

import '../configs/confirm_config.dart';
import '../configs/loading_config.dart';
import '../configs/popup_animation_config.dart';
import '../configs/popup_position.dart';
import '../configs/popup_visual_config.dart';
import '../configs/toast_config.dart';
import '../controller/popup_dismiss_reason.dart';
import '../controller/popup_entry_snapshot.dart';
import '../controller/popup_entry_state.dart';
import '../runtime/popup_runtime.dart';
import 'loading_renderer.dart';
import 'confirm_renderer.dart';
import 'toast_renderer.dart';

/// Default declaration scene used by the global host.
///
/// Non-modal toasts share positional lanes. Modal entries keep their global
/// order below the transient toast layer.
class PopupScene extends StatelessWidget {
  const PopupScene({
    required this.runtime,
    required this.entries,
    super.key,
  });

  final PopupRuntime runtime;
  final List<PopupEntrySnapshot> entries;

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
          if (!laneIds.contains(entry.id))
            _AnimatedPopupEntry(
              key: ValueKey<String>(entry.id),
              runtime: runtime,
              entry: entry,
              fullScreen: true,
            ),
        if (laneToasts.isNotEmpty)
          _ToastLanes(runtime: runtime, entries: laneToasts),
      ],
    );
  }
}

class _ToastLanes extends StatelessWidget {
  const _ToastLanes({required this.runtime, required this.entries});

  final PopupRuntime runtime;
  final List<PopupEntrySnapshot> entries;

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
                      _AnimatedPopupEntry(
                        key: ValueKey<String>(entry.id),
                        runtime: runtime,
                        entry: entry,
                        fullScreen: false,
                      ),
                ],
              ),
            ),
      ],
    );
  }
}

class _AnimatedPopupEntry extends StatefulWidget {
  const _AnimatedPopupEntry({
    required this.runtime,
    required this.entry,
    required this.fullScreen,
    super.key,
  });

  final PopupRuntime runtime;
  final PopupEntrySnapshot entry;
  final bool fullScreen;

  @override
  State<_AnimatedPopupEntry> createState() => _AnimatedPopupEntryState();
}

class _AnimatedPopupEntryState extends State<_AnimatedPopupEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  FocusNode? _entryFocus;
  FocusNode? _previousFocus;

  PopupVisualConfig get _visual => widget.entry.config! as PopupVisualConfig;

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
    Widget content = _content(widget.entry.config!);
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

  Widget _content(Object config) => switch (config) {
        ToastConfig() => ToastRenderer(config: config),
        LoadingConfig() => LoadingRenderer(config: config),
        ConfirmConfig() => ConfirmRenderer(
            runtime: widget.runtime,
            entryId: widget.entry.id,
            config: config,
          ),
        _ => const SizedBox.shrink(),
      };

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

Alignment _alignment(PopupPosition position) => switch (position) {
      PopupPosition.top => Alignment.topCenter,
      PopupPosition.center => Alignment.center,
      PopupPosition.bottom => Alignment.bottomCenter,
      PopupPosition.left => Alignment.centerLeft,
      PopupPosition.right => Alignment.centerRight,
    };
