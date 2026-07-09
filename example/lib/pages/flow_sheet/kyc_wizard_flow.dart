import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

/// 演示 B：开户 / KYC 向导。
///
/// 资料(replace) → 风险问卷(contentWhenAtTop + 生命周期轮询) → 确认提交(closeAll)
class KycWizardFlow {
  KycWizardFlow._();

  static Future<void> open() async {
    final controller = FlowSheetController<_KycResult>();
    final draft = _KycDraft();
    final result = await Pop.flowSheet<_KycResult>(
      controller: controller,
      maxHeight: const SheetDimension.fraction(0.9),
      dragDismissMode: SheetDragDismissMode.handleOnly,
      barrierDismissible: false,
      initialPage: _ProfileStepPage(controller: controller, draft: draft),
    );
    if (result != null) {
      Pop.toast(
        'KYC 完成：${result.name} / ${result.phone} / 风险${result.riskLevel}',
        toastType: ToastType.success,
      );
    } else {
      Pop.toast('已退出开户流程');
    }
  }
}

class _KycDraft {
  String name = '';
  String phone = '';
  int riskLevel = 1;
}

class _KycResult {
  const _KycResult({
    required this.name,
    required this.phone,
    required this.riskLevel,
  });

  final String name;
  final String phone;
  final int riskLevel;
}

class _ProfileStepPage extends FlowSheetPage<void> {
  const _ProfileStepPage({
    required this.controller,
    required this.draft,
  }) : super(
          id: 'kyc_profile',
          dragDismissMode: SheetDragDismissMode.handleOnly,
        );

  final FlowSheetController<_KycResult> controller;
  final _KycDraft draft;

  @override
  State<_ProfileStepPage> createState() => _ProfileStepPageState();
}

class _ProfileStepPageState extends FlowSheetPageState<_ProfileStepPage, void> {
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
    // replace：不可回到过期的资料页
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
                  '1/3 基本资料',
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
            '下一步使用 nav.replace，栈中不会留下本页，系统返回不会回到过期资料。',
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
          id: 'kyc_risk',
          dragDismissMode: SheetDragDismissMode.contentWhenAtTop,
        );

  final FlowSheetController<_KycResult> controller;
  final _KycDraft draft;

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
                  '2/3 风险问卷',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '轮询 #$_tick',
                style: const TextStyle(color: Colors.deepPurple),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'onShow 启动假轮询，onHide/离开时停止。滚到顶再下拉可关 Sheet（contentWhenAtTop）。',
            style: TextStyle(color: Colors.black54, height: 1.3),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 12,
            itemBuilder: (context, index) {
              final level = index + 1;
              final selected = widget.draft.riskLevel == level;
              return Card(
                color: selected ? Colors.deepPurple.shade50 : null,
                child: ListTile(
                  title: Text('风险偏好等级 $level'),
                  subtitle: Text('示例题目 ${index + 1}：请根据自身承受能力选择。'),
                  trailing: selected
                      ? const Icon(Icons.check_circle, color: Colors.deepPurple)
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
          id: 'kyc_review',
          dragDismissMode: SheetDragDismissMode.handleOnly,
        );

  final FlowSheetController<_KycResult> controller;
  final _KycDraft draft;

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
      _KycResult(
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
              child: const Text('取消开户'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _submit,
              child: const Text('提交并关闭 FlowSheet'),
            ),
          ],
        ],
      ),
    );
  }
}
