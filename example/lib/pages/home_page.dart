import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unified Popup Demos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_fullscreen),
            tooltip: 'Hide All Popups',
            onPressed: () => PopupManager.hideAll(),
          )
        ],
      ),
      body: ListView(
        children: [
          _buildMenuItem(
            context,
            title: 'Toast',
            subtitle: '简单的消息提示',
            routeName: '/toast',
          ),
          _buildMenuItem(
            context,
            title: 'Dialogs',
            subtitle: '确认框、警告框等',
            routeName: '/dialog',
          ),
          _buildMenuItem(
            context,
            title: 'Loading',
            subtitle: '加载提示',
            routeName: '/loading',
          ),
          _buildMenuItem(
            context,
            title: 'Sheet & Drawer',
            subtitle: '底部、顶部、侧边弹出菜单',
            routeName: '/sheet',
          ),
          _buildMenuItem(
            context,
            title: 'Anchored Popup',
            subtitle: '跟随特定组件弹出的气泡',
            routeName: '/anchored',
          ),
          const Divider(),
          // 你之前的日历页面入口
          // _buildMenuItem(
          //   context,
          //   title: '日历测试页面',
          //   subtitle: '进入其他测试页面',
          //   routeName: '/home',
          // ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required String title,
        required String subtitle,
        required String routeName,
      }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        Navigator.of(context).pushNamed(routeName);
      },
    );
  }
}
