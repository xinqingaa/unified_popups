import 'popup_dismiss_reason.dart';

/// The business outcome of a popup, independent from its exit animation.
final class PopupOutcome<T> {
  const PopupOutcome({
    required this.reason,
    this.value,
  });

  final T? value;
  final PopupDismissReason reason;

  bool get isCompleted => reason == PopupDismissReason.completed;

  @override
  bool operator ==(Object other) {
    return other is PopupOutcome<T> &&
        other.reason == reason &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(reason, value);

  @override
  String toString() => 'PopupOutcome<$T>(reason: $reason, value: $value)';
}
