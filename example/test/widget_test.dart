import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Example home offers dual entry', (tester) async {
    await tester.pumpWidget(const FitPulseApp());
    await tester.pump();

    expect(find.text('FitPulse 真实 App'), findsOneWidget);
    expect(find.text('API 展柜'), findsOneWidget);

    await tester.tap(find.text('FitPulse 真实 App'));
    await tester.pumpAndSettle();
    expect(find.text('FitPulse · 今日'), findsOneWidget);
  });
}
