/// Defines what may automatically close a popup after it is presented.
sealed class PopupLifetime {
  const PopupLifetime();

  const factory PopupLifetime.manual() = PopupManualLifetime;

  const factory PopupLifetime.after(Duration duration) = PopupAfterLifetime;

  const factory PopupLifetime.until(Future<void> event) = PopupUntilLifetime;

  factory PopupLifetime.anyOf(List<PopupLifetime> conditions) =
      PopupAnyOfLifetime;
}

final class PopupManualLifetime extends PopupLifetime {
  const PopupManualLifetime();
}

final class PopupAfterLifetime extends PopupLifetime {
  const PopupAfterLifetime(this.duration);

  final Duration duration;
}

final class PopupUntilLifetime extends PopupLifetime {
  const PopupUntilLifetime(this.event);

  final Future<void> event;
}

final class PopupAnyOfLifetime extends PopupLifetime {
  PopupAnyOfLifetime(List<PopupLifetime> conditions)
      : assert(conditions.length > 1),
        conditions = List<PopupLifetime>.unmodifiable(conditions);

  final List<PopupLifetime> conditions;
}
