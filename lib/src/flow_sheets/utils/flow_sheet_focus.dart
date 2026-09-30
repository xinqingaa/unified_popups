import 'dart:async';

import 'package:flutter/widgets.dart';

/// FlowSheet 内页与输入焦点相关的通用工具。
class FlowSheetFocus {
  FlowSheetFocus._();

  /// 把焦点交回「上一页」输入框，避免 pop 时键盘先收再弹。
  ///
  /// 典型用法：底层页 `maintainState: true`，子页返回前调用本方法。
  static void handOffToPreviousPage(FocusNode node) {
    if (!node.hasFocus) return;
    node.unfocus(disposition: UnfocusDisposition.previouslyFocusedChild);
  }

  /// 等待当前路由转场接近完成（默认进度 ≥ 0.85），再拉起键盘等布局敏感操作。
  ///
  /// 首帧就 [FocusNode.requestFocus] 会拖慢整段滑入；等完全结束又会单独露出键盘动画。
  static Future<void> waitForRouteNearComplete(
    BuildContext context, {
    double threshold = 0.85,
  }) {
    assert(threshold > 0 && threshold <= 1);
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null ||
        animation.status == AnimationStatus.completed ||
        animation.status == AnimationStatus.dismissed ||
        animation.value >= threshold) {
      return Future<void>.value();
    }

    final completer = Completer<void>();
    late final VoidCallback listener;
    listener = () {
      if (animation.status != AnimationStatus.dismissed &&
          animation.value < threshold) {
        return;
      }
      animation.removeListener(listener);
      if (!completer.isCompleted) completer.complete();
    };
    animation.addListener(listener);
    listener();
    return completer.future;
  }
}
