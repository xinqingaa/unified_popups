import 'package:flutter/material.dart';

import 'flow_sheet/kyc_wizard_flow.dart';
import 'flow_sheet/order_trade_flow.dart';

/// FlowSheet 业务演示入口：两个自包含多步流程。
class FlowSheetDemoPage extends StatelessWidget {
  const FlowSheetDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FlowSheet Demos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'FlowSheet 在单个 Sheet 内维护页面栈，适合多步业务：'
            'push/pop/replace、按页拖关、生命周期与结果回传。',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 24),
          _DemoCard(
            title: 'A. 订单交易流',
            subtitle: '列表 → 详情 → 密码验证\n'
                '展示 push/pop、completeCurrent+closeAll、按页 dragDismissMode、maintainState',
            onTap: () => OrderTradeFlow.open(),
          ),
          const SizedBox(height: 12),
          _DemoCard(
            title: 'B. 开户 / KYC 向导',
            subtitle: '资料 → 风险问卷 → 确认提交\n'
                '展示 replace、onShow/onHide 生命周期、contentWhenAtTop 滚动拖关',
            onTap: () => KycWizardFlow.open(),
          ),
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(subtitle, style: const TextStyle(height: 1.35)),
        ),
        trailing: const Icon(Icons.play_arrow_rounded),
        onTap: onTap,
      ),
    );
  }
}
