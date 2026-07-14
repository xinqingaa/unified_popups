import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/src/api/popup_type_api.dart';
import 'package:unified_popups/src/configs/popup_animation_config.dart';
import 'package:unified_popups/src/configs/confirm_config.dart';
import 'package:unified_popups/src/configs/sheet_config.dart';
import 'package:unified_popups/src/configs/sheet_types.dart';
import 'package:unified_popups/src/controller/popup_dismiss_reason.dart';
import 'package:unified_popups/src/host/popup_host.dart';
import 'package:unified_popups/src/renderers/popup_scene.dart';
import 'package:unified_popups/src/renderers/sheet_renderer.dart';
import 'package:unified_popups/src/runtime/popup_runtime.dart';
import 'package:unified_popups/src/utils/sheet_dimension.dart';

void main() {
  test('sheet direction maps to a full-distance slide', () {
    for (final direction in SheetDirection.values) {
      final config = SheetConfig<void>(
        direction: direction,
        builder: (context, handle) => const Text('sheet'),
      );
      expect(config.animationConfig.slideOffset, 1);
      expect(config.animationConfig.type, isNot(PopupAnimationType.fade));
    }
  });

  testWidgets('sheet builder receives a handle and completes a result',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final handle = PopupTypeApi(runtime).sheet<String>(
      SheetConfig<String>(
        header: const SheetHeaderConfig(title: 'picker'),
        animation: const PopupAnimationConfig(
          type: PopupAnimationType.slideUp,
          duration: Duration.zero,
          slideOffset: 1,
        ),
        builder: (context, handle) => ListTile(
          title: const Text('select'),
          onTap: () => handle.complete('selected'),
        ),
      ),
    );
    await tester.pumpWidget(_SheetApp(runtime: runtime));
    await tester.pump();

    await tester.tap(find.text('select'));

    expect(await handle.result, 'selected');
    expect((await handle.outcome).reason, PopupDismissReason.completed);
    await tester.pumpAndSettle();
    await handle.dismissed;
  });

  testWidgets('drag updates motion without rebuilding the business child',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    var childBuilds = 0;
    final handle = PopupTypeApi(runtime).sheet<void>(
      SheetConfig<void>(
        size: const SheetSizeConfig(height: SheetDimension.pixel(300)),
        animation: const PopupAnimationConfig(
          type: PopupAnimationType.slideUp,
          duration: Duration.zero,
          slideOffset: 1,
        ),
        builder: (context, handle) {
          childBuilds++;
          return const SizedBox(height: 200, child: Text('heavy child'));
        },
      ),
    );
    await tester.pumpWidget(_SheetApp(runtime: runtime));
    await tester.pump();
    expect(childBuilds, 1);

    await tester.drag(
      find.byKey(SheetRendererKeys.panel),
      const Offset(0, 40),
    );
    await tester.pumpAndSettle();

    expect(handle.isActive, isTrue);
    expect(childBuilds, 1);

    await tester.drag(
      find.byKey(SheetRendererKeys.panel),
      const Offset(0, 180),
    );
    await tester.pumpAndSettle();
    expect((await handle.outcome).reason, PopupDismissReason.drag);
    await handle.dismissed;
    expect(childBuilds, 1);
  });

  testWidgets('horizontal handleOnly ignores body drag but accepts handle drag',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final handle = PopupTypeApi(runtime).sheet<void>(
      SheetConfig<void>(
        direction: SheetDirection.left,
        drag: const SheetDragConfig(mode: SheetDragDismissMode.handleOnly),
        animation: const PopupAnimationConfig(
          type: PopupAnimationType.slideLeft,
          duration: Duration.zero,
          slideOffset: 1,
        ),
        builder: (context, handle) => const Center(child: Text('body')),
      ),
    );
    await tester.pumpWidget(_SheetApp(runtime: runtime));
    await tester.pump();

    await tester.drag(find.text('body'), const Offset(-300, 0));
    await tester.pump();
    expect(handle.isActive, isTrue);

    await tester.drag(
      find.byKey(SheetRendererKeys.dragHandle),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    expect((await handle.outcome).reason, PopupDismissReason.drag);
    await handle.dismissed;
  });

  testWidgets('confirm stacks above a sheet and closes independently',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final api = PopupTypeApi(runtime);
    final sheet = api.sheet<void>(
      SheetConfig<void>(
        animation: const PopupAnimationConfig(duration: Duration.zero),
        builder: (context, handle) => const Text('sheet remains'),
      ),
    );
    await tester.pumpWidget(_SheetApp(runtime: runtime));
    await tester.pump();
    final confirm = api.confirm(
      const ConfirmConfig(
        content: 'confirm above',
        animationConfig: PopupAnimationConfig(duration: Duration.zero),
      ),
    );
    await tester.pump();

    expect(find.text('sheet remains'), findsOneWidget);
    expect(find.text('confirm above'), findsOneWidget);
    confirm.dismiss();
    await tester.pumpAndSettle();

    expect(sheet.isActive, isTrue);
    expect(find.text('sheet remains'), findsOneWidget);
  });

  testWidgets('sheet back callback may consume back or allow sheet dismissal',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    var consumeBack = true;
    final handle = PopupTypeApi(runtime).sheet<void>(
      SheetConfig<void>(
        animation: const PopupAnimationConfig(duration: Duration.zero),
        onBack: () async => consumeBack,
        builder: (context, handle) => const Text('back-aware sheet'),
      ),
    );
    await tester.pumpWidget(_SheetApp(runtime: runtime));
    await tester.pump();

    expect(await runtime.controller.handleBack(), isTrue);
    expect(handle.isActive, isTrue);

    consumeBack = false;
    expect(await runtime.controller.handleBack(), isTrue);
    expect((await handle.outcome).reason, PopupDismissReason.back);
    await tester.pumpAndSettle();
  });

  testWidgets(
      'bottom sheet SafeArea ignores top inset so drag handle stays near panel top',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    PopupTypeApi(runtime).sheet<void>(
      SheetConfig<void>(
        header: const SheetHeaderConfig(title: 'title'),
        animation: const PopupAnimationConfig(
          type: PopupAnimationType.slideUp,
          duration: Duration.zero,
          slideOffset: 1,
        ),
        builder: (context, handle) => const Text('content'),
      ),
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(top: 59, bottom: 34),
          size: Size(400, 800),
        ),
        child: _SheetApp(runtime: runtime),
      ),
    );
    await tester.pump();

    final panelTop =
        tester.getTopLeft(find.byKey(SheetRendererKeys.panel)).dy;
    final handleTop =
        tester.getTopLeft(find.byKey(SheetRendererKeys.dragHandle)).dy;
    // Handle vertical padding is 6; must not also absorb status-bar top (59).
    expect(handleTop - panelTop, lessThan(20));
  });
}

class _SheetApp extends StatelessWidget {
  const _SheetApp({required this.runtime});

  final PopupRuntime runtime;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => PopupHost(
        runtime: runtime,
        sceneBuilder: (context, runtime, entries) => PopupScene(
          runtime: runtime,
          entries: entries,
        ),
        child: child!,
      ),
      home: const Scaffold(body: Text('app')),
    );
  }
}
