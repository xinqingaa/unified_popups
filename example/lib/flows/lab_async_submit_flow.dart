import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

/// Lab 真实场景：三页 FlowSheet + 首页 Confirm + 末页键盘 + 关层后异步 Toast。
///
/// 完成时立刻关闭 FlowSheet，再弹「提交中」Toast；模拟接口返回后用同 key
/// `updateExisting` 把文案改成「提交成功」，再按 lifetime 消失。
///
/// 不用 `until` 单独扛「变文案」：`until` 只绑定关闭时机，不会改 message。
abstract final class LabAsyncSubmitFlow {
  static const _toastKey = 'lab.flow.async_submit';

  static Future<void> open() async {
    final controller = FlowSheetController<void>();
    await Pop.flowSheet<void>(
      FlowSheetConfig<void>(
        controller: controller,
        header: const SheetHeaderConfig(
          title: '提交申请',
          showCloseButton: true,
        ),
        size: const SheetSizeConfig(
          maxHeight: SheetDimension.fraction(0.88),
        ),
        drag: const SheetDragConfig(mode: SheetDragDismissMode.handleOnly),
        keyboard: const SheetKeyboardConfig(adjustForKeyboard: true),
        barrier: const PopupBarrierConfig(dismissible: true),
        initialPage: _IntroPage(controller: controller),
      ),
    ).result;
  }

  static Future<void> _submitAfterClose(String note) async {
    final api = Future<void>.delayed(const Duration(milliseconds: 1600));
    Pop.toast(
      const ToastConfig.text(
        '提交中',
        behavior: PopupBehaviorConfig(
          key: _toastKey,
          conflictPolicy: PopupConflictPolicy.updateExisting,
          backPolicy: PopupBackPolicy.ignore,
        ),
        lifetime: PopupLifetime.manual(),
      ),
    );
    await api;
    final successText = note.isEmpty ? '提交成功' : '提交成功 · $note';
    Pop.toast(
      ToastConfig.text(
        successText,
        type: ToastType.success,
        behavior: const PopupBehaviorConfig(
          key: _toastKey,
          conflictPolicy: PopupConflictPolicy.updateExisting,
          backPolicy: PopupBackPolicy.ignore,
        ),
        lifetime: const PopupLifetime.after(Duration(milliseconds: 1400)),
      ),
    );
  }
}

class _IntroPage extends FlowSheetPage<void> {
  const _IntroPage({required this.controller})
      : super(
          id: 'lab.async.intro',
          dragDismissMode: SheetDragDismissMode.handleOnly,
        );

  final FlowSheetController<void> controller;

  @override
  FlowSheetPageState<_IntroPage, void> createState() => _IntroPageState();
}

class _IntroPageState extends FlowSheetPageState<_IntroPage, void> {
  Future<void> _confirmAndContinue() async {
    final ok = await Pop.confirm(
      const ConfirmConfig(
        title: '开始填写？',
        content: '确认后进入后续步骤。取消则留在本页。',
        confirmAction: ConfirmAction.text('开始'),
        cancelAction: ConfirmAction.text('取消'),
      ),
    ).result;
    if (!mounted || ok != true) return;
    widget.controller.push(_DetailPage(controller: widget.controller));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('1 / 3 说明', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            '右上角关闭始终可用。点下方按钮才会弹出 Confirm；'
            '确认后进入第 2 页。',
          ),
          const Spacer(),
          FilledButton(
            onPressed: _confirmAndContinue,
            child: const Text('打开 Confirm 并继续'),
          ),
        ],
      ),
    );
  }
}

class _DetailPage extends FlowSheetPage<void> {
  const _DetailPage({required this.controller})
      : super(
          id: 'lab.async.detail',
          dragDismissMode: SheetDragDismissMode.handleOnly,
          maintainState: true,
        );

  final FlowSheetController<void> controller;

  @override
  FlowSheetPageState<_DetailPage, void> createState() => _DetailPageState();
}

class _DetailPageState extends FlowSheetPageState<_DetailPage, void> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('2 / 3 确认信息', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('中间页。系统返回应回到第 1 页，而不是关掉整张 Sheet。'),
          const Spacer(),
          FilledButton(
            onPressed: () => widget.controller.push(
              _SubmitPage(controller: widget.controller),
            ),
            child: const Text('下一步'),
          ),
          TextButton(
            onPressed: () => widget.controller.pop(),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }
}

class _SubmitPage extends FlowSheetPage<void> {
  const _SubmitPage({required this.controller})
      : super(
          id: 'lab.async.submit',
          dragDismissMode: SheetDragDismissMode.handleOnly,
        );

  final FlowSheetController<void> controller;

  @override
  FlowSheetPageState<_SubmitPage, void> createState() => _SubmitPageState();
}

class _SubmitPageState extends FlowSheetPageState<_SubmitPage, void> {
  late final TextEditingController _noteCtrl;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void onShow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _finish() {
    final note = _noteCtrl.text.trim();
    widget.controller.closeAll();
    unawaited(LabAsyncSubmitFlow._submitAfterClose(note));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('3 / 3 备注并提交', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('本页会拉起键盘。点「完成」后立刻关 Sheet，再走异步 Toast。'),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            focusNode: _focusNode,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _finish(),
            decoration: const InputDecoration(
              labelText: '备注',
              hintText: '随便写点什么',
              border: OutlineInputBorder(),
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _finish,
            child: const Text('完成'),
          ),
          TextButton(
            onPressed: () => widget.controller.pop(),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }
}
