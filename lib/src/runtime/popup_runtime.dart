import 'dart:async';

import '../controller/popup_controller.dart';
import '../navigation/popup_route_observer_v2.dart';
import '../navigation/popup_route_token.dart';

enum PopupRuntimeState {
  cold,
  attached,
  detached,
  shutdown,
}

/// Process-wide popup services; business code accesses the default instance
/// through `Pop`, while tests may construct isolated runtimes.
final class PopupRuntime {
  PopupRuntime({PopupController? controller})
      : controller = controller ?? PopupController() {
    routeObserver = PopupRouteObserverV2(this.controller);
  }

  final PopupController controller;
  late final PopupRouteObserverV2 routeObserver;
  final Completer<void> _ready = Completer<void>();

  PopupRuntimeState _state = PopupRuntimeState.cold;
  Object? _hostBinding;

  PopupRuntimeState get state => _state;
  bool get isHostAttached => _state == PopupRuntimeState.attached;
  bool get isReady => _ready.isCompleted && isHostAttached;
  Future<void> get ready => _ready.future;
  PopupRouteToken? captureRoute() => routeObserver.currentToken;

  /// Returns false only for a competing second host or a shutdown runtime.
  bool attachHost(Object binding) {
    if (_state == PopupRuntimeState.shutdown) return false;
    if (_hostBinding != null && !identical(_hostBinding, binding)) {
      assert(false, 'Only one PopupHost may be attached to a PopupRuntime.');
      return false;
    }
    _hostBinding = binding;
    _state = PopupRuntimeState.attached;
    controller.attachHost();
    if (!_ready.isCompleted) _ready.complete();
    return true;
  }

  void detachHost(Object binding) {
    if (!identical(_hostBinding, binding)) return;
    _hostBinding = null;
    if (_state == PopupRuntimeState.shutdown) return;
    _state = PopupRuntimeState.detached;
    controller.detachHost();
  }

  Future<void> shutdown() async {
    if (_state == PopupRuntimeState.shutdown) return;
    _state = PopupRuntimeState.shutdown;
    _hostBinding = null;
    routeObserver.dispose();
    await controller.shutdown();
  }
}
