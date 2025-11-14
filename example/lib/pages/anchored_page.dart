import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

class AnchoredPage extends StatelessWidget {
  const AnchoredPage({super.key});

  @override
  Widget build(BuildContext context) {
    // GlobalKey 可以在 build 方法内部创建，因为它只在此处使用
    final GlobalKey anchorButtonKey = GlobalKey();
    // 四个方向的锚点用于测试智能定位
    final GlobalKey topAnchorKey = GlobalKey();
    final GlobalKey bottomAnchorKey = GlobalKey();
    final GlobalKey leftAnchorKey = GlobalKey();
    final GlobalKey rightAnchorKey = GlobalKey();

    return PopScopeWidget(
      child: Scaffold(
        appBar: AppBar(title: const Text('Anchored Popup Demo')),
        body: Stack(
          children: [
            // 原有内容
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 基准线
                  Container(
                    key: anchorButtonKey,
                    width: double.infinity,
                    height: 1,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: () => _showAnchoredPopup(anchorButtonKey),
                    child: const Text('锚定弹窗'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _showAnchoredMenu(anchorButtonKey),
                    child: const Text('基础菜单'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _showAnchoredMenuWithIcons(anchorButtonKey),
                    child: const Text('图标菜单'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _showAnchoredMenuWithCustomStyle(anchorButtonKey),
                    child: const Text('行内菜单'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _showAnimationDirectionTest(topAnchorKey),
                    child: const Text('验证动画方向'),
                  ),
                ],
              ),
            ),
            // 新增：四个方向的智能定位测试按钮
            // 顶部锚点
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: _buildSmartPositionTestButton(
                  topAnchorKey,
                  '顶部测试',
                  Colors.red,
                  () => _showMenu(topAnchorKey),
                ),
              ),
            ),
            // 底部锚点
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: _buildSmartPositionTestButton(
                  bottomAnchorKey,
                  '底部测试',
                  Colors.orange,
                  () => _showMenu(bottomAnchorKey),
                ),
              ),
            ),
            // 左侧锚点
            Positioned(
              top: 0,
              bottom: 0,
              left: 16,
              child: Center(
                child: _buildSmartPositionTestButton(
                  leftAnchorKey,
                  '左侧测试',
                  Colors.green,
                  () => _showMenu(leftAnchorKey),
                ),
              ),
            ),
            // 右侧锚点
            Positioned(
              top: 0,
              bottom: 0,
              right: 16,
              child: Center(
                child: _buildSmartPositionTestButton(
                  rightAnchorKey,
                  '右侧测试',
                  Colors.blue,
                  () => _showMenu(rightAnchorKey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartPositionTestButton(GlobalKey key, String label, MaterialColor color, VoidCallback onTap) {
    return Container(
      key: key,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.shade100,
          foregroundColor: color.shade900,
        ),
        child: Text(label),
      ),
    );
  }

  void _showMenu(GlobalKey anchorKey) async {
    final selected = await Pop.menu<String>(
      decoration: BoxDecoration(
        color: Colors.orange.shade400,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ) ,
        ],
      ),
      anchorKey: anchorKey,
      anchorOffset: const Offset(0, 8),
      builder: (dismiss) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            dense: true,
            title: const Text('选项1'),
            onTap: () => dismiss('option1'),
          ),
          ListTile(
            dense: true,
            title: const Text('选项2'),
            onTap: () => dismiss('option2'),
          ),
          ListTile(
            dense: true,
            title: const Text('选项3'),
            onTap: () => dismiss('option3'),
          ),
        ],
      ),
    );
    debugPrint('smart position menu selected: $selected');
  }

  void _showAnchoredPopup(GlobalKey anchorKey) {
    PopupManager.show(
      PopupConfig(
        anchorKey: anchorKey,
        anchorOffset: const Offset(0, 0),
        animation: PopupAnimation.fade,
        showBarrier: true, 
        barrierColor: Colors.black54,
        barrierDismissible: true, // 点击遮盖关闭
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black,
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
      showBarrier: true,
      barrierDismissible: false,
      anchorKey: anchorKey,
      anchorOffset: const Offset(0, 0),
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
      anchorOffset: const Offset(0, 0),
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
      anchorOffset: const Offset(0, 0),
      builder: (dismiss) => Container(
        padding: const EdgeInsets.all(8),
        child: 
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCustomMenuItem(
              icon: Icons.share,
              title: '分享',
              onTap: () => dismiss('share'),
            ),
            _buildCustomMenuItem(
              icon: Icons.favorite,
              title: '收藏',
              onTap: () => dismiss('favorite'),
            ),
            _buildCustomMenuItem(
              icon: Icons.report,
              title: '举报',
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 验证动画方向修复
  /// 
  /// 从底部锚点触发，使用 slideUp 动画
  /// 由于空间不足，弹窗会被智能调整到上方
  /// 修复后：动画应该从上方滑入（与最终位置一致）
  /// 修复前：动画会从下方滑入（与最终位置不一致）
  void _showAnimationDirectionTest(GlobalKey anchorKey) async {
    final selected = await Pop.menu<String>(
      anchorKey: anchorKey,
      anchorOffset: const Offset(0, 30),
      animation: PopupAnimation.slideUp, // 使用 slideUp 动画
      showBarrier: false, // 不显示遮盖层，方便观察动画
      builder: (dismiss) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.purple.shade400,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '动画方向验证',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '从底部按钮触发，弹窗因空间不足被调整到上方。\n'
              '修复后：动画应从上方滑入 ✅\n'
              '修复前：动画从下方滑入 ❌',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTestOption('选项1', () => dismiss('option1')),
                _buildTestOption('选项2', () => dismiss('option2')),
                _buildTestOption('选项3', () => dismiss('option3')),
              ],
            ),
          ],
        ),
      ),
    );
    debugPrint('animation direction test selected: $selected');
  }

  Widget _buildTestOption(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
