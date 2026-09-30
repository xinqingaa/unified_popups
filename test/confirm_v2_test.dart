import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/src/api/popup_type_api.dart';
import 'package:unified_popups/src/configs/confirm_config.dart';
import 'package:unified_popups/src/configs/popup_animation_config.dart';
import 'package:unified_popups/src/configs/popup_back_policy.dart';
import 'package:unified_popups/src/configs/popup_behavior_config.dart';
import 'package:unified_popups/src/configs/popup_channel.dart';
import 'package:unified_popups/src/configs/popup_route_policy.dart';
import 'package:unified_popups/src/controller/popup_dismiss_reason.dart';
import 'package:unified_popups/src/controller/popup_entry_request.dart';
import 'package:unified_popups/src/controller/popup_entry_state.dart';
import 'package:unified_popups/src/controller/popup_lifecycle_callbacks.dart';
import 'package:unified_popups/src/controller/popup_open_result.dart';
import 'package:unified_popups/src/host/popup_host.dart';
import 'package:unified_popups/src/renderers/confirm_renderer.dart';
import 'package:unified_popups/src/renderers/popup_scene.dart';
import 'package:unified_popups/src/runtime/popup_runtime.dart';

void main() {
  testWidgets('confirm defaults to capsule filled and outline buttons',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final api = PopupTypeApi(runtime);
    api.confirm(
      const ConfirmConfig(
        content: 'capsule?',
        confirmText: 'yes',
        cancelText: 'no',
        animationConfig: PopupAnimationConfig(duration: Duration.zero),
      ),
    );
    await tester.pumpWidget(_ConfirmApp(runtime: runtime));
    await tester.pump();

    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('confirm header image is full-bleed above content padding',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    PopupTypeApi(runtime).confirm(
      const ConfirmConfig(
        title: 'Title',
        content: 'Body',
        confirmText: 'ok',
        imagePath: 'assets/images/missing.png',
        imageHeight: 140,
        style: ConfirmStyle(
          contentPadding: EdgeInsets.fromLTRB(26, 20, 26, 0),
          imageGap: 0,
          margin: EdgeInsets.zero,
        ),
        animationConfig: PopupAnimationConfig(duration: Duration.zero),
      ),
    );
    await tester.pumpWidget(_ConfirmApp(runtime: runtime));
    await tester.pump();

    final imageRect =
        tester.getRect(find.byKey(ConfirmRendererKeys.headerImage));
    final titleRect = tester.getRect(find.text('Title'));
    expect(imageRect.height, 140);
    expect(titleRect.top, greaterThanOrEqualTo(imageRect.bottom));
    expect(titleRect.left, closeTo(imageRect.left + 26, 0.5));
    expect(
      tester.widget<Image>(find.byKey(ConfirmRendererKeys.headerImage)).fit,
      BoxFit.cover,
    );
  });

  testWidgets('confirm header imageFit can be overridden', (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    PopupTypeApi(runtime).confirm(
      const ConfirmConfig(
        content: 'Body',
        confirmText: 'ok',
        imagePath: 'assets/images/missing.png',
        imageFit: BoxFit.fill,
        animationConfig: PopupAnimationConfig(duration: Duration.zero),
      ),
    );
    await tester.pumpWidget(_ConfirmApp(runtime: runtime));
    await tester.pump();

    expect(
      tester.widget<Image>(find.byKey(ConfirmRendererKeys.headerImage)).fit,
      BoxFit.fill,
    );
  });

  testWidgets('confirm and cancel callbacks only follow their own buttons',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final api = PopupTypeApi(runtime);
    final events = <String>[];
    final handle = api
        .confirm(
          ConfirmConfig(
            content: 'continue?',
            bodyExtension: const Text('extra'),
            confirmText: 'yes',
            cancelText: 'no',
            animationConfig:
                const PopupAnimationConfig(duration: Duration.zero),
            lifecycle: PopupLifecycleCallbacks<bool>(
              onOutcome: (_) => events.add('outcome'),
            ),
            onConfirm: () => events.add('confirm'),
            onCancel: () => events.add('cancel'),
          ),
        )
        .requireHandle();
    await tester.pumpWidget(_ConfirmApp(runtime: runtime));
    await tester.pump();
    expect(find.text('extra'), findsOneWidget);

    await tester.tap(find.text('no'));
    expect(await handle.result, isFalse);
    expect(events, <String>['outcome', 'cancel']);
    await tester.pumpAndSettle();
    await handle.dismissed;
  });

  testWidgets('custom confirm action owns the tap without InkWell',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final handle = PopupTypeApi(runtime)
        .confirm(
          ConfirmConfig(
            content: 'custom?',
            confirmButton: (onTap) => GestureDetector(
              onTap: onTap,
              child: const Text('yes'),
            ),
            cancelButton: (onTap) => GestureDetector(
              onTap: onTap,
              child: const Text('no'),
            ),
            animationConfig:
                const PopupAnimationConfig(duration: Duration.zero),
          ),
        )
        .requireHandle();
    await tester.pumpWidget(_ConfirmApp(runtime: runtime));
    await tester.pump();

    expect(
      find.ancestor(of: find.text('yes'), matching: find.byType(InkWell)),
      findsNothing,
    );

    await tester.tap(find.text('yes'));
    expect(await handle.result, isTrue);
    await tester.pumpAndSettle();
    await handle.dismissed;
  });

  testWidgets('close button does not invoke confirm or cancel callbacks',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final api = PopupTypeApi(runtime);
    var confirms = 0;
    var cancels = 0;
    final handle = api
        .confirm(
          ConfirmConfig(
            content: 'close me',
            confirmText: 'yes',
            cancelText: 'no',
            showCloseButton: true,
            animationConfig:
                const PopupAnimationConfig(duration: Duration.zero),
            onConfirm: () => confirms++,
            onCancel: () => cancels++,
          ),
        )
        .requireHandle();
    await tester.pumpWidget(_ConfirmApp(runtime: runtime));
    await tester.pump();

    tester.widget<IconButton>(find.byType(IconButton)).onPressed!();
    expect((await handle.outcome).reason, PopupDismissReason.manual);
    expect(confirms, 0);
    expect(cancels, 0);
    expect(handle.state, PopupEntryState.exiting);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(handle.state, PopupEntryState.disposed);
    await handle.dismissed;
  });

  test('confirm defaults block system back without dismissing', () async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    runtime.attachHost(Object());
    final handle = PopupTypeApi(runtime)
        .confirm(
          const ConfirmConfig(content: 'blocked'),
        )
        .requireHandle();
    runtime.controller.markPresented(handle.id);

    expect(await runtime.controller.handleBack(), isTrue);
    expect(handle.state, PopupEntryState.visible);

    runtime.controller.markDisposed(handle.id);
  });

  test('confirm automatically belongs to the current top modal', () async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    runtime.attachHost(Object());
    final parent = (runtime.controller.open<void, String>(
      const PopupEntryRequest<void, String>(
        channel: PopupChannel.sheet,
        config: 'sheet',
      ),
    ) as PopupOpened<void>)
        .handle;
    runtime.controller.markPresented(parent.id);
    final confirm = PopupTypeApi(runtime)
        .confirm(
          const ConfirmConfig(content: 'child'),
        )
        .requireHandle();

    final childEntry = runtime.controller.entries.last;
    expect(childEntry.ownership.parentEntryId, parent.id);
    parent.dismiss();
    expect(
      (await confirm.outcome).reason,
      PopupDismissReason.parentDismissed,
    );
    runtime.controller
      ..markDisposed(confirm.id)
      ..markDisposed(parent.id);
  });

  testWidgets('modal focus returns to the previous field after removal',
      (tester) async {
    final runtime = PopupRuntime();
    final fieldFocus = FocusNode();
    addTearDown(runtime.shutdown);
    addTearDown(fieldFocus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => PopupHost(
          runtime: runtime,
          sceneBuilder: (context, runtime, entries) => PopupScene(
            runtime: runtime,
            entries: entries,
          ),
          child: child!,
        ),
        home: Scaffold(body: TextField(focusNode: fieldFocus)),
      ),
    );
    fieldFocus.requestFocus();
    await tester.pump();
    expect(fieldFocus.hasFocus, isTrue);

    final handle = PopupTypeApi(runtime)
        .confirm(
          const ConfirmConfig(
            content: 'focus',
            animationConfig: PopupAnimationConfig(duration: Duration.zero),
          ),
        )
        .requireHandle();
    await tester.pump();
    await tester.pump();
    expect(fieldFocus.hasFocus, isFalse);

    handle.dismiss();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await handle.dismissed;
    await tester.pump();
    expect(fieldFocus.hasFocus, isTrue);
  });

  test('non-button exits preserve their own reason and a null result',
      () async {
    Future<void> verify(
      PopupDismissReason expected,
      Future<void> Function(PopupRuntime runtime, String id) close, {
      PopupBehaviorConfig behavior = const PopupBehaviorConfig(),
    }) async {
      final runtime = PopupRuntime();
      runtime.attachHost(Object());
      final handle = PopupTypeApi(runtime)
          .confirm(
            ConfirmConfig(content: 'reason', behavior: behavior),
          )
          .requireHandle();
      runtime.controller.markPresented(handle.id);

      await close(runtime, handle.id);

      expect(await handle.result, isNull);
      expect((await handle.outcome).reason, expected);
      runtime.controller.markDisposed(handle.id);
      await runtime.shutdown();
    }

    await verify(
      PopupDismissReason.barrier,
      (runtime, id) async {
        runtime.controller.dismissEntry(
          id,
          reason: PopupDismissReason.barrier,
        );
      },
    );
    await verify(
      PopupDismissReason.back,
      (runtime, id) async {
        expect(await runtime.controller.handleBack(), isTrue);
      },
      behavior: const PopupBehaviorConfig(
        backPolicy: PopupBackPolicy.dismiss,
      ),
    );
    await verify(
      PopupDismissReason.manual,
      (runtime, id) async {
        runtime.controller.dismissEntry(id);
      },
    );
    await verify(
      PopupDismissReason.routeChanged,
      (runtime, id) async {
        runtime.controller.handleRouteChanged(Object());
      },
      behavior: const PopupBehaviorConfig(
        routePolicy: PopupRoutePolicy.dismissOnAnyRouteChange,
      ),
    );
  });
}

class _ConfirmApp extends StatelessWidget {
  const _ConfirmApp({required this.runtime});

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
      home: const Scaffold(body: Text('app')),
    );
  }
}
