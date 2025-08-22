import 'package:flutter/material.dart';
import '../../unified_popups.dart';

class PopScopeWidget extends StatelessWidget {
  final Widget child;
  const PopScopeWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        // 尝试关闭弹窗
        final bool wasPopupHidden = PopupManager.hideLastNonToast();
        // 如果没有弹窗，则返回页面
        if (!wasPopupHidden) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      },
      child: child,
    );
  }
}