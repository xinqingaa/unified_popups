import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

import '../../flows/health_profile_flow.dart';
import '../../widgets/section_header.dart';
import 'settings_page.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String _nickname = 'Runner_Lee';
  DateTime? _birthday;

  Future<void> _editNickname() async {
    final controller = TextEditingController(text: _nickname);
    final result = await Pop.sheet<String>(
      title: '编辑昵称',
      showDragHandle: true,
      adjustForKeyboard: true,
      dragDismissMode: SheetDragDismissMode.handleOnly,
      maxHeight: const SheetDimension.fraction(0.42),
      childBuilder: (dismiss) => Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '昵称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => dismiss(controller.text.trim()),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty) {
      setState(() => _nickname = result);
      Pop.toast('昵称已更新', toastType: ToastType.success);
    }
  }

  Future<void> _pickBirthday() async {
    final date = await Pop.date(
      title: '选择生日',
      initialDate: _birthday ?? DateTime(1995, 6, 15),
      minDate: DateTime(1960),
      maxDate: DateTime.now(),
      confirmText: '确定',
      cancelText: '取消',
    );
    if (date != null) {
      setState(() => _birthday = date);
      Pop.toast(
        '生日：${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      );
    }
  }

  Future<void> _logout() async {
    var typed = '';
    final ok = await Pop.confirm(
      title: '退出登录',
      content: '退出后本地训练缓存将保留。请输入 EXIT 确认。',
      confirmText: '退出',
      cancelText: '取消',
      confirmBgColor: Colors.red,
      confirmChild: TextField(
        onChanged: (value) => typed = value,
        decoration: const InputDecoration(
          hintText: '输入 EXIT',
          border: OutlineInputBorder(),
        ),
      ),
    );
    if (ok == true) {
      if (typed.trim() == 'EXIT') {
        Pop.toast('已退出登录');
      } else {
        Pop.toast('请输入 EXIT 确认', toastType: ToastType.warn);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final birthdayLabel = _birthday == null
        ? '未设置'
        : '${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: '个人资料',
          subtitle: '昵称 / 生日 / 设置 / 健康档案 / 退出登录',
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(_nickname),
                subtitle: const Text('FitPulse 会员'),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _editNickname,
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('生日'),
                subtitle: Text(birthdayLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickBirthday,
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('设置'),
                subtitle: const Text('二级页 · 验证路由切换关弹框'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => HealthProfileFlow.open(),
          icon: const Icon(Icons.health_and_safety_outlined),
          label: const Text('完善健康档案'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout),
          label: const Text('退出登录'),
        ),
      ],
    );
  }
}
