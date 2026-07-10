import 'dart:async';

import 'package:flutter/widgets.dart';

import '../controller/popup_controller.dart';
import 'popup_route_token.dart';

/// A stable observer that connects root-route back behavior to popups.
final class PopupRouteObserverV2 extends NavigatorObserver {
  PopupRouteObserverV2(this.controller) {
    controller.addListener(_syncBackBridge);
  }

  final PopupController controller;
  final List<Route<dynamic>> _stack = <Route<dynamic>>[];
  final Map<Route<dynamic>, PopupRouteToken> _tokens =
      <Route<dynamic>, PopupRouteToken>{};
  final _PopupRoutePopEntry _popEntry = _PopupRoutePopEntry();

  ModalRoute<dynamic>? _registeredRoute;
  int _nextToken = 0;
  bool _disposed = false;

  PopupRouteToken? get currentToken {
    final route = _currentRoute;
    if (route == null) return null;
    return _tokens.putIfAbsent(
      route,
      () => PopupRouteToken.internal(++_nextToken),
    );
  }

  Route<dynamic>? get _currentRoute => _stack.lastOrNull;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _stack.add(route);
    _tokens.putIfAbsent(
      route,
      () => PopupRouteToken.internal(++_nextToken),
    );
    _routeDidChange();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _tokens.remove(route);
    if (previousRoute != null && !_stack.contains(previousRoute)) {
      _stack.add(previousRoute);
    }
    _routeDidChange();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _tokens.remove(route);
    _routeDidChange();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (oldRoute != null) _tokens.remove(oldRoute);
    if (index >= 0 && newRoute != null) {
      _stack[index] = newRoute;
    } else if (newRoute != null) {
      _stack.add(newRoute);
    }
    if (newRoute != null) {
      _tokens.putIfAbsent(
        newRoute,
        () => PopupRouteToken.internal(++_nextToken),
      );
    }
    _routeDidChange();
  }

  void _routeDidChange() {
    _attachToCurrentRoute();
    controller.handleRouteChanged(currentToken);
  }

  void _attachToCurrentRoute() {
    final route = _currentRoute;
    final modalRoute = route is ModalRoute<dynamic> ? route : null;
    if (identical(modalRoute, _registeredRoute)) {
      _syncBackBridge();
      return;
    }
    _registeredRoute?.unregisterPopEntry(_popEntry);
    _registeredRoute = modalRoute;
    _popEntry.onBlockedPop = controller.handleBack;
    _registeredRoute?.registerPopEntry(_popEntry);
    _syncBackBridge();
  }

  void _syncBackBridge() {
    if (_disposed) return;
    _popEntry.canPopNotifier.value = !controller.interceptsSystemBack;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    controller.removeListener(_syncBackBridge);
    _registeredRoute?.unregisterPopEntry(_popEntry);
    _registeredRoute = null;
    _popEntry.dispose();
    _stack.clear();
    _tokens.clear();
  }
}

final class _PopupRoutePopEntry implements PopEntry<Object?> {
  @override
  final ValueNotifier<bool> canPopNotifier = ValueNotifier<bool>(true);

  Future<bool> Function()? onBlockedPop;

  @override
  void onPopInvoked(bool didPop) {
    onPopInvokedWithResult(didPop, null);
  }

  @override
  void onPopInvokedWithResult(bool didPop, Object? result) {
    if (!didPop && !canPopNotifier.value) {
      final callback = onBlockedPop;
      if (callback != null) unawaited(callback());
    }
  }

  void dispose() {
    canPopNotifier.dispose();
  }
}
