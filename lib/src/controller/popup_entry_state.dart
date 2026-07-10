/// Lifecycle states shared by every popup entry.
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

extension PopupEntryStateX on PopupEntryState {
  /// Whether business code can still complete, dismiss, or update the entry.
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

  /// Whether the host may still be rendering the entry.
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

  bool get isTerminal => this == PopupEntryState.disposed;
}
