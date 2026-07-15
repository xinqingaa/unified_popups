import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/src/api/popup_type_api.dart';
import 'package:unified_popups/src/configs/loading_config.dart';
import 'package:unified_popups/src/configs/popup_animation_config.dart';
import 'package:unified_popups/src/configs/popup_channel.dart';
import 'package:unified_popups/src/configs/popup_position.dart';
import 'package:unified_popups/src/configs/toast_config.dart';
import 'package:unified_popups/src/controller/popup_dismiss_reason.dart';
import 'package:unified_popups/src/controller/popup_entry_request.dart';
import 'package:unified_popups/src/controller/popup_lifetime.dart';
import 'package:unified_popups/src/controller/popup_handle.dart';
import 'package:unified_popups/src/controller/popup_open_result.dart';
import 'package:unified_popups/src/host/popup_host.dart';
import 'package:unified_popups/src/renderers/loading_renderer.dart';
import 'package:unified_popups/src/renderers/popup_scene.dart';
import 'package:unified_popups/src/renderers/toast_renderer.dart';
import 'package:unified_popups/src/runtime/popup_runtime.dart';

void main() {
  testWidgets('loading updates content without replacing its renderer',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final api = PopupTypeApi(runtime);
    final handle = api
        .loading(const LoadingConfig(message: 'first'))
        .requireHandle() as LoadingHandle;

    await tester.pumpWidget(_TestApp(runtime: runtime));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('first'), findsOneWidget);
    final stateBefore = tester.state(find.byType(LoadingRenderer));

    handle.update(const LoadingConfig(message: 'second'));
    await tester.pump();
    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
    expect(tester.state(find.byType(LoadingRenderer)), same(stateBefore));

    final dismissed = handle.dismiss();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await dismissed;
    expect(find.byType(LoadingRenderer), findsNothing);
  });

  testWidgets('toast scene renders at most three items per lane',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final api = PopupTypeApi(runtime);
    final handles = <PopupHandle<void>>[];
    for (var index = 0; index < 4; index++) {
      handles.add(
        (api.toast(
          ToastConfig.text(
            'toast-$index',
            position: PopupPosition.top,
            lifetime: const PopupLifetime.manual(),
            animation: const PopupAnimationConfig(duration: Duration.zero),
          ),
        ) as PopupOpened<void>)
            .handle,
      );
    }

    await tester.pumpWidget(_TestApp(runtime: runtime));
    await tester.pump();
    expect(find.byType(ToastRenderer), findsNWidgets(3));
    expect(find.text('toast-3'), findsNothing);

    final dismissed = handles.first.dismiss();
    await tester.pump();
    await tester.pump();
    await dismissed;
    await tester.pump();
    expect(find.byType(ToastRenderer), findsNWidgets(3));
    expect(find.text('toast-3'), findsOneWidget);
  });

  testWidgets('missing renderer reports and completes instead of hanging',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final previous = FlutterError.onError;
    FlutterErrorDetails? reported;
    FlutterError.onError = (details) => reported = details;
    addTearDown(() => FlutterError.onError = previous);
    final handle = (runtime.controller.open<void, String>(
      const PopupEntryRequest<void, String>(
        channel: PopupChannel.custom,
        config: 'unsupported',
      ),
    ) as PopupOpened<void>)
        .handle;

    await tester.pumpWidget(_TestApp(runtime: runtime));
    await tester.pump();
    await tester.pump();

    expect(reported?.exception, isA<FlutterError>());
    expect(
      (await handle.outcome).reason,
      PopupDismissReason.rendererUnavailable,
    );
    await handle.dismissed;
    expect(runtime.controller.entries, isEmpty);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.runtime});

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
