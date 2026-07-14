import 'package:flutter/widgets.dart';

import '../controller/popup_entry_snapshot.dart';
import '../controller/popup_entry_state.dart';
import '../runtime/popup_runtime.dart';

typedef PopupEntryBuilder = Widget Function(
  BuildContext context,
  PopupEntrySnapshot entry,
);

typedef PopupSceneBuilder = Widget Function(
  BuildContext context,
  PopupRuntime runtime,
  List<PopupEntrySnapshot> entries,
);

/// Declaratively renders entries above a fixed application child.
class PopupHost extends StatefulWidget {
  const PopupHost({
    required this.runtime,
    required this.child,
    this.entryBuilder,
    this.sceneBuilder,
    super.key,
  }) : assert(entryBuilder != null || sceneBuilder != null);

  final PopupRuntime runtime;
  final Widget child;
  final PopupEntryBuilder? entryBuilder;
  final PopupSceneBuilder? sceneBuilder;

  @override
  State<PopupHost> createState() => _PopupHostState();
}

class _PopupHostState extends State<PopupHost> {
  bool _attached = false;
  bool _overlayWasBuilt = false;
  late final OverlayEntry _popupOverlayEntry;

  @override
  void initState() {
    super.initState();
    _popupOverlayEntry = OverlayEntry(builder: _buildPopupOverlay);
    _attached = widget.runtime.attachHost(this);
  }

  @override
  void didUpdateWidget(PopupHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(widget.runtime, oldWidget.runtime)) return;
    if (_attached) oldWidget.runtime.detachHost(this);
    _attached = widget.runtime.attachHost(this);
    _popupOverlayEntry.markNeedsBuild();
  }

  @override
  void dispose() {
    // `mounted` describes the entry widget, not whether the entry still
    // belongs to an Overlay. During tree finalization it can already be false
    // while the entry is still registered with OverlayState.
    if (_overlayWasBuilt) _popupOverlayEntry.remove();
    _popupOverlayEntry.dispose();
    if (_attached) widget.runtime.detachHost(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Once inserted, keep the private Overlay alive even if a later runtime
    // attachment is rejected. OverlayEntry instances cannot be reinserted
    // before their previous Overlay has released them.
    if (!_attached && !_overlayWasBuilt) return widget.child;
    _overlayWasBuilt = true;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        Overlay(
          clipBehavior: Clip.none,
          initialEntries: <OverlayEntry>[_popupOverlayEntry],
        ),
      ],
    );
  }

  Widget _buildPopupOverlay(BuildContext context) {
    if (!_attached) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: widget.runtime.controller,
      builder: (context, _) {
        final mounted = widget.runtime.controller.entries
            .where((entry) => entry.state.isMounted)
            .toList(growable: false);
        final sceneBuilder = widget.sceneBuilder;
        if (sceneBuilder != null) {
          return sceneBuilder(context, widget.runtime, mounted);
        }
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            for (final entry in mounted)
              _PopupHostEntry(
                key: ValueKey<String>(entry.id),
                runtime: widget.runtime,
                snapshot: entry,
                builder: widget.entryBuilder!,
              ),
          ],
        );
      },
    );
  }
}

class _PopupHostEntry extends StatefulWidget {
  const _PopupHostEntry({
    required this.runtime,
    required this.snapshot,
    required this.builder,
    super.key,
  });

  final PopupRuntime runtime;
  final PopupEntrySnapshot snapshot;
  final PopupEntryBuilder builder;

  @override
  State<_PopupHostEntry> createState() => _PopupHostEntryState();
}

class _PopupHostEntryState extends State<_PopupHostEntry> {
  @override
  void initState() {
    super.initState();
    _scheduleLifecycle();
  }

  @override
  void didUpdateWidget(_PopupHostEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot.state != widget.snapshot.state) {
      _scheduleLifecycle();
    }
  }

  void _scheduleLifecycle() {
    final id = widget.snapshot.id;
    final state = widget.snapshot.state;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (state == PopupEntryState.entering) {
        widget.runtime.controller.markPresented(id);
      } else if (state == PopupEntryState.exiting ||
          state == PopupEntryState.dismissRequested) {
        widget.runtime.controller.markDisposed(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.snapshot);
  }
}
