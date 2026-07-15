import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

import 'lab_section.dart';
import 'lab_shell.dart';

/// 演示 Config-first 单入口 API 与统一返回模型。
class ConfigLabPage extends StatelessWidget {
  const ConfigLabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: labAppBar(context, 'Lab · 通用 Config'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const LabBanner(
            text: '每种能力只有一个 Pop.xxx(Config) 入口。普通调用可以忽略返回值，'
                '需要结果或控制时再使用 result / requireHandle。',
          ),
          const SizedBox(height: 8),
          const LabGroup(
            title: '唯一选择',
            children: [
              LabNote(
                'Config 是唯一参数契约；Behavior、Barrier、Lifetime、Ownership、'
                'Lifecycle 都是 Config 的分组字段。Builder 使用 V2 PopupHandle。',
              ),
            ],
          ),
          LabGroup(
            title: '同一入口 · 不同配置深度',
            children: [
              LabAction(
                label: '普通：最小 ToastConfig',
                onPressed: () {
                  Pop.toast(const ToastConfig.text('最小 Config'));
                },
              ),
              LabAction(
                label: '高级：同一个 toast 方法',
                outlined: true,
                onPressed: () {
                  Pop.toast(
                    const ToastConfig.text(
                      '高级 Config',
                      type: ToastType.success,
                      lifetime: PopupLifetime.after(Duration(seconds: 2)),
                      behavior: PopupBehaviorConfig(
                        key: 'lab.config.toast',
                        conflictPolicy: PopupConflictPolicy.updateExisting,
                        backPolicy: PopupBackPolicy.ignore,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          LabGroup(
            title: '统一 PopupOpenResult',
            subtitle: '所有 Pop.xxx 都返回 opened / updated / toggled / rejected。',
            children: [
              LabAction(
                label: '演示 opened → toggledClosed',
                subtitle: '同 key Confirm 在 800ms 后再次 toggle',
                onPressed: () async {
                  const behavior = PopupBehaviorConfig(
                    key: 'lab.config.toggle-confirm',
                    conflictPolicy: PopupConflictPolicy.toggle,
                  );
                  final first = Pop.confirm(
                    const ConfirmConfig(
                      content: '第一次返回 PopupOpened，随后自动 toggle 关闭',
                      behavior: behavior,
                    ),
                  );
                  await Future<void>.delayed(
                    const Duration(milliseconds: 800),
                  );
                  final second = Pop.confirm(
                    const ConfirmConfig(
                      content: '不会创建第二个 Confirm',
                      behavior: behavior,
                    ),
                  );
                  if (!context.mounted) return;
                  labShowResult(
                    context,
                    '${first.runtimeType} → ${second.runtimeType}',
                  );
                },
              ),
              LabAction(
                label: '演示 opened → updated',
                subtitle: '同 key Toast 更新并返回原 Handle',
                outlined: true,
                onPressed: () {
                  const behavior = PopupBehaviorConfig(
                    key: 'lab.config.result-toast',
                    conflictPolicy: PopupConflictPolicy.updateExisting,
                    backPolicy: PopupBackPolicy.ignore,
                  );
                  final first = Pop.toast(
                    const ToastConfig.text(
                      'PopupOpened',
                      behavior: behavior,
                      lifetime: PopupLifetime.after(Duration(seconds: 3)),
                    ),
                  );
                  final second = Pop.toast(
                    const ToastConfig.text(
                      'PopupUpdated · 同一个 Handle',
                      behavior: behavior,
                      lifetime: PopupLifetime.after(Duration(seconds: 3)),
                    ),
                  );
                  labShowResult(
                    context,
                    '${first.runtimeType} → ${second.runtimeType} · '
                    'sameHandle=${identical(first.handleOrNull, second.handleOrNull)}',
                  );
                },
              ),
            ],
          ),
          LabGroup(
            title: 'PopupBarrierConfig',
            children: [
              LabAction(
                label: 'Menu 默认 hidden（可滚动）',
                subtitle: '见 Menu 展柜；此处用 Custom 演示 hidden',
                onPressed: () {
                  Pop.custom<void>(
                    CustomPopupConfig<void>(
                      barrier: const PopupBarrierConfig.hidden(),
                      position: PopupPosition.bottom,
                      builder: (context, handle) => Card(
                        margin: const EdgeInsets.all(24),
                        child: ListTile(
                          title: const Text('无遮罩 Custom'),
                          subtitle: const Text('底层仍可交互'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: handle.dismiss,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              LabAction(
                label: '半透明可点关 Barrier',
                outlined: true,
                onPressed: () {
                  Pop.custom<void>(
                    CustomPopupConfig<void>(
                      barrier: const PopupBarrierConfig(
                        dismissible: true,
                        color: Color(0x66000000),
                      ),
                      builder: (context, handle) => Card(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('点遮罩或按钮关闭'),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: handle.dismiss,
                                child: const Text('关闭'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          LabGroup(
            title: 'PopupBehaviorConfig / Ownership / Lifetime',
            children: [
              LabAction(
                label: 'tags + dismissTags',
                onPressed: () {
                  Pop.toast(
                    const ToastConfig.text(
                      'tag=demo',
                      position: PopupPosition.bottom,
                      lifetime: PopupLifetime.after(Duration(seconds: 8)),
                      behavior: PopupBehaviorConfig(
                        tags: {'config-lab'},
                        backPolicy: PopupBackPolicy.ignore,
                      ),
                    ),
                  );
                  Pop.custom<void>(
                    CustomPopupConfig<void>(
                      behavior: const PopupBehaviorConfig(
                        key: 'lab.config.tagged',
                        tags: {'config-lab'},
                      ),
                      builder: (context, handle) => Card(
                        margin: const EdgeInsets.all(48),
                        child: ListTile(
                          title: const Text('同 tag Custom'),
                          subtitle: const Text('点下方 dismissTags'),
                          trailing: IconButton(
                            onPressed: handle.dismiss,
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              LabAction(
                label: 'Pop.dismissTags({config-lab})',
                outlined: true,
                onPressed: () => Pop.dismissTags({'config-lab'}),
              ),
              LabAction(
                label: 'Lifetime.anyOf(duration + until)',
                outlined: true,
                onPressed: () {
                  final until =
                      Future<void>.delayed(const Duration(seconds: 1));
                  Pop.toast(
                    ToastConfig.text(
                      'anyOf：约 1s 关（非 5s）',
                      lifetime: PopupLifetime.anyOf([
                        const PopupLifetime.after(Duration(seconds: 5)),
                        PopupLifetime.until(until),
                      ]),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
