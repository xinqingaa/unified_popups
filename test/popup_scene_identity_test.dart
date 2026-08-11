import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/src/api/popup_type_api.dart';
import 'package:unified_popups/src/configs/custom_popup_config.dart';
import 'package:unified_popups/src/configs/popup_animation_config.dart';
import 'package:unified_popups/src/configs/popup_barrier_config.dart';
import 'package:unified_popups/src/configs/popup_position.dart';
import 'package:unified_popups/src/configs/toast_config.dart';
import 'package:unified_popups/src/controller/popup_lifetime.dart';
import 'package:unified_popups/src/host/popup_host.dart';
import 'package:unified_popups/src/renderers/popup_scene.dart';
import 'package:unified_popups/src/runtime/popup_runtime.dart';

/// Probes PopupScene Stack/Column child identity: removing an earlier sibling
/// must not remount later entries (AnimationController / State).
void main() {
  const enterExit = PopupAnimationConfig(
    type: PopupAnimationType.fade,
    duration: Duration(milliseconds: 200),
    reverseDuration: Duration(milliseconds: 200),
  );

  Future<void> pumpOut(WidgetTester tester, Future<void> dismissed) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await dismissed.timeout(const Duration(seconds: 2));
  }

  testWidgets(
    'dismissing an earlier entry does not remount a later entry mid-enter',
    (tester) async {
      final runtime = PopupRuntime();
      addTearDown(runtime.shutdown);
      final api = PopupTypeApi(runtime);

      await tester.pumpWidget(_SceneApp(runtime: runtime));
      await tester.pump();

      final lower = api
          .custom<void>(
            CustomPopupConfig<void>(
              barrier: const PopupBarrierConfig.hidden(),
              animationConfig: enterExit,
              builder: (context, handle) => const Text('lower'),
            ),
          )
          .requireHandle();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('lower'), findsOneWidget);

      final upper = api
          .custom<void>(
            CustomPopupConfig<void>(
              barrier: const PopupBarrierConfig.hidden(),
              animationConfig: enterExit,
              builder: (context, handle) => const _IdentityProbe(
                label: 'upper',
              ),
            ),
          )
          .requireHandle();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('upper'), findsOneWidget);

      final stateBefore = tester.state<_IdentityProbeState>(
        find.byType(_IdentityProbe),
      );

      await pumpOut(tester, lower.dismiss());
      expect(find.text('lower'), findsNothing);

      expect(
        tester.state<_IdentityProbeState>(find.byType(_IdentityProbe)),
        same(stateBefore),
        reason: 'upper entry remounted when lower sibling was removed',
      );
      expect(find.text('upper'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('upper'), findsOneWidget);

      await pumpOut(tester, upper.dismiss());
      expect(find.text('upper'), findsNothing);
    },
  );

  testWidgets(
    'dismissing an earlier entry mid-exit does not snap later entry away',
    (tester) async {
      final runtime = PopupRuntime();
      addTearDown(runtime.shutdown);
      final api = PopupTypeApi(runtime);

      await tester.pumpWidget(_SceneApp(runtime: runtime));
      await tester.pump();

      // Lower exits instantly so we can remove it without advancing upper's
      // long reverse animation to completion.
      final lower = api
          .custom<void>(
            CustomPopupConfig<void>(
              barrier: const PopupBarrierConfig.hidden(),
              animationConfig: const PopupAnimationConfig(
                type: PopupAnimationType.none,
              ),
              builder: (context, handle) => const Text('lower'),
            ),
          )
          .requireHandle();
      final upper = api
          .custom<void>(
            CustomPopupConfig<void>(
              barrier: const PopupBarrierConfig.hidden(),
              animationConfig: enterExit,
              builder: (context, handle) => const _IdentityProbe(
                label: 'upper',
              ),
            ),
          )
          .requireHandle();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('lower'), findsOneWidget);
      expect(find.text('upper'), findsOneWidget);

      final stateBefore = tester.state<_IdentityProbeState>(
        find.byType(_IdentityProbe),
      );

      final upperDismissed = upper.dismiss();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.text('upper'), findsOneWidget);

      final lowerDismissed = lower.dismiss();
      await tester.pump(); // schedule none-exit → markDisposed post-frame
      await tester.pump(); // run post-frame dispose
      await lowerDismissed.timeout(const Duration(seconds: 2));
      expect(find.text('lower'), findsNothing);

      expect(
        find.text('upper'),
        findsOneWidget,
        reason: 'upper should still be exiting after lower sibling removal',
      );
      expect(
        tester.state<_IdentityProbeState>(find.byType(_IdentityProbe)),
        same(stateBefore),
        reason: 'upper remounted mid-exit when lower was removed',
      );

      await tester.pump(const Duration(milliseconds: 200));
      await upperDismissed.timeout(const Duration(seconds: 2));
      expect(find.text('upper'), findsNothing);
    },
  );

  testWidgets(
    'dismissing an earlier toast lane item does not remount a later toast',
    (tester) async {
      final runtime = PopupRuntime();
      addTearDown(runtime.shutdown);
      final api = PopupTypeApi(runtime);

      await tester.pumpWidget(_SceneApp(runtime: runtime));
      await tester.pump();

      final first = api
          .toast(
            const ToastConfig.text(
              'toast-a',
              position: PopupPosition.top,
              lifetime: PopupLifetime.manual(),
              animation: enterExit,
            ),
          )
          .requireHandle();
      final second = api
          .toast(
            const ToastConfig.content(
              _IdentityProbe(label: 'toast-b'),
              position: PopupPosition.top,
              lifetime: PopupLifetime.manual(),
              animation: enterExit,
            ),
          )
          .requireHandle();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('toast-a'), findsOneWidget);
      expect(find.text('toast-b'), findsOneWidget);

      final stateBefore = tester.state<_IdentityProbeState>(
        find.byType(_IdentityProbe),
      );

      await pumpOut(tester, first.dismiss());
      expect(find.text('toast-a'), findsNothing);

      expect(
        tester.state<_IdentityProbeState>(find.byType(_IdentityProbe)),
        same(stateBefore),
        reason: 'later toast remounted when earlier lane sibling was removed',
      );
      expect(find.text('toast-b'), findsOneWidget);

      await pumpOut(tester, second.dismiss());
      expect(find.text('toast-b'), findsNothing);
    },
  );
}

class _IdentityProbe extends StatefulWidget {
  const _IdentityProbe({required this.label});

  final String label;

  @override
  State<_IdentityProbe> createState() => _IdentityProbeState();
}

class _IdentityProbeState extends State<_IdentityProbe> {
  @override
  Widget build(BuildContext context) => Text(widget.label);
}

class _SceneApp extends StatelessWidget {
  const _SceneApp({required this.runtime});

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
