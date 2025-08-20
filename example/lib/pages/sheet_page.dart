import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

class SheetPage extends StatelessWidget {
  const SheetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sheet & Drawer Demo')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                child: const Text('Show Bottom Sheet'),
                onPressed: () => _showBottomSheet(context),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                child: const Text('Show Left Drawer'),
                onPressed: () => _showLeftDrawer(context),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                child: const Text('Show Top Notification'),
                onPressed: () => _showTopNotification(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBottomSheet(BuildContext context) async {
    final result = await UnifiedPopups.showSheet<String>(
      context,
      title: '选择操作',
      useSafeArea: true,
      childBuilder: (dismiss) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(title: const Text('分享'), onTap: () => dismiss('share')),
          ListTile(title: const Text('编辑'), onTap: () => dismiss('edit')),
          ListTile(title: const Text('删除'), onTap: () => dismiss('delete')),
          const Divider(),
          ListTile(title: const Text('取消'), onTap: () => dismiss()),
        ],
      ),
    );
    _handleSheetResult(result);
  }

  void _showLeftDrawer(BuildContext context) async {
    final result = await UnifiedPopups.showSheet<String>(
      context,
      direction: SheetDirection.left,
      title: '菜单',
      childBuilder: (dismiss) => ListView(
        children: [
          ListTile(leading: const Icon(Icons.home), title: const Text('首页'), onTap: () => dismiss('home')),
          ListTile(leading: const Icon(Icons.settings), title: const Text('设置'), onTap: () => dismiss('setting')),
        ],
      ),
    );
    _handleSheetResult(result);
  }

  void _showTopNotification(BuildContext context) {
    UnifiedPopups.showSheet(
      context,
      direction: SheetDirection.top,
      title: '新消息',
      backgroundColor: Colors.amber.shade100,
      childBuilder: (dismiss) => ListTile(
        title: const Text('您的快递已到达'),
        subtitle: const Text('点击查看详情'),
        onTap: () => dismiss(),
      ),
    );
  }

  void _handleSheetResult(String? result) {
    // if (result != null) {
    //   UnifiedPopups.showToast('你选择了: $result');
    // } else {
    //   UnifiedPopups.showToast('关闭了 Sheet');
    // }
  }
}
