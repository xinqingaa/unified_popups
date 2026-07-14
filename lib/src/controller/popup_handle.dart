import '../configs/popup_channel.dart';
import 'popup_entry_state.dart';
import 'popup_outcome.dart';

/// Type-independent lifecycle operations shared by renderer infrastructure.
abstract interface class PopupHandleBase {
  String get id;

  String? get key;

  PopupChannel get channel;

  bool get isActive;

  bool get isMounted;

  PopupEntryState get state;

  Future<void> get dismissed;

  Future<void> dismiss();
}

/// A stable reference to one logical popup entry.
abstract interface class PopupHandle<T> implements PopupHandleBase {
  Future<PopupOutcome<T>> get outcome;

  Future<T?> get result;

  /// Completes the business result immediately and the returned future after
  /// visual removal.
  Future<void> complete([T? result]);
}

/// A handle whose existing logical entry can accept a type-safe new config.
abstract interface class UpdatablePopupHandle<T, C> implements PopupHandle<T> {
  /// Returns false when the entry is inactive or the new config changes an
  /// immutable part of the renderer contract.
  bool update(C config);
}
