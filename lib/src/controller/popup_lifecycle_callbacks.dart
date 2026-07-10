import 'popup_outcome.dart';

/// Lifecycle notifications shared by every popup type.
///
/// Callback failures are reported by the controller and never interrupt popup
/// cleanup.
final class PopupLifecycleCallbacks<T> {
  const PopupLifecycleCallbacks({
    this.onPresented,
    this.onOutcome,
    this.onDismissed,
  });

  final void Function()? onPresented;
  final void Function(PopupOutcome<T> outcome)? onOutcome;
  final void Function(PopupOutcome<T> outcome)? onDismissed;
}
