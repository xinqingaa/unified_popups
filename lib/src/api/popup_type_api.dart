import '../configs/confirm_config.dart';
import '../configs/date_config.dart';
import '../configs/loading_config.dart';
import '../configs/popup_barrier_config.dart';
import '../configs/popup_channel.dart';
import '../configs/popup_position.dart';
import '../configs/popup_owner_policy.dart';
import '../configs/toast_config.dart';
import '../controller/popup_entry_request.dart';
import '../controller/popup_entry_state.dart';
import '../controller/popup_handle.dart';
import '../controller/popup_lifecycle_callbacks.dart';
import '../controller/popup_open_result.dart';
import '../controller/popup_ownership.dart';
import '../runtime/popup_runtime.dart';

typedef ToastHandle = UpdatablePopupHandle<void, ToastConfig>;
typedef LoadingHandle = UpdatablePopupHandle<void, LoadingConfig>;

/// Type-specific API implementation used by the eventual global `Pop` facade.
final class PopupTypeApi {
  PopupTypeApi(this.runtime);

  final PopupRuntime runtime;

  PopupOpenResult<void> openToast(ToastConfig config) {
    final behavior = config.behavior;
    assert(
      behavior.channel == PopupChannel.toast,
      'ToastConfig must use PopupChannel.toast.',
    );
    final initiallyQueued = _visibleToastCount(config.position) >= 3;
    final ownership = _captureOwnership(config.ownership);
    final lifecycle = PopupLifecycleCallbacks<void>(
      onPresented: config.lifecycle.onPresented,
      onOutcome: config.lifecycle.onOutcome,
      onDismissed: (outcome) {
        try {
          config.lifecycle.onDismissed?.call(outcome);
        } finally {
          _releaseToastLane(config.position);
        }
      },
    );
    return runtime.controller.open<void, ToastConfig>(
      PopupEntryRequest<void, ToastConfig>(
        channel: PopupChannel.toast,
        config: config,
        key: behavior.key,
        tags: behavior.tags,
        conflictPolicy: behavior.conflictPolicy,
        routePolicy: behavior.routePolicy,
        backPolicy: behavior.backPolicy,
        ownership: ownership,
        lifetime: config.lifetime,
        lifecycle: lifecycle,
        updatable: behavior.key != null,
        initiallyQueued: initiallyQueued,
        resolveUpdate: (previous, next) => _toastUpdate(previous, next),
      ),
    );
  }

  LoadingHandle loading(LoadingConfig config) {
    final behavior = config.behavior;
    assert(
      behavior.channel == PopupChannel.loading,
      'LoadingConfig must use PopupChannel.loading.',
    );
    final result = runtime.controller.open<void, LoadingConfig>(
      PopupEntryRequest<void, LoadingConfig>(
        channel: PopupChannel.loading,
        config: config,
        key: behavior.key,
        tags: behavior.tags,
        conflictPolicy: behavior.conflictPolicy,
        routePolicy: behavior.routePolicy,
        backPolicy: behavior.backPolicy,
        ownership: _captureOwnership(config.ownership),
        lifetime: config.lifetime,
        lifecycle: config.lifecycle,
        updatable: true,
        resolveUpdate: (previous, next) => _loadingUpdate(next),
      ),
    );
    final handle = switch (result) {
      PopupOpened<void>(:final handle) => handle,
      PopupUpdated<void>(:final handle) => handle,
      PopupToggledClosed<void>() || PopupRejected<void>() => throw StateError(
          'LoadingConfig must use an open/update conflict policy.',
        ),
    };
    return handle as LoadingHandle;
  }

  PopupHandle<bool> confirm(ConfirmConfig config) {
    final behavior = config.behavior;
    assert(
      behavior.channel == PopupChannel.confirm,
      'ConfirmConfig must use PopupChannel.confirm.',
    );
    final result = runtime.controller.open<bool, ConfirmConfig>(
      PopupEntryRequest<bool, ConfirmConfig>(
        channel: PopupChannel.confirm,
        config: config,
        key: behavior.key,
        tags: behavior.tags,
        conflictPolicy: behavior.conflictPolicy,
        routePolicy: behavior.routePolicy,
        backPolicy: behavior.backPolicy,
        ownership: _modalOwnership(config.ownership),
        lifecycle: config.lifecycle,
      ),
    );
    return switch (result) {
      PopupOpened<bool>(:final handle) => handle,
      PopupUpdated<bool>(:final handle) => handle,
      PopupToggledClosed<bool>() || PopupRejected<bool>() => throw StateError(
          'ConfirmConfig was not opened by its conflict policy.',
        ),
    };
  }

  PopupHandle<DateTime> date(DateConfig config) {
    final behavior = config.behavior;
    assert(
      behavior.channel == PopupChannel.date,
      'DateConfig must use PopupChannel.date.',
    );
    final result = runtime.controller.open<DateTime, DateConfig>(
      PopupEntryRequest<DateTime, DateConfig>(
        channel: PopupChannel.date,
        config: config,
        key: behavior.key,
        tags: behavior.tags,
        conflictPolicy: behavior.conflictPolicy,
        routePolicy: behavior.routePolicy,
        backPolicy: behavior.backPolicy,
        ownership: _modalOwnership(config.ownership),
        lifecycle: config.lifecycle,
      ),
    );
    return switch (result) {
      PopupOpened<DateTime>(:final handle) => handle,
      PopupUpdated<DateTime>(:final handle) => handle,
      PopupToggledClosed<DateTime>() ||
      PopupRejected<DateTime>() =>
        throw StateError(
          'DateConfig was not opened by its conflict policy.',
        ),
    };
  }

  Future<void> hideLoading({String key = PopupKeys.globalLoading}) {
    return runtime.controller.dismissKey(key);
  }

  int _visibleToastCount(PopupPosition position) {
    return runtime.controller.entries.where((entry) {
      return entry.channel == PopupChannel.toast &&
          entry.state != PopupEntryState.queued &&
          (entry.state.isActive || entry.state.isMounted) &&
          (entry.config! as ToastConfig).position == position;
    }).length;
  }

  void _releaseToastLane(PopupPosition position) {
    final available = 3 - _visibleToastCount(position);
    if (available <= 0) return;
    final queued = runtime.controller.entries.where((entry) {
      return entry.channel == PopupChannel.toast &&
          entry.state == PopupEntryState.queued &&
          (entry.config! as ToastConfig).position == position;
    }).take(available);
    for (final entry in queued.toList(growable: false)) {
      runtime.controller.releaseQueued(entry.id);
    }
  }

  PopupOwnership _captureOwnership(PopupOwnership ownership) {
    if (ownership.routeToken != null) return ownership;
    return PopupOwnership(
      routeToken: runtime.captureRoute(),
      parentEntryId: ownership.parentEntryId,
      policy: ownership.policy,
    );
  }

  PopupOwnership _modalOwnership(PopupOwnership ownership) {
    if (ownership.parentEntryId != null ||
        ownership.policy == PopupOwnerPolicy.independent) {
      return _captureOwnership(ownership);
    }
    String? parentId;
    for (final entry in runtime.controller.entries.reversed) {
      if (!entry.state.isActive) continue;
      if (entry.channel == PopupChannel.sheet ||
          entry.channel == PopupChannel.flowSheet ||
          entry.channel == PopupChannel.custom ||
          entry.channel == PopupChannel.date ||
          entry.channel == PopupChannel.confirm) {
        parentId = entry.id;
        break;
      }
    }
    return PopupOwnership(
      routeToken: ownership.routeToken ?? runtime.captureRoute(),
      parentEntryId: parentId,
      policy: ownership.policy,
    );
  }

  PopupEntryUpdate<void>? _toastUpdate(
    ToastConfig previous,
    ToastConfig config,
  ) {
    if (previous.position != config.position ||
        !_sameBarrierTopology(previous.barrier, config.barrier)) {
      return null;
    }
    final behavior = config.behavior;
    return PopupEntryUpdate<void>(
      tags: behavior.tags,
      routePolicy: behavior.routePolicy,
      backPolicy: behavior.backPolicy,
      ownership: _captureOwnership(config.ownership),
      lifetime: config.lifetime,
      lifecycle: PopupLifecycleCallbacks<void>(
        onPresented: config.lifecycle.onPresented,
        onOutcome: config.lifecycle.onOutcome,
        onDismissed: (outcome) {
          try {
            config.lifecycle.onDismissed?.call(outcome);
          } finally {
            _releaseToastLane(config.position);
          }
        },
      ),
    );
  }

  bool _sameBarrierTopology(
    PopupBarrierConfig previous,
    PopupBarrierConfig next,
  ) {
    return previous.visible == next.visible &&
        previous.dismissible == next.dismissible;
  }

  PopupEntryUpdate<void> _loadingUpdate(LoadingConfig config) {
    final behavior = config.behavior;
    return PopupEntryUpdate<void>(
      tags: behavior.tags,
      routePolicy: behavior.routePolicy,
      backPolicy: behavior.backPolicy,
      ownership: _captureOwnership(config.ownership),
      lifetime: config.lifetime,
      lifecycle: config.lifecycle,
    );
  }
}
