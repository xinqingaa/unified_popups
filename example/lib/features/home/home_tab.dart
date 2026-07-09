import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

import '../../widgets/metric_card.dart';
import '../../widgets/section_header.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  Future<void> _syncHealth() async {
    Pop.loading(message: '同步健康数据…');
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    Pop.hideLoading();
    Pop.toast('同步完成', toastType: ToastType.success);
  }

  Future<void> _checkIn() async {
    final ok = await Pop.confirm(
      title: '完成今日打卡',
      content: '确认将今日训练标记为已完成？打卡后会计入连续天数。',
      confirmText: '打卡',
      cancelText: '取消',
    );
    if (ok == true) {
      Pop.toast(
        '打卡成功，继续保持！',
        toastType: ToastType.success,
        position: PopupPosition.bottom,
      );
    }
  }

  void _skipRestDay() {
    Pop.toast(
      '今日目标尚未达成，建议完成至少 20 分钟活动',
      toastType: ToastType.warn,
    );
  }

  void _syncFailedDemo() {
    Pop.toast(
      '网络异常，健康数据同步失败',
      toastType: ToastType.error,
      position: PopupPosition.top,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: '今日概览',
          subtitle: '用真实动机触发 toast / loading / confirm',
        ),
        const Row(
          children: [
            Expanded(
              child: MetricCard(
                label: '步数',
                value: '6,842',
                unit: '步',
                icon: Icons.directions_walk,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: '消耗',
                value: '312',
                unit: 'kcal',
                icon: Icons.local_fire_department_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const MetricCard(
          label: '连续打卡',
          value: '12',
          unit: '天',
          icon: Icons.emoji_events_outlined,
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: '快捷操作'),
        FilledButton.icon(
          onPressed: _syncHealth,
          icon: const Icon(Icons.sync),
          label: const Text('同步健康数据'),
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: _checkIn,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('完成今日打卡'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _skipRestDay,
          icon: const Icon(Icons.bedtime_outlined),
          label: const Text('跳过休息日（警告 toast）'),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _syncFailedDemo,
          icon: const Icon(Icons.error_outline),
          label: const Text('模拟同步失败（顶部 error toast）'),
        ),
      ],
    );
  }
}
