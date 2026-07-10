import 'popup_handle.dart';

/// The exact result of applying a key conflict policy.
sealed class PopupOpenResult<T> {
  const PopupOpenResult();

  const factory PopupOpenResult.opened(PopupHandle<T> handle) = PopupOpened<T>;

  const factory PopupOpenResult.updated(PopupHandle<T> handle) =
      PopupUpdated<T>;

  const factory PopupOpenResult.toggledClosed() = PopupToggledClosed<T>;

  const factory PopupOpenResult.rejected() = PopupRejected<T>;
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
