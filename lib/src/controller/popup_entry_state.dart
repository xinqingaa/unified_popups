/// 单个弹窗 Entry 的生命周期状态。
enum PopupEntryState {
  created,
  pendingHost,
  queued,
  entering,
  visible,
  dismissRequested,
  exiting,
  disposed,
}

/// [PopupEntryState] 的便捷查询。
extension PopupEntryStateX on PopupEntryState {
  /// 业务是否仍可 complete / dismiss / update。
  bool get isActive => switch (this) {
        PopupEntryState.created ||
        PopupEntryState.pendingHost ||
        PopupEntryState.queued ||
        PopupEntryState.entering ||
        PopupEntryState.visible =>
          true,
        PopupEntryState.dismissRequested ||
        PopupEntryState.exiting ||
        PopupEntryState.disposed =>
          false,
      };

  /// Host 是否仍可能在渲染该 Entry。
  bool get isMounted => switch (this) {
        PopupEntryState.entering ||
        PopupEntryState.visible ||
        PopupEntryState.dismissRequested ||
        PopupEntryState.exiting =>
          true,
        PopupEntryState.created ||
        PopupEntryState.pendingHost ||
        PopupEntryState.queued ||
        PopupEntryState.disposed =>
          false,
      };

  /// 是否已进入终态（已销毁）。
  bool get isTerminal => this == PopupEntryState.disposed;
}
