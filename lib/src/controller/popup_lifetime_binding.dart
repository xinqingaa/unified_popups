import 'dart:async';

import 'popup_dismiss_reason.dart';
import 'popup_lifetime.dart';

/// Owns the cancelable resources and generation associated with one entry.
final class PopupLifetimeBinding {
  final List<Timer> _timers = <Timer>[];

  int generation = 0;

  void bumpGeneration() => generation++;

  void start(
    PopupLifetime lifetime,
    void Function(int generation, PopupDismissReason reason) onEvent,
  ) {
    final armedGeneration = generation;

    void arm(PopupLifetime condition) {
      switch (condition) {
        case PopupManualLifetime():
          return;
        case PopupAfterLifetime(:final duration):
          assert(!duration.isNegative, 'Popup lifetime cannot be negative.');
          _timers.add(
            Timer(
              duration,
              () => onEvent(armedGeneration, PopupDismissReason.timeout),
            ),
          );
        case PopupUntilLifetime(:final event):
          event.then(
            (_) => onEvent(
              armedGeneration,
              PopupDismissReason.externalEvent,
            ),
            onError: (Object _, StackTrace __) => onEvent(
              armedGeneration,
              PopupDismissReason.externalEvent,
            ),
          );
        case PopupAnyOfLifetime(:final conditions):
          for (final condition in conditions) {
            arm(condition);
          }
      }
    }

    arm(lifetime);
  }

  void cancel({bool invalidateGeneration = true}) {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    if (invalidateGeneration) generation++;
  }
}
