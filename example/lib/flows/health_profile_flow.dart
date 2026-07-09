import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

/// 健康档案向导：资料(replace) → 风险问卷(lifecycle) → 确认提交。
class HealthProfileFlow {
  HealthProfileFlow._();

  static Future<void> open() async {
    final controller = FlowSheetController<_HealthResult>();
    final draft = _HealthDraft();
    final result = await Pop.flowSheet<_HealthResult>(
      controller: controller,
      maxHeight: const SheetDimension.fraction(0.9),
      dragDismissMode: SheetDragDismissMode.handleOnly,
      barrierDismissible: false,
      initialPage: _BasicsStepPage(controller: controller, draft: draft),
    );
    if (result != null) {
      Pop.toast(
        '档案已保存：${result.name} · 风险等级 ${result.riskLevel}',
        toastType: ToastType.success,
      );
    } else {
      Pop.toast('已退出健康档案');
    }
  }
}

class _HealthDraft {
  String name = '';
  String phone = '';
  int riskLevel = 1;
}

class _HealthResult {
  const _HealthResult({
    required this.name,
    required this.phone,
    required this.riskLevel,
  });

  final String name;
  final String phone;
  final int riskLevel;
}

class _BasicsStepPage extends FlowSheetPage<void> {
  const _BasicsStepPage({
    required this.controller,
    required this.draft,
  }) : super(
          id: 'health_basics',
          dragDismissMode: SheetDragDismissMode.handleOnly,
        );

  final FlowSheetController<_HealthResult> controller;
  final _HealthDraft draft;

  @override
  State<_BasicsStepPage> createState() => _BasicsStepPageState();
}

class _BasicsStepPageState extends FlowSheetPageState<_BasicsStepPage, void> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.draft.name);
    _phoneCtrl = TextEditingController(text: widget.draft.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _next() {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.length < 8) {
      setState(() => _error = '请填写姓名与有效手机号');
      return;
    }
    widget.draft.name = name;
    widget.draft.phone = phone;
    nav.replace(
      _RiskStepPage(controller: widget.controller, draft: widget.draft),
    );
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
              const Expanded(
                child: Text(
                  '1/3 基本信息',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () => widget.controller.closeAll(),
                child: const Text('退出'),
              ),
            ],
          ),
          const Text(
            '下一步使用 nav.replace，栈中不会留下本页。',
            style: TextStyle(color: Colors.black54, height: 1.3),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: '姓名',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: '手机号',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _next,
            child: const Text('下一步'),
          ),
        ],
      ),
    );
  }
}

class _RiskStepPage extends FlowSheetPage<void> {
  const _RiskStepPage({
    required this.controller,
    required this.draft,
  }) : super(
          id: 'health_risk',
          dragDismissMode: SheetDragDismissMode.contentWhenAtTop,
        );

  final FlowSheetController<_HealthResult> controller;
  final _HealthDraft draft;

  @override
  State<_RiskStepPage> createState() => _RiskStepPageState();
}

class _RiskStepPageState extends FlowSheetPageState<_RiskStepPage, void> {
  Timer? _pollTimer;
  int _tick = 0;

  @override
  void onShow() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _tick++);
    });
  }

  @override
  void onHide() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '2/3 健康评估',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '监测 #$_tick',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'onShow 启动假轮询，onHide 停止。滚到顶再下拉可关 Sheet。',
            style: TextStyle(color: Colors.black54, height: 1.3),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 10,
            itemBuilder: (context, index) {
              final level = index + 1;
              final selected = widget.draft.riskLevel == level;
              return Card(
                color: selected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: ListTile(
                  title: Text('运动风险等级 $level'),
                  subtitle: Text('示例题 ${index + 1}：请根据自身情况选择。'),
                  trailing: selected
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () => setState(() => widget.draft.riskLevel = level),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton(
              onPressed: () {
                nav.push(
                  _ReviewStepPage(
                    controller: widget.controller,
                    draft: widget.draft,
                  ),
                );
              },
              child: const Text('下一步：确认提交'),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewStepPage extends FlowSheetPage<void> {
  const _ReviewStepPage({
    required this.controller,
    required this.draft,
  }) : super(
          id: 'health_review',
          dragDismissMode: SheetDragDismissMode.handleOnly,
        );

  final FlowSheetController<_HealthResult> controller;
  final _HealthDraft draft;

  @override
  State<_ReviewStepPage> createState() => _ReviewStepPageState();
}

class _ReviewStepPageState extends FlowSheetPageState<_ReviewStepPage, void> {
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    widget.controller.closeAll(
      _HealthResult(
        name: widget.draft.name,
        phone: widget.draft.phone,
        riskLevel: widget.draft.riskLevel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _submitting ? null : () => nav.pop(),
                icon: const Icon(Icons.arrow_back),
              ),
              const Expanded(
                child: Text(
                  '3/3 确认提交',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          ListTile(title: const Text('姓名'), subtitle: Text(draft.name)),
          ListTile(title: const Text('手机号'), subtitle: Text(draft.phone)),
          ListTile(
            title: const Text('风险等级'),
            subtitle: Text('${draft.riskLevel}'),
          ),
          const Spacer(),
          if (_submitting)
            const Center(child: CircularProgressIndicator())
          else ...[
            OutlinedButton(
              onPressed: () => widget.controller.closeAll(),
              child: const Text('取消'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _submit,
              child: const Text('提交并关闭'),
            ),
          ],
        ],
      ),
    );
  }
}
