import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/src/api/popup_type_api.dart';
import 'package:unified_popups/src/configs/date_config.dart';
import 'package:unified_popups/src/configs/popup_animation_config.dart';
import 'package:unified_popups/src/controller/popup_dismiss_reason.dart';
import 'package:unified_popups/src/host/popup_host.dart';
import 'package:unified_popups/src/renderers/popup_scene.dart';
import 'package:unified_popups/src/runtime/popup_runtime.dart';

void main() {
  test('date range rejects reversed and out-of-range values', () {
    expect(
      () => DateRangeConfig(
        initialDate: DateTime(2024),
        minDate: DateTime(2025),
        maxDate: DateTime(2023),
      ),
      throwsArgumentError,
    );
    expect(
      () => DateRangeConfig(
        initialDate: DateTime(2026),
        minDate: DateTime(2023),
        maxDate: DateTime(2025),
      ),
      throwsArgumentError,
    );
  });

  testWidgets('date confirm returns the selected date', (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final initial = DateTime(2024, 6, 15);
    final handle = PopupTypeApi(runtime).date(
      DateConfig(
        range: DateRangeConfig(
          initialDate: initial,
          minDate: DateTime(2020),
          maxDate: DateTime(2030, 12, 31),
        ),
        labels: const DateLabels(confirm: 'choose', cancel: 'cancel'),
        animationConfig: const PopupAnimationConfig(duration: Duration.zero),
      ),
    );
    await tester.pumpWidget(_DateApp(runtime: runtime));
    await tester.pump();

    await tester.tap(find.text('choose'));

    expect(await handle.result, initial);
    expect((await handle.outcome).reason, PopupDismissReason.completed);
    await tester.pumpAndSettle();
    await handle.dismissed;
  });

  testWidgets('date barrier keeps null result distinct from completion',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final handle = PopupTypeApi(runtime).date(
      DateConfig(
        range: DateRangeConfig(
          initialDate: DateTime(2024),
          minDate: DateTime(2020),
          maxDate: DateTime(2030),
        ),
        animationConfig: const PopupAnimationConfig(duration: Duration.zero),
      ),
    );
    await tester.pumpWidget(_DateApp(runtime: runtime));
    await tester.pump();

    await tester.tapAt(const Offset(10, 10));

    expect(await handle.result, isNull);
    expect((await handle.outcome).reason, PopupDismissReason.barrier);
    await tester.pumpAndSettle();
  });
}

class _DateApp extends StatelessWidget {
  const _DateApp({required this.runtime});

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
