import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/src/api/popup_type_api.dart';
import 'package:unified_popups/src/configs/loading_config.dart';
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
      final result = api.openToast(
        ToastConfig(
          message: 'toast-$index',
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

    final handle = api.loading(
      LoadingConfig(
        message: 'uploading',
        lifetime: PopupLifetime.until(stale.future),
      ),
    );
    runtime.controller.markPresented(handle.id);
    final updated = api.loading(
      LoadingConfig(
        message: 'processing',
        lifetime: PopupLifetime.until(current.future),
      ),
    );

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
    final handle = api.loading(
      LoadingConfig(
        message: 'first',
        lifetime: PopupLifetime.until(stale.future),
      ),
    );
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
}
