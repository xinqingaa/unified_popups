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
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _showAnchoredMenuWithIcons(anchorButtonKey),
                child: const Text('带图标的菜单'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _showAnchoredMenuWithCustomStyle(anchorButtonKey),
                child: const Text('自定义样式菜单'),
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
      anchorOffset: const Offset(10, 40),
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

  void _showAnchoredMenuWithIcons(GlobalKey anchorKey) async {
    final selected = await Pop.menu<String>(
      anchorKey: anchorKey,
      anchorOffset: const Offset(10, 40),
      builder: (dismiss) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.copy, size: 20),
            title: const Text('复制'),
            onTap: () => dismiss('copy'),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.edit, size: 20),
            title: const Text('编辑'),
            onTap: () => dismiss('edit'),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.delete, size: 20, color: Colors.red),
            title: const Text('删除', style: TextStyle(color: Colors.red)),
            onTap: () => dismiss('delete'),
          ),
        ],
      ),
    );
    debugPrint('menu with icons selected: $selected');
  }

  void _showAnchoredMenuWithCustomStyle(GlobalKey anchorKey) async {
    final selected = await Pop.menu<String>(
      anchorKey: anchorKey,
      anchorOffset: const Offset(10, 40),
      builder: (dismiss) => Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCustomMenuItem(
              icon: Icons.share,
              title: '分享',
              subtitle: '分享到社交媒体',
              onTap: () => dismiss('share'),
            ),
            const Divider(height: 1),
            _buildCustomMenuItem(
              icon: Icons.favorite,
              title: '收藏',
              subtitle: '添加到收藏夹',
              onTap: () => dismiss('favorite'),
            ),
            const Divider(height: 1),
            _buildCustomMenuItem(
              icon: Icons.report,
              title: '举报',
              subtitle: '举报不当内容',
              onTap: () => dismiss('report'),
            ),
          ],
        ),
      ),
    );
    debugPrint('custom menu selected: $selected');
  }

  Widget _buildCustomMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
