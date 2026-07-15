import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

import 'lab_section.dart';
import 'lab_shell.dart';

/// 演示便捷 API 与高级 Config 两层用法，以及通用配置对象。
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
            text: '两层 API 不会打架：便捷 API 内部就是组装 Config。'
                '日常用 Pop.toast/sheet/menu/dropMenu；需要 key/tags/策略/精确遮罩时用 openXxx(Config)。',
          ),
          const SizedBox(height: 8),
          const LabGroup(
            title: '怎么选',
            children: [
              LabNote(
                '便捷层：少参数、等 Future 结果。\n'
                '高级层：PopupHandle、PopupBarrierConfig、PopupBehaviorConfig、'
                'PopupLifetime、PopupOwnership、lifecycle。\n'
                '同一调用只走一层；不要既以为「扁平参数」又以为「Config 字段」会叠加。',
              ),
            ],
          ),
          LabGroup(
            title: '同一能力 · 两种写法',
            children: [
              LabAction(
                label: '便捷：Toast + duration',
                onPressed: () {
                  Pop.toast('便捷 API', duration: const Duration(seconds: 2));
                },
              ),
              LabAction(
                label: '高级：ToastConfig + PopupLifetime',
                outlined: true,
                onPressed: () {
                  Pop.openToast(
                    const ToastConfig(
                      message: '高级 Config',
                      type: ToastType.success,
                      lifetime: PopupLifetime.after(Duration(seconds: 2)),
                      behavior: PopupBehaviorConfig(
                        channel: PopupChannel.toast,
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
            subtitle: '所有高级 openXxx 都返回 opened / updated / toggled / rejected。',
            children: [
              LabAction(
                label: '演示 opened → toggledClosed',
                subtitle: '同 key Confirm 在 800ms 后再次 toggle',
                onPressed: () async {
                  const behavior = PopupBehaviorConfig(
                    channel: PopupChannel.confirm,
                    key: 'lab.config.toggle-confirm',
                    conflictPolicy: PopupConflictPolicy.toggle,
                  );
                  final first = Pop.openConfirm(
                    const ConfirmConfig(
                      content: '第一次返回 PopupOpened，随后自动 toggle 关闭',
                      behavior: behavior,
                    ),
                  );
                  await Future<void>.delayed(
                    const Duration(milliseconds: 800),
                  );
                  final second = Pop.openConfirm(
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
                    channel: PopupChannel.toast,
                    key: 'lab.config.result-toast',
                    conflictPolicy: PopupConflictPolicy.updateExisting,
                    backPolicy: PopupBackPolicy.ignore,
                  );
                  final first = Pop.openToast(
                    const ToastConfig(
                      message: 'PopupOpened',
                      behavior: behavior,
                      lifetime: PopupLifetime.after(Duration(seconds: 3)),
                    ),
                  );
                  final second = Pop.openToast(
                    const ToastConfig(
                      message: 'PopupUpdated · 同一个 Handle',
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
                  Pop.openToast(
                    const ToastConfig(
                      message: 'tag=demo',
                      position: PopupPosition.bottom,
                      lifetime: PopupLifetime.after(Duration(seconds: 8)),
                      behavior: PopupBehaviorConfig(
                        channel: PopupChannel.toast,
                        tags: {'config-lab'},
                        backPolicy: PopupBackPolicy.ignore,
                      ),
                    ),
                  );
                  Pop.custom<void>(
                    CustomPopupConfig<void>(
                      behavior: const PopupBehaviorConfig(
                        channel: PopupChannel.custom,
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
                  Pop.openToast(
                    ToastConfig(
                      message: 'anyOf：约 1s 关（非 5s）',
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
