import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/unified_popups.dart';
import 'package:unified_popups/src/widgets/drop_menu/drop_menu_content.dart';
import 'package:unified_popups/src/widgets/liquid_glass/liquid_glass_edge_painter.dart';

void main() {
  setUp(Pop.resetForTest);
  tearDown(Pop.resetForTest);

  test('drop menu defaults to one global replace-existing key', () {
    final anchor = PopupAnchorController();
    final config = DropMenuConfig<int>(
      anchor: anchor,
      menu: const DropMenu<int>.single(
        items: <DropMenuItem<int>>[
          DropMenuItem<int>(value: 1, label: 'one'),
        ],
      ),
    );

    expect(config.behavior.key, PopupKeys.globalDropMenu);
    expect(
      config.behavior.conflictPolicy,
      PopupConflictPolicy.replaceExisting,
    );
  });

  testWidgets('single drop menu returns the selected typed value',
      (tester) async {
    await tester.pumpWidget(const _TestApp(child: _SingleMenuHarness()));
    await tester.pump();

    await tester.tap(find.text('打开一级菜单'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final menuFinder = find.byType(DropMenuContent<String>);
    final backdrop = tester.widget<BackdropFilter>(
      find.descendant(
        of: menuFinder,
        matching: find.byType(BackdropFilter),
      ),
    );
    expect(backdrop.blendMode, BlendMode.src);
    // Glass/BackdropFilter must not sit under the entry FadeTransition.
    final entryFades = tester.widgetList<FadeTransition>(
      find.ancestor(of: menuFinder, matching: find.byType(FadeTransition)),
    );
    expect(entryFades, isEmpty);
    final contentFades = tester.widgetList<FadeTransition>(
      find.descendant(of: menuFinder, matching: find.byType(FadeTransition)),
    );
    expect(
      contentFades.any(
        (fade) => fade.opacity.value > 0 && fade.opacity.value < 1,
      ),
      isTrue,
    );
    final backdropAncestors = find.ancestor(
      of: find.descendant(
        of: menuFinder,
        matching: find.byType(BackdropFilter),
      ),
      matching: find.byType(FadeTransition),
    );
    expect(backdropAncestors, findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('处理中'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(_bottomBorderCount(tester, find.byType(DropMenuContent<String>)), 1);

    await tester.tap(find.text('处理中'));
    await tester.pumpAndSettle();

    expect(find.text('结果：active'), findsOneWidget);
    expect(Pop.countChannel(PopupChannel.menu), 0);
  });

  testWidgets(
      'nested menu expands one section and persistent action stays open',
      (tester) async {
    await tester.pumpWidget(const _TestApp(child: _NestedMenuHarness()));
    await tester.pump();

    await tester.tap(find.text('打开二级菜单'));
    await tester.pumpAndSettle();
    expect(find.text('标准显示'), findsNothing);
    final menu = find.byType(DropMenuContent<String>);
    final primaryDividers = find.descendant(
      of: menu,
      matching: find.byType(ColoredBox),
    );
    expect(primaryDividers, findsOneWidget);

    await tester.tap(find.text('显示模式'));
    await tester.pump();
    final submenuTransitions = find.descendant(
      of: menu,
      matching: find.byType(SizeTransition),
    );
    expect(submenuTransitions, findsWidgets);
    await tester.pump(const Duration(milliseconds: 100));
    final fades = tester.widgetList<FadeTransition>(
      find.descendant(of: menu, matching: find.byType(FadeTransition)),
    );
    expect(
      fades.any(
        (fade) => fade.opacity.value > 0 && fade.opacity.value < 1,
      ),
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(find.text('标准显示'), findsOneWidget);

    await tester.tap(find.text('提醒'));
    await tester.pumpAndSettle();
    expect(find.text('打开二级菜单'), findsOneWidget);
    expect(Pop.countChannel(PopupChannel.menu), 1);
    expect(find.byKey(const ValueKey<String>('custom-check')), findsOneWidget);

    await tester.tap(find.text('标准显示'));
    await tester.pump(const Duration(milliseconds: 80));
    expect(
      find.descendant(of: menu, matching: find.byType(SizeTransition)),
      findsWidgets,
    );
    await tester.pumpAndSettle();
    expect(find.text('结果：standard'), findsOneWidget);
    expect(find.text('标准显示'), findsNothing);
    expect(Pop.countChannel(PopupChannel.menu), 1);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
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
    ResolvedLiquidGlassStyle? darkDefault;
    ResolvedLiquidGlassStyle? dark;
    const backgroundOverride = Color(0x88123456);
    const borderOverride = Color(0x44334455);
    const highlightOverride = Color(0xCCABCDEF);

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
      Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData.dark(),
          child: Builder(
            builder: (context) {
              darkDefault = const LiquidGlassStyle().resolve(context);
              dark = const LiquidGlassStyle(
                backgroundColor: backgroundOverride,
                borderColor: borderOverride,
                topHighlightColor: highlightOverride,
              ).resolve(context);
              return const LiquidGlass(
                style: LiquidGlassStyle(
                  backgroundColor: backgroundOverride,
                  borderColor: borderOverride,
                  topHighlightColor: highlightOverride,
                ),
                child: SizedBox(width: 100, height: 48),
              );
            },
          ),
        ),
      ),
    );

    expect(light, isNotNull);
    expect(darkDefault, isNotNull);
    expect(dark, isNotNull);
    expect(_alpha(light!.backgroundColor), 0xB3);
    expect(_alpha(darkDefault!.backgroundColor), 0x8C);
    expect(_alpha(darkDefault!.topHighlightColor), 0x8F);
    expect(dark!.backgroundColor, backgroundOverride);
    expect(dark!.borderColor, borderOverride);
    expect(dark!.topHighlightColor, highlightOverride);

    final edgePainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((widget) => widget.painter)
        .whereType<LiquidGlassEdgePainter>()
        .single;
    expect(edgePainter.style.borderColor, borderOverride);
    expect(edgePainter.style.topHighlightColor, highlightOverride);
    expect(
      tester.widget<BackdropFilter>(find.byType(BackdropFilter)).blendMode,
      BlendMode.srcOver,
    );
  });

  test('drop menu uses compact default width constraints', () {
    final constraints = const DropMenuStyle().constraints;
    expect(constraints.minWidth, 140);
    expect(constraints.maxWidth, 240);
  });

  testWidgets('auto placement uses actual height and prefers fitting below',
      (tester) async {
    await tester.pumpWidget(
      const _TestApp(
        child: _AutoPlacementHarness(bottom: 140),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('auto-anchor')));
    await tester.pumpAndSettle();

    final anchorRect = tester.getRect(
      find.byKey(const ValueKey<String>('auto-anchor')),
    );
    final menuRect = tester.getRect(find.byType(DropMenuContent<String>));
    expect(menuRect.height, lessThan(140));
    expect(menuRect.top, closeTo(anchorRect.bottom, 0.1));
    expect(menuRect.right, closeTo(anchorRect.right, 0.1));
  });

  testWidgets('auto placement chooses above when below cannot fit',
      (tester) async {
    await tester.pumpWidget(
      const _TestApp(
        child: _AutoPlacementHarness(bottom: 20),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('auto-anchor')));
    await tester.pumpAndSettle();

    final anchorRect = tester.getRect(
      find.byKey(const ValueKey<String>('auto-anchor')),
    );
    final menuRect = tester.getRect(find.byType(DropMenuContent<String>));
    expect(menuRect.bottom, closeTo(anchorRect.top, 0.1));
  });
}

int _alpha(Color color) => (color.toARGB32() >> 24) & 0xFF;

int _bottomBorderCount(WidgetTester tester, Finder root) {
  return tester
      .widgetList<DecoratedBox>(
    find.descendant(of: root, matching: find.byType(DecoratedBox)),
  )
      .where((widget) {
    final decoration = widget.decoration;
    if (decoration is! BoxDecoration || decoration.border is! Border) {
      return false;
    }
    final border = decoration.border! as Border;
    return border.bottom.style != BorderStyle.none;
  }).length;
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
      DropMenuConfig<String>(
        anchor: _anchor,
        menu: const DropMenu<String>.single(
          selectedValue: 'all',
          items: <DropMenuItem<String>>[
            DropMenuItem<String>(value: 'all', label: '全部'),
            DropMenuItem<String>(value: 'active', label: '处理中'),
          ],
        ),
      ),
    ).result;
    if (mounted && value != null) setState(() => _result = value);
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
      DropMenuConfig<String>(
        anchor: _anchor,
        onSelected: (selection) {
          if (mounted) setState(() => _result = selection);
        },
        menu: DropMenu<String>.nested(
          sections: <DropMenuSection<String>>[
            const DropMenuSection<String>(
              id: 'display',
              label: '显示模式',
              items: <DropMenuItem<String>>[
                DropMenuItem<String>(value: 'standard', label: '标准显示'),
                DropMenuItem<String>(value: 'compact', label: '紧凑显示'),
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
      ),
    ).result;
    if (mounted && value != null) setState(() => _result = value);
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

class _AutoPlacementHarness extends StatefulWidget {
  const _AutoPlacementHarness({required this.bottom});

  final double bottom;

  @override
  State<_AutoPlacementHarness> createState() => _AutoPlacementHarnessState();
}

class _AutoPlacementHarnessState extends State<_AutoPlacementHarness> {
  final _anchor = PopupAnchorController();

  @override
  void dispose() {
    _anchor.attached.dispose();
    super.dispose();
  }

  void _open() {
    Pop.dropMenu<String>(
      DropMenuConfig<String>(
        anchor: _anchor,
        menu: const DropMenu<String>.single(
          items: <DropMenuItem<String>>[
            DropMenuItem<String>(value: 'one', label: '选项一'),
            DropMenuItem<String>(value: 'two', label: '选项二'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: <Widget>[
          Positioned(
            right: 24,
            bottom: widget.bottom,
            child: PopupAnchor(
              controller: _anchor,
              child: FilledButton(
                key: const ValueKey<String>('auto-anchor'),
                onPressed: _open,
                child: const Text('自动定位'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
