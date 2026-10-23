import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/src/api/popup_type_api.dart';
import 'package:unified_popups/src/configs/popup_position.dart';
import 'package:unified_popups/src/configs/toast_config.dart';
import 'package:unified_popups/src/controller/popup_lifetime.dart';
import 'package:unified_popups/src/host/popup_host.dart';
import 'package:unified_popups/src/renderers/popup_scene.dart';
import 'package:unified_popups/src/runtime/popup_runtime.dart';

void main() {
  testWidgets(
      'queued bottom toast overlaps the slot and the outgoing one shifts left',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final api = PopupTypeApi(runtime);
    await tester.pumpWidget(_LaneApp(runtime: runtime));

    api.toast(
      const ToastConfig.text(
        '底部 A',
        position: PopupPosition.bottom,
        lifetime: PopupLifetime.manual(),
      ),
    );
    api.toast(
      const ToastConfig.text(
        '底部 B',
        position: PopupPosition.bottom,
        lifetime: PopupLifetime.manual(),
      ),
    );
    await _showCurrent(tester);
    expect(find.text('底部 A'), findsOneWidget);
    expect(find.text('底部 B'), findsNothing);

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('底部 B'), findsNothing);
    final before = tester.getCenter(find.text('底部 A'));

    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('底部 A'), findsOneWidget);
    expect(find.text('底部 B'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    final outgoing = tester.getCenter(find.text('底部 A'));
    final incoming = tester.getCenter(find.text('底部 B'));
    expect(outgoing.dx, lessThan(before.dx - 6));
    expect((outgoing.dy - before.dy).abs(), lessThan(4));
    expect((outgoing.dy - incoming.dy).abs(), lessThan(30));
  });

  testWidgets('left and right handoffs shift outward', (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final api = PopupTypeApi(runtime);
    await tester.pumpWidget(_LaneApp(runtime: runtime));

    api
      ..toast(
        const ToastConfig.text(
          '左侧 A',
          position: PopupPosition.left,
          lifetime: PopupLifetime.manual(),
        ),
      )
      ..toast(
        const ToastConfig.text(
          '左侧 B',
          position: PopupPosition.left,
          lifetime: PopupLifetime.manual(),
        ),
      )
      ..toast(
        const ToastConfig.text(
          '右侧 A',
          position: PopupPosition.right,
          lifetime: PopupLifetime.manual(),
        ),
      )
      ..toast(
        const ToastConfig.text(
          '右侧 B',
          position: PopupPosition.right,
          lifetime: PopupLifetime.manual(),
        ),
      );
    await _showCurrent(tester);
    expect(find.text('左侧 B'), findsNothing);
    expect(find.text('右侧 B'), findsNothing);

    await tester.pump(const Duration(milliseconds: 500));
    final leftBefore = tester.getCenter(find.text('左侧 A'));
    final rightBefore = tester.getCenter(find.text('右侧 A'));
    await tester.pump(const Duration(milliseconds: 150));

    final leftAfter = tester.getCenter(find.text('左侧 A'));
    final rightAfter = tester.getCenter(find.text('右侧 A'));
    expect(leftAfter.dx, lessThan(leftBefore.dx - 6));
    expect(rightAfter.dx, greaterThan(rightBefore.dx + 6));
    expect(find.text('左侧 B'), findsOneWidget);
    expect(find.text('右侧 B'), findsOneWidget);
  });

  testWidgets('a lone bottom toast exits downward', (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final api = PopupTypeApi(runtime);
    await tester.pumpWidget(_LaneApp(runtime: runtime));
    api.toast(
      const ToastConfig.text(
        '向下',
        position: PopupPosition.bottom,
        lifetime: PopupLifetime.after(Duration(milliseconds: 400)),
      ),
    );
    await _showCurrent(tester);
    final before = tester.getCenter(find.text('向下'));

    await tester.pump(const Duration(milliseconds: 400));
    final atExit = tester.getCenter(find.text('向下'));
    await tester.pump(const Duration(milliseconds: 150));
    final after = tester.getCenter(find.text('向下'));

    expect((atExit.dx - before.dx).abs(), lessThan(2));
    expect(after.dy, greaterThan(atExit.dy + 3));
    expect((after.dx - atExit.dx).abs(), lessThan(4));
  });

  testWidgets('a lone center toast fades in place', (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final api = PopupTypeApi(runtime);
    await tester.pumpWidget(_LaneApp(runtime: runtime));
    api.toast(
      const ToastConfig.text(
        '淡出',
        lifetime: PopupLifetime.after(Duration(milliseconds: 400)),
      ),
    );
    await _showCurrent(tester);
    await tester.pump(const Duration(milliseconds: 400));
    final atExit = tester.getCenter(find.text('淡出'));
    await tester.pump(const Duration(milliseconds: 150));
    final after = tester.getCenter(find.text('淡出'));

    expect((after.dx - atExit.dx).abs(), lessThan(2));
    expect((after.dy - atExit.dy).abs(), lessThan(2));
  });
}

Future<void> _showCurrent(WidgetTester tester) async {
  // The entrance ticker's first frame has zero elapsed time, so give it a
  // second interval before treating the toast as fully shown.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump();
}

class _LaneApp extends StatelessWidget {
  const _LaneApp({required this.runtime});

  final PopupRuntime runtime;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PopupHost(
        runtime: runtime,
        sceneBuilder: (context, runtime, entries) => PopupScene(
          runtime: runtime,
          entries: entries,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
