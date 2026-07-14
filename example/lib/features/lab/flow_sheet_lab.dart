import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

import '../../flows/health_profile_flow.dart';
import '../../flows/start_workout_flow.dart';
import 'lab_section.dart';
import 'lab_shell.dart';

/// FlowSheet：链到产品 Flow + 返回顺序说明。
class FlowSheetLabPage extends StatelessWidget {
  const FlowSheetLabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: labAppBar(context, 'Lab · FlowSheet'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          LabBanner(
            text: 'FlowSheet = 外层统一 PopupHandle + 内部 Navigator。'
                '系统返回：栈深>1 先 pop 内页；栈底再关整 Sheet。'
                'Controller 为 one-shot，下次打开请新建。',
          ),
          SizedBox(height: 8),
          LabStatusBar(),
          LabGroup(
            title: '验收要点',
            children: [
              LabNote(
                '1. 打开多页 Flow 后按系统返回，应先退内页而不是整页关掉。\n'
                '2. 在末页完成流程，验证 completeCurrent / closeAll 结果 Toast。\n'
                '3. 中途拖关或点遮罩，结果应为取消。\n'
                '4. 各页可有不同 dragDismissMode（见训练 Flow）。',
              ),
            ],
          ),
          LabGroup(
            title: '全屏 / 半屏',
            children: [
              LabAction(
                label: '全屏迷你 Flow',
                subtitle: 'fraction(1) · 接近全屏页',
                onPressed: _openFullScreenFlow,
              ),
              LabAction(
                label: '半屏迷你 Flow',
                subtitle: 'fraction(0.55) · 返回顺序',
                outlined: true,
                tonal: true,
                onPressed: _openMiniFlow,
              ),
            ],
          ),
          LabGroup(
            title: '产品 Flow',
            children: [
              LabAction(
                label: '开始训练 Flow',
                subtitle: '列表 → 详情 → 确认码 · handleOnly',
                onPressed: StartWorkoutFlow.open,
              ),
              LabAction(
                label: '健康档案 Flow',
                subtitle: '多步表单 · 键盘避让',
                outlined: true,
                onPressed: HealthProfileFlow.open,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> _openFullScreenFlow() async {
    final controller = FlowSheetController<String>();
    final result = await Pop.flowSheet<String>(
      controller: controller,
      maxHeight: const SheetDimension.fraction(1),
      barrierDismissible: false,
      initialPage: _MiniPageA(controller: controller),
    );
    Pop.toast(
      result == null ? '全屏 Flow 取消' : '全屏 Flow 结果：$result',
      toastType: result == null ? ToastType.warn : ToastType.success,
    );
  }

  static Future<void> _openMiniFlow() async {
    final controller = FlowSheetController<String>();
    final result = await Pop.flowSheet<String>(
      controller: controller,
      maxHeight: const SheetDimension.fraction(0.55),
      barrierDismissible: true,
      initialPage: _MiniPageA(controller: controller),
    );
    Pop.toast(
      result == null ? '迷你 Flow 取消' : '迷你 Flow 结果：$result',
      toastType: result == null ? ToastType.warn : ToastType.success,
    );
  }
}

class _MiniPageA extends FlowSheetPage<void> {
  const _MiniPageA({required this.controller})
      : super(id: 'lab.mini.a', maintainState: true);

  final FlowSheetController<String> controller;

  @override
  FlowSheetPageState<_MiniPageA, void> createState() => _MiniPageAState();
}

class _MiniPageAState extends FlowSheetPageState<_MiniPageA, void> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('第 1 页', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('按系统返回应关闭整个 Flow（栈底）。点下方进入第 2 页后再返回，应只退回本页。'),
        const Spacer(),
        FilledButton(
          onPressed: () =>
              widget.controller.push(_MiniPageB(controller: widget.controller)),
          child: const Text('进入第 2 页'),
        ),
      ],
    );
  }
}

class _MiniPageB extends FlowSheetPage<String> {
  const _MiniPageB({required this.controller})
      : super(id: 'lab.mini.b', maintainState: true);

  final FlowSheetController<String> controller;

  @override
  FlowSheetPageState<_MiniPageB, String> createState() => _MiniPageBState();
}

class _MiniPageBState extends FlowSheetPageState<_MiniPageB, String> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('第 2 页', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('系统返回 → 回到第 1 页。完成则 closeAll。'),
        const Spacer(),
        FilledButton(
          onPressed: () {
            widget.controller.completeCurrent('lab-ok');
            widget.controller.closeAll('lab-ok');
          },
          child: const Text('completeCurrent + closeAll'),
        ),
        TextButton(
          onPressed: () => widget.controller.pop(),
          child: const Text('pop 回上一页'),
        ),
      ],
    );
  }
}
