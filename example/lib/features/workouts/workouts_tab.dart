import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

import '../../app/fit_pulse_metrics.dart';
import '../../flows/start_workout_flow.dart';
import '../../widgets/section_header.dart';
import 'course_detail_page.dart';

class _Course {
  const _Course({
    required this.title,
    required this.meta,
    required this.menuAnchor,
  });

  final String title;
  final String meta;
  final PopupAnchorController menuAnchor;
}

class WorkoutsTab extends StatefulWidget {
  const WorkoutsTab({super.key});

  @override
  State<WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends State<WorkoutsTab> {
  String _filter = '全部';
  bool _vibrateReminder = true;

  late final List<_Course> _courses = [
    _Course(
      title: '晨间激活',
      meta: '初级 · 20 分钟',
      menuAnchor: PopupAnchorController(),
    ),
    _Course(
      title: '力量循环',
      meta: '中级 · 35 分钟',
      menuAnchor: PopupAnchorController(),
    ),
    _Course(
      title: 'HIIT 燃脂',
      meta: '进阶 · 25 分钟',
      menuAnchor: PopupAnchorController(),
    ),
  ];

  Future<void> _openFilter() async {
    final scheme = Theme.of(context).colorScheme;
    final picked = await Pop.sheet<String>(
      title: '筛选课程',
      showDragHandle: true,
      dragHandleColor: scheme.primary,
      dragDismissMode: SheetDragDismissMode.contentWhenAtTop,
      maxHeight: const SheetDimension.fraction(0.55),
      dockToEdge: true,
      edgeGap: FitPulseMetrics.sheetDockEdgeGap,
      childBuilder: (dismiss) => ListView(
        children: [
          for (final label in ['全部', '初级', '中级', '进阶', '有氧', '力量', '拉伸', '核心'])
            ListTile(
              title: Text(label),
              trailing: _filter == label
                  ? Icon(Icons.check, color: scheme.primary)
                  : null,
              onTap: () => dismiss(label),
            ),
        ],
      ),
    );
    if (picked != null) {
      setState(() => _filter = picked);
      Pop.toast('已筛选：$_filter');
    }
  }

  Future<void> _openQuickActions() async {
    await Pop.sheet<void>(
      direction: SheetDirection.right,
      maxWidth: const SheetDimension.fraction(0.72),
      showDragHandle: false,
      dragDismissMode: SheetDragDismissMode.fullBody,
      title: '快捷动作',
      childBuilder: (dismiss) => ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('休息计时器'),
            onTap: () {
              dismiss();
              Pop.toast('已启动 60s 休息计时');
            },
          ),
          ListTile(
            leading: const Icon(Icons.music_note_outlined),
            title: const Text('训练歌单'),
            onTap: () {
              dismiss();
              Pop.toast('已打开歌单');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openNoteSheet() async {
    await Pop.sheet<void>(
      title: '训练感受',
      showDragHandle: true,
      adjustForKeyboard: true,
      dragDismissMode: SheetDragDismissMode.handleOnly,
      maxHeight: const SheetDimension.fraction(0.5),
      childBuilder: (dismiss) => Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '今天膝盖感觉如何？有没有力竭…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                dismiss();
                Pop.toast('备注已保存', toastType: ToastType.success);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCourseMenu(PopupAnchorController anchor) async {
    final action = await Pop.menu<String>(
      anchor: anchor,
      builder: (dismiss) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.star_outline),
            title: const Text('收藏'),
            onTap: () => dismiss('fav'),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.share_outlined),
            title: const Text('分享'),
            onTap: () => dismiss('share'),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('删除计划', style: TextStyle(color: Colors.red)),
            onTap: () => dismiss('delete'),
          ),
        ],
      ),
    );
    if (action == null) return;
    if (action == 'delete') {
      final ok = await Pop.confirm(
        title: '删除训练计划',
        content: '删除后不可恢复，确定继续？',
        confirmText: '删除',
        cancelText: '取消',
        style: const ConfirmStyle(
          confirmStyle: TextStyle(color: Colors.red),
        ),
      );
      if (ok == true) {
        Pop.toast('计划已删除', toastType: ToastType.success);
      }
      return;
    }
    Pop.toast(action == 'fav' ? '已收藏' : '分享链接已复制');
  }

  void _toggleReminder() {
    setState(() => _vibrateReminder = !_vibrateReminder);
    Pop.toast(_vibrateReminder ? '已开启震动提醒' : '已切换为静音提醒');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(
          title: '训练课程',
          subtitle: '当前筛选：$_filter · 含 sheet / menu / FlowSheet',
          trailing: TextButton(onPressed: _openFilter, child: const Text('筛选')),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => StartWorkoutFlow.open(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始训练'),
            ),
            OutlinedButton(
              onPressed: _openQuickActions,
              child: const Text('侧边快捷'),
            ),
            OutlinedButton(
              onPressed: _openNoteSheet,
              child: const Text('写感受'),
            ),
            TextButton(
              onPressed: _toggleReminder,
              child: const Text('提醒切换 toast'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._courses.map((course) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(course.title),
              subtitle: Text(course.meta),
              trailing: PopupAnchor(
                controller: course.menuAnchor,
                child: IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () => _openCourseMenu(course.menuAnchor),
                ),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CourseDetailPage(
                      title: course.title,
                      meta: course.meta,
                    ),
                  ),
                );
              },
            ),
          );
        }),
        const SizedBox(height: 8),
        Text(
          '提示：筛选 Sheet 贴在底栏上方（dockToEdge + 与 NavigationBar 同高的 edgeGap），'
          '底栏仍可切换；点课程进入详情可验证路由切换关弹框。',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
