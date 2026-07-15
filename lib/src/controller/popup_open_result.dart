import 'popup_handle.dart';

/// 打开请求应用 key 冲突策略后的同步结果。
///
/// 可用 `.result` 等待业务值，或用 [requireHandle] / [handleOrNull] / 模式匹配
/// 区分 opened、updated、toggledClosed、rejected。
sealed class PopupOpenResult<T> {
  const PopupOpenResult();

  /// 新建并展示了一个 Entry。
  const factory PopupOpenResult.opened(PopupHandle<T> handle) = PopupOpened<T>;

  /// 更新了已有同 key Entry（如 Loading）。
  const factory PopupOpenResult.updated(PopupHandle<T> handle) =
      PopupUpdated<T>;

  /// 冲突策略为 toggle，且已关闭原有 Entry。
  const factory PopupOpenResult.toggledClosed() = PopupToggledClosed<T>;

  /// 冲突策略拒绝了本次打开。
  const factory PopupOpenResult.rejected() = PopupRejected<T>;

  /// 打开或更新成功时的句柄；toggle/拒绝时为 `null`。
  PopupHandle<T>? get handleOrNull => switch (this) {
        PopupOpened<T>(:final handle) ||
        PopupUpdated<T>(:final handle) =>
          handle,
        PopupToggledClosed<T>() || PopupRejected<T>() => null,
      };

  /// 是否产生了可用句柄。
  bool get hasHandle => handleOrNull != null;

  /// 将本次打开决策投影为业务结果 Future（有损便捷接口）。
  ///
  /// opened/updated 等待 Entry 结果；rejected/toggle 立即得到 `null`。
  /// 需要区分打开决策或关闭原因时，请用 [handleOrNull]、[requireHandle] 或模式匹配。
  Future<T?> get result => switch (this) {
        PopupOpened<T>(:final handle) ||
        PopupUpdated<T>(:final handle) =>
          handle.result,
        PopupToggledClosed<T>() || PopupRejected<T>() => Future<T?>.value(),
      };

  /// 同步取出 opened/updated 句柄；否则抛出 [StateError]。
  PopupHandle<T> requireHandle() {
    final handle = handleOrNull;
    if (handle != null) return handle;
    throw StateError('The popup request did not produce a handle.');
  }
}

/// 新建并展示成功。
final class PopupOpened<T> extends PopupOpenResult<T> {
  const PopupOpened(this.handle);

  final PopupHandle<T> handle;
}

/// 更新已有 Entry 成功。
final class PopupUpdated<T> extends PopupOpenResult<T> {
  const PopupUpdated(this.handle);

  final PopupHandle<T> handle;
}

/// Toggle 策略关闭了原有 Entry，未产生新句柄。
final class PopupToggledClosed<T> extends PopupOpenResult<T> {
  const PopupToggledClosed();
}

/// 冲突策略拒绝了本次请求。
final class PopupRejected<T> extends PopupOpenResult<T> {
  const PopupRejected();
}
