import 'package:flutter/widgets.dart';

import '../controller/popup_entry_snapshot.dart';
import '../controller/popup_entry_state.dart';
import '../runtime/popup_runtime.dart';

typedef PopupEntryBuilder = Widget Function(
  BuildContext context,
  PopupEntrySnapshot entry,
);

/// Declaratively renders entries above a fixed application child.
class PopupHost extends StatefulWidget {
  const PopupHost({
    required this.runtime,
    required this.child,
    required this.entryBuilder,
    super.key,
  });

  final PopupRuntime runtime;
  final Widget child;
  final PopupEntryBuilder entryBuilder;

  @override
  State<PopupHost> createState() => _PopupHostState();
}

class _PopupHostState extends State<PopupHost> {
  bool _attached = false;

  @override
  void initState() {
    super.initState();
    _attached = widget.runtime.attachHost(this);
  }

  @override
  void didUpdateWidget(PopupHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(widget.runtime, oldWidget.runtime)) return;
    if (_attached) oldWidget.runtime.detachHost(this);
    _attached = widget.runtime.attachHost(this);
  }

  @override
  void dispose() {
    if (_attached) widget.runtime.detachHost(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_attached) return widget.child;
    return ListenableBuilder(
      listenable: widget.runtime.controller,
      child: widget.child,
      builder: (context, child) {
        final mounted = widget.runtime.controller.entries
            .where((entry) => entry.state.isMounted)
            .toList(growable: false);
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            child!,
            for (final entry in mounted)
              _PopupHostEntry(
                key: ValueKey<String>(entry.id),
                runtime: widget.runtime,
                snapshot: entry,
                builder: widget.entryBuilder,
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
