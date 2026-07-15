import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

import 'lab_section.dart';
import 'lab_shell.dart';

/// Toast：类型、位置、lifetime、队列、toggle、barrier。
class ToastLabPage extends StatelessWidget {
  const ToastLabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: labAppBar(context, 'Lab · Toast'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const LabBanner(
            text: '覆盖 Toast 全能力：类型/位置/样式、duration/until、'
                'lane 排队（每位置最多 3）、同 key 更新、toggle、带遮罩 Toast。',
          ),
          const SizedBox(height: 8),
          const LabStatusBar(),
          LabGroup(
            title: '类型与位置',
            children: [
              LabAction(
                label: 'success / warn / error / none',
                subtitle: '依次弹出四种类型',
                onPressed: () {
                  Pop.toast(
                      const ToastConfig.text('成功', type: ToastType.success));
                  Future<void>.delayed(const Duration(milliseconds: 400), () {
                    Pop.toast(
                        const ToastConfig.text('警告', type: ToastType.warn));
                  });
                  Future<void>.delayed(const Duration(milliseconds: 800), () {
                    Pop.toast(
                        const ToastConfig.text('错误', type: ToastType.error));
                  });
                  Future<void>.delayed(const Duration(milliseconds: 1200), () {
                    Pop.toast(const ToastConfig.text('纯文本'));
                  });
                },
              ),
              LabAction(
                label: 'top / center / bottom',
                subtitle: '三个位置各一条',
                outlined: true,
                onPressed: () {
                  Pop.toast(const ToastConfig.text('顶部',
                      position: PopupPosition.top));
                  Pop.toast(const ToastConfig.text('居中'));
                  Pop.toast(const ToastConfig.text('底部',
                      position: PopupPosition.bottom));
                },
              ),
              LabAction(
                label: '自定义 Widget 内容',
                outlined: true,
                onPressed: () {
                  Pop.toast(
                    const ToastConfig.content(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, color: Colors.amber),
                          SizedBox(width: 8),
                          Text('自定义 messageWidget',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              LabAction(
                label: '纵向布局 + 自定义样式',
                outlined: true,
                onPressed: () {
                  Pop.toast(
                    ToastConfig.text(
                      '纵向 Toast',
                      type: ToastType.success,
                      layoutDirection: Axis.vertical,
                      style: ToastStyle(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade700,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          LabGroup(
            title: 'Lifetime 与外部事件',
            children: [
              LabAction(
                label: '短 duration（800ms）',
                onPressed: () {
                  Pop.toast(
                    const ToastConfig.text(
                      '800ms 后关闭',
                      lifetime:
                          PopupLifetime.after(Duration(milliseconds: 800)),
                    ),
                  );
                },
              ),
              LabAction(
                label: 'until：2 秒后 Future 完成',
                outlined: true,
                onPressed: () {
                  final done = Future<void>.delayed(const Duration(seconds: 2));
                  Pop.toast(
                    ToastConfig.text(
                      '等待 until…',
                      lifetime: PopupLifetime.until(done),
                    ),
                  );
                },
              ),
              LabAction(
                label: 'until：Future 失败也关闭',
                subtitle: '1 秒后抛错；Toast 应正常退场，reason=externalEvent',
                outlined: true,
                onPressed: () async {
                  final failed = Future<void>.delayed(
                    const Duration(seconds: 1),
                    () => throw StateError('Toast Lab simulated failure'),
                  );
                  final handle = Pop.toast(
                    ToastConfig.text(
                      '等待失败 Future…',
                      lifetime: PopupLifetime.until(failed),
                    ),
                  ).requireHandle();
                  final outcome = await handle.outcome;
                  if (context.mounted) {
                    labShowResult(
                      context,
                      'Toast 已关闭：${outcome.reason.name}',
                    );
                  }
                },
              ),
              LabAction(
                label: 'duration + until（anyOf）',
                subtitle: '3s 倒计时 vs 1s Future，先到先关',
                outlined: true,
                onPressed: () {
                  final done = Future<void>.delayed(const Duration(seconds: 1));
                  Pop.toast(
                    ToastConfig.text(
                      'anyOf：应约 1s 关闭',
                      lifetime: PopupLifetime.anyOf([
                        const PopupLifetime.after(Duration(seconds: 3)),
                        PopupLifetime.until(done),
                      ]),
                    ),
                  );
                },
              ),
              LabAction(
                label: 'onTap 回调',
                outlined: true,
                onPressed: () {
                  Pop.toast(
                    ToastConfig.text(
                      '点我触发 onTap',
                      lifetime: const PopupLifetime.after(Duration(seconds: 4)),
                      onTap: () => labShowResult(context, 'Toast onTap'),
                    ),
                  );
                },
              ),
            ],
          ),
          LabGroup(
            title: '队列与 key',
            subtitle: '无 barrier 的 Toast 共享位置 lane，每位置最多同时 3 条。',
            children: [
              LabAction(
                label: '连点 5 次底部 Toast',
                subtitle: '可见 ≤3，其余 queued',
                onPressed: () {
                  for (var i = 1; i <= 5; i++) {
                    Pop.toast(
                      ToastConfig.text(
                        '队列 #$i',
                        position: PopupPosition.bottom,
                        lifetime:
                            const PopupLifetime.after(Duration(seconds: 3)),
                      ),
                    );
                  }
                },
              ),
              LabAction(
                label: '同 key 更新（同一 toast API）',
                subtitle: '重复打开 lab.toast.status',
                outlined: true,
                onPressed: () {
                  unawaited(_showKeyedToast(context));
                },
              ),
            ],
          ),
          LabGroup(
            title: '高级',
            children: [
              LabAction(
                label: 'Toggle Toast',
                subtitle: '点击在两种文案间切换',
                onPressed: () {
                  Pop.toast(
                    const ToastConfig.text(
                      '点击切换 →',
                      type: ToastType.warn,
                      toggle: ToastToggleConfig(
                        message: '已切换状态',
                        type: ToastType.success,
                      ),
                      lifetime: PopupLifetime.after(Duration(seconds: 6)),
                    ),
                  );
                },
              ),
              LabAction(
                label: '带 Barrier 的 Toast',
                subtitle: '走全屏 Entry，非 lane',
                outlined: true,
                onPressed: () {
                  Pop.toast(
                    const ToastConfig.text(
                      '模态 Toast（点遮罩或等 duration）',
                      barrier: PopupBarrierConfig(dismissible: true),
                      lifetime: PopupLifetime.after(Duration(seconds: 4)),
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

  static Future<void> _showKeyedToast(BuildContext context) async {
    const key = 'lab.toast.status';
    Pop.toast(
      ToastConfig.text(
        '状态 A · ${DateTime.now().second}s',
        position: PopupPosition.bottom,
        behavior: const PopupBehaviorConfig(
          key: key,
          conflictPolicy: PopupConflictPolicy.updateExisting,
          backPolicy: PopupBackPolicy.ignore,
        ),
        lifetime: const PopupLifetime.after(Duration(seconds: 4)),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!context.mounted) return;
    Pop.toast(
      ToastConfig.text(
        '状态 B · 已更新 · ${DateTime.now().second}s',
        type: ToastType.success,
        position: PopupPosition.bottom,
        behavior: const PopupBehaviorConfig(
          key: key,
          conflictPolicy: PopupConflictPolicy.updateExisting,
          backPolicy: PopupBackPolicy.ignore,
        ),
        lifetime: const PopupLifetime.after(Duration(seconds: 3)),
      ),
    );
    labShowResult(context, '同 key Toast 已更新（应仍只有一条）');
  }
}
