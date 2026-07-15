import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

import 'lab_section.dart';
import 'lab_shell.dart';

/// Custom、Handle、批量关闭与查询 API。
class CustomHandleLabPage extends StatefulWidget {
  const CustomHandleLabPage({super.key});

  @override
  State<CustomHandleLabPage> createState() => _CustomHandleLabPageState();
}

class _CustomHandleLabPageState extends State<CustomHandleLabPage> {
  PopupHandle<void>? _external;
  String _note = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: labAppBar(context, 'Lab · Custom / Handle'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const LabBanner(
            text: 'CustomPopupConfig 接入统一生命周期。'
                '验证 outcome vs dismissed、外部 Handle、tags/channel 批量关闭与查询。',
          ),
          const SizedBox(height: 8),
          LabStatusBar(extra: _note.isEmpty ? null : _note),
          LabGroup(
            title: 'Custom + Handle',
            children: [
              LabAction(
                label: '打开 Custom（保留 Handle）',
                onPressed: _openCustom,
              ),
              LabAction(
                label: '外部 dismiss Handle',
                outlined: true,
                onPressed: _external?.isActive == true
                    ? () async {
                        await _external?.dismiss();
                        setState(() => _note = '外部 dismiss 完成');
                      }
                    : null,
              ),
              LabAction(
                label: '演示 outcome → dismissed 顺序',
                outlined: true,
                onPressed: () async {
                  final handle = Pop.custom<String>(
                    CustomPopupConfig<String>(
                      behavior: const PopupBehaviorConfig(
                        channel: PopupChannel.custom,
                        key: 'lab.custom.phases',
                      ),
                      builder: (context, h) => _PhaseCard(handle: h),
                    ),
                  );
                  setState(() => _note = '等待 outcome…');
                  final outcome = await handle.outcome;
                  if (!mounted) return;
                  setState(
                    () => _note =
                        'outcome=${outcome.value} / ${outcome.reason.name} · 等待 dismissed…',
                  );
                  await handle.dismissed;
                  if (!mounted) return;
                  setState(() => _note = 'dismissed 已完成（视觉已移除）');
                },
              ),
            ],
          ),
          LabGroup(
            title: '批量关闭与查询',
            children: [
              LabAction(
                label: '打开带 tags 的两个弹窗',
                onPressed: () {
                  Pop.custom<void>(
                    CustomPopupConfig<void>(
                      behavior: const PopupBehaviorConfig(
                        channel: PopupChannel.custom,
                        key: 'lab.tag.a',
                        tags: {'lab-demo'},
                      ),
                      builder: (context, h) => _SimpleCard(
                        title: 'Tag A',
                        onClose: h.dismiss,
                      ),
                    ),
                  );
                  Pop.custom<void>(
                    CustomPopupConfig<void>(
                      behavior: const PopupBehaviorConfig(
                        channel: PopupChannel.custom,
                        key: 'lab.tag.b',
                        tags: {'lab-demo'},
                      ),
                      position: PopupPosition.bottom,
                      builder: (context, h) => _SimpleCard(
                        title: 'Tag B',
                        onClose: h.dismiss,
                      ),
                    ),
                  );
                  setState(() => _note = '已打开 lab-demo tags');
                },
              ),
              LabAction(
                label: 'dismissTags({lab-demo})',
                outlined: true,
                onPressed: () async {
                  final n = await Pop.dismissTags({'lab-demo'});
                  if (mounted) setState(() => _note = 'dismissTags → $n');
                },
              ),
              LabAction(
                label: '弹多个 Toast 后 dismissChannel(toast)',
                outlined: true,
                onPressed: () async {
                  Pop.toast('ch-1', duration: const Duration(seconds: 8));
                  Pop.toast('ch-2',
                      position: PopupPosition.bottom,
                      duration: const Duration(seconds: 8));
                  await Future<void>.delayed(const Duration(milliseconds: 300));
                  final n = await Pop.dismissChannel(PopupChannel.toast);
                  if (mounted) {
                    setState(() => _note = 'dismissChannel(toast)=$n');
                  }
                },
              ),
              LabAction(
                label: 'dismissTop / dismissAll',
                outlined: true,
                onPressed: () async {
                  Pop.toast('将被 dismissTop',
                      duration: const Duration(seconds: 10));
                  await Pop.sheet<void>(
                    title: '上层 Sheet',
                    maxHeight: const SheetDimension.fraction(0.35),
                    childBuilder: (d) => TextButton(
                      onPressed: d,
                      child: const Text('关'),
                    ),
                  );
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final ok = await Pop.dismissTop();
                        if (mounted) {
                          setState(() => _note = 'dismissTop → $ok');
                        }
                      },
                      child: const Text('dismissTop'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await Pop.dismissAll();
                        if (mounted) setState(() => _note = 'dismissAll 完成');
                      },
                      child: const Text('dismissAll'),
                    ),
                  ),
                ],
              ),
              LabAction(
                label: '查询 isVisibleKey / countChannel',
                tonal: true,
                onPressed: () {
                  Pop.loading(
                      message: '查询用 Loading',
                      duration: const Duration(seconds: 3));
                  final visible = Pop.isVisibleKey(PopupKeys.globalLoading);
                  final active = Pop.isActiveKey(PopupKeys.globalLoading);
                  final count = Pop.countChannel(PopupChannel.loading);
                  final has = Pop.hasChannel(PopupChannel.loading);
                  setState(() {
                    _note =
                        'visible=$visible active=$active count=$count has=$has';
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openCustom() {
    final handle = Pop.custom<void>(
      CustomPopupConfig<void>(
        behavior: const PopupBehaviorConfig(
          channel: PopupChannel.custom,
          key: 'lab.custom.external',
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
                const Text('统一生命周期与 PopupHandle。'),
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
    setState(() {
      _external = handle;
      _note = 'Handle 已保存 isActive=${handle.isActive}';
    });
    unawaited(handle.dismissed.then((_) {
      if (mounted && identical(_external, handle)) {
        setState(() => _external = null);
      }
    }));
  }
}

class _SimpleCard extends StatelessWidget {
  const _SimpleCard({required this.title, required this.onClose});

  final String title;
  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextButton(onPressed: onClose, child: const Text('关闭')),
          ],
        ),
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({required this.handle});

  final PopupHandle<String> handle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('先 complete，再等 dismissed'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => handle.complete('ok'),
              child: const Text('complete("ok")'),
            ),
          ],
        ),
      ),
    );
  }
}
