import 'package:flutter/material.dart';

import 'async_lab.dart';
import 'confirm_date_lab.dart';
import 'custom_handle_lab.dart';
import 'flow_sheet_lab.dart';
import 'lab_page.dart';
import 'lab_section.dart';
import 'loading_lab.dart';
import 'menu_lab.dart';
import 'policy_lab.dart';
import 'config_lab.dart';
import 'sheet_lab.dart';
import 'toast_lab.dart';

/// API 展柜外壳：AppBar 右上角常驻 Entry 计数，子页滚动时仍可见。
class LabShell extends StatelessWidget {
  const LabShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 展柜'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: LabEntryBadge()),
          ),
        ],
      ),
      body: const LabCatalog(),
    );
  }
}

/// Shared AppBar for lab sub-pages (keeps badge visible while scrolling).
PreferredSizeWidget labAppBar(BuildContext context, String title) {
  return AppBar(
    title: Text(title),
    actions: const [
      Padding(
        padding: EdgeInsets.only(right: 12),
        child: Center(child: LabEntryBadge()),
      ),
    ],
  );
}

void pushLabPage(BuildContext context, Widget page) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => page),
  );
}

/// Catalog body used by [LabShell] and legacy [LabPage].
class LabCatalog extends StatelessWidget {
  const LabCatalog({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const LabBanner(
          text: '按类型集中验收整库能力。右上角徽章随滚动保持可见。'
              '「通用 Config」演示便捷 API 与高级 Config 两层用法。',
        ),
        const SizedBox(height: 12),
        ...labEntries.map((e) => _LabTile(entry: e)),
      ],
    );
  }
}

class LabNavEntry {
  const LabNavEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}

final labEntries = <LabNavEntry>[
  LabNavEntry(
    icon: Icons.tune,
    title: '通用 Config',
    subtitle: '两层 API · Barrier / Behavior / Lifetime / Ownership',
    builder: (_) => const ConfigLabPage(),
  ),
  LabNavEntry(
    icon: Icons.notifications_active_outlined,
    title: 'Toast',
    subtitle: '类型 · 位置 · lifetime · 队列 · toggle · barrier',
    builder: (_) => const ToastLabPage(),
  ),
  LabNavEntry(
    icon: Icons.hourglass_top_outlined,
    title: 'Loading',
    subtitle: '原地更新 · 长文案 · 双 Loading · Handle',
    builder: (_) => const LoadingLabPage(),
  ),
  LabNavEntry(
    icon: Icons.help_outline,
    title: 'Confirm / Date',
    subtitle: '按钮语义 · outcome · 堆叠 · 日期选择',
    builder: (_) => const ConfirmDateLabPage(),
  ),
  LabNavEntry(
    icon: Icons.vertical_align_bottom,
    title: 'Sheet',
    subtitle: '四方向 · 拖拽（指示器仅底部）· 键盘 · dock',
    builder: (_) => const SheetLabPage(),
  ),
  LabNavEntry(
    icon: Icons.view_carousel_outlined,
    title: 'FlowSheet',
    subtitle: '全屏 / 半屏 · 返回委托 · 产品 Flow',
    builder: (_) => const FlowSheetLabPage(),
  ),
  LabNavEntry(
    icon: Icons.more_vert,
    title: 'Menu Anchor',
    subtitle: '默认无遮罩跟随 · showBarrier 对比',
    builder: (_) => const MenuLabPage(),
  ),
  LabNavEntry(
    icon: Icons.extension_outlined,
    title: 'Custom / Handle',
    subtitle: 'outcome/dismissed · tags/channel · 查询',
    builder: (_) => const CustomHandleLabPage(),
  ),
  LabNavEntry(
    icon: Icons.rule_folder_outlined,
    title: '策略',
    subtitle: '返回顺序 · 路由归属 · Ownership',
    builder: (_) => const PolicyLabPage(),
  ),
  LabNavEntry(
    icon: Icons.schedule,
    title: '异步边界',
    subtitle: 'Future / Stream / Timer / build 阶段',
    builder: (_) => const AsyncLabPage(),
  ),
];

class _LabTile extends StatelessWidget {
  const _LabTile({required this.entry});

  final LabNavEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(entry.icon),
          title: Text(entry.title),
          subtitle: Text(entry.subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => pushLabPage(context, entry.builder(context)),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
