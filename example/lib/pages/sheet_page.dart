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
                onPressed: _showBottomSheet,
                child: const Text('Show Bottom Sheet'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _showLeftDrawer,
                child: const Text('Show Left Drawer'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed:_showTopNotification,
                child: const Text('Show Top Notification'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _showBottomMenu,
                child: const Text('显示底部 Sheet 菜单 (可滚动)'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _showShort,
                child: const Text('短列表'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _showFullScreenBottomDrawer,
                child: const Text('全屏底部抽屉 (无尺寸限制)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBottomSheet() async {
    final result = await UnifiedPopups.showSheet<String>(
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

  void _showLeftDrawer() async {
    final result = await UnifiedPopups.showSheet<String>(
      direction: SheetDirection.left,
      maxWidth: const SheetDimension.fraction(0.75),
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

  void _showTopNotification() {
    UnifiedPopups.showSheet(
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


  void _showBottomMenu() async {
    final result = await UnifiedPopups.showSheet<String>(
      title: '选择一个水果 可滚动',
      direction: SheetDirection.bottom,
      maxHeight: const SheetDimension.pixel(400),
      childBuilder: (dismiss) => ListView.builder(
        itemCount: 20, // 很多项，以确保内容会滚动
        itemBuilder: (context, index) {
          final fruit = '水果 ${index + 1}';
          return ListTile(
            title: Text(fruit),
            onTap: () => dismiss(fruit),
          );
        },
      ),
    );
    _handleSheetResult(result);
  }

  void _showFullScreenBottomDrawer() {
    UnifiedPopups.showSheet(
      title: '全屏内容',
      // 不提供任何 height 或 maxHeight
      useSafeArea: false,
      childBuilder: (dismiss) => Container(
        color: Colors.blue.shade50,
        child: Center(
          child: TextButton(
            onPressed: () => dismiss(),
            child: const Text('关闭'),
          ),
        ),
      ),
    );
  }

  void _showShort(){
    UnifiedPopups.showSheet(
      title: '短列表',
      // maxHeight: const SheetDimension.fraction(0.6), // 最大占屏 60%
      childBuilder: (dismiss) => ListView(
        shrinkWrap: true,
        children: const [
          ListTile(title: Text('选项 1')),
          ListTile(title: Text('选项 2')),
        ],
      ),
    );
  }

  void _handleSheetResult(String? result) {
    print("result: $result");
  }
}
