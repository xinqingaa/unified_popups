/// 当新弹窗请求与已存在的、拥有相同 [PopupBehaviorConfig.key] 的弹窗冲突时的
/// 处理方式。
enum PopupConflictPolicy {
  stack,
  rejectNew,
  replaceExisting,
  toggle,
  updateExisting,
}
