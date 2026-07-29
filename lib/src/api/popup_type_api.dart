import '../configs/confirm_config.dart';
import '../configs/date_config.dart';
import '../configs/drop_menu_config.dart';
import '../configs/custom_popup_config.dart';
import '../configs/flow_sheet_config.dart';
import '../configs/loading_config.dart';
import '../configs/menu_config.dart';
import '../configs/popup_back_policy.dart';
import '../configs/popup_barrier_config.dart';
import '../configs/popup_channel.dart';
import '../configs/popup_position.dart';
import '../configs/sheet_config.dart';
import '../configs/popup_owner_policy.dart';
import '../configs/popup_keys.dart';
import '../configs/toast_config.dart';
import '../controller/popup_dismiss_reason.dart';
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

  PopupOpenResult<void> toast(ToastConfig config) {
    final behavior = config.behavior;
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

  PopupOpenResult<void> loading(LoadingConfig config) {
    final behavior = config.behavior;
    return runtime.controller.open<void, LoadingConfig>(
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
  }

  PopupOpenResult<bool> confirm(ConfirmConfig config) {
    final behavior = config.behavior;
    return runtime.controller.open<bool, ConfirmConfig>(
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
  }

  PopupOpenResult<DateTime> date(DateConfig config) {
    final behavior = config.behavior;
    return runtime.controller.open<DateTime, DateConfig>(
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
  }

  PopupOpenResult<T> sheet<T>(SheetConfig<T> config) {
    final behavior = config.behavior;
    late PopupHandle<T> handle;
    final result = runtime.controller.open<T, SheetConfig<T>>(
      PopupEntryRequest<T, SheetConfig<T>>(
        channel: PopupChannel.sheet,
        config: config,
        key: behavior.key,
        tags: behavior.tags,
        conflictPolicy: behavior.conflictPolicy,
        routePolicy: behavior.routePolicy,
        backPolicy: config.onBack == null
            ? behavior.backPolicy
            : PopupBackPolicy.delegate,
        ownership: _captureOwnership(config.ownership),
        lifecycle: config.lifecycle,
        onBack: config.onBack == null
            ? null
            : () async {
                if (await config.onBack!()) return true;
                runtime.controller.dismissEntry(
                  handle.id,
                  reason: PopupDismissReason.back,
                );
                return true;
              },
      ),
    );
    final openedHandle = result.handleOrNull;
    if (openedHandle != null) handle = openedHandle;
    return result;
  }

  PopupOpenResult<R> flowSheet<R>(FlowSheetConfig<R> config) {
    final behavior = config.behavior;
    config.controller.claimPopupSession();
    late PopupHandle<R> handle;
    late PopupOpenResult<R> result;
    try {
      result = runtime.controller.open<R, FlowSheetConfig<R>>(
        PopupEntryRequest<R, FlowSheetConfig<R>>(
          channel: PopupChannel.flowSheet,
          config: config,
          key: behavior.key,
          tags: behavior.tags,
          conflictPolicy: behavior.conflictPolicy,
          routePolicy: behavior.routePolicy,
          backPolicy: behavior.backPolicy,
          ownership: _captureOwnership(config.ownership),
          lifecycle: config.lifecycle,
          onBack: () async {
            if (config.controller.handleCurrentPageBack()) {
              return true;
            }
            if (config.controller.canPop) {
              config.controller.pop();
              return true;
            }
            runtime.controller.dismissEntry(
              handle.id,
              reason: PopupDismissReason.back,
            );
            return true;
          },
        ),
      );
    } catch (_) {
      config.controller.releasePopupSessionClaim();
      rethrow;
    }
    final openedHandle = result.handleOrNull;
    if (openedHandle != null) {
      handle = openedHandle;
      config.controller.attachPopupHandle(handle);
    } else {
      config.controller.releasePopupSessionClaim();
    }
    return result;
  }

  PopupOpenResult<T> menu<T>(MenuConfig<T> config) {
    final behavior = config.behavior;
    if (!config.anchor.attached.value) {
      throw StateError('PopupAnchor must be mounted before opening a menu.');
    }
    return runtime.controller.open<T, MenuConfig<T>>(
      PopupEntryRequest<T, MenuConfig<T>>(
        channel: PopupChannel.menu,
        config: config,
        key: behavior.key,
        tags: behavior.tags,
        conflictPolicy: behavior.conflictPolicy,
        routePolicy: behavior.routePolicy,
        backPolicy: behavior.backPolicy,
        ownership: _captureOwnership(config.ownership),
        lifecycle: config.lifecycle,
      ),
    );
  }

  PopupOpenResult<T> dropMenu<T>(DropMenuConfig<T> config) {
    final behavior = config.behavior;
    if (!config.anchor.attached.value) {
      throw StateError(
          'PopupAnchor must be mounted before opening a drop menu.');
    }
    return runtime.controller.open<T, DropMenuConfig<T>>(
      PopupEntryRequest<T, DropMenuConfig<T>>(
        channel: PopupChannel.menu,
        config: config,
        key: behavior.key,
        tags: behavior.tags,
        conflictPolicy: behavior.conflictPolicy,
        routePolicy: behavior.routePolicy,
        backPolicy: behavior.backPolicy,
        ownership: _captureOwnership(config.ownership),
        lifecycle: config.lifecycle,
      ),
    );
  }

  PopupOpenResult<T> custom<T>(CustomPopupConfig<T> config) {
    final behavior = config.behavior;
    return runtime.controller.open<T, CustomPopupConfig<T>>(
      PopupEntryRequest<T, CustomPopupConfig<T>>(
        channel: PopupChannel.custom,
        config: config,
        key: behavior.key,
        tags: behavior.tags,
        conflictPolicy: behavior.conflictPolicy,
        routePolicy: behavior.routePolicy,
        backPolicy: behavior.backPolicy,
        ownership: _captureOwnership(config.ownership),
        lifecycle: config.lifecycle,
      ),
    );
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
