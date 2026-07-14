import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FitPulse app starts with the popup host', (tester) async {
    await tester.pumpWidget(const FitPulseApp());
    await tester.pump();

    expect(find.text('FitPulse · 今日'), findsOneWidget);
  });
}
