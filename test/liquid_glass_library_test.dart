import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/liquid_glass.dart';

void main() {
  test('style copy stays on the public glass library', () {
    const style = LiquidGlassStyle(blurSigma: 8);
    expect(style.copyWith(blurSigma: 4).blurSigma, 4);
    expect(LiquidGlassStyle.standard.blurSigma, 24);
  });

  test('button widgets are constructable from the glass library', () {
    final button = LiquidGlassButton(
      onTap: () {},
      child: const Text('press'),
    );
    expect(button.style, LiquidGlassStyle.standard);
    const action = LiquidGlassActionButton(
      onTap: null,
      child: Text('action'),
    );
    expect(action.enableShadow, isFalse);
  });

  testWidgets('a subclass can replace the edge painter', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiquidGlass(
            borderRadius: BorderRadius.circular(16),
            edgePainterBuilder: (radius, style) => _ProbePainter(
              borderRadius: radius,
              style: style,
            ),
            child: const SizedBox(
              width: 120,
              height: 48,
              child: Text('glass'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('glass'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is _ProbePainter,
      ),
      findsOneWidget,
    );
  });
}

class _ProbePainter extends LiquidGlassEdgePainter {
  const _ProbePainter({
    required super.borderRadius,
    required super.style,
  });
}
