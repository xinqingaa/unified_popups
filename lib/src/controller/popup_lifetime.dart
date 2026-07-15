/// 弹窗展示后的自动关闭条件。
sealed class PopupLifetime {
  const PopupLifetime();

  /// 仅手动关闭（Handle / 业务 complete / 批量 dismiss 等）。
  const factory PopupLifetime.manual() = PopupManualLifetime;

  /// 展示后经过 [duration] 自动关闭。
  const factory PopupLifetime.after(Duration duration) = PopupAfterLifetime;

  /// 外部 Future settled（成功或失败）后关闭；业务异常仍由原 Future 调用方处理。
  const factory PopupLifetime.until(Future<void> event) = PopupUntilLifetime;

  /// 多个条件任一满足即关闭；至少需要两个条件。
  factory PopupLifetime.anyOf(List<PopupLifetime> conditions) =
      PopupAnyOfLifetime;
}

/// 仅手动关闭。
final class PopupManualLifetime extends PopupLifetime {
  const PopupManualLifetime();
}

/// 定时自动关闭。
final class PopupAfterLifetime extends PopupLifetime {
  const PopupAfterLifetime(this.duration);

  final Duration duration;
}

/// 等待外部 Future settled 后关闭。
final class PopupUntilLifetime extends PopupLifetime {
  const PopupUntilLifetime(this.event);

  final Future<void> event;
}

/// 任一子条件满足即关闭。
final class PopupAnyOfLifetime extends PopupLifetime {
  PopupAnyOfLifetime(List<PopupLifetime> conditions)
      : assert(conditions.length > 1),
        conditions = List<PopupLifetime>.unmodifiable(conditions);

  final List<PopupLifetime> conditions;
}
