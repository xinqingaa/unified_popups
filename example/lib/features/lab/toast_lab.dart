import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

import 'lab_section.dart';
import 'lab_shell.dart';

/// Toast：类型、位置、lifetime、单槽替换、toggle、barrier。
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
            text: '类型、位置、样式、lifetime、同 key 更新、toggle、带遮罩。'
                '同一位置的并发验收看下面「单槽替换」。',
          ),
          const SizedBox(height: 8),
          const LabBanner(
            text: '验收时看这些现象。时间从这条 Toast 完整出现之后算，不是从手指点下开始。\n'
                '1. 同一位置始终只有一条，不会再挤出第二、第三条。\n'
                '2. 队列里还有下一条，且当前条已完整展示约 500ms：当前条用约 180ms 淡出，并平移约 20px。底部、居中、顶部向左；贴左边的继续向左；贴右边的继续向右。\n'
                '3. 下一条晚约 50ms 在同一位置入场。底部向上滑入，顶部向下滑入，居中淡入，左右沿原来的方向。两条叠在一起，中间不要空一帧。\n'
                '4. 还没满 500ms 时，下一条只排队，不要立刻把当前条换掉。\n'
                '5. 已经超过 500ms 再来一条，应马上换，不要再等 500ms。\n'
                '6. 队列空了、只是时间到：走这条自己的退场。居中淡出，底部向下，顶部向上，左右向外。不要用换场那种平移。\n'
                '7. 顶、中、底可以同时各有一条，互不排队。\n'
                '8. 同 key 更新仍是原地改文案，不要换场。\n'
                '9. 带遮罩的 Toast 不占这个槽，可以和普通 Toast 同时在。',
          ),
          const SizedBox(height: 8),
          const LabStatusBar(),
          LabGroup(
            title: '类型与位置',
            children: [
              LabAction(
                label: 'success / warn / error / none',
                subtitle: '四条在中间依次换掉，不会同时堆叠',
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
                subtitle: '三个位置同时各一条，互不替换',
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
            title: '单槽替换',
            subtitle: '对照上方验收说明看。入场大约 200ms，500ms 从完整出现之后再算。',
            children: [
              LabAction(
                label: '底部连发 5 条',
                subtitle: '始终一条。每条完整出现后再停约 500ms，然后淡出并向左移一点；'
                    '下一条几乎同时从下方滑入。最后一条多留一会，再向下滑走，不要向左飘',
                onPressed: () {
                  for (var i = 1; i <= 5; i++) {
                    Pop.toast(
                      ToastConfig.text(
                        '队列 #$i',
                        position: PopupPosition.bottom,
                        lifetime:
                            const PopupLifetime.after(Duration(seconds: 2)),
                      ),
                    );
                  }
                },
              ),
              LabAction(
                label: '未满 500ms 就来下一条',
                subtitle: '点下约 300ms 后出现第二句。第一句应继续留到完整出现后约 500ms，'
                    '然后才淡出左移',
                outlined: true,
                onPressed: () {
                  Pop.toast(
                    const ToastConfig.text(
                      '第一句 · 先看清',
                      position: PopupPosition.bottom,
                      lifetime: PopupLifetime.after(Duration(seconds: 3)),
                    ),
                  );
                  Future<void>.delayed(const Duration(milliseconds: 300), () {
                    Pop.toast(
                      const ToastConfig.text(
                        '第二句 · 还没到半秒',
                        position: PopupPosition.bottom,
                        lifetime: PopupLifetime.after(Duration(seconds: 2)),
                      ),
                    );
                  });
                },
              ),
              LabAction(
                label: '停稳后再来一条',
                subtitle: '约 1.2 秒后出现第二句。第一句已经超过 500ms，应马上换，不要再等',
                outlined: true,
                onPressed: () {
                  Pop.toast(
                    const ToastConfig.text(
                      '第一句 · 已经停稳',
                      position: PopupPosition.bottom,
                      lifetime: PopupLifetime.after(Duration(seconds: 4)),
                    ),
                  );
                  Future<void>.delayed(const Duration(milliseconds: 1200), () {
                    Pop.toast(
                      const ToastConfig.text(
                        '第二句 · 马上换上',
                        position: PopupPosition.bottom,
                        lifetime: PopupLifetime.after(Duration(seconds: 2)),
                      ),
                    );
                  });
                },
              ),
              LabAction(
                label: '只有一条时底部自己消失',
                subtitle: '入场结束后约 1.2 秒，向下离开。不要向左飘',
                outlined: true,
                onPressed: () {
                  Pop.toast(
                    const ToastConfig.text(
                      '只此一条 · 向下走',
                      position: PopupPosition.bottom,
                      lifetime:
                          PopupLifetime.after(Duration(milliseconds: 1200)),
                    ),
                  );
                },
              ),
              LabAction(
                label: '只有一条时居中自己消失',
                subtitle: '入场结束后约 1.2 秒，原地淡出。不要向左飘',
                outlined: true,
                onPressed: () {
                  Pop.toast(
                    const ToastConfig.text(
                      '只此一条 · 原地淡出',
                      lifetime:
                          PopupLifetime.after(Duration(milliseconds: 1200)),
                    ),
                  );
                },
              ),
              LabAction(
                label: '只有一条时顶部自己消失',
                subtitle: '入场结束后约 1.2 秒，向上离开。不要向左飘',
                outlined: true,
                onPressed: () {
                  Pop.toast(
                    const ToastConfig.text(
                      '只此一条 · 向上走',
                      position: PopupPosition.top,
                      lifetime:
                          PopupLifetime.after(Duration(milliseconds: 1200)),
                    ),
                  );
                },
              ),
              LabAction(
                label: '左侧连发 · 向外',
                subtitle: '当前条应向左外侧移，不要往屏幕中间挤',
                outlined: true,
                onPressed: () {
                  Pop.toast(
                    const ToastConfig.text(
                      '左侧 1',
                      position: PopupPosition.left,
                      lifetime: PopupLifetime.after(Duration(seconds: 3)),
                    ),
                  );
                  Pop.toast(
                    const ToastConfig.text(
                      '左侧 2',
                      position: PopupPosition.left,
                      lifetime: PopupLifetime.after(Duration(seconds: 2)),
                    ),
                  );
                },
              ),
              LabAction(
                label: '右侧连发 · 向外',
                subtitle: '当前条应向右外侧移，不要往屏幕中间挤',
                outlined: true,
                onPressed: () {
                  Pop.toast(
                    const ToastConfig.text(
                      '右侧 1',
                      position: PopupPosition.right,
                      lifetime: PopupLifetime.after(Duration(seconds: 3)),
                    ),
                  );
                  Pop.toast(
                    const ToastConfig.text(
                      '右侧 2',
                      position: PopupPosition.right,
                      lifetime: PopupLifetime.after(Duration(seconds: 2)),
                    ),
                  );
                },
              ),
              LabAction(
                label: '顶 / 中 / 底同时',
                subtitle: '三条一起在，谁也不排队',
                outlined: true,
                onPressed: () {
                  Pop.toast(
                    const ToastConfig.text(
                      '顶部同时',
                      position: PopupPosition.top,
                    ),
                  );
                  Pop.toast(const ToastConfig.text('居中同时'));
                  Pop.toast(
                    const ToastConfig.text(
                      '底部同时',
                      position: PopupPosition.bottom,
                    ),
                  );
                },
              ),
              LabAction(
                label: '同 key 更新（同一 toast API）',
                subtitle: '约 0.8 秒后文案原地变成状态 B，不要淡出左移，屏幕上仍只有一条',
                outlined: true,
                onPressed: () {
                  unawaited(_showKeyedToast(context));
                },
              ),
              LabAction(
                label: '遮罩 Toast + 普通 Toast',
                subtitle: '两条同时在。遮罩这条不占底部槽',
                outlined: true,
                onPressed: () {
                  Pop.toast(
                    const ToastConfig.text(
                      '普通底部',
                      position: PopupPosition.bottom,
                      lifetime: PopupLifetime.after(Duration(seconds: 4)),
                    ),
                  );
                  Pop.toast(
                    const ToastConfig.text(
                      '带遮罩 · 点遮罩或等它自己关',
                      barrier: PopupBarrierConfig(dismissible: true),
                      lifetime: PopupLifetime.after(Duration(seconds: 4)),
                    ),
                  );
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
