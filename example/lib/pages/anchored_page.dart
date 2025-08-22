import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

class AnchoredPage extends StatelessWidget {
  const AnchoredPage({super.key});

  @override
  Widget build(BuildContext context) {
    // GlobalKey 可以在 build 方法内部创建，因为它只在此处使用
    final GlobalKey anchorButtonKey = GlobalKey();

    return PopScopeWidget(
      child: Scaffold(
        appBar: AppBar(title: const Text('Anchored Popup Demo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                key: anchorButtonKey,
                onPressed: () => _showAnchoredPopup(anchorButtonKey),
                child: const Text('Show Anchored Popup Here'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _showAnchoredMenu(anchorButtonKey),
                child: const Text('Show Pop.menu'),
              ),
            ],
          ),
        ),
      )
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

  void _showAnchoredMenu(GlobalKey anchorKey) async {
    final selected = await Pop.menu<String>(
      anchorKey: anchorKey,
      anchorOffset: const Offset(0, 8),
      builder: (dismiss) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            dense: true,
            title: const Text('复制'),
            onTap: () => dismiss('copy'),
          ),
          ListTile(
            dense: true,
            title: const Text('编辑'),
            onTap: () => dismiss('edit'),
          ),
          ListTile(
            dense: true,
            title: const Text('删除'),
            onTap: () => dismiss('delete'),
          ),
        ],
      ),
    );
    debugPrint('menu selected: $selected');
  }
}
