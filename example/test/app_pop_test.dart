import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/unified_popups.dart';

import 'package:example/app/app_pop.dart';

void main() {
  setUp(Pop.resetForTest);
  tearDown(Pop.resetForTest);

  Future<void> mountApp(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [Pop.routeObserver],
        builder: Pop.hostBuilder,
        home: const Scaffold(body: Text('FitPulse')),
      ),
    );
  }

  testWidgets('AppPop maps confirm dismissal to a business bool',
      (tester) async {
    await mountApp(tester);

    final result = AppPop.confirm(
      title: '删除记录',
      content: '确定继续？',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));

    expect(await result, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('AppPop loading exposes business-shaped update and dismiss',
      (tester) async {
    await mountApp(tester);

    final loading = AppPop.showLoading('第一阶段');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('第一阶段'), findsOneWidget);

    expect(loading.update('第二阶段'), isTrue);
    await tester.pump();
    expect(find.text('第二阶段'), findsOneWidget);

    final dismissed = loading.dismiss();
    await tester.pumpAndSettle();
    await dismissed;
    expect(loading.isActive, isFalse);
  });
}
