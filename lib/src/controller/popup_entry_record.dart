import 'dart:async';

import '../configs/popup_back_policy.dart';
import '../configs/popup_channel.dart';
import '../configs/popup_route_policy.dart';
import 'popup_dismiss_reason.dart';
import 'popup_entry_request.dart';
import 'popup_entry_snapshot.dart';
import 'popup_entry_state.dart';
import 'popup_handle.dart';
import 'popup_lifecycle_callbacks.dart';
import 'popup_lifetime.dart';
import 'popup_lifetime_binding.dart';
import 'popup_outcome.dart';
import 'popup_ownership.dart';

typedef PopupCallbackInvoker = void Function(
  void Function()? callback,
  String context,
);

/// Internal mutable state for one logical popup.
///
/// This type is intentionally not exported from the package entrypoint. State
/// transitions and registry mutation remain exclusively owned by
/// `PopupController`.
final class PopupEntryRecord<T, C> {
  PopupEntryRecord({
    required this.id,
    required PopupEntryRequest<T, C> request,
    required PopupCallbackInvoker invokeCallback,
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
        resolveUpdate = request.resolveUpdate,
        resultType = T,
        configType = C,
        _invokeCallback = invokeCallback;

  final String id;
  final String? key;
  final PopupChannel channel;
  final bool updatable;
  final bool initiallyQueued;
  final Future<bool> Function()? onBack;
  final Type resultType;
  final Type configType;
  final PopupCallbackInvoker _invokeCallback;
  final Completer<PopupOutcome<T>> outcomeCompleter =
      Completer<PopupOutcome<T>>();
  final Completer<void> dismissedCompleter = Completer<void>();
  final PopupLifetimeBinding lifetimeBinding = PopupLifetimeBinding();

  late final UpdatablePopupHandle<T, C> handle;
  C config;
  Set<String> tags;
  PopupBackPolicy backPolicy;
  PopupRoutePolicy routePolicy;
  PopupOwnership ownership;
  PopupLifetime lifetime;
  PopupLifecycleCallbacks<T> lifecycle;
  PopupEntryUpdate<T>? Function(C previous, C next)? resolveUpdate;
  PopupEntryState state = PopupEntryState.created;
  PopupOutcome<T>? finalOutcome;
  bool wasMounted = false;

  int get generation => lifetimeBinding.generation;
  set generation(int value) => lifetimeBinding.generation = value;

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
    _invokeCallback(
      () => lifecycle.onOutcome?.call(outcome),
      'while reporting popup outcome',
    );
  }

  void commitReason(PopupDismissReason reason, [Object? value]) {
    commitOutcome(PopupOutcome<T>(reason: reason, value: value as T?));
  }

  void commitUntypedOutcome(PopupOutcome<dynamic> outcome) {
    commitOutcome(PopupOutcome<T>(reason: outcome.reason));
  }

  void commitDismissed() {
    if (dismissedCompleter.isCompleted) return;
    final outcome = finalOutcome!;
    _invokeCallback(
      () => lifecycle.onDismissed?.call(outcome),
      'while reporting popup dismissal',
    );
    dismissedCompleter.complete();
  }

  void cancelLifetime({bool invalidateGeneration = true}) {
    lifetimeBinding.cancel(invalidateGeneration: invalidateGeneration);
  }
}
