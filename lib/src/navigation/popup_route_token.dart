/// 根路由的稳定身份标识，用于 Ownership 与路由变化策略。
final class PopupRouteToken {
  /// 由 Runtime 内部创建；业务侧通过 `Pop.captureRoute()` 获取。
  const PopupRouteToken.internal(this.id);

  final int id;

  @override
  String toString() => 'PopupRouteToken($id)';
}
