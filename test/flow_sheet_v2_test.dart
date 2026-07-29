import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/src/api/popup_type_api.dart';
import 'package:unified_popups/src/configs/confirm_config.dart';
import 'package:unified_popups/src/configs/flow_sheet_config.dart';
import 'package:unified_popups/src/configs/popup_animation_config.dart';
import 'package:unified_popups/src/configs/sheet_config.dart';
import 'package:unified_popups/src/configs/sheet_types.dart';
import 'package:unified_popups/src/controller/popup_dismiss_reason.dart';
import 'package:unified_popups/src/controller/popup_entry_state.dart';
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
    final handle = PopupTypeApi(runtime)
        .flowSheet<String>(
          _config(controller),
        )
        .requireHandle();
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
    final handle = PopupTypeApi(runtime)
        .flowSheet<void>(_config(controller))
        .requireHandle();
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

  testWidgets(
      'platform back keeps canHandlePop and closes a single-page flowSheet',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final canHandlePopEvents = <bool>[];

    late BuildContext pageContext;
    final controller = FlowSheetController<void>();
    await tester.pumpWidget(
      _FlowApp(
        runtime: runtime,
        onNavigationNotification: (notification) {
          canHandlePopEvents.add(notification.canHandlePop);
          return true;
        },
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const Scaffold(body: Text('host-page'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final handle = PopupTypeApi(runtime)
        .flowSheet<void>(_config(controller))
        .requireHandle();
    await tester.pumpAndSettle();
    expect(find.text('page-initial'), findsOneWidget);
    expect(canHandlePopEvents, isNotEmpty);
    expect(canHandlePopEvents.last, isTrue);
    expect(ModalRoute.of(pageContext)!.popGestureEnabled, isFalse);

    expect(await tester.binding.handlePopRoute(), isTrue);
    expect((await handle.outcome).reason, PopupDismissReason.back);
    await tester.pumpAndSettle();
    await handle.dismissed;
    expect(find.text('page-initial'), findsNothing);
    expect(find.text('host-page'), findsOneWidget);
  });

  testWidgets(
      'platform back pops flowSheet pages before dismissing the outer sheet',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    late BuildContext pageContext;
    final controller = FlowSheetController<void>();
    final handle = PopupTypeApi(runtime)
        .flowSheet<void>(_config(controller))
        .requireHandle();
    await tester.pumpWidget(
      _FlowApp(
        runtime: runtime,
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const Scaffold(body: Text('host-page'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.push<void>(const _Page<void>('second'));
    await tester.pumpAndSettle();

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('page-initial'), findsOneWidget);
    expect(handle.isActive, isTrue);
    expect(find.text('host-page'), findsOneWidget);
    expect(ModalRoute.of(pageContext)!.popGestureEnabled, isFalse);

    expect(await tester.binding.handlePopRoute(), isTrue);
    expect((await handle.outcome).reason, PopupDismissReason.back);
    await tester.pumpAndSettle();
    await handle.dismissed;
    expect(find.text('host-page'), findsOneWidget);
  });

  testWidgets(
      'confirm above flowSheet blocks platform back without closing either',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final api = PopupTypeApi(runtime);
    final controller = FlowSheetController<void>();
    final flowHandle = api.flowSheet<void>(_config(controller)).requireHandle();
    await tester.pumpWidget(_FlowApp(runtime: runtime));
    await tester.pumpAndSettle();

    final confirmHandle =
        api.confirm(const ConfirmConfig(content: 'stay?')).requireHandle();
    await tester.pumpAndSettle();
    expect(find.text('stay?'), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pump();
    expect(confirmHandle.state, PopupEntryState.visible);
    expect(flowHandle.isActive, isTrue);
    expect(find.text('page-initial'), findsOneWidget);
    expect(find.text('stay?'), findsOneWidget);

    confirmHandle.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('stay?'), findsNothing);
    expect(flowHandle.isActive, isTrue);
  });

  testWidgets('external close settles pending pages and disposes the session',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final controller = FlowSheetController<void>();
    final handle = PopupTypeApi(runtime)
        .flowSheet<void>(_config(controller))
        .requireHandle();
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
    final handle = PopupTypeApi(runtime)
        .flowSheet<void>(
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
        )
        .requireHandle();
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

  testWidgets('current page can consume back before default navigation',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    var backCount = 0;
    final controller = FlowSheetController<void>();
    final handle = PopupTypeApi(runtime)
        .flowSheet<void>(
          FlowSheetConfig<void>(
            controller: controller,
            initialPage: _BackBlockingPage(() {
              backCount += 1;
              return true;
            }),
            size: const SheetSizeConfig(
              height: SheetDimension.pixel(420),
            ),
            animation: const PopupAnimationConfig(
              type: PopupAnimationType.slideUp,
              duration: Duration.zero,
              slideOffset: 1,
            ),
          ),
        )
        .requireHandle();

    await tester.pumpWidget(_FlowApp(runtime: runtime));
    await tester.pumpAndSettle();

    expect(await runtime.controller.handleBack(), isTrue);
    expect(backCount, 1);
    expect(handle.isActive, isTrue);

    controller.closeAll();
    await tester.pumpAndSettle();
    await handle.dismissed;
  });

  test('dynamic drag mode can be disabled and restored', () {
    final controller = FlowSheetController<void>();
    addTearDown(controller.dispose);

    controller.updateDragDismissMode(SheetDragDismissMode.disabled);
    expect(
      controller.dragDismissModeNotifier.value,
      SheetDragDismissMode.disabled,
    );

    controller.updateDragDismissMode(SheetDragDismissMode.fullBody);
    expect(
      controller.dragDismissModeNotifier.value,
      SheetDragDismissMode.fullBody,
    );
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

class _BackBlockingPage extends FlowSheetPage<void> {
  const _BackBlockingPage(this.onBackCallback)
      : super(id: 'back-blocking', maintainState: true);

  final bool Function() onBackCallback;

  @override
  State<_BackBlockingPage> createState() => _BackBlockingPageState();
}

class _BackBlockingPageState
    extends FlowSheetPageState<_BackBlockingPage, void> {
  @override
  bool onBack() => widget.onBackCallback();

  @override
  Widget build(BuildContext context) => const Text('back-blocking');
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
  const _FlowApp({
    required this.runtime,
    this.home = const Scaffold(body: Text('app')),
    this.onNavigationNotification,
  });

  final PopupRuntime runtime;
  final Widget home;
  final NotificationListenerCallback<NavigationNotification>?
      onNavigationNotification;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: <NavigatorObserver>[runtime.routeObserver],
      onNavigationNotification: onNavigationNotification,
      builder: (context, child) => PopupHost(
        runtime: runtime,
        sceneBuilder: (context, runtime, entries) => PopupScene(
          runtime: runtime,
          entries: entries,
        ),
        child: child!,
      ),
      home: home,
    );
  }
}
