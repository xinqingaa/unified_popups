import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

/// 课程详情二级页：打开弹框后返回 / 再 push，验证路由切换自动关闭。
class CourseDetailPage extends StatelessWidget {
  const CourseDetailPage({
    super.key,
    required this.title,
    required this.meta,
  });

  final String title;
  final String meta;

  Future<void> _adjustDifficulty() async {
    final level = await Pop.sheet<String>(
      title: '调整难度',
      showDragHandle: true,
      childBuilder: (dismiss) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final label in ['初级', '中级', '进阶'])
            ListTile(
              title: Text(label),
              onTap: () => dismiss(label),
            ),
        ],
      ),
    );
    if (level != null) {
      Pop.toast('难度已设为 $level');
    }
  }

  Future<void> _deletePlan(BuildContext context) async {
    final ok = await Pop.confirm(
      title: '删除训练计划',
      content: '确定删除「$title」？删除后不可恢复。',
      confirmText: '删除',
      cancelText: '取消',
      confirmBgColor: Colors.red,
    );
    if (ok == true && context.mounted) {
      Pop.toast('计划已删除', toastType: ToastType.success);
      Navigator.of(context).pop();
    }
  }

  void _openGuide(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _WorkoutGuidePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                '打开下方弹框后点返回，或进入「训练须知」再返回：'
                'sheet / confirm 会随路由切换自动关闭（PopupRouteObserver）。',
                style: TextStyle(height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('课程信息'),
            subtitle: Text(meta),
          ),
          const Divider(),
          FilledButton.tonalIcon(
            onPressed: _adjustDifficulty,
            icon: const Icon(Icons.tune),
            label: const Text('调整难度（Sheet）'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _deletePlan(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('删除计划（Confirm）'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => _openGuide(context),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('查看训练须知（再 push 一级）'),
          ),
        ],
      ),
    );
  }
}

class _WorkoutGuidePage extends StatelessWidget {
  const _WorkoutGuidePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('训练须知')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          '从课程详情打开弹框后进入本页，再返回：'
          '上一页打开的 sheet/confirm 应已被路由观察者关闭。\n\n'
          '1. 训练前充分热身。\n'
          '2. 如有不适请立即停止。\n'
          '3. 保持呼吸节奏，避免憋气发力。',
          style: TextStyle(height: 1.5),
        ),
      ),
    );
  }
}
