import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/unified_popups.dart';

void main() {
  testWidgets('pop completes pushed page result', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    PopupManager.initialize(navigatorKey: navigatorKey);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const SizedBox.shrink(),
      ),
    );

    final result = Completer<int?>();
    final controller = FlowSheetController<void>();
    final sheetFuture = Pop.flowSheet<void>(
      controller: controller,
      initialPage: _InitialFlowPage(
        result: result,
        mode: _ResultMode.pop,
      ),
      animationDuration: Duration.zero,
      showDragHandle: false,
    );

    await _pumpUntil(tester, () => result.isCompleted);

    expect(await result.future, 7);
    controller.closeAll();
    await sheetFuture;
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('completeCurrent completes result without popping page',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    PopupManager.initialize(navigatorKey: navigatorKey);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const SizedBox.shrink(),
      ),
    );

    final result = Completer<int?>();
    final controller = FlowSheetController<String>();
    final sheetFuture = Pop.flowSheet<String>(
      controller: controller,
      initialPage: _InitialFlowPage(
        result: result,
        mode: _ResultMode.completeCurrent,
      ),
      animationDuration: Duration.zero,
      showDragHandle: false,
    );

    await _pumpUntil(tester, () => result.isCompleted);

    expect(await result.future, 7);
    expect(controller.canPop, isTrue);
    controller.closeAll('closed');
    expect(await sheetFuture, 'closed');
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

enum _ResultMode {
  pop,
  completeCurrent,
}

class _InitialFlowPage extends FlowSheetPage<void> {
  const _InitialFlowPage({
    required this.result,
    required this.mode,
  }) : super(id: 'initial');

  final Completer<int?> result;
  final _ResultMode mode;

  @override
  State<_InitialFlowPage> createState() => _InitialFlowPageState();
}

class _InitialFlowPageState extends FlowSheetPageState<_InitialFlowPage, void> {
  bool _didPush = false;

  @override
  void onShow() {
    if (_didPush) return;
    _didPush = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        nav
            .push<int>(_ResultFlowPage(mode: widget.mode))
            .then(widget.result.complete),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _ResultFlowPage extends FlowSheetPage<int> {
  const _ResultFlowPage({
    required this.mode,
  }) : super(id: 'result');

  final _ResultMode mode;

  @override
  State<_ResultFlowPage> createState() => _ResultFlowPageState();
}

class _ResultFlowPageState extends FlowSheetPageState<_ResultFlowPage, int> {
  bool _didComplete = false;

  @override
  void onShow() {
    if (_didComplete) return;
    _didComplete = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (widget.mode) {
        case _ResultMode.pop:
          nav.pop<int>(7);
        case _ResultMode.completeCurrent:
          nav.completeCurrent<int>(7);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition,
) async {
  for (var i = 0; i < 20; i++) {
    if (condition()) return;
    await tester.pump();
  }
  fail('Condition was not met before pump limit.');
}
