import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/src/api/popup_type_api.dart';
import 'package:unified_popups/src/host/popup_host.dart';
import 'package:unified_popups/src/renderers/popup_scene.dart';
import 'package:unified_popups/src/runtime/popup_runtime.dart';
import 'package:unified_popups/unified_popups.dart';

void main() {
  testWidgets('solid confirm keeps an opaque shell', (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    PopupTypeApi(runtime).confirm(
      const ConfirmConfig(
        content: 'solid-body',
        confirmText: 'ok',
        animationConfig: PopupAnimationConfig(duration: Duration.zero),
      ),
    );
    await tester.pumpWidget(_Host(runtime: runtime));
    await tester.pump();

    expect(find.text('solid-body'), findsOneWidget);
    expect(find.byType(LiquidGlass), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('glass confirm blurs with the panel radius', (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    PopupTypeApi(runtime).confirm(
      const ConfirmConfig(
        content: 'glass-body',
        confirmText: 'ok',
        style: ConfirmStyle(
          surface: PopupSurface.glass(),
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        animationConfig: PopupAnimationConfig(duration: Duration.zero),
      ),
    );
    await tester.pumpWidget(_Host(runtime: runtime));
    await tester.pump();

    final glass = tester.widget<LiquidGlass>(find.byType(LiquidGlass));
    expect(glass.borderRadius, const BorderRadius.all(Radius.circular(18)));
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('glass-body'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(BackdropFilter),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
  });

  testWidgets('glass fade keeps the backdrop outside opacity', (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    PopupTypeApi(runtime).confirm(
      const ConfirmConfig(
        content: 'fading',
        confirmText: 'ok',
        style: ConfirmStyle(surface: PopupSurface.glass()),
        animationConfig: PopupAnimationConfig(
          type: PopupAnimationType.fade,
          duration: Duration(milliseconds: 400),
        ),
      ),
    );
    await tester.pumpWidget(_Host(runtime: runtime));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.ancestor(
        of: find.byType(BackdropFilter),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
    final fades = tester.widgetList<FadeTransition>(
      find.descendant(
        of: find.byType(LiquidGlass),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(
      fades.any((fade) => fade.opacity.value > 0 && fade.opacity.value < 1),
      isTrue,
    );
  });

  testWidgets('confirm builder receives content and radius', (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    PopupTypeApi(runtime).confirm(
      ConfirmConfig(
        content: 'custom-body',
        confirmText: 'ok',
        style: ConfirmStyle(
          borderRadius: BorderRadius.circular(22),
          surface: PopupSurface.builder((context, slot) {
            return KeyedSubtree(
              key: const ValueKey<String>('custom-confirm'),
              child: DecoratedBox(
                decoration: BoxDecoration(borderRadius: slot.borderRadius),
                child: slot.child,
              ),
            );
          }),
        ),
        animationConfig: const PopupAnimationConfig(duration: Duration.zero),
      ),
    );
    await tester.pumpWidget(_Host(runtime: runtime));
    await tester.pump();

    final decorated = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('custom-confirm')),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(
      (decorated.decoration as BoxDecoration).borderRadius,
      BorderRadius.circular(22),
    );
    expect(find.text('custom-body'), findsOneWidget);
    expect(find.byType(LiquidGlass), findsNothing);
  });

  testWidgets('glass sheet uses the direction radius', (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    PopupTypeApi(runtime).sheet<void>(
      SheetConfig<void>(
        style: const SheetStyle(surface: PopupSurface.glass()),
        animation: const PopupAnimationConfig(duration: Duration.zero),
        builder: (context, handle) => const Text('sheet-glass'),
      ),
    );
    await tester.pumpWidget(_Host(runtime: runtime));
    await tester.pump();

    expect(
      tester.widget<LiquidGlass>(find.byType(LiquidGlass)).borderRadius,
      const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(32),
      ),
    );
    expect(find.text('sheet-glass'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('solid sheet does not blur', (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    PopupTypeApi(runtime).sheet<void>(
      SheetConfig<void>(
        animation: const PopupAnimationConfig(duration: Duration.zero),
        builder: (context, handle) => const Text('sheet-solid'),
      ),
    );
    await tester.pumpWidget(_Host(runtime: runtime));
    await tester.pump();

    expect(find.text('sheet-solid'), findsOneWidget);
    expect(find.byType(LiquidGlass), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('sheet builder receives the resolved radius', (tester) async {
    const radius = BorderRadius.all(Radius.circular(6));
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    PopupTypeApi(runtime).sheet<void>(
      SheetConfig<void>(
        style: SheetStyle(
          borderRadius: radius,
          surface: PopupSurface.builder((context, slot) {
            return KeyedSubtree(
              key: const ValueKey<String>('custom-sheet'),
              child: DecoratedBox(
                decoration: BoxDecoration(borderRadius: slot.borderRadius),
                child: slot.child,
              ),
            );
          }),
        ),
        animation: const PopupAnimationConfig(duration: Duration.zero),
        builder: (context, handle) => const Text('sheet-custom'),
      ),
    );
    await tester.pumpWidget(_Host(runtime: runtime));
    await tester.pump();

    final shell = tester.widget<KeyedSubtree>(
      find.byKey(const ValueKey<String>('custom-sheet')),
    );
    final decorated = shell.child as DecoratedBox;
    expect((decorated.decoration as BoxDecoration).borderRadius, radius);
    expect(find.text('sheet-custom'), findsOneWidget);
  });

  testWidgets('glass flow sheet clears the page background', (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final controller = FlowSheetController<void>();
    PopupTypeApi(runtime).flowSheet<void>(
      FlowSheetConfig<void>(
        controller: controller,
        initialPage: const _GlassPage('glass-page'),
        style: const SheetStyle(surface: PopupSurface.glass()),
        animation: const PopupAnimationConfig(duration: Duration.zero),
      ),
    );
    await tester.pumpWidget(_Host(runtime: runtime));
    await tester.pumpAndSettle();

    expect(_nearestColor(tester, 'glass-page'), Colors.transparent);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('explicit flow sheet page color wins over glass', (tester) async {
    const pageColor = Color(0xFF112233);
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final controller = FlowSheetController<void>();
    PopupTypeApi(runtime).flowSheet<void>(
      FlowSheetConfig<void>(
        controller: controller,
        initialPage: const _GlassPage('tinted-page'),
        pageBackgroundColor: pageColor,
        style: const SheetStyle(surface: PopupSurface.glass()),
        animation: const PopupAnimationConfig(duration: Duration.zero),
      ),
    );
    await tester.pumpWidget(_Host(runtime: runtime));
    await tester.pumpAndSettle();

    expect(_nearestColor(tester, 'tinted-page'), pageColor);
  });

  testWidgets(
      'transparent flow pages slide together instead of cupertino parallax',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final controller = FlowSheetController<void>();
    PopupTypeApi(runtime).flowSheet<void>(
      FlowSheetConfig<void>(
        controller: controller,
        initialPage: const _GlassPage('glass-page'),
        style: const SheetStyle(surface: PopupSurface.glass()),
        animation: const PopupAnimationConfig(duration: Duration.zero),
      ),
    );
    await tester.pumpWidget(_Host(runtime: runtime));
    await tester.pumpAndSettle();

    controller.push(const _GlassPage('next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    expect(find.byType(CupertinoPageTransition), findsNothing);
    expect(
      tester.getTopLeft(find.text('next')).dx,
      greaterThan(tester.getTopLeft(find.text('glass-page')).dx),
    );

    await tester.pumpAndSettle();
    expect(find.text('next'), findsOneWidget);
  });

  testWidgets('opaque flow pages keep the cupertino transition',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final controller = FlowSheetController<void>();
    PopupTypeApi(runtime).flowSheet<void>(
      FlowSheetConfig<void>(
        controller: controller,
        initialPage: const _GlassPage('solid-page'),
        animation: const PopupAnimationConfig(duration: Duration.zero),
      ),
    );
    await tester.pumpWidget(_Host(runtime: runtime));
    await tester.pumpAndSettle();

    controller.push(const _GlassPage('next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    expect(find.byType(CupertinoPageTransition), findsOneWidget);
  });

  testWidgets('solid flow sheet keeps an opaque page background',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final controller = FlowSheetController<void>();
    PopupTypeApi(runtime).flowSheet<void>(
      FlowSheetConfig<void>(
        controller: controller,
        initialPage: const _GlassPage('solid-page'),
        animation: const PopupAnimationConfig(duration: Duration.zero),
      ),
    );
    await tester.pumpWidget(_Host(runtime: runtime));
    await tester.pumpAndSettle();

    expect(_nearestColor(tester, 'solid-page'), isNot(Colors.transparent));
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('solid menu keeps an opaque shell', (tester) async {
    final harness = await _pumpAnchored(tester);
    PopupTypeApi(harness.runtime).menu<void>(
      MenuConfig<void>(
        anchor: harness.anchor,
        placement: MenuPlacement.belowStart,
        animationConfig: const PopupAnimationConfig(duration: Duration.zero),
        builder: (context, handle) => const Text('solid-menu'),
      ),
    );
    await tester.pump();

    expect(find.text('solid-menu'), findsOneWidget);
    expect(find.byType(LiquidGlass), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('glass menu blurs with the menu radius', (tester) async {
    final harness = await _pumpAnchored(tester);
    PopupTypeApi(harness.runtime).menu<void>(
      MenuConfig<void>(
        anchor: harness.anchor,
        placement: MenuPlacement.belowStart,
        style: const PopupMenuStyle(
          surface: PopupSurface.glass(),
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        animationConfig: const PopupAnimationConfig(
          type: PopupAnimationType.fade,
          duration: Duration(milliseconds: 400),
        ),
        builder: (context, handle) => const Text('glass-menu'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final glass = tester.widget<LiquidGlass>(find.byType(LiquidGlass));
    expect(glass.borderRadius, const BorderRadius.all(Radius.circular(18)));
    expect(glass.backdropBlendMode, BlendMode.src);
    expect(find.text('glass-menu'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(BackdropFilter),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(BackdropFilter),
        matching: find.byType(FadeTransition),
      ),
      findsOneWidget,
    );
  });

  testWidgets('menu builder receives the menu radius', (tester) async {
    final harness = await _pumpAnchored(tester);
    PopupTypeApi(harness.runtime).menu<void>(
      MenuConfig<void>(
        anchor: harness.anchor,
        placement: MenuPlacement.belowStart,
        style: PopupMenuStyle(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          surface: PopupSurface.builder((context, slot) {
            return ColoredBox(
              key: const Key('menu-shell'),
              color: const Color(0xCC123456),
              child: ClipRRect(
                borderRadius: slot.borderRadius,
                child: slot.child,
              ),
            );
          }),
        ),
        animationConfig: const PopupAnimationConfig(duration: Duration.zero),
        builder: (context, handle) => const Text('built-menu'),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('menu-shell')), findsOneWidget);
    expect(find.text('built-menu'), findsOneWidget);
    expect(find.byType(LiquidGlass), findsNothing);
    final clip = tester.widget<ClipRRect>(
      find.descendant(
        of: find.byKey(const Key('menu-shell')),
        matching: find.byType(ClipRRect),
      ),
    );
    expect(clip.borderRadius, const BorderRadius.all(Radius.circular(20)));
  });

  testWidgets('solid drop menu drops the default glass shell', (tester) async {
    final harness = await _pumpAnchored(tester);
    PopupTypeApi(harness.runtime).dropMenu<String>(
      DropMenuConfig<String>(
        anchor: harness.anchor,
        placement: MenuPlacement.belowStart,
        menuStyle: const DropMenuStyle(surface: PopupSurface.solid()),
        animationConfig: const PopupAnimationConfig(duration: Duration.zero),
        menu: const DropMenu<String>.single(
          items: <DropMenuItem<String>>[
            DropMenuItem<String>(value: 'all', label: 'solid-drop'),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('solid-drop'), findsOneWidget);
    expect(find.byType(LiquidGlass), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);
  });
}

Color? _nearestColor(WidgetTester tester, String text) {
  final element = tester.element(find.text(text));
  Color? color;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is ColoredBox) {
      color = widget.color;
      return false;
    }
    return true;
  });
  return color;
}

class _GlassPage extends FlowSheetPage<void> {
  const _GlassPage(String id) : super(id: id);

  @override
  State<_GlassPage> createState() => _GlassPageState();
}

class _GlassPageState extends FlowSheetPageState<_GlassPage, void> {
  @override
  Widget build(BuildContext context) => Text(widget.id);
}

class _Anchored {
  _Anchored(this.runtime, this.anchor);

  final PopupRuntime runtime;
  final PopupAnchorController anchor;
}

Future<_Anchored> _pumpAnchored(WidgetTester tester) async {
  final runtime = PopupRuntime();
  final anchor = PopupAnchorController();
  addTearDown(runtime.shutdown);
  addTearDown(anchor.attached.dispose);
  await tester.pumpWidget(_AnchorHost(runtime: runtime, anchor: anchor));
  await tester.pump();
  expect(anchor.attached.value, isTrue);
  return _Anchored(runtime, anchor);
}

class _AnchorHost extends StatelessWidget {
  const _AnchorHost({required this.runtime, required this.anchor});

  final PopupRuntime runtime;
  final PopupAnchorController anchor;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: <NavigatorObserver>[runtime.routeObserver],
      builder: (context, child) => PopupHost(
        runtime: runtime,
        sceneBuilder: (context, runtime, entries) => PopupScene(
          runtime: runtime,
          entries: entries,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: PopupAnchor(
          controller: anchor,
          child: const SizedBox(width: 48, height: 48),
        ),
      ),
    );
  }
}

class _Host extends StatelessWidget {
  const _Host({required this.runtime});

  final PopupRuntime runtime;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: <NavigatorObserver>[runtime.routeObserver],
      builder: (context, child) => PopupHost(
        runtime: runtime,
        sceneBuilder: (context, runtime, entries) => PopupScene(
          runtime: runtime,
          entries: entries,
        ),
        child: child!,
      ),
      home: const Scaffold(body: SizedBox.expand()),
    );
  }
}
