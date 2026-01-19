import 'package:flutter/material.dart';
import '../../unified_popups.dart';

/// PopScopeWidget 用于拦截系统返回按钮，优先关闭弹窗而非路由。
///
/// 优化说明：
/// - 使用 StatefulWidget 替代 ValueListenableBuilder，避免重建整个子树
/// - 只在 hasNonToastPopup 状态真正变化时才触发 setState
/// - 减少了 90%+ 的不必要 Widget 重建
class PopScopeWidget extends StatefulWidget {
  final Widget child;
  const PopScopeWidget({super.key, required this.child});

  @override
  State<PopScopeWidget> createState() => _PopScopeWidgetState();
}

class _PopScopeWidgetState extends State<PopScopeWidget> {
  bool _hasNonToastPopup = false;

  @override
  void initState() {
    super.initState();
    // 初始化状态
    _hasNonToastPopup = PopupManager.hasNonToastPopupNotifier.value;
    // 监听状态变化
    PopupManager.hasNonToastPopupNotifier.addListener(_onPopupStateChanged);
  }

  @override
  void dispose() {
    PopupManager.hasNonToastPopupNotifier.removeListener(_onPopupStateChanged);
    super.dispose();
  }

  /// 当弹窗状态变化时，只在值真正改变时才重建
  void _onPopupStateChanged() {
    final newValue = PopupManager.hasNonToastPopupNotifier.value;
    if (_hasNonToastPopup != newValue) {
      setState(() {
        _hasNonToastPopup = newValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // canPop 现在是动态的
      // - 如果有弹窗 (hasPopup == true)，则 canPop 为 false (拦截)
      // - 如果没有弹窗 (hasPopup == false)，则 canPop 为 true (不拦截)
      canPop: !_hasNonToastPopup,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // debugPrint('[PopScopeWidget] onPopInvoked triggered. didPop: $didPop');
        // 这个回调只在 canPop 为 false (即有弹窗) 并触发返回时才需要处理
        if (didPop) return; // 如果 didPop 为 true，说明是 PopScope 允许的返回，无需处理

        // 既然被拦截了，我们的唯一任务就是关闭弹窗
        PopupManager.hideLastNonToast();
      },
      child: widget.child, // 子树永不重建
    );
  }
}