import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

import 'lab_section.dart';
import 'lab_shell.dart';

/// Confirm / Date：按钮语义、outcome、样式、日期选择。
class ConfirmDateLabPage extends StatefulWidget {
  const ConfirmDateLabPage({super.key});

  @override
  State<ConfirmDateLabPage> createState() => _ConfirmDateLabPageState();
}

class _ConfirmDateLabPageState extends State<ConfirmDateLabPage> {
  String _last = '';

  void _setLast(String value) => setState(() => _last = value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: labAppBar(context, 'Lab · Confirm / Date'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const LabBanner(
            text: 'Confirm：确认→true+onConfirm，取消→false+onCancel；'
                '遮罩/关闭按钮/返回/路由→null 且不调 onCancel。'
                'Date：范围与样式。',
          ),
          const SizedBox(height: 8),
          LabStatusBar(extra: _last.isEmpty ? null : '最近：$_last'),
          if (_last.isEmpty) const LabNote('操作后这里会显示 result / outcome.reason'),
          LabGroup(
            title: 'Confirm 结果语义',
            children: [
              LabAction(
                label: '标准确认框（默认线条）',
                subtitle: '试确认 / 取消 / 遮罩 / 返回',
                onPressed: () async {
                  final result = await Pop.confirm(
                    ConfirmConfig(
                      title: '删除记录',
                      content: '删除后无法恢复。请分别试按钮与遮罩。',
                      confirmText: '删除',
                      cancelText: '取消',
                      onConfirm: () => _setLast('onConfirm 已执行'),
                      onCancel: () => _setLast('onCancel 已执行'),
                    ),
                  ).result;
                  _setLast('result=$result（另看上方 onConfirm/onCancel）');
                },
              ),
              LabAction(
                label: '胶囊填充按钮',
                subtitle: 'buttonStyle = filled',
                outlined: true,
                onPressed: () async {
                  final result = await Pop.confirm(
                    const ConfirmConfig(
                      title: '删除记录',
                      content: '填充 / 胶囊风格（非默认）。',
                      confirmText: '删除',
                      cancelText: '取消',
                      style: ConfirmStyle(
                        buttonStyle: ConfirmButtonStyle.filled,
                        confirmBackgroundColor: Colors.redAccent,
                        buttonBorderRadius:
                            BorderRadius.all(Radius.circular(24)),
                        padding: EdgeInsets.all(24),
                      ),
                    ),
                  ).result;
                  _setLast('胶囊 result=$result');
                },
              ),
              LabAction(
                label: 'confirm + outcome',
                subtitle: '区分 barrier / back / completed',
                outlined: true,
                onPressed: () async {
                  final handle = Pop.confirm(
                    ConfirmConfig(
                      title: '高级 Confirm',
                      content: '关闭后读取 outcome.reason',
                      cancelText: '取消',
                      confirmText: '确定',
                      onConfirm: () {},
                      onCancel: () {},
                      lifecycle: PopupLifecycleCallbacks<bool>(
                        onOutcome: (outcome) {
                          _setLast(
                            'outcome value=${outcome.value} reason=${outcome.reason.name}',
                          );
                        },
                      ),
                    ),
                  ).requireHandle();
                  final outcome = await handle.outcome;
                  if (!mounted) return;
                  _setLast(
                    'await outcome → ${outcome.value} / ${outcome.reason.name}',
                  );
                },
              ),
              LabAction(
                label: '仅确认按钮（无取消）',
                outlined: true,
                onPressed: () async {
                  final r = await Pop.confirm(
                    const ConfirmConfig(
                      title: '提示',
                      content: '只有确认按钮',
                      confirmText: '知道了',
                      showCloseButton: true,
                    ),
                  ).result;
                  _setLast('result=$r');
                },
              ),
              LabAction(
                label: '纵向按钮布局',
                outlined: true,
                onPressed: () {
                  Pop.confirm(
                    const ConfirmConfig(
                      title: '纵向按钮',
                      content: 'buttonLayout = column',
                      cancelText: '取消',
                      buttonLayout: ConfirmButtonLayout.column,
                    ),
                  );
                },
              ),
              LabAction(
                label: '自定义 Widget 标题/内容/扩展区',
                outlined: true,
                onPressed: () {
                  Pop.confirm(
                    ConfirmConfig(
                      titleWidget: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline),
                          SizedBox(width: 8),
                          Text('自定义标题'),
                        ],
                      ),
                      contentWidget:
                          const Text('contentWidget + bodyExtension'),
                      bodyExtension: Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(8),
                        color: Colors.black12,
                        child: const Text('额外区域 bodyExtension'),
                      ),
                      confirmText: '确定',
                      cancelText: '取消',
                    ),
                  );
                },
              ),
            ],
          ),
          LabGroup(
            title: '堆叠与外部关闭',
            children: [
              LabAction(
                label: 'Sheet 上再开 Confirm',
                onPressed: () async {
                  await Pop.sheet<void>(
                    SheetConfig<void>(
                      header: const SheetHeaderConfig(title: '父级 Sheet'),
                      size: const SheetSizeConfig(
                        maxHeight: SheetDimension.fraction(0.5),
                      ),
                      builder: (context, handle) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                              'Confirm 默认 dismissWithParent：关 Sheet 会带走 Confirm。'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () async {
                              final r = await Pop.confirm(
                                const ConfirmConfig(
                                  title: '子 Confirm',
                                  content: '位于 Sheet 上方',
                                  cancelText: '取消',
                                ),
                              ).result;
                              if (context.mounted) {
                                labShowResult(context, 'Confirm result=$r');
                              }
                            },
                            child: const Text('打开 Confirm'),
                          ),
                          TextButton(
                              onPressed: handle.dismiss,
                              child: const Text('关闭 Sheet')),
                        ],
                      ),
                    ),
                  ).result;
                },
              ),
              LabAction(
                label: '外部 Handle.dismiss',
                outlined: true,
                onPressed: () async {
                  final handle = Pop.confirm(
                    const ConfirmConfig(
                      title: '将被外部关闭',
                      content: '1 秒后 dismiss',
                      cancelText: '取消',
                    ),
                  ).requireHandle();
                  await Future<void>.delayed(const Duration(seconds: 1));
                  await handle.dismiss();
                  final outcome = await handle.outcome;
                  if (!mounted) return;
                  _setLast('外部关闭 reason=${outcome.reason.name}');
                },
              ),
            ],
          ),
          LabGroup(
            title: 'Date',
            children: [
              LabAction(
                label: '选择生日',
                onPressed: () async {
                  final date = await Pop.date(
                    DateConfig(
                      initialDate: DateTime(1995, 6, 15),
                      minDate: DateTime(1960),
                      maxDate: DateTime.now(),
                      labels: const DateLabels(
                        title: '生日',
                        confirm: '确定',
                        cancel: '取消',
                      ),
                    ),
                  ).result;
                  _setLast(date == null ? 'Date 取消' : 'Date=$date');
                },
              ),
              LabAction(
                label: '自定义 Date 样式',
                outlined: true,
                onPressed: () async {
                  final scheme = Theme.of(context).colorScheme;
                  final date = await Pop.date(
                    DateConfig(
                      initialDate: DateTime.now(),
                      minDate: DateTime(2000),
                      maxDate: DateTime.now(),
                      labels: const DateLabels(
                        title: '训练日',
                        confirm: '选用',
                        cancel: '取消',
                      ),
                      style: DateStyle(
                        activeColor: scheme.primary,
                        inactiveColor: scheme.onSurfaceVariant,
                        headerBackgroundColor: scheme.primaryContainer,
                        height: 200,
                        radius: 20,
                      ),
                    ),
                  ).result;
                  _setLast(date == null ? 'Date 取消' : 'Date=$date');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
