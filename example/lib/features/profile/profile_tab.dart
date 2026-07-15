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
      SheetConfig<String>(
        header: const SheetHeaderConfig(title: '编辑昵称'),
        drag: const SheetDragConfig(mode: SheetDragDismissMode.handleOnly),
        keyboard: const SheetKeyboardConfig(adjustForKeyboard: true),
        size: const SheetSizeConfig(
          maxHeight: SheetDimension.fraction(0.42),
        ),
        builder: (context, handle) => Padding(
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
                onPressed: () => handle.complete(controller.text.trim()),
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    ).result;
    controller.dispose();
    if (result != null && result.isNotEmpty) {
      setState(() => _nickname = result);
      Pop.toast(const ToastConfig.text('昵称已更新', type: ToastType.success));
    }
  }

  Future<void> _pickBirthday() async {
    final date = await Pop.date(
      DateConfig(
        initialDate: _birthday ?? DateTime(1995, 6, 15),
        minDate: DateTime(1960),
        maxDate: DateTime.now(),
        labels: const DateLabels(
          title: '选择生日',
          confirm: '确定',
          cancel: '取消',
        ),
      ),
    ).result;
    if (date != null) {
      setState(() => _birthday = date);
      Pop.toast(ToastConfig.text(
        '生日：${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      ));
    }
  }

  Future<void> _logout() async {
    var typed = '';
    final ok = await Pop.confirm(
      ConfirmConfig(
        title: '退出登录',
        content: '退出后本地训练缓存将保留。请输入 EXIT 确认。',
        confirmText: '退出',
        cancelText: '取消',
        style: const ConfirmStyle(
          confirmStyle: TextStyle(color: Colors.red),
        ),
        bodyExtension: TextField(
          onChanged: (value) => typed = value,
          decoration: const InputDecoration(
            hintText: '输入 EXIT',
            border: OutlineInputBorder(),
          ),
        ),
      ),
    ).result;
    if (ok == true) {
      if (typed.trim() == 'EXIT') {
        Pop.toast(const ToastConfig.text('已退出登录'));
      } else {
        Pop.toast(
          const ToastConfig.text('请输入 EXIT 确认', type: ToastType.warn),
        );
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
