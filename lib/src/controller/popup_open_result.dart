import 'popup_handle.dart';

/// The exact result of applying a key conflict policy.
sealed class PopupOpenResult<T> {
  const PopupOpenResult();

  const factory PopupOpenResult.opened(PopupHandle<T> handle) = PopupOpened<T>;

  const factory PopupOpenResult.updated(PopupHandle<T> handle) =
      PopupUpdated<T>;

  const factory PopupOpenResult.toggledClosed() = PopupToggledClosed<T>;

  const factory PopupOpenResult.rejected() = PopupRejected<T>;

  PopupHandle<T>? get handleOrNull => switch (this) {
        PopupOpened<T>(:final handle) ||
        PopupUpdated<T>(:final handle) =>
          handle,
        PopupToggledClosed<T>() || PopupRejected<T>() => null,
      };

  bool get hasHandle => handleOrNull != null;

  /// Projects this synchronous opening decision into a business-result Future.
  ///
  /// Opened and updated requests wait for the entry result. Rejected requests
  /// and requests consumed by toggle complete immediately with `null`. This is
  /// intentionally a lossy convenience: use [handleOrNull], [requireHandle],
  /// or pattern matching when the opening decision or dismissal reason matters.
  Future<T?> get result => switch (this) {
        PopupOpened<T>(:final handle) ||
        PopupUpdated<T>(:final handle) =>
          handle.result,
        PopupToggledClosed<T>() || PopupRejected<T>() => Future<T?>.value(),
      };

  /// Extracts the opened or updated handle synchronously.
  ///
  /// Throws when the conflict policy rejected the request or consumed it by
  /// toggling an existing entry closed. Use [handleOrNull] when either outcome
  /// is valid for the caller.
  PopupHandle<T> requireHandle() {
    final handle = handleOrNull;
    if (handle != null) return handle;
    throw StateError('The popup request did not produce a handle.');
  }
}

final class PopupOpened<T> extends PopupOpenResult<T> {
  const PopupOpened(this.handle);

  final PopupHandle<T> handle;
}

final class PopupUpdated<T> extends PopupOpenResult<T> {
  const PopupUpdated(this.handle);

  final PopupHandle<T> handle;
}

final class PopupToggledClosed<T> extends PopupOpenResult<T> {
  const PopupToggledClosed();
}

final class PopupRejected<T> extends PopupOpenResult<T> {
  const PopupRejected();
}
