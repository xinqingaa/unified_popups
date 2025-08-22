import 'package:flutter/material.dart';
import '../../unified_popups.dart';


class PopScopeWidget extends StatelessWidget {
  final Widget child;
  const PopScopeWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // 使用 ValueListenableBuilder 来监听 PopupManager 的状态变化
    return ValueListenableBuilder<bool>(
      // 监听 Notifier
      valueListenable: PopupManager.hasNonToastPopupNotifier,
      // 每当 Notifier 的值改变时，这个 builder 就会重新运行
      builder: (context, hasPopup, _) {
        // 返回一个根据最新状态配置的 PopScope
        // debugPrint('[PopScopeWidget] Rebuilding. hasPopup is $hasPopup. Setting canPop to ${!hasPopup}.');
        return PopScope(
          // canPop 现在是动态的
          // - 如果有弹窗 (hasPopup == true)，则 canPop 为 false (拦截)
          // - 如果没有弹窗 (hasPopup == false)，则 canPop 为 true (不拦截)
          canPop: !hasPopup,
          onPopInvokedWithResult: (bool didPop,  dynamic result) {
            // debugPrint('[PopScopeWidget] onPopInvoked triggered. didPop: $didPop');
            // 这个回调只在 canPop 为 false (即有弹窗) 并触发返回时才需要处理
            if (didPop) return; // 如果 didPop 为 true，说明是 PopScope 允许的返回，无需处理

            // 既然被拦截了，我们的唯一任务就是关闭弹窗
            PopupManager.hideLastNonToast();
          },
          child: child,
        );
      },
    );
  }
}