import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

import 'lab_section.dart';
import 'lab_shell.dart';

/// pause/resume：跳转子页时挂起 Sheet，返回后恢复状态。
class PauseResumeLabPage extends StatefulWidget {
  const PauseResumeLabPage({super.key});

  @override
  State<PauseResumeLabPage> createState() => _PauseResumeLabPageState();
}

class _PauseResumeLabPageState extends State<PauseResumeLabPage> {
  String _note = '';

  Future<void> _pushDetail({
    required String title,
    required String hint,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _DetailProbePage(title: title, hint: hint),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: labAppBar(context, 'Lab · Pause / Resume'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const LabBanner(
            text: 'pause 保留 Entry 与内部 Widget 状态（Offstage），'
                '不绘制、不响应手势，且跳过系统返回与路由自动关闭。'
                '典型场景：Sheet / FlowSheet 内跳转详情页，返回后继续编辑。'
                '注意：Popup Overlay 不在 Navigator 子树内，跳转需用页面 context'
                '（本 Lab 通过回调 push）。',
          ),
          const SizedBox(height: 8),
          LabStatusBar(extra: _note.isEmpty ? null : _note),
          LabGroup(
            title: 'Sheet + 详情跳转',
            children: [
              LabAction(
                label: '打开可计数 Sheet → Pause & push',
                subtitle: '返回后计数应保留；未 pause 会被 routePolicy 关掉',
                onPressed: () {
                  Pop.sheet<void>(
                    SheetConfig<void>(
                      header: const SheetHeaderConfig(title: '可 Pause 的 Sheet'),
                      size: const SheetSizeConfig(
                        maxHeight: SheetDimension.fraction(0.5),
                      ),
                      behavior: const PopupBehaviorConfig(
                        routePolicy:
                            PopupRoutePolicy.dismissWhenOwnerRouteChanges,
                      ),
                      builder: (context, handle) => _PauseSheetBody(
                        onNote: (note) {
                          if (mounted) setState(() => _note = note);
                        },
                        openDetail: () => _pushDetail(
                          title: 'Pause 详情页',
                          hint: '返回后 Sheet 应恢复，且计数不变。',
                        ),
                      ),
                    ),
                  );
                  setState(() => _note = '已打开 Sheet，点内部「Pause & 打开详情」');
                },
              ),
              LabAction(
                label: '对照：不 pause 直接 push',
                subtitle: '默认 routePolicy 下 Sheet 会被关掉',
                outlined: true,
                onPressed: () {
                  Pop.sheet<void>(
                    SheetConfig<void>(
                      header: const SheetHeaderConfig(title: '会被路由关掉'),
                      size: const SheetSizeConfig(
                        maxHeight: SheetDimension.fraction(0.4),
                      ),
                      behavior: const PopupBehaviorConfig(
                        routePolicy:
                            PopupRoutePolicy.dismissWhenOwnerRouteChanges,
                      ),
                      builder: (context, handle) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('点下方按钮直接 push，不 pause。'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () {
                              unawaited(
                                _pushDetail(
                                  title: '未 pause 探测页',
                                  hint: '返回后 Sheet 应已消失。',
                                ),
                              );
                            },
                            child: const Text('不 pause，直接 push'),
                          ),
                        ],
                      ),
                    ),
                  );
                  setState(() => _note = '对照：未 pause 的 Sheet 将随路由关闭');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PauseSheetBody extends StatefulWidget {
  const _PauseSheetBody({
    required this.onNote,
    required this.openDetail,
  });

  final ValueChanged<String> onNote;
  final Future<void> Function() openDetail;

  @override
  State<_PauseSheetBody> createState() => _PauseSheetBodyState();
}

class _PauseSheetBodyState extends State<_PauseSheetBody> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('本地计数：$_count（pause 期间应保留）'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => setState(() => _count++),
          child: const Text('计数 +1'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () async {
            final paused = Pop.pauseLatest(PopupChannel.sheet);
            widget.onNote(
              paused == null
                  ? 'pauseLatest 失败'
                  : '已 pause，进入详情；返回后应看到计数 $_count',
            );
            if (paused == null) return;
            await widget.openDetail();
            final ok = Pop.resume(paused.id);
            widget.onNote('resume → $ok；计数应为 $_count');
          },
          child: const Text('Pause & 打开详情'),
        ),
      ],
    );
  }
}

class _DetailProbePage extends StatelessWidget {
  const _DetailProbePage({
    required this.title,
    required this.hint,
  });

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(hint),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}
