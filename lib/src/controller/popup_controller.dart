import 'dart:async';

import 'package:flutter/foundation.dart';

import '../configs/popup_back_policy.dart';
import '../configs/popup_channel.dart';
import '../configs/popup_conflict_policy.dart';
import '../configs/popup_owner_policy.dart';
import '../configs/popup_route_policy.dart';
import 'popup_controller_handle.dart';
import 'popup_dismiss_reason.dart';
import 'popup_entry_record.dart';
import 'popup_entry_request.dart';
import 'popup_entry_snapshot.dart';
import 'popup_entry_state.dart';
import 'popup_handle.dart';
import 'popup_lifecycle_callbacks.dart';
import 'popup_open_result.dart';
import 'popup_outcome.dart';

typedef _PopupRecord<T, C> = PopupEntryRecord<T, C>;

/// Owns popup lifecycle state without depending on an Overlay or BuildContext.
class PopupController extends ChangeNotifier {
  PopupController({
    String runtimeEpoch = 'runtime',
    this.maxPendingHostEntries = 100,
  })  : assert(maxPendingHostEntries > 0),
        _runtimeEpoch = runtimeEpoch;

  final String _runtimeEpoch;
  final int maxPendingHostEntries;
  final List<_PopupRecord<dynamic, dynamic>> _entries =
      <_PopupRecord<dynamic, dynamic>>[];
  final Map<String, _PopupRecord<dynamic, dynamic>> _keyed =
      <String, _PopupRecord<dynamic, dynamic>>{};

  int _nextId = 0;
  bool _hostAttached = false;
  bool _everAttached = false;
  bool _shutdown = false;
  bool _changeNotifierDisposed = false;
  int _mutationDepth = 0;
  bool _notificationPending = false;

  bool get isHostAttached => _hostAttached;

  bool get isShutdown => _shutdown;

  List<PopupEntrySnapshot> get entries => List<PopupEntrySnapshot>.unmodifiable(
        _entries.map((entry) => entry.snapshot),
      );

  /// Registers a logical entry and applies its key conflict policy.
  PopupOpenResult<T> open<T, C>(PopupEntryRequest<T, C> request) {
    final key = request.key;
    final existing = key == null ? null : _keyed[key];
    if (existing != null && !existing.state.isTerminal) {
      // Keys are global to a channel. Replacing or toggling does not require
      // matching generic types because the old and new handles remain
      // independent. Updating in place does require an exact typed contract.
      if (existing.channel != request.channel) {
        assert(
          false,
          'Popup key "$key" is already used by ${existing.channel}.',
        );
        return PopupOpenResult<T>.rejected();
      }

      switch (request.conflictPolicy) {
        case PopupConflictPolicy.rejectNew:
        case PopupConflictPolicy.stack:
          return PopupOpenResult<T>.rejected();
        case PopupConflictPolicy.toggle:
          _requestClose(existing, PopupDismissReason.toggled);
          return PopupOpenResult<T>.toggledClosed();
        case PopupConflictPolicy.updateExisting:
          final compatible =
              existing.resultType == T && existing.configType == C;
          if (!compatible ||
              !existing.isActive ||
              !existing.updatable ||
              !request.updatable) {
            return PopupOpenResult<T>.rejected();
          }
          final typed = existing as _PopupRecord<T, C>;
          if (!_updateRecord(typed, request)) {
            return PopupOpenResult<T>.rejected();
          }
          return PopupOpenResult<T>.updated(typed.handle);
        case PopupConflictPolicy.replaceExisting:
          final replacement = _createRecord(request, forceQueued: true);
          _keyed[key!] = replacement;
          _requestClose(existing, PopupDismissReason.replaced);
          existing.dismissed.then((_) {
            if (replacement.isActive) _activate(replacement);
          });
          return PopupOpenResult<T>.opened(replacement.handle);
      }
    }

    final record = _createRecord(request);
    if (key != null && !record.state.isTerminal) _keyed[key] = record;
    return PopupOpenResult<T>.opened(record.handle);
  }

  _PopupRecord<T, C> _createRecord<T, C>(
    PopupEntryRequest<T, C> request, {
    bool forceQueued = false,
  }) {
    final record = _PopupRecord<T, C>(
      id: '$_runtimeEpoch-${++_nextId}',
      request: request,
      invokeCallback: _invoke,
    );
    record.handle = ControllerPopupHandle<T, C>(
      record: record,
      complete: (value) => _complete(record, value),
      dismiss: () => _dismiss(record),
      update: (config) => _updateConfig(record, config),
      pause: () => pauseEntry(record.id),
      resume: () => resumeEntry(record.id),
    );
    _entries.add(record);

    if (_shutdown) {
      _requestClose(record, PopupDismissReason.runtimeDisposed);
    } else if (_everAttached && !_hostAttached) {
      _requestClose(record, PopupDismissReason.hostUnavailable);
    } else if (!_hostAttached) {
      _transition(record, PopupEntryState.pendingHost);
      _enforcePendingHostCapacity(record);
    } else if (forceQueued || request.initiallyQueued) {
      _transition(record, PopupEntryState.queued);
    } else {
      _transition(record, PopupEntryState.entering);
    }
    _notifySafely();
    return record;
  }

  bool _updateRecord<T, C>(
    _PopupRecord<T, C> record,
    PopupEntryRequest<T, C> request,
  ) {
    if (!record.isActive) return false;
    final update = record.resolveUpdate?.call(record.config, request.config);
    if (record.resolveUpdate != null && update == null) return false;
    record
      ..config = request.config
      ..resolveUpdate = request.resolveUpdate;
    _applyUpdate(
      record,
      update ??
          PopupEntryUpdate<T>(
            tags: request.tags,
            routePolicy: request.routePolicy,
            backPolicy: request.backPolicy,
            ownership: request.ownership,
            lifetime: request.lifetime,
            lifecycle: request.lifecycle ?? PopupLifecycleCallbacks<T>(),
          ),
    );
    record.generation++;
    _restartLifetime(record);
    _notifySafely();
    return true;
  }

  bool _updateConfig<T, C>(_PopupRecord<T, C> record, C config) {
    if (!record.isActive || !record.updatable) return false;
    final update = record.resolveUpdate?.call(record.config, config);
    if (record.resolveUpdate != null && update == null) return false;
    record.config = config;
    if (update != null) _applyUpdate(record, update);
    record.generation++;
    _restartLifetime(record);
    _notifySafely();
    return true;
  }

  void _applyUpdate<T, C>(
    _PopupRecord<T, C> record,
    PopupEntryUpdate<T> update,
  ) {
    record
      ..tags = Set<String>.unmodifiable(update.tags)
      ..routePolicy = update.routePolicy
      ..backPolicy = update.backPolicy
      ..ownership = update.ownership
      ..lifetime = update.lifetime
      ..lifecycle = update.lifecycle;
  }

  void _enforcePendingHostCapacity(
    _PopupRecord<dynamic, dynamic> newest,
  ) {
    final pending = _entries
        .where((entry) => entry.state == PopupEntryState.pendingHost)
        .toList(growable: false);
    if (pending.length <= maxPendingHostEntries) return;
    final overflow = pending.firstWhere(
      (entry) =>
          entry.channel == PopupChannel.toast ||
          entry.channel == PopupChannel.loading,
      orElse: () => pending.first,
    );
    // Prefer dropping an old transient entry, but never reject the new entry
    // solely because all older entries are modal.
    _requestClose(
      identical(overflow, newest) && pending.length > 1
          ? pending.first
          : overflow,
      PopupDismissReason.queueOverflow,
    );
  }

  /// Attaches the declaration host and releases entries created before frame 1.
  void attachHost() {
    if (_shutdown || _hostAttached) return;
    _hostAttached = true;
    _everAttached = true;
    for (final entry in List<_PopupRecord<dynamic, dynamic>>.of(_entries)) {
      if (entry.state == PopupEntryState.pendingHost) {
        if (entry.initiallyQueued) {
          _transition(entry, PopupEntryState.queued);
        } else {
          _transition(entry, PopupEntryState.entering);
        }
      }
    }
    _notifySafely();
  }

  /// Detaches the host and synchronously removes every remaining entry.
  void detachHost() {
    if (!_hostAttached) return;
    _mutate(() {
      _hostAttached = false;
      for (final entry
          in List<_PopupRecord<dynamic, dynamic>>.of(_entries).reversed) {
        if (entry.isActive) {
          _requestClose(entry, PopupDismissReason.hostDetached);
        }
        if (!entry.state.isTerminal) _disposeRecord(entry);
      }
      _notifySafely();
    });
  }

  /// Moves an entering entry to visible and starts its lifetime.
  void markPresented(String id) {
    final entry = _find(id);
    if (entry == null || entry.state != PopupEntryState.entering) return;
    _transition(entry, PopupEntryState.visible);
    _invoke(entry.lifecycle.onPresented, 'while reporting popup presentation');
    if (entry.state == PopupEntryState.visible) _startLifetime(entry);
    _notifySafely();
  }

  /// Releases a queued entry when its lane or conflict dependency has capacity.
  void releaseQueued(String id) {
    final entry = _find(id);
    if (entry == null || entry.state != PopupEntryState.queued) return;
    _activate(entry);
  }

  void _activate(_PopupRecord<dynamic, dynamic> entry) {
    if (!entry.isActive || entry.state != PopupEntryState.queued) return;
    if (!_hostAttached) {
      _requestClose(entry, PopupDismissReason.hostUnavailable);
      return;
    }
    _transition(entry, PopupEntryState.entering);
    _notifySafely();
  }

  /// Called by the host after the exit animation and widget removal complete.
  void markDisposed(String id) {
    final entry = _find(id);
    if (entry == null || entry.state.isTerminal || entry.isActive) return;
    _disposeRecord(entry);
    _notifySafely();
  }

  Future<void> _complete<T, C>(_PopupRecord<T, C> entry, T? value) {
    _requestClose(entry, PopupDismissReason.completed, value);
    return entry.dismissed;
  }

  Future<void> _dismiss(_PopupRecord<dynamic, dynamic> entry) {
    _requestClose(entry, PopupDismissReason.manual);
    return entry.dismissed;
  }

  void _requestClose(
    _PopupRecord<dynamic, dynamic> entry,
    PopupDismissReason reason, [
    Object? value,
  ]) =>
      _mutate(() => _requestCloseNow(entry, reason, value));

  void _requestCloseNow(
    _PopupRecord<dynamic, dynamic> entry,
    PopupDismissReason reason, [
    Object? value,
  ]) {
    if (!entry.isActive) return;

    final children = _entries.reversed.where((candidate) {
      return candidate.isActive &&
          candidate.ownership.policy == PopupOwnerPolicy.dismissWithParent &&
          candidate.ownership.parentEntryId == entry.id;
    }).toList(growable: false);
    for (final child in children) {
      _requestCloseNow(child, PopupDismissReason.parentDismissed);
    }

    entry.cancelLifetime();
    entry.paused = false;
    final needsVisualExit = entry.state == PopupEntryState.entering ||
        entry.state == PopupEntryState.visible;
    _transition(entry, PopupEntryState.dismissRequested);
    entry.commitReason(reason, value);
    if (entry.state.isTerminal) return;
    if (needsVisualExit) {
      _transition(entry, PopupEntryState.exiting);
    } else {
      _disposeRecord(entry);
    }
    _notifySafely();
  }

  void _disposeRecord(_PopupRecord<dynamic, dynamic> entry) {
    if (entry.state.isTerminal) return;
    entry.cancelLifetime();
    if (!entry.hasOutcome) {
      entry.commitUntypedOutcome(
        const PopupOutcome<dynamic>(reason: PopupDismissReason.manual),
      );
    }
    _transition(entry, PopupEntryState.disposed);
    _entries.remove(entry);
    if (entry.key case final key?) {
      if (identical(_keyed[key], entry)) _keyed.remove(key);
    }
    entry.commitDismissed();
  }

  void _restartLifetime(_PopupRecord<dynamic, dynamic> entry) {
    entry.cancelLifetime(invalidateGeneration: false);
    if (entry.state == PopupEntryState.visible) _startLifetime(entry);
  }

  void _startLifetime(_PopupRecord<dynamic, dynamic> entry) {
    entry.lifetimeBinding.start(entry.lifetime, (generation, reason) {
      if (_acceptLifetimeEvent(entry, generation)) {
        _requestClose(entry, reason);
      }
    });
  }

  bool _acceptLifetimeEvent(
    _PopupRecord<dynamic, dynamic> entry,
    int generation,
  ) {
    return entry.isActive &&
        !entry.paused &&
        entry.state == PopupEntryState.visible &&
        entry.generation == generation;
  }

  Future<void> dismissKey(String key) {
    final entry = _keyed[key];
    if (entry == null) return Future<void>.value();
    return _dismiss(entry);
  }

  Future<void> dismissEntry(
    String id, {
    PopupDismissReason reason = PopupDismissReason.manual,
  }) {
    final entry = _find(id);
    if (entry == null) return Future<void>.value();
    _requestClose(entry, reason);
    return entry.dismissed;
  }

  Future<void> completeEntry<T>(String id, [T? value]) {
    final entry = _find(id);
    if (entry == null || entry.resultType != T) return Future<void>.value();
    final typed = entry as _PopupRecord<T, dynamic>;
    _requestClose(typed, PopupDismissReason.completed, value);
    return typed.dismissed;
  }

  /// Returns the stable typed handle used by a renderer-owned builder.
  PopupHandle<T>? handleFor<T>(String id) {
    final entry = _find(id);
    if (entry == null || entry.resultType != T) return null;
    return (entry as _PopupRecord<T, dynamic>).handle;
  }

  PopupHandleBase? handleForEntry(String id) => _find(id)?.handle;

  /// Pauses the latest active, non-paused entry on [channel].
  ///
  /// Returns the handle, or `null` when nothing matched.
  PopupHandleBase? pauseLatest(PopupChannel channel) {
    for (final entry in _entries.reversed) {
      if (entry.channel != channel || !entry.isActive || entry.paused) {
        continue;
      }
      if (pauseEntry(entry.id)) return entry.handle;
    }
    return null;
  }

  /// Pauses a mounted active entry: keep state, hide paint/input, skip back
  /// and route auto-dismiss. Returns `false` if the entry cannot be paused.
  bool pauseEntry(String id) {
    final entry = _find(id);
    if (entry == null || !entry.isActive || entry.paused) return false;
    if (entry.state != PopupEntryState.entering &&
        entry.state != PopupEntryState.visible) {
      return false;
    }
    entry.paused = true;
    // Invalidate generation so in-flight `until` / timer callbacks cannot
    // dismiss the entry while it is paused.
    entry.cancelLifetime(invalidateGeneration: true);
    _notifySafely();
    return true;
  }

  /// Resumes a previously paused entry. Returns `false` if not paused/active.
  bool resumeEntry(String id) {
    final entry = _find(id);
    if (entry == null || !entry.isActive || !entry.paused) return false;
    entry.paused = false;
    if (entry.state == PopupEntryState.visible) _startLifetime(entry);
    _notifySafely();
    return true;
  }

  Future<int> dismissChannel(PopupChannel channel) async {
    final matches = _entries.reversed
        .where((entry) => entry.channel == channel && entry.isActive)
        .toList(growable: false);
    _mutate(() {
      for (final entry in matches) {
        _requestClose(entry, PopupDismissReason.manual);
      }
    });
    await Future.wait(matches.map((entry) => entry.dismissed));
    return matches.length;
  }

  Future<int> dismissTags(Set<String> tags) async {
    final matches = _entries.reversed
        .where((entry) => entry.isActive && entry.tags.any(tags.contains))
        .toList(growable: false);
    _mutate(() {
      for (final entry in matches) {
        _requestClose(entry, PopupDismissReason.manual);
      }
    });
    await Future.wait(matches.map((entry) => entry.dismissed));
    return matches.length;
  }

  Future<void> dismissAll() async {
    final matches = _entries.reversed.toList(growable: false);
    _mutate(() {
      for (final entry in matches) {
        if (entry.isActive) _requestClose(entry, PopupDismissReason.manual);
      }
    });
    await Future.wait(matches.map((entry) => entry.dismissed));
  }

  Future<bool> dismissTop() async {
    _PopupRecord<dynamic, dynamic>? entry;
    for (final candidate in _entries.reversed) {
      if (candidate.isActive) {
        entry = candidate;
        break;
      }
    }
    if (entry == null) return false;
    _requestClose(entry, PopupDismissReason.manual);
    await entry.dismissed;
    return true;
  }

  /// Applies back semantics from the visual top down.
  Future<bool> handleBack() async {
    for (final entry in _entries.reversed) {
      if (entry.state == PopupEntryState.exiting ||
          entry.state == PopupEntryState.dismissRequested) {
        return true;
      }
      if (!entry.isActive || entry.paused) continue;
      switch (entry.backPolicy) {
        case PopupBackPolicy.ignore:
          continue;
        case PopupBackPolicy.block:
          return true;
        case PopupBackPolicy.dismiss:
          _requestClose(entry, PopupDismissReason.back);
          return true;
        case PopupBackPolicy.delegate:
          final delegate = entry.onBack;
          if (delegate == null) continue;
          try {
            if (await delegate()) return true;
          } catch (error, stackTrace) {
            FlutterError.reportError(
              FlutterErrorDetails(
                exception: error,
                stack: stackTrace,
                library: 'unified_popups',
                context: ErrorDescription('while delegating popup back'),
              ),
            );
            return true;
          }
      }
    }
    return false;
  }

  /// Whether the current route must defer its system back action to popups.
  bool get interceptsSystemBack => _entries.any((entry) {
        if (entry.state == PopupEntryState.exiting ||
            entry.state == PopupEntryState.dismissRequested) {
          return true;
        }
        return entry.isActive &&
            !entry.paused &&
            entry.backPolicy != PopupBackPolicy.ignore;
      });

  /// Applies route ownership policies after the root route changes.
  void handleRouteChanged(Object? currentRouteToken) {
    _mutate(() {
      for (final entry in _entries.reversed.toList(growable: false)) {
        if (!entry.isActive || entry.paused) continue;
        final shouldDismiss = switch (entry.routePolicy) {
          PopupRoutePolicy.persist => false,
          PopupRoutePolicy.dismissOnAnyRouteChange => true,
          PopupRoutePolicy.dismissWhenOwnerRouteChanges =>
            entry.ownership.routeToken != null &&
                entry.ownership.routeToken != currentRouteToken,
        };
        if (shouldDismiss) {
          _requestClose(entry, PopupDismissReason.routeChanged);
        }
      }
    });
  }

  bool isVisibleKey(String key) {
    final entry = _keyed[key];
    if (entry == null || entry.paused) return false;
    final state = entry.state;
    return state == PopupEntryState.entering ||
        state == PopupEntryState.visible ||
        state == PopupEntryState.dismissRequested ||
        state == PopupEntryState.exiting;
  }

  bool isActiveKey(String key) => _keyed[key]?.isActive ?? false;

  bool hasChannel(PopupChannel channel) =>
      _entries.any((entry) => entry.channel == channel && entry.isActive);

  int countChannel(PopupChannel channel) => _entries
      .where((entry) => entry.channel == channel && entry.isActive)
      .length;

  Future<void> shutdown() async {
    if (_shutdown) return;
    _shutdown = true;
    final records = _entries.reversed.toList(growable: false);
    _mutate(() {
      for (final entry in records) {
        if (entry.isActive) {
          _requestClose(entry, PopupDismissReason.runtimeDisposed);
        }
        if (!entry.state.isTerminal) _disposeRecord(entry);
      }
      _notifySafely();
    });
    await Future.wait(records.map((entry) => entry.dismissed));
  }

  _PopupRecord<dynamic, dynamic>? _find(String id) {
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  void _transition(
    _PopupRecord<dynamic, dynamic> entry,
    PopupEntryState next,
  ) {
    assert(
      _isLegalTransition(entry.state, next),
      'Illegal popup transition: ${entry.state} -> $next (${entry.id}).',
    );
    entry.wasMounted = entry.wasMounted || entry.state.isMounted;
    entry.state = next;
    if (next == PopupEntryState.entering ||
        next == PopupEntryState.visible ||
        next == PopupEntryState.exiting) {
      entry.wasMounted = true;
    }
  }

  bool _isLegalTransition(PopupEntryState current, PopupEntryState next) {
    return switch (current) {
      PopupEntryState.created => next == PopupEntryState.pendingHost ||
          next == PopupEntryState.queued ||
          next == PopupEntryState.entering ||
          next == PopupEntryState.dismissRequested,
      PopupEntryState.pendingHost => next == PopupEntryState.queued ||
          next == PopupEntryState.entering ||
          next == PopupEntryState.dismissRequested,
      PopupEntryState.queued => next == PopupEntryState.entering ||
          next == PopupEntryState.dismissRequested,
      PopupEntryState.entering => next == PopupEntryState.visible ||
          next == PopupEntryState.dismissRequested,
      PopupEntryState.visible => next == PopupEntryState.dismissRequested,
      PopupEntryState.dismissRequested =>
        next == PopupEntryState.exiting || next == PopupEntryState.disposed,
      PopupEntryState.exiting => next == PopupEntryState.disposed,
      PopupEntryState.disposed => false,
    };
  }

  void _invoke(void Function()? callback, String context) {
    if (callback == null) return;
    try {
      callback();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'unified_popups',
          context: ErrorDescription(context),
        ),
      );
    }
  }

  void _notifySafely() {
    if (_changeNotifierDisposed) return;
    if (_mutationDepth > 0) {
      _notificationPending = true;
      return;
    }
    notifyListeners();
  }

  R _mutate<R>(R Function() mutation) {
    _mutationDepth++;
    try {
      return mutation();
    } finally {
      _mutationDepth--;
      if (_mutationDepth == 0 && _notificationPending) {
        _notificationPending = false;
        if (!_changeNotifierDisposed) notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    unawaited(shutdown());
    _changeNotifierDisposed = true;
    super.dispose();
  }
}
