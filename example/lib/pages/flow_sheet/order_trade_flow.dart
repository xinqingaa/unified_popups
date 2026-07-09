import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unified_popups/unified_popups.dart';

/// 演示 A：订单交易多步流。
///
/// 列表(handleOnly + maintainState) → 详情(contentWhenAtTop) → 密码(handleOnly + 键盘)
/// 成功时用 completeCurrent 再 closeAll，避免内部返回动画与 sheet 退场打架。
class OrderTradeFlow {
  OrderTradeFlow._();

  static Future<void> open() async {
    final controller = FlowSheetController<_TradeResult>();
    final result = await Pop.flowSheet<_TradeResult>(
      controller: controller,
      maxHeight: const SheetDimension.fraction(0.88),
      dragDismissMode: SheetDragDismissMode.handleOnly,
      barrierDismissible: true,
      initialPage: _OrderListPage(controller: controller),
    );
    if (result != null) {
      Pop.toast(
        '已提交 ${result.orderId}，金额 ${result.amount}',
        toastType: ToastType.success,
      );
    } else {
      Pop.toast('已取消交易');
    }
  }
}

class _TradeResult {
  const _TradeResult({required this.orderId, required this.amount});

  final String orderId;
  final String amount;
}

class _Order {
  const _Order({
    required this.id,
    required this.symbol,
    required this.side,
    required this.amount,
    required this.summary,
  });

  final String id;
  final String symbol;
  final String side;
  final String amount;
  final String summary;
}

const _demoOrders = <_Order>[
  _Order(
    id: 'ORD-1001',
    symbol: 'AAPL',
    side: '买入',
    amount: '\$1,250.00',
    summary: '限价单 · 数量 10 · 预计今日成交。包含手续费预估与资金冻结说明。',
  ),
  _Order(
    id: 'ORD-1002',
    symbol: 'TSLA',
    side: '卖出',
    amount: '\$3,480.50',
    summary: '市价单 · 数量 5 · 可能存在滑点。请确认持仓与可用额度。',
  ),
  _Order(
    id: 'ORD-1003',
    symbol: 'NVDA',
    side: '买入',
    amount: '\$2,100.00',
    summary: '止盈止损单 · 触发价已设置。详情页可滚动查看风控条款。',
  ),
];

class _OrderListPage extends FlowSheetPage<void> {
  const _OrderListPage({required this.controller})
      : super(
          id: 'order_list',
          maintainState: true,
          dragDismissMode: SheetDragDismissMode.handleOnly,
        );

  final FlowSheetController<_TradeResult> controller;

  @override
  State<_OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends FlowSheetPageState<_OrderListPage, void> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '待处理订单',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => widget.controller.closeAll(),
              child: const Text('关闭'),
            ),
          ],
        ),
        const Text(
          '仅标题/拖条可下拉关闭（handleOnly）。选中订单后 push 详情，列表页 maintainState 保活。',
          style: TextStyle(color: Colors.black54, height: 1.3),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: _demoOrders.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final order = _demoOrders[index];
              return ListTile(
                title: Text('${order.symbol} · ${order.side}'),
                subtitle: Text('${order.id}  ${order.amount}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  nav.push<_TradeResult?>(
                    _OrderDetailPage(
                      order: order,
                      controller: widget.controller,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OrderDetailPage extends FlowSheetPage<_TradeResult?> {
  const _OrderDetailPage({
    required this.order,
    required this.controller,
  }) : super(
          id: 'order_detail',
          dragDismissMode: SheetDragDismissMode.contentWhenAtTop,
        );

  final _Order order;
  final FlowSheetController<_TradeResult> controller;

  @override
  State<_OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState
    extends FlowSheetPageState<_OrderDetailPage, _TradeResult?> {
  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => nav.pop(),
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                '${order.symbol} 详情',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            children: [
              ListTile(title: const Text('订单号'), subtitle: Text(order.id)),
              ListTile(title: const Text('方向'), subtitle: Text(order.side)),
              ListTile(title: const Text('金额'), subtitle: Text(order.amount)),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${order.summary}\n\n'
                  '向下滚动查看更多条款……\n\n'
                  '1. 交易存在市场风险，过往表现不代表未来收益。\n'
                  '2. 提交后不可撤销，请核对数量与价格。\n'
                  '3. 本页使用 contentWhenAtTop：滚到顶再下拉可关闭整个 Sheet。\n'
                  '4. 系统返回键会优先 pop 本页，而不是直接关掉 Sheet。\n'
                  '5. 确认后进入密码页，成功时用 completeCurrent + closeAll。\n\n'
                  '${List.generate(8, (i) => '补充说明段落 ${i + 1}：用于演示可滚动详情。').join('\n\n')}',
                  style: const TextStyle(height: 1.45),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton(
              onPressed: () async {
                final verified = await nav.push<bool>(
                  _PasswordPage(order: order),
                );
                if (verified == true && mounted) {
                  widget.controller.closeAll(
                    _TradeResult(orderId: order.id, amount: order.amount),
                  );
                }
              },
              child: const Text('确认下单'),
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordPage extends FlowSheetPage<bool> {
  const _PasswordPage({required this.order})
      : super(
          id: 'password',
          dragDismissMode: SheetDragDismissMode.handleOnly,
        );

  final _Order order;

  @override
  State<_PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends FlowSheetPageState<_PasswordPage, bool> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _controller.text.trim();
    if (pin.length < 4) {
      setState(() => _error = '请输入至少 4 位交易密码');
      return;
    }
    // 回传结果但不播内部返回动画，由外层 closeAll 统一退场。
    nav.completeCurrent(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => nav.pop(false),
                icon: const Icon(Icons.arrow_back),
              ),
              const Expanded(
                child: Text(
                  '交易密码',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Text(
            '验证 ${widget.order.id} · ${widget.order.amount}',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: '交易密码',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          const Text(
            '键盘弹出时 Sheet 会上移（adjustForKeyboard）。本页 handleOnly，避免与输入冲突。',
            style: TextStyle(color: Colors.black54, height: 1.3),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _submit,
            child: const Text('验证并提交'),
          ),
        ],
      ),
    );
  }
}
