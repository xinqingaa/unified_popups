import '../configs/popup_channel.dart';
import 'popup_entry_state.dart';
import 'popup_outcome.dart';

/// A stable reference to one logical popup entry.
abstract interface class PopupHandle<T> {
  String get id;

  String? get key;

  PopupChannel get channel;

  bool get isActive;

  bool get isMounted;

  PopupEntryState get state;

  Future<PopupOutcome<T>> get outcome;

  Future<T?> get result;

  Future<void> get dismissed;

  /// Completes the business result immediately and the returned future after
  /// visual removal.
  Future<void> complete([T? result]);

  /// Dismisses without a business result and completes after visual removal.
  Future<void> dismiss();
}

/// A handle whose existing logical entry can accept a type-safe new config.
abstract interface class UpdatablePopupHandle<T, C> implements PopupHandle<T> {
  void update(C config);
}
