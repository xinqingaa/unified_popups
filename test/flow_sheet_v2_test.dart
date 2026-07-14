import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/src/api/popup_type_api.dart';
import 'package:unified_popups/src/configs/flow_sheet_config.dart';
import 'package:unified_popups/src/configs/popup_animation_config.dart';
import 'package:unified_popups/src/configs/sheet_config.dart';
import 'package:unified_popups/src/controller/popup_dismiss_reason.dart';
import 'package:unified_popups/src/flow_sheets/flow_sheet.dart';
import 'package:unified_popups/src/host/popup_host.dart';
import 'package:unified_popups/src/renderers/popup_scene.dart';
import 'package:unified_popups/src/runtime/popup_runtime.dart';
import 'package:unified_popups/src/utils/sheet_dimension.dart';

void main() {
  testWidgets('flowSheet push/pop returns internally before closing outer',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final controller = FlowSheetController<String>();
    final handle = PopupTypeApi(runtime).flowSheet<String>(
      _config(controller),
    );
    await tester.pumpWidget(_FlowApp(runtime: runtime));
    await tester.pumpAndSettle();
    expect(find.text('page-initial'), findsOneWidget);

    final innerResult = controller.push<int>(const _Page<int>('second'));
    await tester.pumpAndSettle();
    expect(find.text('page-second'), findsOneWidget);

    controller.pop<int>(7);
    expect(await innerResult, 7);
    await tester.pumpAndSettle();
    expect(find.text('page-initial'), findsOneWidget);
    expect(handle.isActive, isTrue);

    controller.closeAll('done');
    expect(await handle.result, 'done');
    await tester.pumpAndSettle();
    await handle.dismissed;
    expect(controller.isDisposed, isTrue);
  });

  testWidgets('system back pops an inner page before the outer flowSheet',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final controller = FlowSheetController<void>();
    final handle = PopupTypeApi(runtime).flowSheet<void>(_config(controller));
    await tester.pumpWidget(_FlowApp(runtime: runtime));
    await tester.pumpAndSettle();
    controller.push<void>(const _Page<void>('second'));
    await tester.pumpAndSettle();

    expect(await runtime.controller.handleBack(), isTrue);
    await tester.pumpAndSettle();

    expect(find.text('page-initial'), findsOneWidget);
    expect(handle.isActive, isTrue);

    expect(await runtime.controller.handleBack(), isTrue);
    expect((await handle.outcome).reason, PopupDismissReason.back);
    await tester.pumpAndSettle();
    await handle.dismissed;
  });

  testWidgets('external close settles pending pages and disposes the session',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final controller = FlowSheetController<void>();
    final handle = PopupTypeApi(runtime).flowSheet<void>(_config(controller));
    await tester.pumpWidget(_FlowApp(runtime: runtime));
    await tester.pumpAndSettle();
    final pending = controller.push<int>(const _Page<int>('pending'));
    await tester.pumpAndSettle();

    handle.dismiss();

    expect(await pending, isNull);
    expect((await handle.outcome).reason, PopupDismissReason.manual);
    await tester.pumpAndSettle();
    await handle.dismissed;
    expect(controller.isDisposed, isTrue);
  });

  testWidgets('page lifecycle hooks survive unified outer lifecycle',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final events = <String>[];
    final controller = FlowSheetController<void>();
    final handle = PopupTypeApi(runtime).flowSheet<void>(
      FlowSheetConfig<void>(
        controller: controller,
        initialPage: _LifecyclePage('initial', events),
        size: const SheetSizeConfig(height: SheetDimension.pixel(420)),
        animation: const PopupAnimationConfig(
          type: PopupAnimationType.slideUp,
          duration: Duration.zero,
          slideOffset: 1,
        ),
      ),
    );
    await tester.pumpWidget(_FlowApp(runtime: runtime));
    await tester.pumpAndSettle();
    expect(events, <String>['initial:load', 'initial:show']);

    controller.push<void>(_LifecyclePage('second', events));
    await tester.pumpAndSettle();
    expect(
        events,
        containsAllInOrder(
            <String>['initial:hide', 'second:load', 'second:show']));
    controller.pop();
    await tester.pumpAndSettle();
    expect(
        events,
        containsAllInOrder(
            <String>['second:hide', 'second:remove', 'initial:show']));

    controller.closeAll();
    await tester.pumpAndSettle();
    await handle.dismissed;
    expect(events.last, 'initial:close');
  });

  test('controller ownership is one-shot', () async {
    final runtime = PopupRuntime();
    final controller = FlowSheetController<void>();
    PopupTypeApi(runtime).flowSheet<void>(_config(controller));

    expect(
      () => PopupTypeApi(runtime).flowSheet<void>(_config(controller)),
      throwsStateError,
    );
    await runtime.shutdown();
  });
}

FlowSheetConfig<R> _config<R>(FlowSheetController<R> controller) {
  return FlowSheetConfig<R>(
    controller: controller,
    initialPage: const _Page<void>('initial'),
    size: const SheetSizeConfig(height: SheetDimension.pixel(420)),
    animation: const PopupAnimationConfig(
      type: PopupAnimationType.slideUp,
      duration: Duration.zero,
      slideOffset: 1,
    ),
  );
}

class _Page<T> extends FlowSheetPage<T> {
  const _Page(String id) : super(id: id, maintainState: true);

  @override
  State<_Page<T>> createState() => _PageState<T>();
}

class _PageState<T> extends FlowSheetPageState<_Page<T>, T> {
  @override
  Widget build(BuildContext context) =>
      Center(child: Text('page-${widget.id}'));
}

class _LifecyclePage extends FlowSheetPage<void> {
  const _LifecyclePage(String id, this.events)
      : super(id: id, maintainState: true);

  final List<String> events;

  @override
  State<_LifecyclePage> createState() => _LifecyclePageState();
}

class _LifecyclePageState extends FlowSheetPageState<_LifecyclePage, void> {
  void _record(String event) => widget.events.add('${widget.id}:$event');

  @override
  void onLoad() => _record('load');
  @override
  void onShow() => _record('show');
  @override
  void onHide() => _record('hide');
  @override
  void onRemove() => _record('remove');
  @override
  void onClose() => _record('close');

  @override
  Widget build(BuildContext context) => Text('lifecycle-${widget.id}');
}

class _FlowApp extends StatelessWidget {
  const _FlowApp({required this.runtime});

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
