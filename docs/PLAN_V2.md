# unified_popups v2 重构计划书

> 实施状态（2026-07-14）：核心 Runtime/Controller/Host、各类型 Renderer、
> Sheet/FlowSheet、Menu Anchor、全局 Pop 门面、Example 迁移、v1 删除和公开文档
> 已完成。静态分析、包测试与 Example 测试已通过；最终交互验收以运行 Example
> 的真机/模拟器结果为准。

## 1. 重构目标

将当前：

```
全局 Pop
  → 单体 PopupManager
  → navigatorKey
  → 每个弹窗一个 OverlayEntry
```

重构为：

```
全局 Pop 门面
  → 可替换 PopupRuntime
  → PopupController 状态与生命周期
  → PopupHost 统一渲染
  → 各类型独立 Config 与 Renderer
```

最终业务调用保持全局、无 `BuildContext`、无业务注入：

```
Pop.toast('保存成功');

final loading = Pop.loading(message: '处理中');
await loading.dismiss();

final confirmed = await Pop.confirm(...);

final result = await Pop.sheet<String>(...);
```

------

# 2. 已确认的设计原则

以下作为本次重构的固定前提：

1. 保留全局唯一调用入口 `Pop`。
2. 业务代码不依赖 `BuildContext`。
3. 业务模块不需要重复注入 `PopupController`。
4. 移除 PopupManager 对 navigatorKey 的依赖。
5. 移除 AnimationControllerPool。
6. 使用 PopupRuntime + PopupController + PopupHost。
7. Sheet、FlowSheet、Confirm、Menu、Toast 等允许互相堆叠。
8. Loading 默认阻止系统返回，不因为返回键关闭。
9. 关闭请求与退出动画完成分成两个生命周期阶段。
10. 拆除 `part`，每类弹窗使用独立 Config。
11. Loading 重复调用时更新原 Entry，不执行 hide + show。
12. Toast 和 Loading 支持自动倒计时、外部事件和手动关闭。
13. Confirm 同时支持 Future 结果与 `onConfirm`、`onCancel`。
14. Menu 改为可跟随 Anchor 的组合图层定位。
15. 可以接受 v2 破坏性升级，但应提供迁移文档。

------

# 3. 不属于本次重构的目标

第一版暂不处理：

- 多 Flutter Engine 共享弹窗状态。
- 后台 isolate 直接展示 UI。
- 桌面多窗口中的多个全局 PopupHost。
- 任意 Stream/Listenable 生命周期绑定。
- 异步 Confirm 校验和“回调成功后才关闭”。
- 路由状态恢复/restoration。
- 完整插件化注册第三方弹窗类型。

但内部结构应为未来扩展保留空间。

------

# 4. 目标目录结构

```
lib/
  unified_popups.dart

  src/
    runtime/
      popup_runtime.dart
      popup_binding.dart

    controller/
      popup_controller.dart
      popup_entry.dart
      popup_handle.dart
      popup_outcome.dart
      popup_entry_state.dart
      popup_dismiss_reason.dart
      popup_snapshot.dart
      popup_ownership.dart
      popup_open_result.dart

    host/
      popup_host.dart
      popup_host_state.dart
      popup_entry_view.dart
      popup_barrier.dart
      popup_back_dispatcher.dart

    navigation/
      popup_route_observer.dart
      popup_route_policy.dart

    configs/
      popup_animation_config.dart
      popup_barrier_config.dart
      popup_behavior_config.dart
      popup_lifetime.dart
      popup_channel.dart
      popup_conflict_policy.dart
      popup_lifecycle_callbacks.dart

      toast_config.dart
      loading_config.dart
      confirm_config.dart
      sheet_config.dart
      flow_sheet_config.dart
      menu_config.dart
      date_config.dart
      custom_popup_config.dart

    features/
      toast/
        toast_renderer.dart
        toast_host.dart
        toast_widget.dart

      loading/
        loading_renderer.dart
        loading_widget.dart

      confirm/
        confirm_renderer.dart
        confirm_widget.dart

      sheet/
        sheet_renderer.dart
        sheet_widget.dart
        sheet_drag_controller.dart

      flow_sheet/
        ...

      menu/
        popup_anchor.dart
        popup_anchor_controller.dart
        menu_renderer.dart
        menu_position_delegate.dart

      date/
        date_picker_widget.dart

      custom/
        custom_popup_renderer.dart

    api/
      pop.dart
      pop_toast_api.dart
      pop_loading_api.dart
      pop_confirm_api.dart
      pop_sheet_api.dart
      pop_flow_sheet_api.dart
      pop_menu_api.dart
      pop_date_api.dart
      pop_custom_api.dart
```

所有文件使用普通 `import/export`，不再使用 `part/part of`。

------

# 5. 核心运行时设计

## 5.1 Pop：全局门面

`Pop` 是唯一推荐给业务使用的入口。

```
abstract final class Pop {
  static PopupRuntime get runtime;

  static Widget hostBuilder(
    BuildContext context,
    Widget? child,
  );

  /// Runtime 生命周期内保持同一实例，避免 MaterialApp rebuild 时重复绑定。
  static NavigatorObserver get routeObserver;

  static Future<void> get ready;

  static bool get isReady;

  static PopupRouteToken? captureRoute();

  static PopupHandle<void> toast(...);

  static PopupHandle<void> loading(...);

  static Future<bool?> confirm(...);

  static Future<T?> sheet<T>(...);

  static Future<T?> menu<T>(...);

  static Future<R?> flowSheet<R>(...);

  static Future<DateTime?> date(...);

  static Future<void> dismissAll();

  static Future<bool> handleBack();
}
```

`Pop` 不直接持有：

- OverlayEntry
- AnimationController
- Timer
- Widget
- NavigatorState
- popup Map

所有状态委托给默认 Runtime。

## 5.2 PopupRuntime

职责：

- 持有默认 PopupController。
- 处理 PopupHost attach/detach。
- 提供 `ready`。
- 连接路由观察者。
- 测试重置。
- 阻止多个全局 Host 同时挂载。

```
class PopupRuntime {
  PopupRuntime({
    PopupController? controller,
  });

  PopupController get controller;

  bool get isHostAttached;

  Future<void> get ready;

  void attachHost(PopupHostBinding host);

  void detachHost(PopupHostBinding host);

  Future<void> shutdown();
}
```

Runtime 使用明确的宿主状态，而不是只保存一个 `bool`：

```
enum PopupRuntimeState {
  cold,      // 从未挂载过 Host，可暂存首帧前调用
  attached,  // Host 正常工作
  detached,  // 曾挂载但已经卸载，不再无限排队
  shutdown,  // Runtime 已销毁
}
```

规则：

- `Pop.ready` 只代表第一次 Host attach；重挂载状态通过 `Pop.isReady` 判断。
- `cold` 状态允许 Entry 进入 `pendingHost`。
- `detached` 状态的新调用立即以 `hostUnavailable` 收口，避免旧消息在未来突然显示。
- pending 队列设置容量上限（默认 100）；超过上限时优先丢弃最旧 transient Entry。
- Host attach/detach 必须进行身份校验，忽略旧 Host 的迟到 detach。
- Runtime reset 后旧 Handle 通过 runtime epoch 识别为失效对象。

全局模式只允许一个 active host：

- Debug：第二个 Host attach 直接断言。
- Release：拒绝第二个 Host，并记录错误。
- 不允许两个 Host 同时消费同一 Entry。

## 5.3 Host 未挂载

如果 Service 在首帧前调用：

```
Pop.toast('初始化失败');
```

Entry 进入：

```
pendingHost
```

规则：

- 不创建动画控制器。
- 不启动 Timer。
- Host attach 后才进入 entering。
- pendingHost 阶段调用 dismiss，直接清理。
- Runtime shutdown 时以 `runtimeDisposed` 完成。
- 不允许延迟插入幽灵 Widget。
- pending 队列超过上限时以 `queueOverflow` 收口。
- Host 曾挂载后又卸载时不再把新调用加入 pending 队列。

提供：

```
await Pop.ready;
```

供确实依赖 UI 已挂载的启动流程使用。

------

# 6. PopupEntry 状态机

```
created
  ├─ Host 未挂载 → pendingHost
  ├─ Toast lane 已满 / 等待 conflict → queued
  └─ 可立即展示 ──────────────────────┐
                                       ↓
entering
   ↓
visible
   ↓
dismissRequested
   ↓
exiting
   ↓
disposed
```

还需要终止分支：

```
created/pendingHost
   ↓ dismiss
disposed
```

## 状态约束

- 每个状态迁移只允许发生一次。
- dismiss、complete、Timer、外部 Future 可以并发触发，但只有第一个成功。
- Entry 从注册表删除必须发生在退出动画完成后。
- dismissRequested 后不再接受普通 update。
- disposed 后所有操作为幂等 no-op。
- 用户回调异常不能阻止状态迁移和资源释放。
- `queued` 不创建动画控制器、不启动 lifetime，可以被 Handle 或批量 API 关闭。
- `exiting` 不再参与业务操作，但在动画完成前继续阻止点击穿透并消费重复返回，不能让连续返回误关下层 Entry。
- Entry 同时暴露 `isActive`（可业务操作）和 `isMounted`（仍由 Host 渲染）两个状态。

------

# 7. PopupHandle 设计

```
abstract interface class PopupHandle<T> {
  String get id;

  String? get key;

  PopupChannel get channel;

  bool get isActive;

  bool get isMounted;

  PopupEntryState get state;

  /// 业务 Outcome 确定时完成，包含 value 与关闭原因。
  Future<PopupOutcome<T>> get outcome;

  /// outcome 的便捷 value 视图，保持原 Future<T?> 使用体验。
  Future<T?> get result;

  /// 退出动画结束、Widget 移除时完成。
  Future<void> get dismissed;

  /// 携带结果请求关闭；返回的 Future 在 Widget 移除后完成。
  Future<void> complete([T? result]);

  /// 无业务结果关闭；返回的 Future 在 Widget 移除后完成。
  Future<void> dismiss();
}

abstract interface class UpdatablePopupHandle<T, C>
    implements PopupHandle<T> {
  /// 仅接受对应类型的 Config，避免 LoadingHandle 收到 SheetConfig。
  void update(C config);
}

typedef LoadingHandle = UpdatablePopupHandle<void, LoadingConfig>;
typedef ToastHandle = UpdatablePopupHandle<void, ToastConfig>;
```

## Future 完成语义

```
用户点击确认
  ↓
原子提交 outcome(value: true, reason: completed)
  ↓
result / outcome 完成
  ↓
onConfirm（异常不改变已提交结果）
  ↓
退出动画
  ↓
dismissed、complete() Future 完成
```

外部可以选择：

```
final result = await handle.result;
```

或者：

```
await handle.dismissed;
```

不再让一个 Future 同时承担“业务结束”和“动画移除”。

`dismiss()` / `complete()` 的调用会立即提交 Outcome 和启动退出；它们返回的 Future 与 `dismissed` 同步完成。因此调用方既可以 fire-and-forget，也可以 `await` 到视觉层彻底清理。

## 7.1 PopupOutcome

```
class PopupOutcome<T> {
  const PopupOutcome({
    required this.reason,
    this.value,
  });

  final T? value;
  final PopupDismissReason reason;

  bool get isCompleted =>
      reason == PopupDismissReason.completed;
}
```

`PopupOutcome` 用来区分 `complete(null)`、Barrier、返回键、路由变化和 Runtime 销毁；普通便捷 API 仍可只返回 `T?`。

## 7.2 通用生命周期回调

所有 Config 通过组合提供明确回调，替代含义模糊的单一 `onDismiss`：

```
class PopupLifecycleCallbacks<T> {
  final VoidCallback? onPresented;
  final ValueChanged<PopupOutcome<T>>? onOutcome;
  final ValueChanged<PopupOutcome<T>>? onDismissed;
}
```

- `onPresented`：进入动画完成后触发一次。
- `onOutcome`：业务 Outcome 原子提交后触发一次。
- `onDismissed`：退出动画完成、节点移除后触发一次。
- 回调异常统一通过 `FlutterError.reportError` 上报，不影响资源清理和其他回调。

------

# 8. DismissReason

```
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
```

作用：

- 生命周期回调。
- 日志。
- 测试断言。
- 业务统计。
- 区分取消按钮和外部关闭。

------

# 9. Config 解耦

## 9.1 共享小配置

不使用巨型基类，采用组合。

```
class PopupAnimationConfig {
  final Duration duration;
  final Curve curve;
  final PopupAnimation type;
}
class PopupBarrierConfig {
  final bool visible;
  final bool dismissible;
  final Color color;
  final String? semanticsLabel;
}
class PopupBehaviorConfig {
  final PopupBackPolicy backPolicy;
  final PopupRoutePolicy routePolicy;
  final PopupConflictPolicy conflictPolicy;
  final PopupOwnerPolicy ownerPolicy;
  final PopupChannel channel;
  final String? key;
  final Set<String> tags;
}
```

```
enum PopupOwnerPolicy {
  independent,
  dismissWithParent,
}

class PopupOwnership {
  final Object? routeToken;
  final String? parentEntryId;
  final PopupOwnerPolicy policy;
}
```

Entry 同时记录 owner route 和可选 parent Entry。关闭父 Entry 时，先按从上到下的顺序关闭所有 `dismissWithParent` 子 Entry，再关闭父 Entry，避免 Sheet 已移除但 Confirm/Menu 仍悬浮。

默认父级策略：

| 类型 | 默认策略 |
| --- | --- |
| Toast / Loading | `independent` |
| Menu | `dismissWithParent`，优先使用 Anchor 所属 Entry |
| Confirm / Date | 当前存在顶层 modal 时默认 `dismissWithParent` |
| Sheet / FlowSheet | 默认继承当前顶层 modal，可显式改为 `independent` |

## 9.2 类型 Config

```
class ToastConfig { ... }

class LoadingConfig { ... }

class ConfirmConfig { ... }

class SheetConfig<T> { ... }

class FlowSheetConfig<R> { ... }

class MenuConfig<T> { ... }

class DateConfig { ... }

class CustomPopupConfig<T> { ... }
```

`PopupType` 不再驱动行为。

可以保留 `PopupChannel` 用于查询：

```
PopupChannel.toast
PopupChannel.loading
PopupChannel.confirm
PopupChannel.sheet
PopupChannel.menu
PopupChannel.date
PopupChannel.custom
```

Channel 只用于查找和分组，不决定返回、路由或动画。

------

# 10. 堆叠与渲染顺序

默认按创建顺序进入全局 Entry 栈：

```
Entry 1: Sheet
Entry 2: Confirm
Entry 3: Menu
Entry 4: Toast
```

渲染：

```
PopupHost Stack
  ├─ app child
  ├─ Sheet barrier + content
  ├─ Confirm barrier + content
  ├─ Menu barrier + content
  └─ Toast lane
```

规则：

- 后创建的 Entry 在上层。
- 每个 modal Entry 的 Barrier 只覆盖其下方内容。
- Toast 默认显示在当前弹窗栈上方。
- 返回只处理最上层参与返回的 Entry。
- 独立下层 Entry 退出时不影响上层 Entry；存在 ownership 时按 `dismissWithParent` 级联。
- 多 Sheet、多 Confirm 都允许。
- Loading 是否遮挡 Toast 由明确 layer policy 控制，不依赖 PopupType。
- 关闭父 Entry 时按 ownership 级联关闭依赖子 Entry；Toast/Loading 默认不随父 Entry 关闭。
- `exiting` Entry 的 Barrier 在视觉移除前继续阻止点击穿透，但不再接受 update/complete。

建议增加内部：

```
enum PopupLayer {
  content,
  modal,
  system,
  transient,
}
```

默认：

- Sheet/Confirm/Menu：modal
- Loading：system
- Toast：transient，默认始终可显示在 Loading/Modal 之上

同层内继续按创建顺序排列。

------

# 11. ConflictPolicy

```
enum PopupConflictPolicy {
  stack,
  rejectNew,
  replaceExisting,
  toggle,
  updateExisting,
}
```

默认建议：

| 类型      | 默认策略       |
| --------- | -------------- |
| Toast     | stack          |
| Loading   | updateExisting |
| Confirm   | stack          |
| Sheet     | stack          |
| FlowSheet | stack          |
| Menu      | stack          |
| Date      | stack          |

业务可覆盖：

```
Pop.sheet(
  key: 'order-sheet',
  conflictPolicy: PopupConflictPolicy.toggle,
  ...
);
```

或者：

```
Pop.flowSheet(
  key: 'order-trade',
  conflictPolicy: PopupConflictPolicy.replaceExisting,
  ...
);
```

精确定义：

- `stack`：立即创建新 Entry 并按全局顺序入场。
- `rejectNew`：不创建 Entry，以 `conflictRejected` 返回高级打开结果。
- `replaceExisting`：旧 Entry 完成退出动画后，新 Entry 才开始 entering，避免两个同 key Barrier 交叉。
- `toggle`：存在匹配 Entry 时只关闭旧 Entry，不创建新 Entry；便捷 `Future<T?>` 返回 `null`。
- `updateExisting`：只允许用于明确支持更新的类型，复用原 Entry/Handle，更新 Config 并重置 lifetime。

高级打开 API 使用显式结果描述冲突行为：

```
sealed class PopupOpenResult<T> {
  const factory PopupOpenResult.opened(PopupHandle<T> handle);
  const factory PopupOpenResult.updated(PopupHandle<T> handle);
  const factory PopupOpenResult.toggledClosed();
  const factory PopupOpenResult.rejected();
}
```

key 在单个 Runtime 内全局唯一，不按 Channel 重复命名；不同 Channel 使用相同 key 时 Debug 抛出明确错误，Release 拒绝新 Entry。Entry id 使用 `runtimeEpoch + 单调递增序号`，避免时间戳碰撞并隔离 reset 前的旧 Handle。

------

# 12. PopupLifetime

```
sealed class PopupLifetime {
  const PopupLifetime.manual();

  const PopupLifetime.after(Duration duration);

  const PopupLifetime.until(Future<void> event);

  const PopupLifetime.anyOf(
    List<PopupLifetime> conditions,
  );
}
```

## 默认值

- Toast：`after(defaultDuration)`
- Loading：`manual`
- 其他 Popup：`manual`

## 生命周期规则

- Timer 从进入动画完成后开始。
- updateExisting 后取消旧 Timer，重新计时。
- 旧 Future 无法真正取消，但通过 generation 检查忽略。
- Timer、Future、手动关闭同时发生时只接受第一个。
- Future 抛异常默认不关闭，错误交给 FlutterError。
- 如需“成功或失败都关闭”，调用方传入 `.whenComplete()` 生成的 Future。

------

# 13. Loading 设计

## 13.1 默认 key

```
Pop.loading(message: '处理中');
```

等价于：

```
key: PopupKeys.globalLoading
conflictPolicy: updateExisting
```

## 13.2 重复调用

```
final first = Pop.loading(
  message: '上传中',
);

final second = Pop.loading(
  message: '正在处理结果',
);
```

行为：

- 保留同一个 Entry。
- 更新 LoadingConfig。
- 不重新播放完整进入动画。
- 不重新创建 Barrier。
- 重置 lifetime。
- generation +1。
- `first` 与 `second` 指向同一个稳定逻辑 Handle，均可关闭当前 Entry。
- generation 仅用于取消旧 Timer、忽略旧外部 Future 和过滤迟到异步更新，不改变 Handle 的物理 `dismissed` 语义。
- `Pop.hideLoading()` 可以强制关闭当前全局 Loading。

## 13.3 同一调用方更新

```
final loading = Pop.loading(
  message: '上传中',
);

loading.update(
  const LoadingConfig(
    message: '已上传 50%',
  ),
);

await loading.dismiss();
```

`handle.update()` 更新原 Entry 并递增内部 generation；Handle 身份保持稳定。

## 13.4 不同并发任务

推荐不同 key：

```
Pop.loading(
  key: 'upload-avatar',
  message: '上传头像',
);

Pop.loading(
  key: 'export-report',
  message: '导出报表',
);
```

------

# 14. Toast 设计

Toast 使用共享 ToastHost/Lane，不为每个 Toast 创建全屏 OverlayEntry。

```
ToastHost
  ├─ top lane
  ├─ center lane
  └─ bottom lane
```

建议默认：

- 每个位置最多显示 3 个。
- 超出后排队。
- 同 key 使用 updateExisting。
- 无 key 每次创建新 Toast。
- 默认倒计时保持现有语义。
- Toast 不参与返回键。
- Toast 默认跨路由保持。
- 单个 Toast 有独立 Handle。
- 超出可见数的 Toast 进入 `queued`，不启动 lifetime、不创建动画控制器。
- queued Toast 可被 Handle、`dismissChannel` 或 `dismissAll` 关闭；空位出现后按 FIFO 入场。
- queued Toast 的 owner route 已失效时直接以 `routeChanged` 收口，不显示过期内容。

该默认策略已经确认，见计划末尾“已确认的实施决策”。

------

# 15. Confirm 设计

便捷 API：

```
final confirmed = await Pop.confirm(
  title: '删除确认',
  content: '删除后无法恢复',
  confirmText: '删除',
  cancelText: '取消',
  onConfirm: () {},
  onCancel: () {},
);
```

语义：

| 操作     | 回调            | result |
| -------- | --------------- | ------ |
| 确认按钮 | onConfirm       | true   |
| 取消按钮 | onCancel        | false  |
| Barrier  | 不调用 onCancel | null   |
| 返回键   | 不调用 onCancel | null   |
| 外部关闭 | 不调用 onCancel | null   |
| 路由变化 | 不调用 onCancel | null   |

执行顺序：

```
按钮点击
  ↓
原子提交 true/false Outcome 与 dismissRequested
  ↓
执行 onConfirm/onCancel
  ↓
即使回调抛异常也保留已提交结果并继续关闭
  ↓
退出动画
  ↓
完成 dismissed
```

回调异常通过 `FlutterError.reportError` 上报。

第一版仅支持同步回调：

```
VoidCallback? onConfirm;
VoidCallback? onCancel;
```

------

# 16. Sheet 重构

## 16.1 拖拽局部化

当前每次拖拽 setState 整个 Sheet。重构后：

- Sheet 内容作为固定 child。
- 位移使用专用 Animation/ValueNotifier。
- 拖动只更新 Transform。
- 不重新 build FlowSheet Navigator 和业务内容。

## 16.2 统一进度

采用归一化进度：

```
0.0 = 完全退出
1.0 = 完全显示
```

拖拽修改 progress，而不是额外叠加 Offset。

优势：

- 入场动画、拖拽、回弹、退出共用同一个控制器。
- 不会出现内部 Transform 和外部 SlideTransition 叠加。
- 可以根据拖拽位置继续退出。

## 16.3 手势规则

补齐：

- dragStart
- dragUpdate
- dragEnd
- dragCancel
- 位移比例阈值
- velocity 阈值
- 回弹动画
- 水平 Sheet 的 handleOnly
- contentWhenAtTop
- 滚动内容和 Sheet 手势协调

三种模式在四个方向都需要明确测试。

------

# 17. FlowSheet 重构

FlowSheet 保留内部 Navigator，但接入统一 PopupHandle 生命周期。

目标：

- FlowSheet `result` 与外层 Sheet result 一致。
- 外层关闭时所有内部 pending Future 收口。
- `dismissed` 由 PopupHost 统一完成。
- FlowSheetController 不再自己管理外层 Widget 销毁握手。
- 系统返回先交给 FlowSheet：
  - 栈深度 > 1：pop 内页。
  - 栈底：根据 BackPolicy 关闭整个 FlowSheet。
- 生命周期 hook 继续支持：
  - onLoad
  - onShow
  - onHide
  - onRemove
  - onClose

Controller 所有权固定为：调用方创建后交给本次 FlowSheet Session 接管，是 one-shot 对象；Session 结束后自动 dispose，调用方如需再次打开必须创建新 Controller。

拆除 `part` 后，FlowSheetHost 不再跨文件直接访问 Controller 私有字段，而是通过受限内部接口协作：

```
abstract interface class FlowSheetHostDelegate {
  List<FlowSheetEntry> get entries;
  void attachHost(Object host);
  void detachHost(Object host);
  void handlePageRemoved(FlowSheetEntry entry);
}
```

`PopupHandle` 管理 FlowSheet 外层业务 Outcome 与视觉销毁；`FlowSheetController` 只管理内部页面栈、页面结果和生命周期 hook。

移除热路径 debugPrint，改为可选 debug logger。

------

# 18. Menu 重构

## 18.1 新 Anchor API

```
final anchor = PopupAnchorController();

PopupAnchor(
  controller: anchor,
  child: button,
);
final result = await Pop.menu<String>(
  anchor: anchor,
  builder: (dismiss) => ...,
);
```

内部使用：

- CompositedTransformTarget
- CompositedTransformFollower
- LayerLink

## 18.2 定位规则

支持：

```
MenuPlacement.auto
MenuPlacement.belowStart
MenuPlacement.belowEnd
MenuPlacement.aboveStart
MenuPlacement.aboveEnd
```

`auto`：

1. 获取 Anchor 几何信息。
2. Menu 完成一次约束布局。
3. 判断上下空间。
4. 判断左右溢出。
5. 应用安全区和键盘区域。
6. 定位完成后开始进入动画。

## 18.3 动态行为

- Anchor 随滚动移动：Menu 自动跟随。
- Anchor 卸载：以 `anchorDetached` 关闭。
- 旋转屏幕：重新计算 placement。
- 键盘变化：重新约束可用空间。
- 不再使用最多 5 次 post-frame 重试。
- 不缓存可能失效的 RenderBox。

------

# 19. Barrier、焦点和无障碍

使用 `AnimatedModalBarrier` 替代 GestureDetector + Container。

`dockToEdge/edgeGap` 场景不能直接使用全屏 Barrier。`PopupBarrierConfig` 需要支持可交互边界/insets，由 Host 组合局部 AnimatedModalBarrier、HitTest 与 Semantics，保留底部导航或侧边区域点击透传，不能因切换标准 Barrier 丢失现有能力。

补充：

- Barrier semantics label。
- dismissible 语义。
- Confirm/Sheet 打开时记录当前焦点。
- 只有最上层 modal 完成退出时才尝试恢复原焦点；目标仍 mounted 才恢复。
- 如果还有上层 modal，焦点转交新的栈顶 modal，不恢复到底层页面。
- dismissWithParent 批量关闭时只在整组退出完成后恢复一次焦点。
- Modal 内容的焦点进入策略。
- Toast 使用 live region 语义。
- 键盘 Escape 对应 BackPolicy。
- Barrier 点击只关闭当前 Entry，不影响下层。
- Loading 居中位置继续使用不受键盘 viewInsets 改变的稳定屏幕坐标；Sheet/Confirm 按各自 Config 处理键盘布局。

------

# 20. 路由策略

```
enum PopupRoutePolicy {
  persist,
  dismissWhenOwnerRouteChanges,
  dismissOnAnyRouteChange,
}
```

默认：

| 类型      | 默认                         |
| --------- | ---------------------------- |
| Toast     | persist                      |
| Loading   | persist                      |
| Menu      | dismissWhenOwnerRouteChanges |
| Confirm   | dismissWhenOwnerRouteChanges |
| Sheet     | dismissWhenOwnerRouteChanges |
| FlowSheet | dismissWhenOwnerRouteChanges |
| Date      | dismissWhenOwnerRouteChanges |

初始化：

```
MaterialApp(
  navigatorObservers: [
    Pop.routeObserver,
  ],
  builder: Pop.hostBuilder,
);
```

`Pop.routeObserver` 在单个 Runtime 生命周期内保持稳定实例，MaterialApp rebuild 不会创建或重复绑定 Observer。第一版只将 Root Navigator 作为默认 route scope；嵌套 Navigator 不得把事件混入同一个 current route token，未来如需支持必须通过显式 `scopeId` 扩展。

Entry 创建时记录 owner route。路由 push/pop/replace/remove 后，根据 policy 处理。

无 Context 的全局调用只能把“调用时当前路由”作为默认 owner，不能自动推断异步任务最初来自哪个路由。高级异步场景可以在操作开始时捕获 token：

```
final owner = Pop.captureRoute();

await request();

Pop.confirm(
  routeOwner: owner,
  ...
);
```

如果 token 已失效且策略为 `dismissWhenOwnerRouteChanges`，Popup 不再入场，直接以 `routeChanged` 收口。Toast/Loading 默认 `persist`，普通全局提示无需捕获 token。

由于 PopupHost 展示弹窗不 push Navigator Route，因此：

```
Sheet 上打开 Confirm
```

不会被误判为业务路由切换。

------

# 21. 返回键处理

PopupHost 统一接管返回分发。

```
系统返回
  ↓
找到最上层参与返回的 Entry
  ↓
执行 BackPolicy
enum PopupBackPolicy {
  dismiss,
  block,
  ignore,
  delegate,
}
```

默认：

| 类型      | 默认     |
| --------- | -------- |
| Toast     | ignore   |
| Loading   | block    |
| Menu      | dismiss  |
| Confirm   | dismiss  |
| Sheet     | dismiss  |
| FlowSheet | delegate |
| Date      | dismiss  |

特殊页面仍可调用：

```
if (await Pop.handleBack()) {
  return;
}

Navigator.pop(context);
```

在任何核心重构实现前，先做返回机制技术验证，覆盖：

- Android back
- Android predictive back
- iOS swipe back
- Navigator 1.0
- GetX 路由
- 嵌套 Navigator
- FlowSheet 内部 Navigator

如果 MaterialApp.builder 层的返回拦截不能完整覆盖，将验证当前 Route 的 PopEntry 注册或内部 `PopupBackDispatcher`；在技术方案证明可覆盖 predictive back 与 iOS 侧滑前，不进入核心状态机的大规模实现。对外初始化方式保持不变。

------

# 22. 外部控制 API

```
Future<void> Pop.dismissKey(String key);

Future<int> Pop.dismissChannel(
  PopupChannel channel,
);

Future<int> Pop.dismissTags(
  Set<String> tags,
);

Future<void> Pop.dismissAll();

Future<bool> Pop.dismissTop();

Future<bool> Pop.handleBack();

bool Pop.isVisibleKey(String key);

bool Pop.hasChannel(PopupChannel channel);

int Pop.countChannel(PopupChannel channel);

bool Pop.isActiveKey(String key);
```

区别：

- `dismissTop()`：强制关闭最上层 Popup。
- `handleBack()`：执行返回语义，可能只 pop FlowSheet 内页。
- `dismissChannel()`：等待匹配 Entry 的退出动画完成。
- Handle：精确控制单个 Popup。
- `dismissAll()` 包含 pendingHost、queued、entering、visible 和 exiting Entry；从栈顶向下提交强制关闭请求，再等待全部 `dismissed`，不受 BackPolicy.block 影响。
- `isVisibleKey()` 包含 entering/visible/exiting；`isActiveKey()` 只包含仍可接受业务操作的状态。

不再公开 `hideByType(PopupType)`。

------

# 23. Custom Popup

为了覆盖当前直接使用 PopupManager.show 的场景，提供：

```
final handle = Pop.custom<String>(
  CustomPopupConfig<String>(
    key: 'debug-log',
    builder: (handle) {
      return DebugLogView(
        onClose: handle.dismiss,
      );
    },
    position: PopupPosition.bottom,
    animation: ...,
    behavior: ...,
  ),
);
```

Custom Popup 同样获得：

- Handle
- result/dismissed
- RoutePolicy
- BackPolicy
- Barrier
- key/channel/tags
- 生命周期状态机

避免业务退回直接操作 Host 或 Controller。

------

# 24. 全局 Runtime 的测试与重置

提供测试绑定：

```
setUp(() {
  Pop.resetForTest();
});

tearDown(() async {
  await Pop.shutdown();
});
```

或者：

```
await Pop.runWithRuntime(
  PopupRuntime(),
  () async {
    // test body
  },
);
```

要求：

- 测试之间不共享 Entry。
- 不共享 Timer。
- 不共享 Observer。
- 不共享动画控制器。
- `runWithRuntime` 只保证纯 Controller/Runtime 测试的 zone 隔离；Widget 测试受 Flutter binding zone 约束，使用全局 reset 并串行执行，不承诺并行共享全局 Host。
- 默认全局 Runtime 只用于生产主 isolate。

## 24.1 PopupHost 重建隔离

PopupEntry 列表变化不得重建 app/Navigator 子树。Host 使用固定 child：

```
ListenableBuilder(
  listenable: controller,
  child: appChild,
  builder: (context, child) {
    return Stack(
      children: [
        child!,
        buildPopupEntries(),
      ],
    );
  },
);
```

验收增加：连续显示/关闭 100 个 Toast，app child build count 不增加。

## 24.2 MaterialApp.builder 组合

真实应用已有 builder 时使用显式组合：

```
builder: (context, child) {
  final app = MediaQuery(
    data: MediaQuery.of(context).copyWith(...),
    child: child!,
  );

  return Pop.hostBuilder(context, app);
}
```

文档必须说明 PopupHost 与 Theme、MediaQuery、Directionality、Localizations、ScreenUtil、性能面板等包装层的顺序，确保 Popup 获得正确主题和布局环境。

## 24.3 App 生命周期与 lifetime

第一版保持 Timer 的墙上时间语义：App 进入后台期间 lifetime 继续经过，回到前台时已超时的 Toast 不重新展示；Loading 默认 manual，不受影响。该行为写入 API 文档，不在 v2 首版增加暂停/恢复计时复杂度。

## 24.4 SDK 与 API parity 门槛

阶段 0 必须建立 `docs/API_PARITY_V2.md`，逐项记录每个 v1 参数在 v2 中的保留、替代、删除、默认值变化和回归测试，重点覆盖 toast toggle、自定义 Widget/图片、Loading customIndicator、Sheet dockToEdge/edgeGap/useSafeArea、Confirm 自定义按钮、Menu constraints/decoration、Date 范围与样式、FlowSheet routeBuilder/maintainState。

同时根据最终使用的 PopScope/predictive back、`withValues`、sealed class 和 Navigator API 确定真实最低 Flutter/Dart 版本，更新 pubspec，并为最低支持版本与当前 stable 建立 CI。当前 `flutter >=1.17.0` 不再作为 v2 的有效承诺。

------

# 25. 实施阶段

## 阶段 0：设计冻结与行为基线

工作：

- 将本计划整理进 `docs/ARCHITECTURE_V2.md`。
- 先完成返回与路由技术 Spike：Android back、predictive back、iOS swipe、Navigator 1.0、GetMaterialApp 和 FlowSheet 内 Navigator；技术方案未通过前不进入大规模实现。
- 记录当前 API 行为。
- 建立 `docs/API_PARITY_V2.md` 参数级迁移矩阵。
- 冻结 PopupOutcome、dismiss/complete Future、稳定更新 Handle、父子 ownership、queued/exiting、ConflictPolicy、key 作用域和 FlowSheetController ownership 契约。
- 确定最低 Flutter/Dart 版本并建立 CI 版本矩阵。
- 补充关键回归测试。
- 记录已经确认的 Toast 队列策略、Menu Anchor 破坏性升级、pendingHost 和移除 v1 Manager 决策。
- 建立重构分支。

暂不改公开 API。

验收：

- 架构文档确认。
- 状态机和 API 签名确认。
- 关键行为都有测试描述。
- 返回/路由 Spike 通过目标平台验证。
- API parity 与 SDK 支持范围明确。

## 阶段 1：核心状态机

实现：

- PopupEntryState
- PopupDismissReason
- PopupChannel
- PopupConflictPolicy
- PopupLifetime
- PopupEntry
- PopupHandle
- PopupOutcome
- PopupOwnership
- UpdatablePopupHandle
- PopupController

不接入 UI。

测试：

- pendingHost。
- complete/result。
- outcome/reason。
- dismiss/dismissed。
- 多次关闭。
- Timer 和外部 Future 竞争。
- generation。
- parent/child 级联关闭。
- queued/exiting 与点击、返回隔离。
- ConflictPolicy 精确结果。
- Runtime dispose。
- 回调异常。

验收：

- 生命周期单测全部通过。
- 无 Flutter Widget 也能验证 Controller。

## 阶段 2：PopupRuntime 与 PopupHost 骨架

实现：

- 默认 Runtime。
- Pop 全局绑定。
- Host attach/detach。
- Pop.hostBuilder。
- 单 Host 限制。
- Entry 列表声明式渲染。
- 接入阶段 0 已验证的返回/Route PopEntry 方案。
- app child 重建隔离。

验收：

- 无 navigatorKey 展示 Custom Popup。
- show 后立即 dismiss 不产生幽灵 Entry。
- Host detach 后无 pending Future。
- 返回技术方案可覆盖目标平台。
- Popup 变化不重建 app/Navigator child。

## 阶段 3：动画、Barrier 和资源管理

实现：

- EntryView 动画。
- AnimatedModalBarrier。
- 动画结束回调。
- result/dismissed 分离。
- 每个 View 自己创建和 dispose Controller。

删除：

- AnimationControllerPool。
- SafeOverlayEntry。

验收：

- 无残留 Ticker。
- 无对象池。
- 退出动画中重复关闭安全。
- 回调异常不影响清理。

## 阶段 4：Toast 与 Loading

Toast：

- ToastHost/Lane。
- 堆叠和最大可见数。
- lifetime。
- Handle。
- key 更新。

Loading：

- 默认全局 key。
- updateExisting。
- 稳定逻辑 Handle + 内部 lifetime generation。
- handle.update。
- 外部 Future。
- 默认 back block。

验收：

- 连续更新 100 次仍只有一个 Loading Entry。
- 旧事件不能关闭新 generation。
- 同 key 重复调用返回同一逻辑 Handle，`dismissed` 只在物理 Entry 移除时完成。
- Toast 节点数量有上限。
- Timer 全部可清理。

## 阶段 5：Confirm 与 Date

实现：

- 独立 Config。
- onConfirm/onCancel。
- result/dismissed。
- 焦点恢复。
- Barrier/Back/RouteReason。

验收：

- 所有关闭路径结果明确。
- 回调只对应按钮。
- Sheet 上叠 Confirm 不关闭 Sheet。

## 阶段 6：Sheet

实现：

- SheetConfig。
- 独立 Renderer。
- 进度驱动动画。
- 局部 Transform 更新。
- 回弹、速度阈值、drag cancel。
- 三种 drag mode。
- 四个方向。

验收：

- 重内容 child 拖拽中不重复 build。
- 水平 handleOnly 生效。
- 滚动内容和拖拽无明显冲突。
- 键盘适配正常。

## 阶段 7：FlowSheet

实现：

- 接入统一 Handle。
- 统一外层生命周期。
- 内部返回委托。
- 删除重复销毁握手。
- 保留页面生命周期 hooks。

验收：

- push/pop/replace/closeAll。
- pending result 全部收口。
- 返回优先内部页面。
- 外层退出后 Controller 正确销毁。

## 阶段 8：Menu

实现：

- PopupAnchor。
- AnchorController。
- Target/Follower。
- Placement。
- Anchor detach。
- 屏幕变化重新定位。

验收：

- 页面滚动时菜单跟随。
- 无首帧跳位。
- Anchor 卸载自动关闭。
- 屏幕边缘正确翻转。

## 阶段 9：公开 API 切换

实现：

- 新 Pop 门面。
- 便捷 API。
- Config API。
- Handle API。
- Custom Popup。
- 外部关闭 API。

删除：

- PopupManager。
- PopupConfig。
- PopupType 策略。
- PopScopeWidget。
- 旧 RouteObserver。
- 所有 part 文件。

版本：

```
2.0.0
```

## 阶段 10：Example 全量迁移

Example 初始化：

```
navigatorObservers: [Pop.routeObserver],
builder: Pop.hostBuilder,
```

业务调用尽量保持：

```
Pop.toast
Pop.loading
Pop.confirm
Pop.sheet
Pop.menu
Pop.flowSheet
```

增加 Lab：

- Loading update。
- stale handle。
- 外部事件关闭。
- 多层 Popup。
- 返回顺序。
- 路由切换。
- Anchor 滚动。
- Host 前调用。
- runtime reset。

## 阶段 11：测试和性能基准

修复当前：

- example 失效测试入口。
- pending Timer。
- 跨测试 AnimationController。
- 非法 tester.pump。
- 不可信 Stopwatch 阈值。

新增：

- 状态机单测。
- Host Widget 测试。
- 路由测试。
- 返回测试。
- Sheet 拖拽 build 次数测试。
- Toast 峰值测试。
- Loading 更新测试。
- Menu 跟随测试。
- profile FrameTiming。

## 阶段 12：文档与迁移指南

更新：

- README
- README_EN
- API_REFERENCE
- BEST_PRACTICES
- CHANGELOG
- example README

新增：

- ARCHITECTURE_V2.md
- MIGRATION_V1_TO_V2.md

迁移表：

```
PopupManager.show        → Pop.custom
PopupManager.hide(id)    → handle.dismiss
hideByType               → dismissChannel/key
hasNonToastPopup         → Pop.handleBack/hasBlockingPopup
PopScopeWidget           → 删除
PopupManager.initialize  → 删除
navigatorKey             → 不再用于 Popup
```

------

# 26. 验收标准

## 架构

- 业务调用不需要 BuildContext。
- 业务不需要注入 PopupController。
- 只有 Pop 是推荐入口。
- 无 navigatorKey 初始化。
- 无 PopupManager 单体。
- 无 part。
- Config 按类型拆分。
- PopupType 不再驱动行为。

## 生命周期

- result 与 dismissed 分离。
- outcome 可区分 complete(null) 与各种关闭原因。
- dismiss()/complete() Future 在视觉移除后完成。
- 所有关闭路径幂等。
- show 后立即 hide 安全。
- Host 前调用安全。
- Host detach 安全。
- Timer/Future 竞争安全。
- 用户回调异常不影响清理。
- 同 key update 保持稳定逻辑 Handle，generation 只过滤旧 lifetime 事件。
- 父 Popup 关闭时按 ownership 正确级联子 Popup。
- queued/exiting 状态不会点击穿透或误关下层 Entry。

## 功能

- Sheet/FlowSheet 上可叠 Toast、Confirm、Menu。
- Loading 默认阻止返回。
- Confirm 双按钮回调正确。
- Loading 原地更新。
- Toast 支持 Handle 和外部事件。
- Menu 跟随 Anchor。
- FlowSheet 返回优先内部页。
- 按 Handle/key/channel/all 关闭。
- Root Navigator 返回、predictive back 与 iOS 侧滑行为通过实测。
- async 场景可以用 RouteToken 防止在错误路由显示 Popup。

## 性能

- 无 AnimationControllerPool。
- Loading update 不增加 Entry。
- Toast 使用共享 Host。
- Sheet 拖拽不重建重内容。
- Popup 列表变化不重建 app/Navigator child。
- 无残留 Ticker/Timer。
- 完整 profile 无明显性能回退。

## 质量

- `flutter analyze`通过。
- `flutter test` 通过。
- `example test` 通过。
- 新增回归测试覆盖关键竞态。
- 文档和迁移指南完成。
- API parity 参数矩阵完成。
- 最低 Flutter/Dart 版本及 CI 矩阵明确。

------

# 27. 已确认的实施决策

以下决策已经确认并纳入实施基线：

1. **Toast 每个位置最多同时显示 3 个，超出进入队列。**
2. **Host 挂载前调用进入 pendingHost，Host 挂载后显示。**
3. **Menu 的 GlobalKey API 直接替换为 PopupAnchorController，不长期保留旧兼容层。**
4. **v2 删除 PopupManager，不在包内保留完整 v1 实现；只通过迁移文档协助升级。**

同时采用本计划审查补充的 PopupOutcome、稳定更新 Handle、父子 ownership、阶段 0 返回技术 Spike、queued/exiting 契约和 API parity/SDK 门槛。完成阶段 0 技术验证后再进入正式代码替换。
