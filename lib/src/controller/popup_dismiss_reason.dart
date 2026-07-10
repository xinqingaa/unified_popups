/// Why a popup produced its final outcome.
enum PopupDismissReason {
  completed,
  manual,
  timeout,
  externalEvent,
  barrier,
  back,
  routeChanged,
  replaced,
  toggled,
  anchorDetached,
  parentDismissed,
  hostDetached,
  hostUnavailable,
  queueOverflow,
  conflictRejected,
  runtimeDisposed,
}
