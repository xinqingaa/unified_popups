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
  final _filterAnchor = PopupAnchorController();
  final _settingsAnchor = PopupAnchorController();
  bool _showDetachTarget = true;
  String _filterValue = 'all';
  String _displayMode = 'standard';
  String _refreshMode = 'live';
  bool _confirmBeforeAction = true;
  bool _messageReminder = false;

  late final List<PopupAnchorController> _all = [
    _scrollAnchor,
    _plainAnchor,
    _barrierAnchor,
    _edgeAnchor,
    _cornerAnchor,
    _detachAnchor,
    _filterAnchor,
    _settingsAnchor,
  ];

  @override
  void dispose() {
    for (final anchor in _all) {
      anchor.attached.dispose();
    }
    super.dispose();
  }

  Future<void> _openFilterDropMenu() async {
    final value = await Pop.dropMenu<String>(
      anchor: _filterAnchor,
      menu: DropMenu<String>.single(
        selectedValue: _filterValue,
        items: const <DropMenuItem<String>>[
          DropMenuItem<String>(value: 'all', label: '全部'),
          DropMenuItem<String>(value: 'active', label: '处理中'),
          DropMenuItem<String>(value: 'done', label: '已完成'),
          DropMenuItem<String>(
            value: 'archived',
            label: '已归档（禁用示例）',
            disabled: true,
          ),
        ],
      ),
    );
    if (!mounted || value == null) return;
    setState(() => _filterValue = value);
    labShowResult(context, '筛选结果 → ${_filterLabel(value)}');
  }

  Future<void> _openSettingsDropMenu() async {
    final colors = Theme.of(context).colorScheme;
    await Pop.dropMenu<String>(
      anchor: _settingsAnchor,
      onSelected: _handleSettingsSelection,
      style: DropMenuStyle(
        constraints: const BoxConstraints(
          minWidth: 140,
          maxWidth: 220,
          maxHeight: 420,
        ),
        glassStyle: LiquidGlassStyle(
          backgroundColor: colors.surface.withAlpha(0x88),
          borderColor: colors.outline.withAlpha(0x45),
          topHighlightColor: colors.primary.withAlpha(0xA0),
        ),
      ),
      menu: DropMenu<String>.nested(
        sections: <DropMenuSection<String>>[
          DropMenuSection<String>(
            id: 'displayMode',
            label: _displayMode == 'standard' ? '标准显示' : '紧凑显示',
            items: <DropMenuItem<String>>[
              DropMenuItem<String>(
                value: 'display:standard',
                label: '标准显示',
                selected: _displayMode == 'standard',
              ),
              DropMenuItem<String>(
                value: 'display:compact',
                label: '紧凑显示',
                selected: _displayMode == 'compact',
              ),
            ],
          ),
          DropMenuSection<String>(
            id: 'refreshMode',
            label: _refreshMode == 'live' ? '实时刷新' : '节能刷新',
            items: <DropMenuItem<String>>[
              DropMenuItem<String>(
                value: 'refresh:live',
                label: '实时刷新',
                selected: _refreshMode == 'live',
              ),
              DropMenuItem<String>(
                value: 'refresh:saver',
                label: '节能刷新',
                selected: _refreshMode == 'saver',
              ),
            ],
          ),
          DropMenuSection<String>.direct(
            id: 'confirmBeforeAction',
            item: DropMenuItem<String>(
              value: 'setting:confirm',
              label: '操作前确认',
              selected: _confirmBeforeAction,
              showUnselectedIndicator: true,
              closeOnSelect: false,
              onTap: () {
                if (mounted) {
                  setState(() => _confirmBeforeAction = !_confirmBeforeAction);
                }
              },
            ),
          ),
          DropMenuSection<String>.direct(
            id: 'messageReminder',
            item: DropMenuItem<String>(
              value: 'setting:message',
              label: '消息提醒（自定义图标）',
              selected: _messageReminder,
              showUnselectedIndicator: true,
              closeOnSelect: false,
              selectedIcon: const Icon(
                Icons.verified_rounded,
                size: 18,
                color: Colors.amber,
              ),
              onTap: () {
                if (mounted) {
                  setState(() => _messageReminder = !_messageReminder);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleSettingsSelection(String action) {
    if (!mounted) return;
    var changed = true;
    setState(() {
      switch (action) {
        case 'display:standard':
          _displayMode = 'standard';
        case 'display:compact':
          _displayMode = 'compact';
        case 'refresh:live':
          _refreshMode = 'live';
        case 'refresh:saver':
          _refreshMode = 'saver';
        default:
          changed = false;
      }
    });
    if (changed) labShowResult(context, '二级选项 → $action');
  }

  String _filterLabel(String value) => switch (value) {
        'active' => '处理中',
        'done' => '已完成',
        'archived' => '已归档',
        _ => '全部',
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
            title: 'DropMenu · 一级筛选',
            subtitle: '主题化液态玻璃、系统勾选图标、禁用项；默认透明 Barrier 可点外关闭。',
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: PopupAnchor(
                  controller: _filterAnchor,
                  child: OutlinedButton.icon(
                    onPressed: _openFilterDropMenu,
                    icon: const Icon(Icons.filter_list),
                    label: Text('状态：${_filterLabel(_filterValue)}'),
                  ),
                ),
              ),
            ],
          ),
          LabGroup(
            title: 'DropMenu · 二级设置',
            subtitle: '紧凑宽度、外部玻璃颜色、单组展开、保持打开与自定义勾选 Widget。',
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: PopupAnchor(
                  controller: _settingsAnchor,
                  child: FilledButton.tonalIcon(
                    onPressed: _openSettingsDropMenu,
                    icon: const Icon(Icons.more_horiz),
                    label: const Text('更多设置'),
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
