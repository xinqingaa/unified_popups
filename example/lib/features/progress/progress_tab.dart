import 'package:flutter/material.dart';
import '../../app/app_pop.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/section_header.dart';

class ProgressTab extends StatefulWidget {
  const ProgressTab({super.key});

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  DateTime? _rangeStart;
  String _metric = '体重';

  Future<void> _pickStartDate() async {
    final date = await AppPop.date(
      initialDate: _rangeStart ?? DateTime.now(),
      minDate: DateTime(2020),
      maxDate: DateTime.now(),
      title: '选择区间起始日',
    );
    if (date != null) {
      setState(() => _rangeStart = date);
      AppPop.info(
        '起始日：${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      );
    }
  }

  Future<void> _openMetricSheet() async {
    final picked = await AppPop.sheet<String>(
      title: '数据指标',
      builder: (context, handle) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final m in ['体重', '体脂', '围度', '静息心率'])
            ListTile(
              title: Text(m),
              onTap: () => handle.complete(m),
            ),
        ],
      ),
    );
    if (picked != null) {
      setState(() => _metric = picked);
      AppPop.info('已切换：$_metric');
    }
  }

  Future<void> _exportReport() async {
    await AppPop.runLoading<void>(
      message: '导出周报…',
      task: Future<void>.delayed(const Duration(milliseconds: 1200)),
    );
    AppPop.success('周报已生成');
  }

  @override
  Widget build(BuildContext context) {
    final startLabel = _rangeStart == null
        ? '未选择'
        : '${_rangeStart!.year}-${_rangeStart!.month.toString().padLeft(2, '0')}-${_rangeStart!.day.toString().padLeft(2, '0')}';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: '身体数据',
          subtitle: 'Date · Loading until · Toast',
        ),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: _metric,
                value: _metric == '体重' ? '68.2' : '18.4',
                unit: _metric == '体重' ? 'kg' : '%',
                icon: Icons.monitor_weight_outlined,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: MetricCard(
                label: '本周训练',
                value: '4',
                unit: '次',
                icon: Icons.calendar_month_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SectionHeader(
          title: '区间与导出',
          subtitle: '起始日：$startLabel',
        ),
        FilledButton.tonalIcon(
          onPressed: _pickStartDate,
          icon: const Icon(Icons.date_range),
          label: const Text('选择区间起始日'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _openMetricSheet,
          icon: const Icon(Icons.tune),
          label: Text('切换指标（当前：$_metric）'),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _exportReport,
          icon: const Icon(Icons.ios_share),
          label: const Text('导出周报'),
        ),
      ],
    );
  }
}
