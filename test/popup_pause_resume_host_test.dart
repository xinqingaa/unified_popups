import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/unified_popups.dart';

void main() {
  tearDown(() async {
    await Pop.resetForTest();
  });

  testWidgets('pause keeps sheet state offstage across route push',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [Pop.routeObserver],
        builder: Pop.hostBuilder,
        home: Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () {
                Pop.sheet<void>(
                  SheetConfig<void>(
                    header: const SheetHeaderConfig(title: 'Paused sheet'),
                    size: const SheetSizeConfig(
                      maxHeight: SheetDimension.fraction(0.45),
                    ),
                    behavior: const PopupBehaviorConfig(
                      routePolicy:
                          PopupRoutePolicy.dismissWhenOwnerRouteChanges,
                    ),
                    builder: (context, handle) => _SheetBody(
                      navigatorKey: navigatorKey,
                    ),
                  ),
                );
              },
              child: const Text('Open sheet'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    expect(find.text('counter: 0'), findsOneWidget);

    await tester.tap(find.text('Inc'));
    await tester.pumpAndSettle();
    expect(find.text('counter: 1'), findsOneWidget);

    await tester.tap(find.text('Pause & push'));
    await tester.pumpAndSettle();

    expect(find.text('counter: 1'), findsNothing);
    expect(find.text('Detail page'), findsOneWidget);
    expect(Pop.hasChannel(PopupChannel.sheet), isTrue);

    await tester.tap(find.text('Pop detail'));
    await tester.pumpAndSettle();

    expect(find.text('counter: 1'), findsOneWidget);
    expect(find.text('Detail page'), findsNothing);
  });
}

class _SheetBody extends StatefulWidget {
  const _SheetBody({required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('counter: $_count'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => setState(() => _count++),
          child: const Text('Inc'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () async {
            final paused = Pop.pauseLatest(PopupChannel.sheet);
            expect(paused, isNotNull);
            expect(paused!.isPaused, isTrue);
            await widget.navigatorKey.currentState!.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Detail page')),
                  body: Center(
                    child: FilledButton(
                      onPressed: () =>
                          widget.navigatorKey.currentState!.pop(),
                      child: const Text('Pop detail'),
                    ),
                  ),
                ),
              ),
            );
            final resumed = Pop.resume(paused.id);
            expect(resumed, isTrue);
          },
          child: const Text('Pause & push'),
        ),
      ],
    );
  }
}
