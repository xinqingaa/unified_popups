# unified_popups v2 架构设计与实现原理

本文解释 v2 为什么这样设计，以及 Runtime、生命周期、冲突、路由和各类弹窗如何协作。API 签名与参数请查阅 [API 与参数参考](API_REFERENCE.md)，从 v1 升级请查阅 [v1 与 v2 对比及迁移指南](MIGRATION_V1_TO_V2.md)。与官方 `showDialog` / `showModalBottomSheet` 的产品取舍见 [为何使用 Overlay](WHY_OVERLAY.md)。

## 1. 目标与边界

v2 保留业务最需要的调用体验：页面、Service、Flow、Timer 和网络回调都可以直接调用 `Pop.*`，不要求 `BuildContext`，也不需要在业务模块注入 Controller。官方 Dialog / Sheet 把弹层做成 Navigator Route；本包把弹层做成应用级 Overlay 系统，以便统一冲突、返回、路由归属与多类型叠放。

```text
业务代码
   │
   ▼
全局 Pop 门面
   │
   ▼
PopupRuntime ── Host 所有权 / RouteObserver
   │
   ▼
PopupController ── Entry / 冲突 / 生命周期 / 返回 / 路由
   │ immutable snapshots
   ▼
PopupHost + PopupScene
   │
   ├─ Toast / Loading / Confirm / Date Renderer
   ├─ Sheet / FlowSheet Renderer
   ├─ Menu / DropMenu Renderer
   └─ Custom Renderer
```

v2 不处理多 Flutter Engine、后台 isolate 展示 UI、桌面多窗口共享 Host、路由状态恢复和第三方弹窗类型的完整插件注册。

## 2. 各层职责

### Pop

`Pop` 是 SDK 唯一公开创建入口。每种能力只有一个 `Pop.xxx(Config)` 方法；Config
是唯一参数契约，Pop 只把它交给内部类型适配器和默认 Runtime。它不保存
OverlayEntry、Timer、AnimationController、NavigatorState 或弹窗 Map。

真实产品可以在其上增加 `AppPop`：由 App 层固定品牌样式、国际化、埋点和默认策略，
再向页面提供 `Future<bool> confirm(...)` 等业务形状方法。这个门面不创建第二套 SDK
状态，也不绕过 Pop；它只是把完整 Config 契约收口到应用自己的设计系统。

所有创建方法同步返回 `PopupOpenResult<T>`。它先表达本次请求的打开决策，而不是
业务值或 Handle：

- `.result` 将打开决策投影成 `Future<T?>`，供普通业务等待结果。
- `.requireHandle()` 同步提取命令式 Handle，无 Handle 时抛出异常。
- `.handleOrNull` 适合 reject/toggle 是合法分支的调用方。
- 不读取成员时，调用方拿到的仍是 `PopupOpenResult<T>`，不是 Handle。

`await` 只负责等待 `.result`、`handle.outcome`、`handle.dismissed` 等 Future，不决定
API 返回哪一种模型。完整调用决策见 [API 参考](API_REFERENCE.md)。

Config 中不保存 channel；Toast、Sheet 等能力在适配器中固定自己的 channel，避免
无效组合。

公开 package 入口只导出业务 Config、结果/Handle、FlowSheet 契约、Anchor 和必要
策略。`PopupRuntime`、`PopupController`、`PopupHost`、`PopupScene` 以及 Renderer
Base 类型属于内部实现，不是稳定公开契约。

### PopupRuntime

一个 Runtime 持有一个 Controller、一个稳定的根路由观察者和最多一个 active Host。首次 Host 挂载前的调用进入 `pendingHost`；Host 曾挂载后又卸载时，新调用以 `hostUnavailable` 立即收口，避免旧消息在未来突然显示。

测试可以直接构造隔离的 `PopupRuntime`。全局 `Pop.resetForTest()` 会关闭旧 Runtime，并用新的 epoch 创建 Runtime，使旧 Handle 不会碰到新 Entry。

### PopupController

Controller 是唯一状态权威。Entry 注册表、key 索引、状态迁移、冲突处理、父子关闭、路由策略和返回分发都由它原子完成。

内部结构按职责拆分为：

- `PopupController`：注册表、状态迁移和全局操作。
- `PopupEntryRecord`：单个 Entry 的可变数据、Outcome 和 Completer。
- `ControllerPopupHandle`：把 Handle 操作转发给 Controller。
- `PopupLifetimeBinding`：Timer、外部 Future 和 generation 资源。

这些内部类型不从 `unified_popups.dart` 导出，不构成稳定公共 API。

### PopupHost 与 PopupScene

`PopupHost` 在应用 child 上方挂载一个私有 Overlay。应用 child 不监听 Controller，因此弹窗变化不会重建 Navigator 或业务页面。

Controller 变化会重新生成 PopupScene 的声明式 Widget 描述，但 Entry 使用稳定 id 作为 Key，所以 Renderer State、AnimationController、Sheet 缓存的重内容和 Menu 缓存的 content 都会保留。这是轻量的 Widget rebuild，不是销毁并重新创建弹窗。

当前没有引入 Entry 级 Listenable。正常同时显示的 Entry 数量很小，Entry 级通知会增加队列、replace、detach 和资源销毁复杂度；只有真实 profile 证明 Scene rebuild 成为瓶颈时才值得引入。

## 3. Entry 状态机与结果

```text
created
  ├─ Host 未挂载 ──> pendingHost
  ├─ Toast lane 满 ─> queued
  └────────────────> entering ─> visible
                                      │
完成 / 手动 / 返回 / 遮罩 / 路由 / lifetime
                                      ▼
                           dismissRequested ─> exiting ─> disposed
```

`result/outcome` 与 `dismissed` 是两个阶段：

1. 首个关闭请求原子确定 `PopupOutcome`，业务 `result` 立即完成。
2. Renderer 播放退出动画。
3. Host 确认节点移除，`dismissed` 和 `dismiss()/complete()` 返回的 Future 完成。

所有关闭路径幂等。Timer、外部 Future、手动关闭和返回键并发时，只有第一个结果生效。

## 4. Lifetime 与更新

`PopupLifetime` 支持：

- `manual()`：只接受显式关闭。
- `after(duration)`：进入动画完成后开始计时。
- `until(future)`：Future 无论成功还是失败，只要结束就以 `externalEvent` 关闭。
- `anyOf(conditions)`：任一条件先到即关闭。

业务 Future 的错误仍由业务代码负责，Popup 只观察它是否结束，不重复上报业务异常。

Loading 和带 key 的 Toast 更新时保留同一个 Entry 和 Handle，递增 generation、取消旧 Timer，并启动新 lifetime。旧 Future 即使稍后成功或失败，也因为 generation 不匹配而不能关闭新配置。

## 5. 多弹窗顺序与冲突

所有弹窗共享同一个创建顺序列表。普通模态 Entry 按创建顺序叠放；无 Barrier Toast 从主列表中提取到最上方的 Toast lane，因此可显示在 Loading、Sheet 或 Confirm 上方。

### key、channel、tags

- `key`：Runtime 内的逻辑唯一资源，用于冲突和更新。
- `channel`：类型查询和批量关闭，不隐式决定 UI 行为。
- `tags`：业务域批量管理。

同 key 不允许跨 channel 复用。

### PopupConflictPolicy

所有 `Pop.xxx(Config)` 统一返回 `PopupOpenResult<T>`：

| 策略 | 行为 | 返回 |
| --- | --- | --- |
| `stack` | 无 key 时创建新 Entry；同 key 已存在时拒绝 | `PopupOpened` / `PopupRejected` |
| `rejectNew` | 保留旧 Entry，拒绝新请求 | `PopupRejected` |
| `replaceExisting` | 旧 Entry 退出后激活新 Entry | `PopupOpened(newHandle)` |
| `toggle` | 存在则关闭旧 Entry，不创建新 Entry | `PopupToggledClosed` |
| `updateExisting` | 原地更新 Config、Handle 和 Entry 不变 | `PopupUpdated(existingHandle)` |

只有 `updateExisting` 要求旧、新 Config 与结果泛型完全兼容。replace 和 toggle 不复用旧 Handle，因此允许同一 channel 内不同结果泛型互相替换。

`PopupRejected` 是打开决策，不是一个真实 Entry 的关闭原因，所以不属于 `PopupDismissReason`。

标准 DropMenu 使用 `PopupKeys.globalDropMenu + replaceExisting`，保证全局同时只有一个标准 DropMenu；完全自定义的 Menu 默认无 key，可以按业务需要独立堆叠。

## 6. 路由、返回和 Ownership

`Pop.routeObserver` 只观察根 Navigator，并为当前根 Route 分配稳定 `PopupRouteToken`。它在 Route 注册 `PopEntry`，系统返回先交给 Controller：

1. exiting Entry 消费重复返回，防止误关下层。
2. 从视觉顶部向下检查 `PopupBackPolicy`。
3. `block` 只消费；`dismiss` 关闭；`ignore` 跳过；`delegate` 交给 Sheet/FlowSheet 等内部逻辑。
4. 没有 Popup 处理时，Route 才正常返回。

路由策略包括跨路由保留、owner route 改变关闭和任意根路由变化关闭。异步流程可以提前 `captureRoute()`，把 RouteToken 放入 Ownership，避免请求结束后在错误页面展示弹窗。

`PopupOwnership` 还可以记录父 Entry。Confirm 和 Date 默认归属于当前顶层模态弹窗；父 Sheet/FlowSheet 关闭时，`dismissWithParent` 子弹窗先关闭。

## 7. Sheet 实现

Sheet 与普通弹窗使用同一个 Entry 和外层 AnimationController。四个方向统一使用 0–1 动画进度，Renderer 将进度映射为完整面板位移。

拖拽只更新动画进度，不重新构造业务 child。松手时结合 progress 和 velocity 判断关闭或回弹。`fullBody`、`contentWhenAtTop`、`handleOnly` 控制手势入口；拖拽指示器只在底部方向显示。

外层 Align/SafeArea 负责屏幕位置，Renderer 内层 SafeArea 负责 dock 边缘和系统区域。dock 的 `edgeGap` 同时转换为 Barrier insets，使保留区域可以继续交互。

## 8. FlowSheet 实现

FlowSheet 外层仍是统一的 Sheet Entry，因此参与全局堆叠、路由、Barrier、Handle 和退出动画。内部由一次性 `FlowSheetController` 和嵌套 Navigator 维护页面栈。

系统返回先委托内部 Controller：有第二页时 pop 内页；位于首页时完成整个外层 Popup。页面自己的 result、maintainState 和 onLoad/onShow/onHide/onRemove/onClose 与外层 Popup Outcome 分开管理。

Controller 的业务关闭和对象 dispose 也是两个阶段：先完成所有 pending 页面 Future，再等外层 Renderer 移除且内部 Host detach 后释放 notifier。

## 9. Menu 与 DropMenu 实现

`PopupAnchor` 使用 `CompositedTransformTarget`，Menu Renderer 使用 `CompositedTransformFollower`。菜单跟随滚动、Transform 和布局变化，不再通过 GlobalKey 持续轮询坐标。

`MenuPlacement.auto` 首帧先不可见布局，取得菜单真实尺寸，再结合 SafeArea、键盘、offset 和四侧溢出选择 above/below 与 start/end，并在本次会话内锁定方向。Anchor 卸载时监听器以 `anchorDetached` 关闭 Entry。

Menu 默认使用透明可关闭 Barrier：点外或拖动关闭（`dismissOnDrag: true`），同时阻止下层滚动。传 `PopupBarrierConfig.hidden()` 后底层可以滚动，Follower 继续跟随 Anchor。

DropMenu 是建立在同一个 Menu Renderer 上的数据模型层，增加一级选择、二级 Section、选中态、禁用态和 LiquidGlass。一级项目通常完成 Handle；二级项目可以只通过 `onSelected` 通知并保持外层菜单打开。

## 10. 应用 builder 组合

PopupHost 只能从其上方继承 Theme、MediaQuery、Directionality 和 Localizations。应用已有 builder 包装时，应按期望的继承范围显式组合：

```dart
MaterialApp(
  navigatorObservers: [Pop.routeObserver],
  builder: (context, child) {
    final app = MediaQuery(
      data: MediaQuery.of(context).copyWith(...),
      child: child!,
    );
    return Pop.hostBuilder(context, app);
  },
)
```

若希望 Popup 也看到自定义 MediaQuery、ScreenUtil 或主题包装，应让 `Pop.hostBuilder` 位于这些包装内部；若包装只应作用于业务页面，则放在传入的 child 上。
