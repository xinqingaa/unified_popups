import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/src/configs/popup_back_policy.dart';
import 'package:unified_popups/src/configs/popup_channel.dart';
import 'package:unified_popups/src/configs/popup_conflict_policy.dart';
import 'package:unified_popups/src/configs/popup_owner_policy.dart';
import 'package:unified_popups/src/configs/popup_route_policy.dart';
import 'package:unified_popups/src/controller/popup_controller.dart';
import 'package:unified_popups/src/controller/popup_dismiss_reason.dart';
import 'package:unified_popups/src/controller/popup_entry_request.dart';
import 'package:unified_popups/src/controller/popup_entry_state.dart';
import 'package:unified_popups/src/controller/popup_handle.dart';
import 'package:unified_popups/src/controller/popup_lifecycle_callbacks.dart';
import 'package:unified_popups/src/controller/popup_lifetime.dart';
import 'package:unified_popups/src/controller/popup_open_result.dart';
import 'package:unified_popups/src/controller/popup_ownership.dart';

void main() {
  late PopupController controller;

  setUp(() {
    controller = PopupController(runtimeEpoch: 'test');
  });

  tearDown(() {
    controller.dispose();
  });

  PopupHandle<T> open<T, C>(PopupEntryRequest<T, C> request) {
    final result = controller.open(request);
    expect(result, isA<PopupOpened<T>>());
    return (result as PopupOpened<T>).handle;
  }

  test('dismiss before host attach cannot leave a ghost entry', () async {
    final handle = open<void, String>(
      const PopupEntryRequest<void, String>(
        channel: PopupChannel.toast,
        config: 'hello',
      ),
    );
    expect(handle.state, PopupEntryState.pendingHost);

    await handle.dismiss();

    expect(handle.state, PopupEntryState.disposed);
    expect((await handle.outcome).reason, PopupDismissReason.manual);
    expect(controller.entries, isEmpty);
  });

  test('business result completes before visual dismissal', () async {
    controller.attachHost();
    final handle = open<String, String>(
      const PopupEntryRequest<String, String>(
        channel: PopupChannel.sheet,
        config: 'sheet',
      ),
    );
    controller.markPresented(handle.id);

    var physicallyDismissed = false;
    handle.dismissed.then((_) => physicallyDismissed = true);
    final removal = handle.complete('selected');

    expect(await handle.result, 'selected');
    expect((await handle.outcome).reason, PopupDismissReason.completed);
    expect(handle.state, PopupEntryState.exiting);
    expect(physicallyDismissed, isFalse);

    controller.markDisposed(handle.id);
    await removal;
    expect(physicallyDismissed, isTrue);
    expect(handle.state, PopupEntryState.disposed);
  });

  test('open result exposes business result and null conflict decisions',
      () async {
    controller.attachHost();
    final opened = controller.open<String, String>(
      const PopupEntryRequest<String, String>(
        channel: PopupChannel.menu,
        config: 'first',
        key: 'result-menu',
      ),
    );
    final handle = opened.requireHandle();
    controller.markPresented(handle.id);

    final rejected = controller.open<String, String>(
      const PopupEntryRequest<String, String>(
        channel: PopupChannel.menu,
        config: 'rejected',
        key: 'result-menu',
        conflictPolicy: PopupConflictPolicy.rejectNew,
      ),
    );
    expect(rejected, isA<PopupRejected<String>>());
    expect(await rejected.result, isNull);

    final completion = handle.complete('selected');
    expect(await opened.result, 'selected');
    controller.markDisposed(handle.id);
    await completion;
  });

  test('only the first competing close commits an outcome', () async {
    controller.attachHost();
    final handle = open<bool, String>(
      const PopupEntryRequest<bool, String>(
        channel: PopupChannel.confirm,
        config: 'confirm',
      ),
    );
    controller.markPresented(handle.id);

    final first = handle.complete(true);
    final second = handle.dismiss();
    expect(await handle.result, isTrue);
    expect((await handle.outcome).reason, PopupDismissReason.completed);

    controller.markDisposed(handle.id);
    await Future.wait(<Future<void>>[first, second]);
  });

  test('lifecycle callbacks may close reentrantly without corrupting state',
      () async {
    controller.attachHost();
    late PopupHandle<void> handle;
    handle = open<void, String>(
      PopupEntryRequest<void, String>(
        channel: PopupChannel.custom,
        config: 'custom',
        lifecycle: PopupLifecycleCallbacks<void>(
          onPresented: () => handle.dismiss(),
          onOutcome: (_) => handle.dismiss(),
        ),
      ),
    );

    controller.markPresented(handle.id);

    expect(handle.state, PopupEntryState.exiting);
    expect((await handle.outcome).reason, PopupDismissReason.manual);
    controller.markDisposed(handle.id);
    await handle.dismissed;
  });

  test('updateExisting returns the same handle and ignores stale events',
      () async {
    final oldEvent = Completer<void>();
    final newEvent = Completer<void>();
    controller.attachHost();

    final firstResult = controller.open<void, String>(
      PopupEntryRequest<void, String>(
        channel: PopupChannel.loading,
        config: 'uploading',
        key: 'global-loading',
        conflictPolicy: PopupConflictPolicy.updateExisting,
        updatable: true,
        lifetime: PopupLifetime.until(oldEvent.future),
      ),
    ) as PopupOpened<void>;
    final first = firstResult.handle;
    controller.markPresented(first.id);

    final secondResult = controller.open<void, String>(
      PopupEntryRequest<void, String>(
        channel: PopupChannel.loading,
        config: 'processing',
        key: 'global-loading',
        conflictPolicy: PopupConflictPolicy.updateExisting,
        updatable: true,
        lifetime: PopupLifetime.until(newEvent.future),
      ),
    ) as PopupUpdated<void>;
    final second = secondResult.handle;

    expect(identical(first, second), isTrue);
    expect(controller.entries.single.config, 'processing');
    expect(controller.entries.single.generation, 1);

    oldEvent.complete();
    await Future<void>.delayed(Duration.zero);
    expect(first.isActive, isTrue);

    newEvent.complete();
    expect((await first.outcome).reason, PopupDismissReason.externalEvent);
    controller.markDisposed(first.id);
    await first.dismissed;
  });

  test('replaceExisting may replace a differently typed result in one channel',
      () async {
    final controller = PopupController();
    addTearDown(controller.dispose);
    controller.attachHost();
    final first = controller
        .open<String, String>(
          const PopupEntryRequest<String, String>(
            channel: PopupChannel.menu,
            config: 'first',
            key: 'global-menu',
          ),
        )
        .requireHandle();
    controller.markPresented(first.id);

    final second = controller.open<int, int>(
      const PopupEntryRequest<int, int>(
        channel: PopupChannel.menu,
        config: 2,
        key: 'global-menu',
        conflictPolicy: PopupConflictPolicy.replaceExisting,
      ),
    );

    expect(second, isA<PopupOpened<int>>());
    expect((await first.outcome).reason, PopupDismissReason.replaced);
    controller.markDisposed(first.id);
    await first.dismissed;
    await Future<void>.delayed(Duration.zero);
    expect(second.requireHandle().state, PopupEntryState.entering);
  });

  test('parent dismissal first closes dismissWithParent children', () async {
    controller.attachHost();
    final order = <String>[];
    final parent = open<void, String>(
      PopupEntryRequest<void, String>(
        channel: PopupChannel.sheet,
        config: 'parent',
        lifecycle: PopupLifecycleCallbacks<void>(
          onOutcome: (_) => order.add('parent'),
        ),
      ),
    );
    final child = open<void, String>(
      PopupEntryRequest<void, String>(
        channel: PopupChannel.confirm,
        config: 'child',
        ownership: PopupOwnership(
          parentEntryId: parent.id,
          policy: PopupOwnerPolicy.dismissWithParent,
        ),
        lifecycle: PopupLifecycleCallbacks<void>(
          onOutcome: (_) => order.add('child'),
        ),
      ),
    );
    controller
      ..markPresented(parent.id)
      ..markPresented(child.id);

    parent.dismiss();

    expect(order, <String>['child', 'parent']);
    expect(
      (await child.outcome).reason,
      PopupDismissReason.parentDismissed,
    );
    controller
      ..markDisposed(child.id)
      ..markDisposed(parent.id);
    await Future.wait(<Future<void>>[parent.dismissed, child.dismissed]);
  });

  test('parent cascade emits one controller notification', () {
    controller.attachHost();
    final parent = open<void, String>(
      const PopupEntryRequest<void, String>(
        channel: PopupChannel.sheet,
        config: 'parent',
      ),
    );
    open<void, String>(
      PopupEntryRequest<void, String>(
        channel: PopupChannel.confirm,
        config: 'child',
        ownership: PopupOwnership(
          parentEntryId: parent.id,
          policy: PopupOwnerPolicy.dismissWithParent,
        ),
      ),
    );
    var notifications = 0;
    controller.addListener(() => notifications++);

    parent.dismiss();

    expect(notifications, 1);
  });

  test('queued entries do not start lifetime until presented', () async {
    final event = Completer<void>();
    controller.attachHost();
    final handle = open<void, String>(
      PopupEntryRequest<void, String>(
        channel: PopupChannel.toast,
        config: 'queued',
        initiallyQueued: true,
        lifetime: PopupLifetime.until(event.future),
      ),
    );
    expect(handle.state, PopupEntryState.queued);

    event.complete();
    await Future<void>.delayed(Duration.zero);
    expect(handle.isActive, isTrue);

    controller.releaseQueued(handle.id);
    controller.markPresented(handle.id);
    expect((await handle.outcome).reason, PopupDismissReason.externalEvent);
    controller.markDisposed(handle.id);
  });

  test('an exiting entry consumes repeated back presses', () async {
    controller.attachHost();
    final handle = open<void, String>(
      const PopupEntryRequest<void, String>(
        channel: PopupChannel.sheet,
        config: 'sheet',
        backPolicy: PopupBackPolicy.dismiss,
      ),
    );
    controller.markPresented(handle.id);

    expect(await controller.handleBack(), isTrue);
    expect(handle.state, PopupEntryState.exiting);
    expect(await controller.handleBack(), isTrue);
    expect((await handle.outcome).reason, PopupDismissReason.back);
    controller.markDisposed(handle.id);
  });

  test('host detach completes mounted and future calls immediately', () async {
    controller.attachHost();
    final mounted = open<void, String>(
      const PopupEntryRequest<void, String>(
        channel: PopupChannel.loading,
        config: 'loading',
      ),
    );
    controller.markPresented(mounted.id);

    controller.detachHost();
    expect(mounted.state, PopupEntryState.disposed);
    expect((await mounted.outcome).reason, PopupDismissReason.hostDetached);

    final late = open<void, String>(
      const PopupEntryRequest<void, String>(
        channel: PopupChannel.toast,
        config: 'late',
      ),
    );
    expect(late.state, PopupEntryState.disposed);
    expect((await late.outcome).reason, PopupDismissReason.hostUnavailable);
  });

  test('pendingHost capacity closes the oldest transient entry', () async {
    controller.dispose();
    controller = PopupController(
      runtimeEpoch: 'bounded',
      maxPendingHostEntries: 2,
    );
    final first = open<void, String>(
      const PopupEntryRequest<void, String>(
        channel: PopupChannel.toast,
        config: 'first',
      ),
    );
    final second = open<void, String>(
      const PopupEntryRequest<void, String>(
        channel: PopupChannel.confirm,
        config: 'second',
      ),
    );
    final third = open<void, String>(
      const PopupEntryRequest<void, String>(
        channel: PopupChannel.confirm,
        config: 'third',
      ),
    );

    expect(first.state, PopupEntryState.disposed);
    expect((await first.outcome).reason, PopupDismissReason.queueOverflow);
    expect(second.state, PopupEntryState.pendingHost);
    expect(third.state, PopupEntryState.pendingHost);
    expect(controller.entries, hasLength(2));
  });

  test('back delegate errors are reported and consume the back action',
      () async {
    controller.attachHost();
    final previous = FlutterError.onError;
    Object? reported;
    FlutterError.onError = (details) => reported = details.exception;
    addTearDown(() => FlutterError.onError = previous);
    open<void, String>(
      PopupEntryRequest<void, String>(
        channel: PopupChannel.custom,
        config: 'delegate',
        backPolicy: PopupBackPolicy.delegate,
        onBack: () async => throw StateError('back failed'),
      ),
    );

    expect(await controller.handleBack(), isTrue);
    expect(reported, isA<StateError>());
  });

  test('pause hides from back/route and resume restores', () async {
    controller.attachHost();
    final handle = open<String, String>(
      const PopupEntryRequest<String, String>(
        channel: PopupChannel.sheet,
        config: 'sheet',
        key: 'paused-sheet',
        routePolicy: PopupRoutePolicy.dismissOnAnyRouteChange,
        backPolicy: PopupBackPolicy.dismiss,
        ownership: PopupOwnership(routeToken: Object()),
      ),
    );
    controller.markPresented(handle.id);

    expect(handle.pause(), isTrue);
    expect(handle.isPaused, isTrue);
    expect(handle.isActive, isTrue);
    expect(controller.isVisibleKey('paused-sheet'), isFalse);
    expect(controller.hasChannel(PopupChannel.sheet), isTrue);
    expect(controller.interceptsSystemBack, isFalse);
    expect(await controller.handleBack(), isFalse);

    controller.handleRouteChanged(Object());
    expect(handle.isActive, isTrue);
    expect(handle.state, PopupEntryState.visible);

    expect(handle.resume(), isTrue);
    expect(handle.isPaused, isFalse);
    expect(controller.isVisibleKey('paused-sheet'), isTrue);
    expect(controller.interceptsSystemBack, isTrue);

    expect(handle.pause(), isTrue);
    expect(handle.resume(), isTrue);
    expect(handle.pause(), isTrue);
    expect(handle.pause(), isFalse);
  });

  test('pauseLatest targets topmost matching channel', () async {
    controller.attachHost();
    final bottom = open<void, String>(
      const PopupEntryRequest<void, String>(
        channel: PopupChannel.sheet,
        config: 'bottom',
      ),
    );
    controller.markPresented(bottom.id);
    final top = open<void, String>(
      const PopupEntryRequest<void, String>(
        channel: PopupChannel.sheet,
        config: 'top',
      ),
    );
    controller.markPresented(top.id);
    open<void, String>(
      const PopupEntryRequest<void, String>(
        channel: PopupChannel.confirm,
        config: 'confirm',
        backPolicy: PopupBackPolicy.block,
      ),
    );

    final paused = controller.pauseLatest(PopupChannel.sheet);
    expect(paused, isNotNull);
    expect(paused!.id, top.id);
    expect(top.isPaused, isTrue);
    expect(bottom.isPaused, isFalse);

    expect(controller.resumeEntry(top.id), isTrue);
    expect(top.isPaused, isFalse);
    expect(controller.pauseLatest(PopupChannel.loading), isNull);
  });

  test('pause suppresses lifetime; resume rearms timer', () async {
    controller.attachHost();
    final handle = open<void, String>(
      const PopupEntryRequest<void, String>(
        channel: PopupChannel.loading,
        config: 'loading',
        key: 'lifetime-pause',
        lifetime: PopupLifetime.after(Duration(milliseconds: 40)),
      ),
    );
    controller.markPresented(handle.id);

    expect(handle.pause(), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(handle.isActive, isTrue);
    expect(handle.isPaused, isTrue);

    expect(handle.resume(), isTrue);
    expect(handle.isPaused, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(handle.isActive, isFalse);
    expect((await handle.outcome).reason, PopupDismissReason.timeout);
  });
}
