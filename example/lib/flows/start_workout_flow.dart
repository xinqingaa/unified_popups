import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unified_popups/unified_popups.dart';

import '../app/app_pop.dart';

/// 开始训练 FlowSheet：课程列表 → 详情组数 → 确认码。
///
/// 展示 push/pop、completeCurrent+closeAll、按页 dragDismissMode、maintainState。
class StartWorkoutFlow {
  StartWorkoutFlow._();

  static Future<void> open() async {
    final controller = FlowSheetController<_WorkoutResult>();
    final result = await AppPop.flowSheet<_WorkoutResult>(
      controller: controller,
      size: const SheetSizeConfig(
        maxHeight: SheetDimension.fraction(0.88),
      ),
      drag: const SheetDragConfig(mode: SheetDragDismissMode.handleOnly),
      initialPage: _WorkoutListPage(controller: controller),
    );
    if (result != null) {
      AppPop.success('已开始「${result.title}」· ${result.sets} 组');
    } else {
      AppPop.info('已取消训练');
    }
  }
}

class _WorkoutResult {
  const _WorkoutResult({required this.title, required this.sets});

  final String title;
  final int sets;
}

class _WorkoutPlan {
  const _WorkoutPlan({
    required this.id,
    required this.title,
    required this.level,
    required this.duration,
    required this.summary,
  });

  final String id;
  final String title;
  final String level;
  final String duration;
  final String summary;
}

const _demoPlans = <_WorkoutPlan>[
  _WorkoutPlan(
    id: 'W-101',
    title: '晨间激活',
    level: '初级',
    duration: '20 分钟',
    summary: '全身唤醒 · 低冲击。适合久坐后启动，含动态拉伸与核心激活。',
  ),
  _WorkoutPlan(
    id: 'W-202',
    title: '力量循环',
    level: '中级',
    duration: '35 分钟',
    summary: '深蹲 / 推举 / 划船超级组。请确认护具与可用重量。',
  ),
  _WorkoutPlan(
    id: 'W-303',
    title: 'HIIT 燃脂',
    level: '进阶',
    duration: '25 分钟',
    summary: '高强度间歇。心率会快速上升，有不适请立即停止。',
  ),
];

class _WorkoutListPage extends FlowSheetPage<void> {
  const _WorkoutListPage({required this.controller})
      : super(
          id: 'workout_list',
          maintainState: true,
          dragDismissMode: SheetDragDismissMode.handleOnly,
        );

  final FlowSheetController<_WorkoutResult> controller;

  @override
  State<_WorkoutListPage> createState() => _WorkoutListPageState();
}

class _WorkoutListPageState extends FlowSheetPageState<_WorkoutListPage, void> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '选择训练计划',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => widget.controller.closeAll(),
              child: const Text('关闭'),
            ),
          ],
        ),
        Text(
          '仅拖条/标题可下拉关闭（handleOnly）。选中后 push 详情，列表 maintainState 保活。',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: _demoPlans.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final plan = _demoPlans[index];
              return ListTile(
                title: Text(plan.title),
                subtitle: Text('${plan.level} · ${plan.duration}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  nav.push<_WorkoutResult?>(
                    _WorkoutDetailPage(
                      plan: plan,
                      controller: widget.controller,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WorkoutDetailPage extends FlowSheetPage<_WorkoutResult?> {
  const _WorkoutDetailPage({
    required this.plan,
    required this.controller,
  }) : super(
          id: 'workout_detail',
          dragDismissMode: SheetDragDismissMode.contentWhenAtTop,
        );

  final _WorkoutPlan plan;
  final FlowSheetController<_WorkoutResult> controller;

  @override
  State<_WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState
    extends FlowSheetPageState<_WorkoutDetailPage, _WorkoutResult?> {
  int _sets = 3;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => nav.pop(),
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                plan.title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            children: [
              ListTile(title: const Text('计划编号'), subtitle: Text(plan.id)),
              ListTile(title: const Text('难度'), subtitle: Text(plan.level)),
              ListTile(title: const Text('时长'), subtitle: Text(plan.duration)),
              ListTile(
                title: const Text('组数'),
                subtitle: Text('$_sets 组'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => setState(() {
                        if (_sets > 1) _sets--;
                      }),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _sets++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${plan.summary}\n\n'
                  '向下滚动查看注意事项……\n\n'
                  '1. 训练前请充分热身，避免急性损伤。\n'
                  '2. 如有心血管疾病请先咨询医生。\n'
                  '3. 本页 contentWhenAtTop：滚到顶再下拉可关整个 Sheet。\n'
                  '4. 系统返回优先 pop 本页，而不是直接关掉 Sheet。\n'
                  '5. 确认后进入确认码页，成功时 completeCurrent + closeAll。\n\n'
                  '${List.generate(6, (i) => '补充说明 ${i + 1}：用于演示可滚动详情。').join('\n\n')}',
                  style: const TextStyle(height: 1.45),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton(
              onPressed: () async {
                final verified = await nav.push<bool>(
                  _ConfirmCodePage(plan: plan, sets: _sets),
                );
                if (verified == true && mounted) {
                  widget.controller.closeAll(
                    _WorkoutResult(title: plan.title, sets: _sets),
                  );
                }
              },
              child: const Text('确认开始'),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfirmCodePage extends FlowSheetPage<bool> {
  const _ConfirmCodePage({
    required this.plan,
    required this.sets,
  }) : super(
          id: 'confirm_code',
          dragDismissMode: SheetDragDismissMode.handleOnly,
        );

  final _WorkoutPlan plan;
  final int sets;

  @override
  State<_ConfirmCodePage> createState() => _ConfirmCodePageState();
}

class _ConfirmCodePageState extends FlowSheetPageState<_ConfirmCodePage, bool> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.length < 4) {
      setState(() => _error = '请输入至少 4 位确认码（演示任意数字即可）');
      return;
    }
    nav.completeCurrent(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => nav.pop(false),
                icon: const Icon(Icons.arrow_back),
              ),
              const Expanded(
                child: Text(
                  '确认开始',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Text(
            '${widget.plan.title} · ${widget.sets} 组',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: '确认码',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          Text(
            '键盘弹出时 Sheet 会上移。本页 handleOnly，避免与输入冲突。',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _submit,
            child: const Text('验证并开始'),
          ),
        ],
      ),
    );
  }
}
