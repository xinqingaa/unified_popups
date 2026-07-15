import 'popup_dismiss_reason.dart';

/// 弹窗业务结果；与退出动画 / 视觉移除相互独立。
final class PopupOutcome<T> {
  const PopupOutcome({
    required this.reason,
    this.value,
  });

  final T? value;
  final PopupDismissReason reason;

  /// 是否因业务正常完成而关闭。
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
