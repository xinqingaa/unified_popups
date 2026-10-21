import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

import 'lab_section.dart';
import 'lab_shell.dart';

const _pageColor = Color(0xFFF2F2F7);
const _ink = Color(0xFF1C1C1E);
const _paper = Color(0xFFFFFFFF);
const _line = Color(0xFFE5E5EA);

const _lightGlass = LiquidGlassStyle(
  backgroundColor: Color(0xE6FFFFFF),
  borderColor: Color(0x14000000),
  topHighlightColor: Color(0xFFFFFFFF),
  blurSigma: 18,
);

const _darkGlass = LiquidGlassStyle(
  backgroundColor: Color(0xF21C1C1E),
  borderColor: Color(0x33FFFFFF),
  topHighlightColor: Color(0x40FFFFFF),
  blurSigma: 22,
);

const _darkTitle = TextStyle(
  color: _ink,
  fontSize: 20,
  fontWeight: FontWeight.w600,
);
const _darkBody = TextStyle(color: _ink, height: 1.4);
const _lightTitle = TextStyle(
  color: _paper,
  fontSize: 20,
  fontWeight: FontWeight.w600,
);
const _lightBody = TextStyle(color: Color(0xFFF2F2F7), height: 1.4);

const _seeThroughBarrier = PopupBarrierConfig(
  dismissible: true,
  color: Color(0x14000000),
);

const _dismissBack = PopupBehaviorConfig(
  backPolicy: PopupBackPolicy.dismiss,
);

Widget _darkAction(String label, VoidCallback onTap) {
  return FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: _ink,
      foregroundColor: _paper,
      side: const BorderSide(color: Color(0x33FFFFFF)),
    ),
    onPressed: onTap,
    child: Text(label),
  );
}

Widget _lightAction(String label, VoidCallback onTap) {
  return FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: _paper,
      foregroundColor: _ink,
      side: const BorderSide(color: _line),
    ),
    onPressed: onTap,
    child: Text(label),
  );
}

/// 玻璃容器：Confirm / Sheet / FlowSheet / Menu / DropMenu，以及页面内的 LiquidGlass。
class GlassLabPage extends StatelessWidget {
  const GlassLabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageColor,
      appBar: labAppBar(context, 'Lab · 玻璃容器'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const LabBanner(
            text: '页面是淡灰白。浅玻璃接近白色，深玻璃接近黑色，填充比刚才更实。'
                '按钮和文字仍是一深一浅。',
          ),
          const SizedBox(height: 8),
          const LabStatusBar(),
          LabGroup(
            title: 'Confirm',
            children: [
              _ToneButton(
                label: '浅玻璃',
                subtitle: '浅底 · 深色字 · 圆角 12',
                dark: false,
                onPressed: _standardConfirm,
              ),
              _ToneButton(
                label: '深玻璃',
                subtitle: '深底 · 浅色字 · blur 22',
                dark: true,
                onPressed: _darkConfirm,
              ),
              _ToneButton(
                label: '外部容器 + 自定义描边',
                subtitle: 'builder 包一层浅玻璃，描边继承默认 painter',
                dark: false,
                onPressed: _customConfirm,
              ),
            ],
          ),
          LabGroup(
            title: 'Sheet',
            children: [
              _ToneButton(
                label: '底部浅玻璃',
                subtitle: '进入边圆角 32 · 深色字 · 可下拉关闭',
                dark: true,
                onPressed: _bottomSheet,
              ),
              _ToneButton(
                label: '悬浮浅玻璃',
                subtitle: 'dock 16 · 四角 28 · 略浅一点',
                dark: false,
                onPressed: _floatingSheet,
              ),
              _ToneButton(
                label: '左侧浅玻璃',
                subtitle: '方向 left · 右侧纯色透进面板',
                dark: true,
                onPressed: _sideSheet,
              ),
              _ToneButton(
                label: '外部深玻璃',
                subtitle: 'builder 使用深色填充和浅色字',
                dark: false,
                onPressed: _customSheet,
              ),
            ],
          ),
          LabGroup(
            title: 'FlowSheet',
            children: [
              _ToneButton(
                label: '两页浅玻璃',
                subtitle: '内页底透明 · 深色字落在玻璃上',
                dark: true,
                onPressed: _flowSheet,
              ),
            ],
          ),
          const _MenuGlassGroup(),
          const LabGroup(
            title: '页面内直接使用',
            subtitle: 'import package:unified_popups/liquid_glass.dart',
            children: [
              _InlineGlassSamples(),
            ],
          ),
        ],
      ),
    );
  }

  void _standardConfirm() {
    Pop.confirm(
      ConfirmConfig(
        title: '保存更改',
        content: '浅玻璃，接近白色，深色字落在上面。',
        confirmText: '保存',
        cancelText: '取消',
        style: const ConfirmStyle(
          surface: PopupSurface.glass(style: _lightGlass),
          titleStyle: _darkTitle,
          contentStyle: _darkBody,
        ),
        confirmButton: (onTap) => _darkAction('保存', onTap),
        cancelButton: (onTap) => _lightAction('取消', onTap),
        barrier: _seeThroughBarrier,
        behavior: _dismissBack,
      ),
    );
  }

  void _darkConfirm() {
    Pop.confirm(
      ConfirmConfig(
        title: '深色玻璃',
        content: '深玻璃配浅色字。填充更透，底色仍然能看见。',
        confirmText: '知道了',
        cancelText: '关闭',
        style: const ConfirmStyle(
          surface: PopupSurface.glass(style: _darkGlass),
          titleStyle: _lightTitle,
          contentStyle: _lightBody,
        ),
        confirmButton: (onTap) => _darkAction('知道了', onTap),
        cancelButton: (onTap) => _lightAction('关闭', onTap),
        barrier: _seeThroughBarrier,
        behavior: _dismissBack,
      ),
    );
  }

  void _customConfirm() {
    Pop.confirm(
      ConfirmConfig(
        title: '外部容器',
        content: '壳由调用方绘制。浅底、深色字，描边继承默认 painter。',
        confirmText: '好',
        cancelText: '取消',
        style: ConfirmStyle(
          borderRadius: BorderRadius.circular(28),
          titleStyle: _darkTitle,
          contentStyle: _darkBody,
          surface: PopupSurface.builder((context, slot) {
            return LiquidGlass(
              borderRadius: slot.borderRadius,
              style: _lightGlass,
              enableShadow: true,
              backdropBlendMode: BlendMode.src,
              edgePainterBuilder: (radius, style) => _LightRimPainter(
                borderRadius: radius,
                style: style,
              ),
              child: slot.child,
            );
          }),
        ),
        confirmButton: (onTap) => _darkAction('好', onTap),
        cancelButton: (onTap) => _lightAction('取消', onTap),
        barrier: _seeThroughBarrier,
        behavior: _dismissBack,
      ),
    );
  }

  void _bottomSheet() {
    Pop.sheet<void>(
      SheetConfig<void>(
        header: const SheetHeaderConfig(
          title: '底部浅玻璃',
          titleStyle: _darkTitle,
          showCloseButton: true,
        ),
        size: const SheetSizeConfig(height: SheetDimension.fraction(0.42)),
        style: const SheetStyle(
          surface: PopupSurface.glass(style: _lightGlass),
        ),
        barrier: _seeThroughBarrier,
        builder: (context, handle) => const Text(
          '默认进入边圆角 32。下拉或点关闭都可以离开。',
          style: _darkBody,
        ),
      ),
    );
  }

  void _floatingSheet() {
    Pop.sheet<void>(
      SheetConfig<void>(
        header: const SheetHeaderConfig(
          title: '悬浮浅玻璃',
          titleStyle: _darkTitle,
        ),
        size: const SheetSizeConfig(height: SheetDimension.fraction(0.36)),
        dock: const SheetDockConfig(enabled: true, edgeGap: 16),
        style: SheetStyle(
          borderRadius: BorderRadius.circular(28),
          surface: const PopupSurface.glass(
            style: LiquidGlassStyle(
              backgroundColor: Color(0xD9FFFFFF),
              borderColor: Color(0x14000000),
              topHighlightColor: Color(0xFFFFFFFF),
              blurSigma: 16,
            ),
          ),
        ),
        barrier: _seeThroughBarrier,
        builder: (context, handle) => const Text(
          '四周留出缝。这一块比标准浅玻璃略透一点。',
          style: _darkBody,
        ),
      ),
    );
  }

  void _sideSheet() {
    Pop.sheet<void>(
      SheetConfig<void>(
        direction: SheetDirection.left,
        header: const SheetHeaderConfig(
          title: '左侧浅玻璃',
          titleStyle: _darkTitle,
          showCloseButton: true,
        ),
        size: const SheetSizeConfig(width: SheetDimension.fraction(0.72)),
        style: const SheetStyle(
          surface: PopupSurface.glass(style: _lightGlass),
        ),
        barrier: _seeThroughBarrier,
        builder: (context, handle) => const Text(
          '面板在左边。右边的纯色会透进玻璃。',
          style: _darkBody,
        ),
      ),
    );
  }

  void _customSheet() {
    Pop.sheet<void>(
      SheetConfig<void>(
        header: const SheetHeaderConfig(
          title: '外部深玻璃',
          titleStyle: _lightTitle,
        ),
        size: const SheetSizeConfig(height: SheetDimension.fraction(0.4)),
        style: SheetStyle(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          surface: PopupSurface.builder((context, slot) {
            return LiquidGlass(
              borderRadius: slot.borderRadius,
              style: _darkGlass,
              enableShadow: true,
              backdropBlendMode: BlendMode.src,
              child: slot.child,
            );
          }),
        ),
        barrier: _seeThroughBarrier,
        builder: (context, handle) => const Text(
          'builder 拿到内容和圆角。这里用深玻璃和浅色字。',
          style: _lightBody,
        ),
      ),
    );
  }

  void _flowSheet() {
    final controller = FlowSheetController<void>();
    Pop.flowSheet<void>(
      FlowSheetConfig<void>(
        controller: controller,
        initialPage: const _GlassFlowRootPage(),
        header: const SheetHeaderConfig(
          title: '浅玻璃 Flow',
          titleStyle: _darkTitle,
          showCloseButton: true,
        ),
        size: const SheetSizeConfig(height: SheetDimension.fraction(0.58)),
        style: const SheetStyle(
          surface: PopupSurface.glass(style: _lightGlass),
        ),
        barrier: _seeThroughBarrier,
      ),
    );
  }
}

class _GlassFlowRootPage extends FlowSheetPage<void> {
  const _GlassFlowRootPage() : super(id: 'glass-root');

  @override
  State<_GlassFlowRootPage> createState() => _GlassFlowRootPageState();
}

class _GlassFlowRootPageState
    extends FlowSheetPageState<_GlassFlowRootPage, void> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '首页没有实色底，深色字直接落在浅玻璃上。',
          style: _darkBody,
        ),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _ink,
            foregroundColor: _paper,
          ),
          onPressed: () => nav.push(const _GlassFlowDetailPage()),
          child: const Text('下一页'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _paper,
            foregroundColor: _ink,
          ),
          onPressed: () => nav.closeAll(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

class _GlassFlowDetailPage extends FlowSheetPage<void> {
  const _GlassFlowDetailPage() : super(id: 'glass-detail');

  @override
  State<_GlassFlowDetailPage> createState() => _GlassFlowDetailPageState();
}

class _GlassFlowDetailPageState
    extends FlowSheetPageState<_GlassFlowDetailPage, void> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '第二页同样透明，深色字落在同一块浅玻璃上。',
          style: _darkBody,
        ),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _ink,
            foregroundColor: _paper,
          ),
          onPressed: () => nav.pop(),
          child: const Text('返回'),
        ),
      ],
    );
  }
}

class _MenuGlassGroup extends StatefulWidget {
  const _MenuGlassGroup();

  @override
  State<_MenuGlassGroup> createState() => _MenuGlassGroupState();
}

class _MenuGlassGroupState extends State<_MenuGlassGroup> {
  final _menuAnchor = PopupAnchorController();
  final _menuBuilderAnchor = PopupAnchorController();
  final _dropAnchor = PopupAnchorController();
  final _dropCustomAnchor = PopupAnchorController();

  @override
  void dispose() {
    _menuAnchor.attached.dispose();
    _menuBuilderAnchor.attached.dispose();
    _dropAnchor.attached.dispose();
    _dropCustomAnchor.attached.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LabGroup(
      title: 'Menu / DropMenu',
      subtitle: '同一个 PopupSurface。Menu 默认实色，这里显式打开玻璃。',
      children: [
        PopupAnchor(
          controller: _menuAnchor,
          child: _ToneButton(
            label: '浅玻璃 Menu',
            subtitle: 'PopupMenuStyle.surface · 深色字 · 圆角 8',
            dark: false,
            onPressed: _glassMenu,
          ),
        ),
        PopupAnchor(
          controller: _menuBuilderAnchor,
          child: _ToneButton(
            label: '外部深色 Menu',
            subtitle: 'builder 使用深底和浅色字',
            dark: true,
            onPressed: _builderMenu,
          ),
        ),
        PopupAnchor(
          controller: _dropAnchor,
          child: _ToneButton(
            label: '默认玻璃 DropMenu',
            subtitle: '不传 surface，默认就是 PopupSurface.glass()',
            dark: false,
            onPressed: _defaultDropMenu,
          ),
        ),
        PopupAnchor(
          controller: _dropCustomAnchor,
          child: _ToneButton(
            label: '深玻璃 DropMenu',
            subtitle: '深底 · 浅色字 · blurSigma 32',
            dark: true,
            onPressed: _customDropMenu,
          ),
        ),
      ],
    );
  }

  void _glassMenu() {
    Pop.menu<void>(
      MenuConfig<void>(
        anchor: _menuAnchor,
        placement: MenuPlacement.belowStart,
        barrier: _seeThroughBarrier,
        style: const PopupMenuStyle(
          surface: PopupSurface.glass(style: _lightGlass),
          padding: EdgeInsets.symmetric(vertical: 4),
        ),
        builder: (context, handle) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('编辑', style: TextStyle(color: _ink)),
              onTap: () => handle.complete(),
            ),
            ListTile(
              title: const Text('分享', style: TextStyle(color: _ink)),
              onTap: () => handle.complete(),
            ),
          ],
        ),
      ),
    );
  }

  void _builderMenu() {
    Pop.menu<void>(
      MenuConfig<void>(
        anchor: _menuBuilderAnchor,
        placement: MenuPlacement.belowStart,
        barrier: _seeThroughBarrier,
        style: PopupMenuStyle(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 4),
          surface: PopupSurface.builder((context, slot) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xF21C1C1E),
                borderRadius: slot.borderRadius,
                border: Border.all(color: _paper),
              ),
              child: ClipRRect(
                borderRadius: slot.borderRadius,
                child: slot.child,
              ),
            );
          }),
        ),
        builder: (context, handle) => ListTile(
          title: const Text('自定义壳', style: TextStyle(color: _paper)),
          onTap: () => handle.complete(),
        ),
      ),
    );
  }

  void _defaultDropMenu() {
    Pop.dropMenu<String>(
      DropMenuConfig<String>(
        anchor: _dropAnchor,
        placement: MenuPlacement.belowStart,
        barrier: _seeThroughBarrier,
        menu: const DropMenu<String>.single(
          items: <DropMenuItem<String>>[
            DropMenuItem<String>(value: 'all', label: '全部'),
            DropMenuItem<String>(value: 'open', label: '进行中'),
          ],
        ),
      ),
    );
  }

  void _customDropMenu() {
    Pop.dropMenu<String>(
      DropMenuConfig<String>(
        anchor: _dropCustomAnchor,
        placement: MenuPlacement.belowStart,
        barrier: _seeThroughBarrier,
        menuStyle: const DropMenuStyle(
          textColor: _paper,
          secondaryTextColor: _paper,
          selectedColor: _paper,
          arrowColor: _paper,
          dividerColor: Color(0x33FFFFFF),
          surface: PopupSurface.glass(
            blurSigma: 32,
            style: _darkGlass,
          ),
        ),
        menu: const DropMenu<String>.single(
          items: <DropMenuItem<String>>[
            DropMenuItem<String>(value: 'night', label: '深色'),
            DropMenuItem<String>(value: 'day', label: '浅色'),
          ],
        ),
      ),
    );
  }
}

class _InlineGlassSamples extends StatelessWidget {
  const _InlineGlassSamples();

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(20));
    return Column(
      children: [
        const Row(
          children: [
            Expanded(
              child: LiquidGlass(
                borderRadius: radius,
                enableShadow: true,
                backdropBlendMode: BlendMode.src,
                padding: EdgeInsets.all(16),
                style: _lightGlass,
                child: Text(
                  '浅玻璃\n深色字',
                  style: _darkBody,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: LiquidGlass(
                borderRadius: radius,
                enableShadow: true,
                backdropBlendMode: BlendMode.src,
                padding: EdgeInsets.all(16),
                style: _darkGlass,
                child: Text(
                  '深玻璃\n浅色字',
                  style: _lightBody,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LiquidGlass(
          borderRadius: radius,
          enableShadow: true,
          backdropBlendMode: BlendMode.src,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          style: _lightGlass,
          edgePainterBuilder: (borderRadius, style) => _LightRimPainter(
            borderRadius: borderRadius,
            style: style,
          ),
          child: LiquidGlassButton(
            onTap: () {},
            borderRadius: radius,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('浅底深字', style: _darkBody),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToneButton extends StatelessWidget {
  const _ToneButton({
    required this.label,
    required this.onPressed,
    required this.dark,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final VoidCallback onPressed;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final background = dark ? _ink : _paper;
    final foreground = dark ? _paper : _ink;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          side: BorderSide(color: dark ? const Color(0x33FFFFFF) : _line),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onPressed: onPressed,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: foreground.withAlpha(0xCC),
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 在默认顶缘高光之外再描一圈浅色边，演示继承 [LiquidGlassEdgePainter]。
class _LightRimPainter extends LiquidGlassEdgePainter {
  const _LightRimPainter({
    required super.borderRadius,
    required super.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    super.paint(canvas, size);
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect.deflate(1.5),
        topLeft: borderRadius.topLeft,
        topRight: borderRadius.topRight,
        bottomLeft: borderRadius.bottomLeft,
        bottomRight: borderRadius.bottomRight,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _line,
    );
  }
}
