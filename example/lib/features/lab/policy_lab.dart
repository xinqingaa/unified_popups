import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

import 'lab_section.dart';
import 'lab_shell.dart';

/// 返回键、路由归属、ownership、persist。
class PolicyLabPage extends StatefulWidget {
  const PolicyLabPage({super.key});

  @override
  State<PolicyLabPage> createState() => _PolicyLabPageState();
}

class _PolicyLabPageState extends State<PolicyLabPage> {
  String _note = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: labAppBar(context, 'Lab · 策略'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const LabBanner(
            text: '验证 BackPolicy、RoutePolicy、Ownership。'
                '系统返回从最上层参与返回的 Entry 开始；Toast ignore、Loading block。',
          ),
          const SizedBox(height: 8),
          LabStatusBar(extra: _note.isEmpty ? null : _note),
          LabGroup(
            title: '返回顺序',
            children: [
              LabAction(
                label: '叠层：Sheet + Loading + Toast',
                subtitle: '返回应：忽略 Toast → block Loading → 再关 Sheet',
                onPressed: () async {
                  unawaited(
                    Pop.sheet<void>(
                      title: '底层 Sheet',
                      maxHeight: const SheetDimension.fraction(0.4),
                      childBuilder: (d) => const Text(
                        '先出 Toast 与 Loading，再连按系统返回观察顺序。',
                      ),
                    ),
                  );
                  await Future<void>.delayed(const Duration(milliseconds: 400));
                  Pop.loading(
                    message: 'block 返回 · 8s',
                    duration: const Duration(seconds: 8),
                  );
                  Pop.toast(
                    'ignore 返回',
                    duration: const Duration(seconds: 8),
                  );
                  setState(() => _note = '请连续按系统返回');
                },
              ),
              LabAction(
                label: '手动 Pop.handleBack()',
                outlined: true,
                onPressed: () async {
                  final handled = await Pop.handleBack();
                  setState(() => _note = 'handleBack → $handled');
                },
              ),
            ],
          ),
          LabGroup(
            title: '路由策略',
            children: [
              LabAction(
                label: 'persist Toast 后 push 下一页',
                subtitle: 'Toast 应仍在',
                onPressed: () {
                  Pop.openToast(
                    const ToastConfig(
                      message: '跨路由 persist Toast',
                      position: PopupPosition.bottom,
                      lifetime: PopupLifetime.after(Duration(seconds: 8)),
                      behavior: PopupBehaviorConfig(
                        channel: PopupChannel.toast,
                        routePolicy: PopupRoutePolicy.persist,
                        backPolicy: PopupBackPolicy.ignore,
                      ),
                    ),
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const _RouteProbePage(
                        title: 'persist 探测页',
                        hint: '底部 Toast 应仍然可见；返回本 Lab。',
                      ),
                    ),
                  );
                },
              ),
              LabAction(
                label: 'owner 路由 Confirm 后 push',
                subtitle: 'Confirm 应随路由变化关闭',
                outlined: true,
                onPressed: () {
                  Pop.openConfirm(
                    const ConfirmConfig(
                      title: '所属路由 Confirm',
                      content: 'push 后应自动关闭',
                      cancelText: '取消',
                      behavior: PopupBehaviorConfig(
                        channel: PopupChannel.confirm,
                        routePolicy:
                            PopupRoutePolicy.dismissWhenOwnerRouteChanges,
                      ),
                    ),
                  );
                  Future<void>.delayed(const Duration(milliseconds: 500), () {
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const _RouteProbePage(
                          title: 'owner 探测页',
                          hint: 'Confirm 应已消失。',
                        ),
                      ),
                    );
                  });
                },
              ),
              LabAction(
                label: 'captureRoute 异步后再弹',
                subtitle: '模拟请求完成后在原路由展示',
                outlined: true,
                onPressed: () async {
                  final owner = Pop.captureRoute();
                  setState(() => _note = '已 captureRoute，模拟请求 1s…');
                  await Future<void>.delayed(const Duration(seconds: 1));
                  if (!mounted) return;
                  Pop.openConfirm(
                    ConfirmConfig(
                      title: '异步归属',
                      content: '使用 capture 的 routeOwner',
                      cancelText: '取消',
                      ownership: PopupOwnership(routeToken: owner),
                      behavior: const PopupBehaviorConfig(
                        channel: PopupChannel.confirm,
                        routePolicy:
                            PopupRoutePolicy.dismissWhenOwnerRouteChanges,
                      ),
                    ),
                  );
                  setState(() => _note = '已用 captureRoute 打开 Confirm');
                },
              ),
              LabAction(
                label: 'capture 后先离开页面再弹',
                subtitle: 'token 失效则不应入场',
                tonal: true,
                onPressed: () async {
                  final owner = Pop.captureRoute();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _RouteProbePage(
                        title: '离开后再弹',
                        hint: '1s 后尝试用旧 token 弹 Confirm，应被 routeChanged 收口。',
                        onReady: () async {
                          await Future<void>.delayed(
                              const Duration(seconds: 1));
                          Pop.openConfirm(
                            ConfirmConfig(
                              title: '不应出现',
                              content: '若看到此框，说明失效 token 未拦截',
                              cancelText: '取消',
                              ownership: PopupOwnership(routeToken: owner),
                              behavior: const PopupBehaviorConfig(
                                channel: PopupChannel.confirm,
                                routePolicy: PopupRoutePolicy
                                    .dismissWhenOwnerRouteChanges,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          LabGroup(
            title: 'Ownership',
            children: [
              LabAction(
                label: 'Sheet + 子 Confirm（关 Sheet 级联）',
                onPressed: () {
                  Pop.sheet<void>(
                    title: '父 Sheet',
                    maxHeight: const SheetDimension.fraction(0.45),
                    childBuilder: (dismiss) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton(
                          onPressed: () {
                            Pop.openConfirm(
                              const ConfirmConfig(
                                title: '子 Confirm',
                                content: 'dismissWithParent',
                                cancelText: '取消',
                              ),
                            );
                          },
                          child: const Text('打开子 Confirm'),
                        ),
                        const SizedBox(height: 8),
                        const Text('打开 Confirm 后点关闭 Sheet，Confirm 应一并消失。'),
                        TextButton(
                          onPressed: dismiss,
                          child: const Text('关闭父 Sheet'),
                        ),
                      ],
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

class _RouteProbePage extends StatefulWidget {
  const _RouteProbePage({
    required this.title,
    required this.hint,
    this.onReady,
  });

  final String title;
  final String hint;
  final Future<void> Function()? onReady;

  @override
  State<_RouteProbePage> createState() => _RouteProbePageState();
}

class _RouteProbePageState extends State<_RouteProbePage> {
  @override
  void initState() {
    super.initState();
    final onReady = widget.onReady;
    if (onReady != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onReady());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(widget.hint, style: const TextStyle(height: 1.5)),
      ),
    );
  }
}
