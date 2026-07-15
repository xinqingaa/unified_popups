import 'popup_outcome.dart';

/// 各类弹窗共用的生命周期回调。
///
/// 回调异常由 Controller 上报，不会中断弹窗清理流程。
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
