/// 弹窗在路由变化时被关闭的时机。
enum PopupRoutePolicy {
  persist,
  dismissWhenOwnerRouteChanges,
  dismissOnAnyRouteChange,
}
