import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

import 'lab_section.dart';
import 'lab_shell.dart';

/// Menu：Anchor 跟随、遮罩对比、边缘翻转、卸载关闭。
class MenuLabPage extends StatefulWidget {
  const MenuLabPage({super.key});

  @override
  State<MenuLabPage> createState() => _MenuLabPageState();
}

class _MenuLabPageState extends State<MenuLabPage> {
  final _scrollAnchor = PopupAnchorController();
  final _plainAnchor = PopupAnchorController();
  final _barrierAnchor = PopupAnchorController();
  final _edgeAnchor = PopupAnchorController();
  final _cornerAnchor = PopupAnchorController();
  final _detachAnchor = PopupAnchorController();
  final _statusAnchor = PopupAnchorController();
  final _tradeAnchor = PopupAnchorController();
  bool _showDetachTarget = true;
  String _orderStatus = 'all';
  String _orderType = 'limit';
  String _timeFrame = 'regular';
  bool _secondConfirm = true;
  bool _shortSellReminder = false;

  late final List<PopupAnchorController> _all = [
    _scrollAnchor,
    _plainAnchor,
    _barrierAnchor,
    _edgeAnchor,
    _cornerAnchor,
    _detachAnchor,
    _statusAnchor,
    _tradeAnchor,
  ];

  @override
  void dispose() {
    for (final anchor in _all) {
      anchor.attached.dispose();
    }
    super.dispose();
  }

  Future<void> _openStatusDropMenu() async {
    final status = await Pop.dropMenu<String>(
      anchor: _statusAnchor,
      menu: DropMenu<String>.single(
        selectedValue: _orderStatus,
        items: const <DropMenuItem<String>>[
          DropMenuItem<String>(value: 'all', label: '全部订单'),
          DropMenuItem<String>(value: 'pending', label: '待成交'),
          DropMenuItem<String>(value: 'filled', label: '已成交'),
          DropMenuItem<String>(
            value: 'cancelled',
            label: '已撤单（禁用示例）',
            disabled: true,
          ),
        ],
      ),
    );
    if (!mounted || status == null) return;
    setState(() => _orderStatus = status);
    labShowResult(context, '订单状态 → ${_statusLabel(status)}');
  }

  Future<void> _openTradeDropMenu() async {
    final action = await Pop.dropMenu<String>(
      anchor: _tradeAnchor,
      menu: DropMenu<String>.nested(
        sections: <DropMenuSection<String>>[
          DropMenuSection<String>(
            id: 'orderType',
            label: _orderType == 'limit' ? '限价单' : '市价单',
            items: <DropMenuItem<String>>[
              DropMenuItem<String>(
                value: 'order:limit',
                label: '限价单',
                selected: _orderType == 'limit',
              ),
              DropMenuItem<String>(
                value: 'order:market',
                label: '市价单',
                selected: _orderType == 'market',
              ),
            ],
          ),
          DropMenuSection<String>(
            id: 'timeFrame',
            label: _timeFrame == 'regular' ? '正常交易时段' : '盘前盘后',
            items: <DropMenuItem<String>>[
              DropMenuItem<String>(
                value: 'time:regular',
                label: '正常交易时段',
                selected: _timeFrame == 'regular',
              ),
              DropMenuItem<String>(
                value: 'time:extended',
                label: '盘前盘后',
                selected: _timeFrame == 'extended',
              ),
            ],
          ),
          DropMenuSection<String>.direct(
            id: 'secondConfirm',
            item: DropMenuItem<String>(
              value: 'setting:confirm',
              label: '下单二次确认',
              selected: _secondConfirm,
              showUnselectedIndicator: true,
              closeOnSelect: false,
              onTap: () {
                if (mounted) {
                  setState(() => _secondConfirm = !_secondConfirm);
                }
              },
            ),
          ),
          DropMenuSection<String>.direct(
            id: 'shortSellReminder',
            item: DropMenuItem<String>(
              value: 'setting:short',
              label: '沽空提醒（自定义勾选图标）',
              selected: _shortSellReminder,
              showUnselectedIndicator: true,
              closeOnSelect: false,
              selectedIcon: const Icon(
                Icons.verified_rounded,
                size: 18,
                color: Colors.amber,
              ),
              onTap: () {
                if (mounted) {
                  setState(() => _shortSellReminder = !_shortSellReminder);
                }
              },
            ),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    setState(() {
      switch (action) {
        case 'order:limit':
          _orderType = 'limit';
        case 'order:market':
          _orderType = 'market';
        case 'time:regular':
          _timeFrame = 'regular';
        case 'time:extended':
          _timeFrame = 'extended';
      }
    });
    labShowResult(context, '二级菜单 → $action');
  }

  String _statusLabel(String status) => switch (status) {
        'pending' => '待成交',
        'filled' => '已成交',
        'cancelled' => '已撤单',
        _ => '全部订单',
      };

  Future<void> _openMenu(
    PopupAnchorController anchor, {
    MenuPlacement placement = MenuPlacement.auto,
    bool showBarrier = false,
  }) async {
    final action = await Pop.menu<String>(
      anchor: anchor,
      placement: placement,
      showBarrier: showBarrier,
      builder: (dismiss) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('编辑'),
            onTap: () => dismiss('edit'),
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('分享'),
            onTap: () => dismiss('share'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('删除'),
            onTap: () => dismiss('delete'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    labShowResult(context, action == null ? 'Menu 关闭无结果' : 'Menu → $action');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: labAppBar(context, 'Lab · Menu Anchor'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const LabBanner(
            text: '标准选择使用 Pop.dropMenu；任意内容使用 Pop.menu。'
                '两者都通过 PopupAnchor + PopupAnchorController 定位。'
                '默认无遮罩：打开菜单后可继续滚动列表验证跟随。'
                '需要点外部关闭时传 showBarrier: true。'
                'Anchor 卸载以 anchorDetached 关闭。',
          ),
          const SizedBox(height: 8),
          const LabStatusBar(),
          LabGroup(
            title: 'DropMenu · 一级订单筛选',
            subtitle: '主题化液态玻璃、系统勾选图标、禁用项；默认透明 Barrier 可点外关闭。',
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: PopupAnchor(
                  controller: _statusAnchor,
                  child: OutlinedButton.icon(
                    onPressed: _openStatusDropMenu,
                    icon: const Icon(Icons.filter_list),
                    label: Text('状态：${_statusLabel(_orderStatus)}'),
                  ),
                ),
              ),
            ],
          ),
          LabGroup(
            title: 'DropMenu · 二级交易设置',
            subtitle: '分组展开、单组展开、保持打开的设置开关，以及自定义勾选 Widget。',
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: PopupAnchor(
                  controller: _tradeAnchor,
                  child: FilledButton.tonalIcon(
                    onPressed: _openTradeDropMenu,
                    icon: const Icon(Icons.more_horiz),
                    label: const Text('交易更多设置'),
                  ),
                ),
              ),
            ],
          ),
          LabGroup(
            title: '原始 Pop.menu · 滚动跟随（默认无遮罩）',
            subtitle: '打开菜单后继续上下滑动列表，菜单应跟着走。',
            children: [
              SizedBox(
                height: 220,
                child: ListView.builder(
                  itemCount: 40,
                  itemBuilder: (context, index) {
                    if (index != 12) {
                      return ListTile(title: Text('滚动项 $index'));
                    }
                    return ListTile(
                      title: const Text('带菜单的项（点右侧）'),
                      trailing: PopupAnchor(
                        controller: _scrollAnchor,
                        child: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _openMenu(_scrollAnchor),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          LabGroup(
            title: '遮罩对比',
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: PopupAnchor(
                  controller: _plainAnchor,
                  child: FilledButton.tonal(
                    onPressed: () => _openMenu(_plainAnchor),
                    child: const Text('无遮罩（默认）'),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: PopupAnchor(
                  controller: _barrierAnchor,
                  child: OutlinedButton(
                    onPressed: () => _openMenu(
                      _barrierAnchor,
                      showBarrier: true,
                    ),
                    child: const Text('有遮罩 · 点外部关闭'),
                  ),
                ),
              ),
            ],
          ),
          LabGroup(
            title: '边缘 placement',
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: PopupAnchor(
                  controller: _edgeAnchor,
                  child: OutlinedButton(
                    onPressed: () => _openMenu(
                      _edgeAnchor,
                      placement: MenuPlacement.belowEnd,
                    ),
                    child: const Text('靠右 · belowEnd'),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: PopupAnchor(
                  controller: _cornerAnchor,
                  child: OutlinedButton(
                    onPressed: () => _openMenu(
                      _cornerAnchor,
                      placement: MenuPlacement.belowStart,
                    ),
                    child: const Text('靠左 · belowStart'),
                  ),
                ),
              ),
            ],
          ),
          LabGroup(
            title: 'Anchor 卸载',
            children: [
              if (_showDetachTarget)
                PopupAnchor(
                  controller: _detachAnchor,
                  child: FilledButton(
                    onPressed: () => _openMenu(_detachAnchor),
                    child: const Text('打开菜单'),
                  ),
                ),
              LabAction(
                label: _showDetachTarget ? '打开菜单后点此移除 Anchor' : '重新显示 Anchor',
                subtitle: '菜单打开时移除，应自动关闭',
                outlined: true,
                onPressed: () {
                  setState(() => _showDetachTarget = !_showDetachTarget);
                },
              ),
              LabAction(
                label: '一键：打开菜单并在 800ms 后卸 Anchor',
                onPressed: () async {
                  if (!_showDetachTarget) {
                    setState(() => _showDetachTarget = true);
                    await Future<void>.delayed(
                        const Duration(milliseconds: 50));
                  }
                  // ignore: unawaited_futures
                  _openMenu(_detachAnchor);
                  await Future<void>.delayed(const Duration(milliseconds: 800));
                  if (mounted) setState(() => _showDetachTarget = false);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
