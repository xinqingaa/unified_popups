import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

/// 集中回归 v2 全局 facade、handle、堆叠、返回键和路由归属。
class PopupRuntimeLabPage extends StatefulWidget {
  const PopupRuntimeLabPage({super.key});

  @override
  State<PopupRuntimeLabPage> createState() => _PopupRuntimeLabPageState();
}

class _PopupRuntimeLabPageState extends State<PopupRuntimeLabPage> {
  PopupHandle<void>? _externalHandle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lab · Popup Runtime')),
      body: AnimatedBuilder(
        animation: Pop.runtime.controller,
        builder: (context, _) {
          final count = Pop.runtime.controller.entries
              .where((entry) => entry.state.isActive || entry.state.isMounted)
              .length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '当前活跃弹窗：$count\n'
                    '无需 context；系统返回键会先交给最上层弹窗。',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _openCustom,
                child: const Text('打开自定义弹窗（保留 handle）'),
              ),
              OutlinedButton(
                onPressed: _externalHandle?.isActive == true
                    ? () => _externalHandle?.dismiss()
                    : null,
                child: const Text('通过 handle 从外部关闭'),
              ),
              const Divider(height: 32),
              FilledButton.tonal(
                onPressed: _openStack,
                child: const Text('Sheet 上堆叠 Confirm + Toast'),
              ),
              OutlinedButton(
                onPressed: _updateLoading,
                child: const Text('重复调用 Loading：更新内容并重设计时'),
              ),
              OutlinedButton(
                onPressed: _eventControlledToast,
                child: const Text('由 Future 事件关闭 Toast'),
              ),
              const Divider(height: 32),
              const OutlinedButton(
                onPressed: Pop.dismissTop,
                child: Text('关闭最上层弹窗'),
              ),
              const OutlinedButton(
                onPressed: Pop.dismissAll,
                child: Text('关闭全部弹窗'),
              ),
              const SizedBox(height: 12),
              const Text(
                '跨路由验证：保持本页打开弹窗后按返回键，第一次关闭弹窗；'
                '再次返回才离开页面。路由归属型弹窗会在路由切换时自动关闭。',
              ),
            ],
          );
        },
      ),
    );
  }

  void _openCustom() {
    final handle = Pop.custom<void>(
      CustomPopupConfig<void>(
        behavior: const PopupBehaviorConfig(
          channel: PopupChannel.custom,
          routePolicy: PopupRoutePolicy.dismissWhenOwnerRouteChanges,
        ),
        animationConfig: const PopupAnimationConfig(
          type: PopupAnimationType.scale,
        ),
        builder: (context, popupHandle) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('CustomPopupConfig',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('同样拥有统一生命周期和 PopupHandle。'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: popupHandle.complete,
                  child: const Text('完成并关闭'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    setState(() => _externalHandle = handle);
    unawaited(handle.dismissed.then((_) {
      if (mounted && identical(_externalHandle, handle)) {
        setState(() => _externalHandle = null);
      }
    }));
  }

  Future<void> _openStack() async {
    await Pop.sheet<void>(
      title: '堆叠验证',
      maxHeight: const SheetDimension.fraction(0.45),
      childBuilder: (dismissSheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Sheet 保持显示，上层可以继续打开 Confirm 与 Toast。'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              final confirmed = await Pop.confirm(
                title: '确认堆叠',
                content: '这个 Confirm 位于 Sheet 上方。',
                cancelText: '取消',
                onConfirm: () => Pop.toast('onConfirm 已执行'),
                onCancel: () => Pop.toast('onCancel 已执行'),
              );
              if (confirmed == true) Pop.toast('业务结果为 true');
            },
            child: const Text('打开 Confirm'),
          ),
          TextButton(onPressed: dismissSheet, child: const Text('关闭 Sheet')),
        ],
      ),
    );
  }

  void _updateLoading() {
    Pop.loading(message: '第一阶段…', duration: const Duration(seconds: 4));
    Future<void>.delayed(const Duration(seconds: 1), () {
      Pop.loading(
          message: '第二阶段：计时已重新开始', duration: const Duration(seconds: 2));
    });
  }

  void _eventControlledToast() {
    final finished = Future<void>.delayed(const Duration(seconds: 2));
    Pop.toast(
      '等待外部 Future 完成…',
      until: finished,
    );
  }
}
