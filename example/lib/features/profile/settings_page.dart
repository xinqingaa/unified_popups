import 'package:flutter/material.dart';

import '../../app/app_pop.dart';

/// 设置二级页：验证 confirm 随路由返回关闭。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _clearCache() async {
    final ok = await AppPop.confirm(
      title: '清除缓存',
      content: '将清除本地训练草稿与临时图片缓存，不会删除已同步的健康数据。',
      confirmText: '清除',
    );
    if (ok) {
      await AppPop.runLoading<void>(
        message: '清理中…',
        task: Future<void>.delayed(const Duration(milliseconds: 600)),
      );
      AppPop.success('缓存已清除');
    }
  }

  void _openAbout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _AboutPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: theme.colorScheme.secondaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  '打开「清除缓存」确认框后点返回，或进入「关于」再返回：'
                  'confirm 会随路由切换自动关闭。',
                  style: TextStyle(height: 1.4),
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('清除缓存'),
            subtitle: const Text('打开 Confirm，再返回验证自动关闭'),
            onTap: _clearCache,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于 FitPulse'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openAbout(context),
          ),
        ],
      ),
    );
  }
}

class _AboutPage extends StatelessWidget {
  const _AboutPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'FitPulse Example · unified_popups 演示应用。\n\n'
          '从设置页打开 confirm 后进入本页再返回，可验证路由切换关闭弹框。',
          style: TextStyle(height: 1.5),
        ),
      ),
    );
  }
}
