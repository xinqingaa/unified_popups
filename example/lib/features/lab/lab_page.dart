import 'package:flutter/material.dart';

import 'async_lab.dart';
import 'popup_runtime_lab.dart';

/// 技术实验室：非产品路径，用于回归异步调用与 Popup Runtime。
class LabPage extends StatelessWidget {
  const LabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('技术实验室')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '此处不是 FitPulse 产品路径，仅用于验证异步调用、'
                '全局关闭、返回键与堆叠等边界场景。',
                style: TextStyle(height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('异步边界场景'),
            subtitle: const Text('Future / Stream / Timer / build 阶段调用'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AsyncLabPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.layers_outlined),
            title: const Text('Popup Runtime API'),
            subtitle: const Text('自定义弹窗、全局关闭、返回键与堆叠'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PopupRuntimeLabPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
