# unified_popups v1 与 v2 对比及迁移指南

v2 是一次有意进行的破坏性升级。本篇先说明 v1 为什么需要重构，再给出架构、行为和 API 的完整迁移关系。

## 1. v1 的主要问题

### PopupManager 承担过多职责

v1 的全局单体同时保存 OverlayEntry、动画、Timer、navigatorKey、弹窗 Map 和策略。UI 生命周期、资源释放与业务管理互相耦合，使并发关闭、路由切换和异步调用很难独立验证。

### 每个弹窗一个全屏 OverlayEntry

每次展示都直接操作 Overlay。build 阶段、首帧前、路由销毁时插入或移除 Entry 容易产生时序问题；多个弹窗堆叠时，每层又有自己的全屏命中区域和资源。

### PopupConfig 和 PopupType 隐式驱动行为

一个巨型配置承载所有类型参数，很多字段只对部分弹窗有效。PopupType 同时参与查询和行为判断，返回、路由、Barrier 等策略不够明确。

### AnimationControllerPool 跨 State 复用资源

AnimationController 与 TickerProvider/State 生命周期天然绑定。对象池节省的分配很小，却增加跨页面、跨测试和异常销毁风险。

### 一个 Future 同时表达业务结果和视觉关闭

调用方无法明确区分“用户已经确认”和“退出动画已经完成”，也难以区分 barrier、back、routeChanged、timeout 等无结果关闭。

### Menu 依赖 GlobalKey/RenderBox 手算坐标

位置计算容易受到滚动、Transform、键盘和首帧布局影响，Anchor 移动后菜单不能自然跟随。

## 2. v2 如何解决

```text
v1                                      v2
Pop                                     Pop
  → PopupManager 单体                     → PopupRuntime
  → navigatorKey                          → PopupController 状态机
  → 每 Popup 一个 OverlayEntry             → 单一 PopupHost / PopupScene
  → 巨型 PopupConfig                       → 每类型独立 Config / Renderer
  → AnimationControllerPool                → Renderer State 自有 Controller
  → String popup id                        → PopupHandle<T>
  → 单一关闭 Future                         → outcome/result + dismissed
  → GlobalKey 坐标轮询                      → Target/Follower Anchor
```

业务仍然使用全局 `Pop.*`，但全局层只定位默认 Runtime，不再承担 UI 和策略细节。

## 3. 初始化迁移

v1：

```dart
final navigatorKey = GlobalKey<NavigatorState>();
PopupManager.initialize(navigatorKey: navigatorKey);

MaterialApp(
  navigatorKey: navigatorKey,
  builder: (_, child) => PopScopeWidget(child: child!),
);
```

v2：

```dart
MaterialApp(
  navigatorObservers: [Pop.routeObserver],
  builder: Pop.hostBuilder,
);
```

删除 Popup 专用 navigatorKey、`PopupManager.initialize()`、`PopScopeWidget` 和业务层 Controller 注入。

## 4. 管理 API 对照

| v1 | v2 | 说明 |
| --- | --- | --- |
| `PopupManager.show(PopupConfig)` | `Pop.custom(CustomPopupConfig)` | 使用类型 Config 或 Custom |
| String id | `PopupHandle<T>` | 类型安全且包含完整生命周期 |
| `hide(id)` | `handle.dismiss()` | 等视觉移除 |
| `hideLast()` | `Pop.dismissTop()` | 关闭最上层活跃 Entry |
| `hideAll()` | `Pop.dismissAll()` | 包含 pending/queued/exiting |
| `hideByType(type)` | `Pop.dismissChannel(channel)` | Channel 只用于管理 |
| `getCountByType(type)` | `Pop.countChannel(channel)` | 统计活跃 Entry |
| `isVisible(id)` | Handle 状态 / `Pop.isVisibleKey` | key 用于逻辑资源 |
| `maybePop(context)` | 自动返回桥 / `Pop.handleBack()` | 无需页面 PopScope |

## 5. 生命周期迁移

```dart
final opened = Pop.openConfirm(config);

switch (opened) {
  case PopupOpened(:final handle):
  case PopupUpdated(:final handle):
    final outcome = await handle.outcome;
    await handle.dismissed;
  case PopupToggledClosed():
  case PopupRejected():
    break;
}
```

- `result`：兼容旧 `Future<T?>` 体验。
- `outcome`：包含 value 与准确的 `PopupDismissReason`。
- `dismissed`：退出动画完成且 Renderer 已移除。
- `complete(value)`：提交业务结果并启动退出。
- `dismiss()`：无业务结果关闭。

`onShow` 迁移为 `onPresented`；旧 `onDismiss` 按需求拆为 `onOutcome` 和 `onDismissed`。

## 6. 通用参数迁移

| v1 | v2 |
| --- | --- |
| animation/duration/curve | `PopupAnimationConfig` |
| showBarrier/barrierColor | `PopupBarrierConfig` |
| duration | `PopupLifetime.after` |
| 外部结束事件 | `PopupLifetime.until` |
| dismissOnRouteChange | `PopupRoutePolicy` |
| onBackPressed | `PopupBackPolicy.delegate` / 类型回调 |
| popup id | behavior.key |
| 业务分组 | behavior.tags |
| type 批量管理 | behavior.channel |
| 父子关系 | `PopupOwnership` |

`until` 在 v2 中表示 Future settled：成功或失败都会关闭 Popup；业务错误仍由原 Future 的调用方处理。

## 7. 各类型能力对照

### Toast

- message/messageWidget、位置、图片、方向、样式、toggle 和 onTap 保留。
- duration 替换为 `PopupLifetime`。
- 无 Barrier Toast 进入共享 lane，每个位置最多显示三个，超出 FIFO 排队。
- `openToast` 返回 `PopupOpenResult<void>`，带 key 时可原地更新。

### Loading

- 重复调用不再 hide + show；默认全局 key 原地更新并返回同一个逻辑 Handle。
- 默认 `PopupBackPolicy.block`，系统返回不会关闭 Loading。
- 支持 duration、until、anyOf 和 `handle.update()`。

### Confirm

- String/Widget 标题、正文和按钮、自定义图片与样式保留。
- `onConfirm`、`onCancel` 只对应两个真实按钮。
- Barrier、关闭按钮、返回和路由变化结果为 null，不伪装成取消按钮。
- 默认按钮风格为底部分割线，可选择 filled 胶囊风格。

### Sheet

- childBuilder、标题、四方向、尺寸、SafeArea、dock、键盘和三种拖拽模式保留。
- 拖拽改为统一进度 + velocity + 回弹，重业务 child 不随指针重复构建。
- 拖拽指示器只在底部方向渲染。

### FlowSheet

- push/pop/replace/completeCurrent/closeAll、页面结果、maintainState 和生命周期保留。
- 外层不再套用独立的旧 Sheet 管理逻辑，而是直接成为统一 Popup Entry。
- FlowSheetController 仍是一场会话一个实例；系统返回优先退出内部页面。

### Menu 与 DropMenu

- v1 `GlobalKey anchorKey` 替换为 `PopupAnchorController + PopupAnchor`。
- Target/Follower 自动跟随滚动、布局和 Transform；Anchor 卸载自动关闭。
- Menu 默认透明 Barrier；需要底层滚动跟随时传 `showBarrier: false`。
- DropMenu 提供一级/二级数据模型和 LiquidGlass，并通过默认全局 key 保证同时只有一个标准 DropMenu。

### Date 与 Custom

- Date 的 initial/min/max 和样式保留；高级 `DateRangeConfig` 严格校验范围。
- 原 `PopupManager.show(PopupConfig)` 的完全自定义内容迁移为 `Pop.custom(CustomPopupConfig)`。

## 8. 冲突策略迁移

v2 不再让类型隐式决定冲突。设置 behavior.key 后选择：

- `stack`：同 key 已存在时拒绝；无 key 普通堆叠。
- `rejectNew`：返回 `PopupRejected`。
- `replaceExisting`：旧 Entry 以 replaced 退出，新 Entry 随后入场。
- `toggle`：关闭旧 Entry并返回 `PopupToggledClosed`。
- `updateExisting`：仅用于明确支持更新且类型兼容的 Config。

所有高级 `openXxx` 统一返回 `PopupOpenResult<T>`；便捷 API 继续直接返回业务 Future 或 LoadingHandle。

## 9. 推荐迁移步骤

1. 先替换 MaterialApp 初始化。
2. 保持日常 `Pop.toast/confirm/sheet/...` 调用，处理编译期参数变化。
3. 将直接使用 PopupManager 的代码迁移到类型 Config 和 Handle。
4. 将 duration、route、back、barrier 等行为迁移到显式策略。
5. 将 Menu GlobalKey 改为 PopupAnchor。
6. 将依赖 String id 的外部关闭改为保存 Handle 或使用 key/tags/channel。
7. 使用 Example 的 API 展柜逐类型人工验收。

完整签名与默认值见 [API 与参数参考](API_REFERENCE.md)，实现原理见 [架构设计](ARCHITECTURE.md)。

