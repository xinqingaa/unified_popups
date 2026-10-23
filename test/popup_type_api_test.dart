import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/src/api/popup_type_api.dart';
import 'package:unified_popups/src/api/toast_lane_scheduler.dart';
import 'package:unified_popups/src/configs/toast_lane_motion.dart';
import 'package:unified_popups/src/configs/loading_config.dart';
import 'package:unified_popups/src/configs/popup_barrier_config.dart';
import 'package:unified_popups/src/configs/popup_behavior_config.dart';
import 'package:unified_popups/src/configs/popup_conflict_policy.dart';
import 'package:unified_popups/src/configs/popup_position.dart';
import 'package:unified_popups/src/configs/toast_config.dart';
import 'package:unified_popups/src/controller/popup_dismiss_reason.dart';
import 'package:unified_popups/src/controller/popup_entry_state.dart';
import 'package:unified_popups/src/controller/popup_handle.dart';
import 'package:unified_popups/src/controller/popup_lifetime.dart';
import 'package:unified_popups/src/controller/popup_open_result.dart';
import 'package:unified_popups/src/runtime/popup_runtime.dart';

void main() {
  testWidgets('toast lane keeps one visible toast and hands off FIFO',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final api = PopupTypeApi(runtime);
    final handles = <PopupHandle<void>>[];
    for (var index = 0; index < 4; index++) {
      handles.add(
        api
            .toast(
              ToastConfig.text(
                'toast-$index',
                position: PopupPosition.top,
                lifetime: const PopupLifetime.manual(),
              ),
            )
            .requireHandle(),
      );
    }

    runtime.attachHost(Object());
    expect(handles[0].state, PopupEntryState.entering);
    expect(handles[1].state, PopupEntryState.queued);
    expect(handles[2].state, PopupEntryState.queued);
    expect(handles[3].state, PopupEntryState.queued);

    runtime.controller.markPresented(handles[0].id);
    await tester.pump(const Duration(milliseconds: 499));
    expect(handles[0].state, PopupEntryState.visible);
    expect(handles[1].state, PopupEntryState.queued);

    await tester.pump(const Duration(milliseconds: 1));
    expect(handles[0].state, PopupEntryState.exiting);
    expect(_replaceExit(runtime, handles[0].id), isTrue);
    expect(handles[1].state, PopupEntryState.queued);
    await tester.pump(const Duration(milliseconds: 49));
    expect(handles[1].state, PopupEntryState.queued);
    await tester.pump(const Duration(milliseconds: 1));
    expect(handles[1].state, PopupEntryState.entering);
    expect(handles[2].state, PopupEntryState.queued);

    runtime.controller.markPresented(handles[1].id);
    await tester.pump(ToastLaneMotion.dwell);
    await tester.pump(ToastLaneMotion.enterDelay);
    expect(handles[1].state, PopupEntryState.exiting);
    expect(handles[2].state, PopupEntryState.entering);
    expect(handles[3].state, PopupEntryState.queued);
    ToastLaneScheduler.detach(runtime.controller);
  });

  testWidgets('a queued toast waits out a short lifetime before replacing',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final api = PopupTypeApi(runtime);
    final first = api
        .toast(
          const ToastConfig.text(
            'first',
            lifetime: PopupLifetime.after(Duration(milliseconds: 200)),
          ),
        )
        .requireHandle();
    final second = api
        .toast(
          const ToastConfig.text(
            'second',
            lifetime: PopupLifetime.manual(),
          ),
        )
        .requireHandle();
    runtime.attachHost(Object());
    runtime.controller.markPresented(first.id);

    await tester.pump(const Duration(milliseconds: 200));
    expect(first.state, PopupEntryState.visible);
    expect(second.state, PopupEntryState.queued);

    await tester.pump(const Duration(milliseconds: 300));
    expect(first.state, PopupEntryState.exiting);
    expect(_replaceExit(runtime, first.id), isTrue);
    expect((await first.outcome).reason, PopupDismissReason.replaced);
    ToastLaneScheduler.detach(runtime.controller);
  });

  testWidgets('a toast already past the dwell is replaced immediately',
      (tester) async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final api = PopupTypeApi(runtime);
    final first = api
        .toast(
          const ToastConfig.text(
            'first',
            lifetime: PopupLifetime.manual(),
          ),
        )
        .requireHandle();
    runtime.attachHost(Object());
    runtime.controller.markPresented(first.id);
    await tester.pump(ToastLaneMotion.dwell);
    expect(first.state, PopupEntryState.visible);

    final second = api
        .toast(
          const ToastConfig.text(
            'second',
            lifetime: PopupLifetime.manual(),
          ),
        )
        .requireHandle();
    expect(first.state, PopupEntryState.exiting);
    expect(_replaceExit(runtime, first.id), isTrue);
    expect(second.state, PopupEntryState.queued);
    await tester.pump(ToastLaneMotion.enterDelay);
    expect(second.state, PopupEntryState.entering);
    ToastLaneScheduler.detach(runtime.controller);
  });

  test('toast positions and barrier toasts do not share the lane slot', () {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    runtime.attachHost(Object());
    final api = PopupTypeApi(runtime);
    final top = api
        .toast(
          const ToastConfig.text('top', position: PopupPosition.top),
        )
        .requireHandle();
    final bottom = api
        .toast(
          const ToastConfig.text('bottom', position: PopupPosition.bottom),
        )
        .requireHandle();
    final modal = api
        .toast(
          const ToastConfig.text(
            'modal',
            barrier: PopupBarrierConfig(),
          ),
        )
        .requireHandle();

    expect(top.state, PopupEntryState.entering);
    expect(bottom.state, PopupEntryState.entering);
    expect(modal.state, PopupEntryState.entering);
    ToastLaneScheduler.detach(runtime.controller);
  });

  test('toasts opened before the host still keep a single slot', () {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final api = PopupTypeApi(runtime);
    final handles = <PopupHandle<void>>[];
    for (var index = 0; index < 3; index++) {
      handles.add(
        api
            .toast(
              ToastConfig.text(
                'toast-$index',
                position: PopupPosition.bottom,
                lifetime: const PopupLifetime.manual(),
              ),
            )
            .requireHandle(),
      );
    }

    runtime.attachHost(Object());
    expect(handles[0].state, PopupEntryState.entering);
    expect(handles[1].state, PopupEntryState.queued);
    expect(handles[2].state, PopupEntryState.queued);
  });

  test('toast lane motion constants stay at the acceptance values', () {
    expect(ToastLaneMotion.dwell, const Duration(milliseconds: 500));
    expect(ToastLaneMotion.enterDelay, const Duration(milliseconds: 50));
    expect(ToastLaneMotion.exitDuration, const Duration(milliseconds: 180));
    expect(ToastLaneMotion.shift, 20);
    expect(
      ToastLaneMotion.outgoingShift(PopupPosition.left),
      const Offset(-20, 0),
    );
    expect(
      ToastLaneMotion.outgoingShift(PopupPosition.right),
      const Offset(20, 0),
    );
    expect(
      ToastLaneMotion.outgoingShift(PopupPosition.bottom),
      const Offset(-20, 0),
    );
  });

  test('loading updates one stable handle and replaces external lifetime',
      () async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final binding = Object();
    runtime.attachHost(binding);
    final api = PopupTypeApi(runtime);
    final stale = Completer<void>();
    final current = Completer<void>();

    final handle = api
        .loading(
          LoadingConfig.text(
            'uploading',
            lifetime: PopupLifetime.until(stale.future),
          ),
        )
        .requireHandle() as LoadingHandle;
    runtime.controller.markPresented(handle.id);
    final updated = api
        .loading(
          LoadingConfig.text(
            'processing',
            lifetime: PopupLifetime.until(current.future),
          ),
        )
        .requireHandle() as LoadingHandle;

    expect(identical(handle, updated), isTrue);
    expect(
      (runtime.controller.entries.single.config! as LoadingConfig).message,
      'processing',
    );

    stale.complete();
    await Future<void>.delayed(Duration.zero);
    expect(handle.isActive, isTrue);

    current.complete();
    expect((await handle.outcome).reason, PopupDismissReason.externalEvent);
    runtime.controller.markDisposed(handle.id);
    await handle.dismissed;
  });

  test('handle.update also restarts lifetime from the new config', () async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    runtime.attachHost(Object());
    final api = PopupTypeApi(runtime);
    final stale = Completer<void>();
    final current = Completer<void>();
    final handle = api
        .loading(
          LoadingConfig.text(
            'first',
            lifetime: PopupLifetime.until(stale.future),
          ),
        )
        .requireHandle() as LoadingHandle;
    runtime.controller.markPresented(handle.id);

    handle.update(
      LoadingConfig.text(
        'second',
        lifetime: PopupLifetime.until(current.future),
      ),
    );
    stale.complete();
    await Future<void>.delayed(Duration.zero);
    expect(handle.isActive, isTrue);

    current.complete();
    expect((await handle.outcome).reason, PopupDismissReason.externalEvent);
    runtime.controller.markDisposed(handle.id);
  });

  test('until closes loading and toast when the observed future fails',
      () async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    runtime.attachHost(Object());
    final api = PopupTypeApi(runtime);
    final loadingDone = Completer<void>();
    final toastDone = Completer<void>();

    final loading = api
        .loading(
          LoadingConfig.indicator(
            lifetime: PopupLifetime.until(loadingDone.future),
          ),
        )
        .requireHandle();
    final toast = api
        .toast(
          ToastConfig.text(
            'waiting',
            lifetime: PopupLifetime.until(toastDone.future),
          ),
        )
        .requireHandle();
    runtime.controller
      ..markPresented(loading.id)
      ..markPresented(toast.id);

    loadingDone.completeError(StateError('loading failed'));
    toastDone.completeError(StateError('toast failed'));

    expect(
      (await loading.outcome).reason,
      PopupDismissReason.externalEvent,
    );
    expect(
      (await toast.outcome).reason,
      PopupDismissReason.externalEvent,
    );
    runtime.controller
      ..markDisposed(loading.id)
      ..markDisposed(toast.id);
  });

  test('toast update rejects immutable position and barrier topology',
      () async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    runtime.attachHost(Object());
    final api = PopupTypeApi(runtime);
    const behavior = PopupBehaviorConfig(
      key: 'status',
      conflictPolicy: PopupConflictPolicy.updateExisting,
    );
    final result = api.toast(
      const ToastConfig.text(
        'first',
        behavior: behavior,
        lifetime: PopupLifetime.manual(),
      ),
    ) as PopupOpened<void>;
    final handle = result.handle as ToastHandle;
    runtime.controller.markPresented(handle.id);

    expect(
      handle.update(
        const ToastConfig.text(
          'moved',
          position: PopupPosition.bottom,
          behavior: behavior,
          lifetime: PopupLifetime.manual(),
        ),
      ),
      isFalse,
    );
    expect(
      handle.update(
        const ToastConfig.text(
          'modal',
          behavior: behavior,
          barrier: PopupBarrierConfig(),
          lifetime: PopupLifetime.manual(),
        ),
      ),
      isFalse,
    );
    final current = runtime.controller.entries.single.config! as ToastConfig;
    expect(current.message, 'first');
    expect(runtime.controller.entries.single.generation, 0);

    expect(
      handle.update(
        const ToastConfig.text(
          'second',
          behavior: behavior,
          lifetime: PopupLifetime.manual(),
        ),
      ),
      isTrue,
    );
    expect(
      (runtime.controller.entries.single.config! as ToastConfig).message,
      'second',
    );
    expect(runtime.controller.entries.single.state, PopupEntryState.visible);
    expect(runtime.controller.entries.single.replaceExit, isFalse);
    ToastLaneScheduler.detach(runtime.controller);
  });
}

bool _replaceExit(PopupRuntime runtime, String id) {
  return runtime.controller.entries
      .singleWhere((entry) => entry.id == id)
      .replaceExit;
}
