import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

import 'lab_section.dart';
import 'lab_shell.dart';

/// Loading：单例更新、Handle、lifetime、返回 block、样式。
class LoadingLabPage extends StatefulWidget {
  const LoadingLabPage({super.key});

  @override
  State<LoadingLabPage> createState() => _LoadingLabPageState();
}

class _LoadingLabPageState extends State<LoadingLabPage> {
  LoadingHandle? _handle;
  String _note = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: labAppBar(context, 'Lab · Loading'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const LabBanner(
            text: '默认全局 key + updateExisting：重复调用更新同一 Entry。'
                '系统返回默认 block。可用 Handle / hideLoading / until 关闭。',
          ),
          const SizedBox(height: 8),
          LabStatusBar(extra: _note.isEmpty ? null : _note),
          LabGroup(
            title: '基础与更新',
            children: [
              LabAction(
                label: '分阶段更新文案',
                subtitle: '同一 Loading，不闪进出场',
                onPressed: () {
                  Pop.loading(
                    message: '第一阶段…',
                    duration: const Duration(seconds: 5),
                  );
                  Future<void>.delayed(const Duration(seconds: 1), () {
                    Pop.loading(
                      message: '第二阶段：计时已重置',
                      duration: const Duration(seconds: 3),
                    );
                  });
                  Future<void>.delayed(const Duration(milliseconds: 2200), () {
                    Pop.loading(
                      message: '即将完成…',
                      duration: const Duration(seconds: 2),
                    );
                  });
                  setState(() => _note = '已触发三次 loading 更新');
                },
              ),
              LabAction(
                label: '保存 Handle → update → dismiss',
                outlined: true,
                onPressed: () async {
                  final handle = Pop.loading(message: 'Handle 持有中…');
                  setState(() {
                    _handle = handle;
                    _note = 'handle.isActive=${handle.isActive}';
                  });
                  await Future<void>.delayed(const Duration(seconds: 1));
                  if (!mounted) return;
                  handle
                      .update(const LoadingConfig(message: 'Handle.update()'));
                  setState(() => _note = '已 update');
                  await Future<void>.delayed(const Duration(seconds: 1));
                  if (!mounted) return;
                  await handle.dismiss();
                  setState(() {
                    _handle = null;
                    _note = 'handle 已 dismiss';
                  });
                },
              ),
              LabAction(
                label: 'Pop.hideLoading()',
                outlined: true,
                onPressed: () async {
                  Pop.loading(message: '可被 hideLoading 强制关闭');
                  await Future<void>.delayed(const Duration(milliseconds: 600));
                  await Pop.hideLoading();
                  if (mounted) setState(() => _note = 'hideLoading 完成');
                },
              ),
              LabAction(
                label: '关闭当前 Handle（若有）',
                outlined: true,
                onPressed: _handle?.isActive == true
                    ? () async {
                        await _handle?.dismiss();
                        if (mounted) {
                          setState(() {
                            _handle = null;
                            _note = '手动关闭 Handle';
                          });
                        }
                      }
                    : null,
              ),
            ],
          ),
          LabGroup(
            title: 'Lifetime',
            children: [
              LabAction(
                label: 'until：1.5s Future',
                onPressed: () {
                  final done =
                      Future<void>.delayed(const Duration(milliseconds: 1500));
                  Pop.loading(message: 'until 关闭中…', until: done);
                },
              ),
              LabAction(
                label: '仅 duration 2s',
                outlined: true,
                onPressed: () {
                  Pop.loading(
                    message: '2 秒后自动关',
                    duration: const Duration(seconds: 2),
                  );
                },
              ),
            ],
          ),
          LabGroup(
            title: '返回键与多 key',
            children: [
              LabAction(
                label: '打开 Loading 后按系统返回',
                subtitle: '应挡住返回，Loading 不关',
                onPressed: () {
                  Pop.loading(
                    message: '返回应被 block · 2s 后自动关',
                    duration: const Duration(seconds: 2),
                  );
                  setState(() => _note = '请立即按系统返回键验证 block');
                },
              ),
              LabAction(
                label: '长文案（不应截断）',
                outlined: true,
                onPressed: () {
                  Pop.loading(
                    message: '正在同步健康数据并写入本地缓存，请稍候…',
                    duration: const Duration(seconds: 3),
                  );
                },
              ),
              LabAction(
                label: '不同 key 并存（分位置 + 颜色）',
                subtitle: '顶部上传 · 底部导出，可同时看见',
                outlined: true,
                onPressed: () {
                  Pop.openLoading(
                    const LoadingConfig(
                      message: '上传头像…',
                      position: PopupPosition.top,
                      style: LoadingStyle(
                        backgroundColor: Color(0xCC1565C0),
                      ),
                      barrier: PopupBarrierConfig(
                        visible: true,
                        dismissible: false,
                        color: Color(0x33000000),
                      ),
                      behavior: PopupBehaviorConfig(
                        channel: PopupChannel.loading,
                        key: 'lab.loading.upload',
                        conflictPolicy: PopupConflictPolicy.stack,
                        backPolicy: PopupBackPolicy.block,
                      ),
                      lifetime: PopupLifetime.after(Duration(seconds: 4)),
                    ),
                  );
                  Pop.openLoading(
                    const LoadingConfig(
                      message: '导出周报到本地…',
                      position: PopupPosition.bottom,
                      style: LoadingStyle(
                        backgroundColor: Color(0xCC2E7D32),
                      ),
                      barrier: PopupBarrierConfig.hidden(),
                      behavior: PopupBehaviorConfig(
                        channel: PopupChannel.loading,
                        key: 'lab.loading.export',
                        conflictPolicy: PopupConflictPolicy.stack,
                        backPolicy: PopupBackPolicy.block,
                      ),
                      lifetime: PopupLifetime.after(Duration(seconds: 4)),
                    ),
                  );
                  setState(
                    () => _note =
                        'count=${Pop.countChannel(PopupChannel.loading)} · 看顶部蓝 / 底部绿',
                  );
                },
              ),
            ],
          ),
          LabGroup(
            title: '样式',
            children: [
              LabAction(
                label: '自定义指示器',
                onPressed: () {
                  Pop.openLoading(
                    LoadingConfig(
                      message: '自定义 indicator',
                      indicator: LoadingIndicatorConfig(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CustomPaint(painter: _PulsePainter()),
                        ),
                        rotationDuration: const Duration(milliseconds: 900),
                      ),
                      lifetime: const PopupLifetime.after(Duration(seconds: 2)),
                    ),
                  );
                },
              ),
              LabAction(
                label: 'messageWidget',
                outlined: true,
                onPressed: () {
                  Pop.loading(
                    messageWidget: const Text(
                      '富文本 Loading',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    duration: const Duration(seconds: 2),
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

class _PulsePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.lightBlueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.shortestSide / 2 - 2,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.shortestSide / 4,
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
