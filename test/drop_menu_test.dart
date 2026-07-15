import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/unified_popups.dart';

void main() {
  setUp(Pop.resetForTest);
  tearDown(Pop.resetForTest);

  testWidgets('single drop menu returns the selected typed value',
      (tester) async {
    await tester.pumpWidget(const _TestApp(child: _SingleMenuHarness()));
    await tester.pump();

    await tester.tap(find.text('打开一级菜单'));
    await tester.pumpAndSettle();
    expect(find.text('待成交'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(find.text('待成交'));
    await tester.pumpAndSettle();

    expect(find.text('结果：pending'), findsOneWidget);
    expect(Pop.countChannel(PopupChannel.menu), 0);
  });

  testWidgets(
      'nested menu expands one section and persistent action stays open',
      (tester) async {
    await tester.pumpWidget(const _TestApp(child: _NestedMenuHarness()));
    await tester.pump();

    await tester.tap(find.text('打开二级菜单'));
    await tester.pumpAndSettle();
    expect(find.text('限价单'), findsNothing);

    await tester.tap(find.text('订单类型'));
    await tester.pumpAndSettle();
    expect(find.text('限价单'), findsOneWidget);

    await tester.tap(find.text('提醒'));
    await tester.pumpAndSettle();
    expect(find.text('打开二级菜单'), findsOneWidget);
    expect(Pop.countChannel(PopupChannel.menu), 1);
    expect(find.byKey(const ValueKey<String>('custom-check')), findsOneWidget);

    await tester.tap(find.text('限价单'));
    await tester.pumpAndSettle();
    expect(find.text('结果：limit'), findsOneWidget);
    expect(Pop.countChannel(PopupChannel.menu), 0);
  });

  testWidgets('transparent default barrier dismisses on outside tap',
      (tester) async {
    await tester.pumpWidget(const _TestApp(child: _SingleMenuHarness()));
    await tester.pump();

    await tester.tap(find.text('打开一级菜单'));
    await tester.pumpAndSettle();
    expect(Pop.countChannel(PopupChannel.menu), 1);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(Pop.countChannel(PopupChannel.menu), 0);
  });

  testWidgets('liquid glass resolves theme colors and accepts overrides',
      (tester) async {
    ResolvedLiquidGlassStyle? light;
    ResolvedLiquidGlassStyle? dark;
    const override = Color(0xFF123456);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Builder(
          builder: (context) {
            light = const LiquidGlassStyle().resolve(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(
          builder: (context) {
            dark = const LiquidGlassStyle(
              backgroundColor: override,
            ).resolve(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(light, isNotNull);
    expect(dark, isNotNull);
    expect(light!.backgroundColor, isNot(dark!.backgroundColor));
    expect(dark!.backgroundColor, override);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: <NavigatorObserver>[Pop.routeObserver],
      builder: Pop.hostBuilder,
      home: Scaffold(
        body: Stack(
          children: <Widget>[
            const Positioned(left: 8, top: 8, child: Text('外部区域')),
            Center(child: child),
          ],
        ),
      ),
    );
  }
}

class _SingleMenuHarness extends StatefulWidget {
  const _SingleMenuHarness();

  @override
  State<_SingleMenuHarness> createState() => _SingleMenuHarnessState();
}

class _SingleMenuHarnessState extends State<_SingleMenuHarness> {
  final _anchor = PopupAnchorController();
  String? _result;

  @override
  void dispose() {
    _anchor.attached.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final value = await Pop.dropMenu<String>(
      anchor: _anchor,
      menu: const DropMenu<String>.single(
        selectedValue: 'all',
        items: <DropMenuItem<String>>[
          DropMenuItem<String>(value: 'all', label: '全部订单'),
          DropMenuItem<String>(value: 'pending', label: '待成交'),
        ],
      ),
    );
    if (mounted) setState(() => _result = value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PopupAnchor(
          controller: _anchor,
          child: FilledButton(
            onPressed: _open,
            child: const Text('打开一级菜单'),
          ),
        ),
        Text('结果：${_result ?? '-'}'),
      ],
    );
  }
}

class _NestedMenuHarness extends StatefulWidget {
  const _NestedMenuHarness();

  @override
  State<_NestedMenuHarness> createState() => _NestedMenuHarnessState();
}

class _NestedMenuHarnessState extends State<_NestedMenuHarness> {
  final _anchor = PopupAnchorController();
  String? _result;
  bool _reminder = false;

  @override
  void dispose() {
    _anchor.attached.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final value = await Pop.dropMenu<String>(
      anchor: _anchor,
      menu: DropMenu<String>.nested(
        sections: <DropMenuSection<String>>[
          const DropMenuSection<String>(
            id: 'type',
            label: '订单类型',
            items: <DropMenuItem<String>>[
              DropMenuItem<String>(value: 'limit', label: '限价单'),
              DropMenuItem<String>(value: 'market', label: '市价单'),
            ],
          ),
          DropMenuSection<String>.direct(
            id: 'reminder',
            item: DropMenuItem<String>(
              value: 'reminder',
              label: '提醒',
              selected: _reminder,
              closeOnSelect: false,
              selectedIcon: const Icon(
                Icons.star,
                key: ValueKey<String>('custom-check'),
              ),
              onTap: () => _reminder = !_reminder,
            ),
          ),
        ],
      ),
    );
    if (mounted) setState(() => _result = value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PopupAnchor(
          controller: _anchor,
          child: FilledButton(
            onPressed: _open,
            child: const Text('打开二级菜单'),
          ),
        ),
        Text('结果：${_result ?? '-'}'),
      ],
    );
  }
}
