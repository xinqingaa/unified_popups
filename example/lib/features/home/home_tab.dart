import 'package:flutter/material.dart';

import '../../app/app_pop.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/section_header.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  Future<void> _syncHealth() async {
    final sync = Future<void>.delayed(const Duration(milliseconds: 1800));
    final loading = AppPop.showLoading('连接健康服务…');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    loading.update('拉取步数与消耗…');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    loading.update('写入本地…', until: sync);
    await sync;
    AppPop.success('同步完成');
  }

  Future<void> _checkIn() async {
    final ok = await AppPop.confirm(
      title: '完成今日打卡',
      content: '确认将今日训练标记为已完成？打卡后会计入连续天数。',
      confirmText: '打卡',
    );
    if (ok) {
      AppPop.success('打卡成功，继续保持！');
    }
  }

  void _skipRestDay() {
    AppPop.warning('今日目标尚未达成，建议完成至少 20 分钟活动');
  }

  void _syncFailedDemo() {
    AppPop.error('网络异常，健康数据同步失败');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: '今日概览',
          subtitle: 'Loading 分阶段更新 · Confirm · Toast',
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
