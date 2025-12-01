// lib/src/core/popup_route_observer.dart
import 'package:flutter/material.dart';
import 'popup_manager.dart';

/// 弹窗路由观察者
/// 
/// 监听路由变化，当路由切换时自动关闭符合条件的弹窗（confirm、sheet等）。
/// toast 和 loading 不会被关闭。
class PopupRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _onRouteChanged(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _onRouteChanged(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _onRouteChanged(newRoute);
    }
  }

  /// 路由变化时的处理逻辑
  void _onRouteChanged(Route<dynamic> route) {
    // 关闭所有应该在路由切换时关闭的弹窗
    PopupManager.hidePopupsOnRouteChange();
  }
}
