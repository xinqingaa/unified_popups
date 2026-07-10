import 'dart:async';

import 'package:flutter/foundation.dart';

import '../configs/popup_back_policy.dart';
import '../configs/popup_channel.dart';
import '../configs/popup_conflict_policy.dart';
import '../configs/popup_owner_policy.dart';
import '../configs/popup_route_policy.dart';
import 'popup_dismiss_reason.dart';
import 'popup_entry_request.dart';
import 'popup_entry_snapshot.dart';
import 'popup_entry_state.dart';
import 'popup_handle.dart';
import 'popup_lifecycle_callbacks.dart';
import 'popup_lifetime.dart';
import 'popup_open_result.dart';
import 'popup_outcome.dart';
import 'popup_ownership.dart';

/// Owns popup lifecycle state without depending on an Overlay or BuildContext.
class PopupController extends ChangeNotifier {
  PopupController({String runtimeEpoch = 'runtime'})
      : _runtimeEpoch = runtimeEpoch;

  final String _runtimeEpoch;
  final List<_PopupRecord<dynamic, dynamic>> _entries =
      <_PopupRecord<dynamic, dynamic>>[];
  final Map<String, _PopupRecord<dynamic, dynamic>> _keyed =
      <String, _PopupRecord<dynamic, dynamic>>{};

  int _nextId = 0;
  bool _hostAttached = false;
  bool _everAttached = false;
  bool _shutdown = false;
  bool _changeNotifierDisposed = false;

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
      final compatible = existing.channel == request.channel &&
          existing.resultType == T &&
          existing.configType == C;
      assert(
        compatible,
        'Popup key "$key" is already used by ${existing.channel} with '
        'different result/config types.',
      );
      if (!compatible) return PopupOpenResult<T>.rejected();

      switch (request.conflictPolicy) {
        case PopupConflictPolicy.rejectNew:
        case PopupConflictPolicy.stack:
          return PopupOpenResult<T>.rejected();
        case PopupConflictPolicy.toggle:
          _requestClose(existing, PopupDismissReason.toggled);
          return PopupOpenResult<T>.toggledClosed();
        case PopupConflictPolicy.updateExisting:
          if (!existing.isActive || !existing.updatable || !request.updatable) {
            return PopupOpenResult<T>.rejected();
          }
          final typed = existing as _PopupRecord<T, C>;
          _updateRecord(typed, request);
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
      controller: this,
      id: '$_runtimeEpoch-${++_nextId}',
      request: request,
    );
    _entries.add(record);

    if (_shutdown) {
      _requestClose(record, PopupDismissReason.runtimeDisposed);
    } else if (_everAttached && !_hostAttached) {
      _requestClose(record, PopupDismissReason.hostUnavailable);
    } else if (!_hostAttached) {
      _transition(record, PopupEntryState.pendingHost);
    } else if (forceQueued || request.initiallyQueued) {
      _transition(record, PopupEntryState.queued);
    } else {
      _transition(record, PopupEntryState.entering);
    }
    _notifySafely();
    return record;
  }

  void _updateRecord<T, C>(
    _PopupRecord<T, C> record,
    PopupEntryRequest<T, C> request,
  ) {
    if (!record.isActive) return;
    record
      ..config = request.config
      ..tags = Set<String>.unmodifiable(request.tags)
      ..backPolicy = request.backPolicy
      ..routePolicy = request.routePolicy
      ..ownership = request.ownership
      ..lifetime = request.lifetime
      ..lifecycle = request.lifecycle ?? PopupLifecycleCallbacks<T>();
    record.generation++;
    _restartLifetime(record);
    _notifySafely();
  }

  void _updateConfig<T, C>(_PopupRecord<T, C> record, C config) {
    if (!record.isActive || !record.updatable) return;
    record.config = config;
    record.generation++;
    _restartLifetime(record);
    _notifySafely();
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
    _hostAttached = false;
    for (final entry
        in List<_PopupRecord<dynamic, dynamic>>.of(_entries).reversed) {
      if (entry.isActive) {
        _requestClose(entry, PopupDismissReason.hostDetached);
      }
      if (!entry.state.isTerminal) _disposeRecord(entry);
    }
    _notifySafely();
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

  void _requestClose<T>(
    _PopupRecord<T, dynamic> entry,
    PopupDismissReason reason, [
    T? value,
  ]) {
    if (!entry.isActive) return;

    final children = _entries.reversed.where((candidate) {
      return candidate.isActive &&
          candidate.ownership.policy == PopupOwnerPolicy.dismissWithParent &&
          candidate.ownership.parentEntryId == entry.id;
    }).toList(growable: false);
    for (final child in children) {
      _requestClose(child, PopupDismissReason.parentDismissed);
    }

    entry.cancelLifetime();
    final needsVisualExit = entry.state == PopupEntryState.entering ||
        entry.state == PopupEntryState.visible;
    _transition(entry, PopupEntryState.dismissRequested);
    final outcome = PopupOutcome<T>(reason: reason, value: value);
    entry.commitOutcome(outcome);
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
    final generation = entry.generation;
    void arm(PopupLifetime lifetime) {
      switch (lifetime) {
        case PopupManualLifetime():
          return;
        case PopupAfterLifetime(:final duration):
          assert(!duration.isNegative, 'Popup lifetime cannot be negative.');
          entry.timers.add(Timer(duration, () {
            if (_acceptLifetimeEvent(entry, generation)) {
              _requestClose(entry, PopupDismissReason.timeout);
            }
          }));
        case PopupUntilLifetime(:final event):
          event.then((_) {
            if (_acceptLifetimeEvent(entry, generation)) {
              _requestClose(entry, PopupDismissReason.externalEvent);
            }
          }, onError: (Object error, StackTrace stackTrace) {
            FlutterError.reportError(
              FlutterErrorDetails(
                exception: error,
                stack: stackTrace,
                library: 'unified_popups',
                context: ErrorDescription('while waiting for popup lifetime'),
              ),
            );
          });
        case PopupAnyOfLifetime(:final conditions):
          for (final condition in conditions) {
            arm(condition);
          }
      }
    }

    arm(entry.lifetime);
  }

  bool _acceptLifetimeEvent(
    _PopupRecord<dynamic, dynamic> entry,
    int generation,
  ) {
    return entry.isActive &&
        entry.state == PopupEntryState.visible &&
        entry.generation == generation;
  }

  Future<void> dismissKey(String key) {
    final entry = _keyed[key];
    if (entry == null) return Future<void>.value();
    return _dismiss(entry);
  }

  Future<int> dismissChannel(PopupChannel channel) async {
    final matches = _entries.reversed
        .where((entry) => entry.channel == channel && entry.isActive)
        .toList(growable: false);
    for (final entry in matches) {
      _requestClose(entry, PopupDismissReason.manual);
    }
    await Future.wait(matches.map((entry) => entry.dismissed));
    return matches.length;
  }

  Future<int> dismissTags(Set<String> tags) async {
    final matches = _entries.reversed
        .where((entry) => entry.isActive && entry.tags.any(tags.contains))
        .toList(growable: false);
    for (final entry in matches) {
      _requestClose(entry, PopupDismissReason.manual);
    }
    await Future.wait(matches.map((entry) => entry.dismissed));
    return matches.length;
  }

  Future<void> dismissAll() async {
    final matches = _entries.reversed.toList(growable: false);
    for (final entry in matches) {
      if (entry.isActive) _requestClose(entry, PopupDismissReason.manual);
    }
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
      if (!entry.isActive) continue;
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
          if (delegate != null && await delegate()) return true;
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
        return entry.isActive && entry.backPolicy != PopupBackPolicy.ignore;
      });

  /// Applies route ownership policies after the root route changes.
  void handleRouteChanged(Object? currentRouteToken) {
    for (final entry in _entries.reversed.toList(growable: false)) {
      if (!entry.isActive) continue;
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
  }

  bool isVisibleKey(String key) {
    final state = _keyed[key]?.state;
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
    for (final entry in records) {
      if (entry.isActive) {
        _requestClose(entry, PopupDismissReason.runtimeDisposed);
      }
      if (!entry.state.isTerminal) _disposeRecord(entry);
    }
    _notifySafely();
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
    entry.wasMounted = entry.wasMounted || entry.state.isMounted;
    entry.state = next;
    if (next == PopupEntryState.entering ||
        next == PopupEntryState.visible ||
        next == PopupEntryState.exiting) {
      entry.wasMounted = true;
    }
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
    if (!_changeNotifierDisposed) notifyListeners();
  }

  @override
  void dispose() {
    unawaited(shutdown());
    _changeNotifierDisposed = true;
    super.dispose();
  }
}

final class _PopupRecord<T, C> {
  _PopupRecord({
    required this.controller,
    required this.id,
    required PopupEntryRequest<T, C> request,
  })  : key = request.key,
        channel = request.channel,
        config = request.config,
        tags = Set<String>.unmodifiable(request.tags),
        backPolicy = request.backPolicy,
        routePolicy = request.routePolicy,
        ownership = request.ownership,
        lifetime = request.lifetime,
        lifecycle = request.lifecycle ?? PopupLifecycleCallbacks<T>(),
        updatable = request.updatable,
        initiallyQueued = request.initiallyQueued,
        onBack = request.onBack,
        resultType = T,
        configType = C {
    handle = _ControllerPopupHandle<T, C>(controller, this);
  }

  final PopupController controller;
  final String id;
  final String? key;
  final PopupChannel channel;
  final bool updatable;
  final bool initiallyQueued;
  final Future<bool> Function()? onBack;
  final Type resultType;
  final Type configType;
  final Completer<PopupOutcome<T>> outcomeCompleter =
      Completer<PopupOutcome<T>>();
  final Completer<void> dismissedCompleter = Completer<void>();
  final List<Timer> timers = <Timer>[];

  late final _ControllerPopupHandle<T, C> handle;
  C config;
  Set<String> tags;
  PopupBackPolicy backPolicy;
  PopupRoutePolicy routePolicy;
  PopupOwnership ownership;
  PopupLifetime lifetime;
  PopupLifecycleCallbacks<T> lifecycle;
  PopupEntryState state = PopupEntryState.created;
  PopupOutcome<T>? finalOutcome;
  int generation = 0;
  bool wasMounted = false;

  bool get isActive => state.isActive;
  bool get hasOutcome => outcomeCompleter.isCompleted;
  Future<void> get dismissed => dismissedCompleter.future;

  PopupEntrySnapshot get snapshot => PopupEntrySnapshot(
        id: id,
        key: key,
        channel: channel,
        state: state,
        config: config,
        generation: generation,
        backPolicy: backPolicy,
        routePolicy: routePolicy,
        ownership: ownership,
      );

  void commitOutcome(PopupOutcome<T> outcome) {
    if (outcomeCompleter.isCompleted) return;
    finalOutcome = outcome;
    outcomeCompleter.complete(outcome);
    controller._invoke(
      () => lifecycle.onOutcome?.call(outcome),
      'while reporting popup outcome',
    );
  }

  void commitUntypedOutcome(PopupOutcome<dynamic> outcome) {
    commitOutcome(PopupOutcome<T>(reason: outcome.reason));
  }

  void commitDismissed() {
    if (dismissedCompleter.isCompleted) return;
    final outcome = finalOutcome!;
    controller._invoke(
      () => lifecycle.onDismissed?.call(outcome),
      'while reporting popup dismissal',
    );
    dismissedCompleter.complete();
  }

  void cancelLifetime({bool invalidateGeneration = true}) {
    for (final timer in timers) {
      timer.cancel();
    }
    timers.clear();
    if (invalidateGeneration) generation++;
  }
}

final class _ControllerPopupHandle<T, C> implements UpdatablePopupHandle<T, C> {
  const _ControllerPopupHandle(this._controller, this._record);

  final PopupController _controller;
  final _PopupRecord<T, C> _record;

  @override
  String get id => _record.id;

  @override
  String? get key => _record.key;

  @override
  PopupChannel get channel => _record.channel;

  @override
  bool get isActive => _record.isActive;

  @override
  bool get isMounted => _record.state.isMounted;

  @override
  PopupEntryState get state => _record.state;

  @override
  Future<PopupOutcome<T>> get outcome => _record.outcomeCompleter.future;

  @override
  Future<T?> get result => outcome.then((outcome) => outcome.value);

  @override
  Future<void> get dismissed => _record.dismissed;

  @override
  Future<void> complete([T? result]) => _controller._complete(_record, result);

  @override
  Future<void> dismiss() => _controller._dismiss(_record);

  @override
  void update(C config) => _controller._updateConfig(_record, config);
}
