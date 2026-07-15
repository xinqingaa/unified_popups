import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/src/api/popup_type_api.dart';
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
  test('toast lanes admit three and release queued entries in FIFO order',
      () async {
    final runtime = PopupRuntime();
    addTearDown(runtime.shutdown);
    final api = PopupTypeApi(runtime);
    final handles = <PopupHandle<void>>[];
    for (var index = 0; index < 5; index++) {
      final result = api.toast(
        ToastConfig.text(
          'toast-$index',
          position: PopupPosition.top,
          lifetime: const PopupLifetime.manual(),
        ),
      ) as PopupOpened<void>;
      handles.add(result.handle);
    }

    runtime.attachHost(Object());
    expect(
      handles.map((handle) => handle.state),
      <PopupEntryState>[
        PopupEntryState.entering,
        PopupEntryState.entering,
        PopupEntryState.entering,
        PopupEntryState.queued,
        PopupEntryState.queued,
      ],
    );
    for (final handle in handles.take(3)) {
      runtime.controller.markPresented(handle.id);
    }

    handles.first.dismiss();
    runtime.controller.markDisposed(handles.first.id);
    await handles.first.dismissed;

    expect(handles[3].state, PopupEntryState.entering);
    expect(handles[4].state, PopupEntryState.queued);
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
          LoadingConfig(
            message: 'uploading',
            lifetime: PopupLifetime.until(stale.future),
          ),
        )
        .requireHandle() as LoadingHandle;
    runtime.controller.markPresented(handle.id);
    final updated = api
        .loading(
          LoadingConfig(
            message: 'processing',
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
          LoadingConfig(
            message: 'first',
            lifetime: PopupLifetime.until(stale.future),
          ),
        )
        .requireHandle() as LoadingHandle;
    runtime.controller.markPresented(handle.id);

    handle.update(
      LoadingConfig(
        message: 'second',
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
          LoadingConfig(
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
  });
}
