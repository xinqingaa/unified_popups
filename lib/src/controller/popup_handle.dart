import '../configs/popup_channel.dart';
import 'popup_entry_state.dart';
import 'popup_outcome.dart';

/// 与结果类型无关的弹窗句柄能力（供渲染层与基础设施共用）。
abstract interface class PopupHandleBase {
  /// 逻辑 Entry 的稳定 id。
  String get id;

  /// 业务 key；同 key 受冲突策略约束。
  String? get key;

  /// 所属能力通道。
  PopupChannel get channel;

  /// 是否仍可 complete / dismiss / update。
  bool get isActive;

  /// Host 是否仍可能在渲染该 Entry。
  bool get isMounted;

  /// 当前生命周期状态。
  PopupEntryState get state;

  /// 退出动画结束、视觉节点移除后完成。
  Future<void> get dismissed;

  /// 无业务结果地关闭弹窗。
  Future<void> dismiss();
}

/// 指向单个逻辑弹窗 Entry 的稳定句柄。
abstract interface class PopupHandle<T> implements PopupHandleBase {
  /// 首次关闭决策落定时完成，携带原因与业务值。
  Future<PopupOutcome<T>> get outcome;

  /// [outcome] 的有损投影，只返回可空业务值。
  Future<T?> get result;

  /// 立即提交业务结果；返回的 Future 在视觉移除后完成。
  Future<void> complete([T? result]);
}

/// 支持对同一逻辑 Entry 做类型安全配置更新的句柄（如 Loading）。
abstract interface class UpdatablePopupHandle<T, C> implements PopupHandle<T> {
  /// 用新配置更新已有 Entry；Entry 已失效或变更了不可变渲染契约时返回 `false`。
  bool update(C config);
}
