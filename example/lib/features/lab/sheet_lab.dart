import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

import 'lab_section.dart';
import 'lab_shell.dart';

/// Sheet：方向、拖拽模式、键盘、dock、样式、堆叠。
class SheetLabPage extends StatelessWidget {
  const SheetLabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: labAppBar(context, 'Lab · Sheet'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          LabBanner(
            text: 'Sheet 全能力：四方向、三种拖拽、回弹/速度阈值、键盘避让、'
                'dockToEdge、SafeArea、重内容拖拽、与 Confirm/Toast 堆叠。'
                '拖拽指示器仅底部方向显示。',
          ),
          SizedBox(height: 8),
          LabStatusBar(),
          _DirectionGroup(),
          _DragModeGroup(),
          _KeyboardDockGroup(),
          _StackGroup(),
        ],
      ),
    );
  }
}

class _DirectionGroup extends StatelessWidget {
  const _DirectionGroup();

  @override
  Widget build(BuildContext context) {
    return LabGroup(
      title: '方向',
      children: [
        for (final direction in SheetDirection.values)
          LabAction(
            label: direction.name,
            outlined: direction != SheetDirection.bottom,
            onPressed: () {
              Pop.sheet<void>(
                title: '方向 · ${direction.name}',
                direction: direction,
                maxHeight: direction == SheetDirection.left ||
                        direction == SheetDirection.right
                    ? null
                    : const SheetDimension.fraction(0.45),
                maxWidth: direction == SheetDirection.left ||
                        direction == SheetDirection.right
                    ? const SheetDimension.fraction(0.75)
                    : null,
                childBuilder: (dismiss) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('当前方向：${direction.name}'),
                    const SizedBox(height: 12),
                    const Spacer(),
                    FilledButton(onPressed: dismiss, child: const Text('关闭')),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _DragModeGroup extends StatelessWidget {
  const _DragModeGroup();

  @override
  Widget build(BuildContext context) {
    return LabGroup(
      title: '拖拽模式',
      subtitle: '指示器仅底部 Sheet 显示。左右 handleOnly 请用标题栏拖关。',
      children: [
        LabAction(
          label: 'fullBody',
          onPressed: () => _openDragSheet(
            context,
            mode: SheetDragDismissMode.fullBody,
            body: const Text('整页可拖关闭'),
          ),
        ),
        LabAction(
          label: 'contentWhenAtTop',
          subtitle: '列表在顶部时下拉关闭',
          outlined: true,
          onPressed: () => _openDragSheet(
            context,
            mode: SheetDragDismissMode.contentWhenAtTop,
            body: ListView.builder(
              itemCount: 30,
              itemBuilder: (_, i) => ListTile(title: Text('行 $i')),
            ),
            tall: true,
          ),
        ),
        LabAction(
          label: 'handleOnly',
          subtitle: '仅手柄/标题可拖',
          outlined: true,
          onPressed: () => _openDragSheet(
            context,
            mode: SheetDragDismissMode.handleOnly,
            body: ListView.builder(
              itemCount: 20,
              itemBuilder: (_, i) => ListTile(title: Text('内容 $i · 正文不可拖关')),
            ),
            tall: true,
          ),
        ),
        LabAction(
          label: '水平 Sheet + handleOnly',
          subtitle: '无指示器；拖标题栏关闭',
          outlined: true,
          onPressed: () {
            Pop.sheet<void>(
              title: '左侧面板',
              direction: SheetDirection.left,
              maxWidth: const SheetDimension.fraction(0.8),
              dragDismissMode: SheetDragDismissMode.handleOnly,
              childBuilder: (dismiss) => ListView(
                children: [
                  const ListTile(
                    title: Text('无底部指示器；请拖标题栏关闭'),
                  ),
                  for (var i = 0; i < 12; i++) ListTile(title: Text('项 $i')),
                  ListTile(
                    title: FilledButton(
                      onPressed: dismiss,
                      child: const Text('关闭'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  static void _openDragSheet(
    BuildContext context, {
    required SheetDragDismissMode mode,
    required Widget body,
    bool tall = false,
  }) {
    Pop.sheet<void>(
      title: '拖拽 · ${mode.name}',
      showDragHandle: true,
      dragDismissMode: mode,
      maxHeight: SheetDimension.fraction(tall ? 0.7 : 0.4),
      childBuilder: (dismiss) {
        if (!tall) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              body,
              const SizedBox(height: 12),
              TextButton(onPressed: dismiss, child: const Text('关闭')),
            ],
          );
        }
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: Column(
            children: [
              Expanded(child: body),
              TextButton(onPressed: dismiss, child: const Text('关闭')),
            ],
          ),
        );
      },
    );
  }
}

class _KeyboardDockGroup extends StatelessWidget {
  const _KeyboardDockGroup();

  @override
  Widget build(BuildContext context) {
    return LabGroup(
      title: '键盘 / dock / 样式',
      children: [
        LabAction(
          label: '键盘避让输入',
          onPressed: () {
            Pop.sheet<void>(
              title: '备注',
              adjustForKeyboard: true,
              maxHeight: const SheetDimension.fraction(0.5),
              childBuilder: (dismiss) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TextField(
                    decoration: InputDecoration(
                      hintText: '聚焦后键盘应顶起 Sheet',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: dismiss, child: const Text('完成')),
                ],
              ),
            );
          },
        ),
        LabAction(
          label: 'dockToEdge（底栏可点透）',
          subtitle: 'edgeGap 对齐导航栏高度',
          outlined: true,
          onPressed: () {
            Pop.sheet<void>(
              title: '贴边 Sheet',
              dockToEdge: true,
              edgeGap: 80,
              maxHeight: const SheetDimension.fraction(0.4),
              childBuilder: (dismiss) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('遮罩不应盖住底部导航区域，可尝试点下方 Tab。'),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: dismiss, child: const Text('关闭')),
                ],
              ),
            );
          },
        ),
        LabAction(
          label: '自定义背景 / 圆角 / 无手柄',
          outlined: true,
          onPressed: () {
            Pop.sheet<void>(
              title: '样式 Sheet',
              showDragHandle: false,
              showCloseButton: true,
              backgroundColor: const Color(0xFF1B2A41),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              maxHeight: const SheetDimension.fraction(0.35),
              childBuilder: (dismiss) => const Text(
                '自定义 SheetStyle',
                style: TextStyle(color: Colors.white70),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StackGroup extends StatelessWidget {
  const _StackGroup();

  @override
  Widget build(BuildContext context) {
    return LabGroup(
      title: '堆叠',
      children: [
        LabAction(
          label: 'Sheet → Confirm → Toast',
          onPressed: () {
            Pop.sheet<void>(
              title: '堆叠演示',
              maxHeight: const SheetDimension.fraction(0.45),
              childBuilder: (dismiss) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    onPressed: () async {
                      final ok = await Pop.confirm(
                        title: '继续？',
                        content: 'Confirm 在 Sheet 之上',
                        cancelText: '取消',
                      );
                      Pop.toast(
                        ok == true ? '已确认' : '未确认 ($ok)',
                        toastType:
                            ok == true ? ToastType.success : ToastType.warn,
                      );
                    },
                    child: const Text('打开 Confirm'),
                  ),
                  TextButton(onPressed: dismiss, child: const Text('关闭 Sheet')),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
