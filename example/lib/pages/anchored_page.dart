import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

class AnchoredPage extends StatelessWidget {
  const AnchoredPage({super.key});

  @override
  Widget build(BuildContext context) {
    // GlobalKey 可以在 build 方法内部创建，因为它只在此处使用
    final GlobalKey anchorButtonKey = GlobalKey();

    return Scaffold(
      appBar: AppBar(title: const Text('Anchored Popup Demo')),
      body: Center(
        child: ElevatedButton(
          key: anchorButtonKey,
          onPressed: () => _showAnchoredPopup(anchorButtonKey),
          child: const Text('Show Anchored Popup Here'),
        ),
      ),
    );
  }

  void _showAnchoredPopup(GlobalKey anchorKey) {
    PopupManager.show(
      PopupConfig(
        anchorKey: anchorKey,
        anchorOffset: const Offset(0, 8),
        animation: PopupAnimation.fade,
        showBarrier: true, // 点击外部可关闭
        barrierColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade700,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Anchored Popup!',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
