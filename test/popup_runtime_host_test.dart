import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/src/configs/popup_channel.dart';
import 'package:unified_popups/src/controller/popup_entry_request.dart';
import 'package:unified_popups/src/controller/popup_entry_state.dart';
import 'package:unified_popups/src/controller/popup_open_result.dart';
import 'package:unified_popups/src/host/popup_host.dart';
import 'package:unified_popups/src/runtime/popup_runtime.dart';

void main() {
  test('runtime epochs isolate ids and shutdown releases ready', () async {
    final first = PopupRuntime();
    final second = PopupRuntime();
    final firstHandle = (first.controller.open<void, String>(
      const PopupEntryRequest<void, String>(
        channel: PopupChannel.toast,
        config: 'first',
      ),
    ) as PopupOpened<void>)
        .handle;
    final secondHandle = (second.controller.open<void, String>(
      const PopupEntryRequest<void, String>(
        channel: PopupChannel.toast,
        config: 'second',
      ),
    ) as PopupOpened<void>)
        .handle;

    expect(firstHandle.id, isNot(secondHandle.id));
    final ready = first.ready;
    await first.shutdown();
    await ready;
    expect(first.isReady, isFalse);
    await second.shutdown();
  });

  testWidgets('host releases pending entries without rebuilding app child',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final pending = (runtime.controller.open<void, String>(
      const PopupEntryRequest<void, String>(
        channel: PopupChannel.toast,
        config: 'before-host',
      ),
    ) as PopupOpened<void>)
        .handle;
    expect(pending.state, PopupEntryState.pendingHost);

    var childBuilds = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => PopupHost(
          runtime: runtime,
          entryBuilder: (context, entry) => Align(
            child: Text(entry.config! as String),
          ),
          child: child!,
        ),
        home: _BuildCounter(onBuild: () => childBuilds++),
      ),
    );
    await tester.pump();

    expect(runtime.isReady, isTrue);
    expect(pending.state, PopupEntryState.visible);
    expect(find.text('before-host'), findsOneWidget);
    final baselineBuilds = childBuilds;

    final second = (runtime.controller.open<void, String>(
      const PopupEntryRequest<void, String>(
        channel: PopupChannel.loading,
        config: 'second',
      ),
    ) as PopupOpened<void>)
        .handle;
    await tester.pump();
    expect(childBuilds, baselineBuilds);
    expect(find.text('second'), findsOneWidget);

    second.dismiss();
    await tester.pump();
    await tester.pump();
    await second.dismissed;
    expect(find.text('second'), findsNothing);
    expect(childBuilds, baselineBuilds);
  });
}

class _BuildCounter extends StatelessWidget {
  const _BuildCounter({required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return const Scaffold(body: Text('app'));
  }
}
