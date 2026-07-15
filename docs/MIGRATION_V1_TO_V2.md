# unified_popups v1 与 v2 对比及迁移

v2 是破坏性升级。核心目标不是增加更多调用方式，而是把 v1 的隐式全局管理收敛为
单一 Runtime、单一状态权威和单一公开契约。

## 1. v1 的主要问题

- `PopupManager` 同时负责 OverlayEntry、动画、Timer、路由、Map 和业务策略。
- 每个 Popup 直接操作全屏 OverlayEntry，并发关闭和路由销毁时序复杂。
- 巨型 PopupConfig 包含大量只对部分类型有效的字段。
- PopupType 同时承担分类和行为职责，冲突、返回、路由语义隐式。
- 业务结果和退出动画共用一个 Future，无法区分 outcome 与视觉移除。
- Menu 使用 GlobalKey/RenderBox 手算坐标，滚动和 Transform 后容易失准。
- `dismiss([result])` 同时表达业务完成和普通取消，两种语义无法区分。

## 2. v2 架构变化

```text
v1                                      v2
PopupManager 单体                         PopupRuntime + PopupController
每 Popup 一个 OverlayEntry                一个 PopupHost + PopupScene
巨型 PopupConfig                          每种能力独立 Config
PopupType 隐式行为                         显式 Behavior / Lifetime / Ownership
String id                                PopupHandle<T>
单一关闭 Future                           result/outcome + dismissed
dismiss([result])                         complete(result) / dismiss()
GlobalKey 坐标计算                         Target/Follower Anchor
```

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

删除 Popup 专用 navigatorKey、`PopupManager.initialize()` 和
`PopScopeWidget`。

## 4. 单入口 Config-first API

v2 每种能力只有一个入口：

```dart
Pop.toast(ToastConfig config);
Pop.loading(LoadingConfig config);
Pop.confirm(ConfirmConfig config);
Pop.date(DateConfig config);
Pop.sheet<T>(SheetConfig<T> config);
Pop.flowSheet<R>(FlowSheetConfig<R> config);
Pop.menu<T>(MenuConfig<T> config);
Pop.dropMenu<T>(DropMenuConfig<T> config);
Pop.custom<T>(CustomPopupConfig<T> config);
```

不存在 `openToast/openLoading/openConfirm/openDate/openSheet/openFlowSheet/`
`openMenu/openDropMenu`，也不存在一套零散参数和一套 Config 参数并存的情况。

### Toast

v1：

```dart
Pop.toast('保存成功', toastType: ToastType.success);
```

v2：

```dart
Pop.toast(
  const ToastConfig.text(
    '保存成功',
    type: ToastType.success,
  ),
);
```

Widget 内容使用 `ToastConfig.content(widget)`。

### Loading

v1：

```dart
final handle = Pop.loading(message: '提交中');
```

v2：

```dart
final handle = Pop.loading(
  const LoadingConfig(message: '提交中'),
).requireHandle();
```

重复调用仍更新默认全局 Loading Entry。

### Confirm 与 Date

v1：

```dart
final ok = await Pop.confirm(content: '确定继续？');
final date = await Pop.date(initialDate: DateTime.now());
```

v2：

```dart
final ok = await Pop.confirm(
  const ConfirmConfig(content: '确定继续？'),
).result;

final date = await Pop.date(
  DateConfig(initialDate: DateTime.now()),
).result;
```

Date 主构造器直接接受 initial/min/max；复用已有范围时使用
`DateConfig.range(range: range)`。

### Sheet

v1：

```dart
final value = await Pop.sheet<String>(
  childBuilder: (dismiss) => ListTile(
    onTap: () => dismiss('done'),
  ),
);
```

v2：

```dart
final value = await Pop.sheet<String>(
  SheetConfig<String>(
    builder: (context, handle) => ListTile(
      onTap: () => handle.complete('done'),
    ),
  ),
).result;
```

v2 有意区分：

- `handle.complete(value)`：业务正常完成，reason 为 `completed`。
- `handle.dismiss()`：普通取消或外部关闭。

### Menu 与 DropMenu

Menu 的 v1 dismiss builder 迁移为 V2 Handle builder。Anchor 从 GlobalKey 迁移为：

```dart
final anchor = PopupAnchorController();

PopupAnchor(
  controller: anchor,
  child: ...,
);
```

```dart
final action = await Pop.menu<String>(
  MenuConfig<String>(
    anchor: anchor,
    builder: (context, handle) => ListTile(
      onTap: () => handle.complete('edit'),
    ),
  ),
).result;
```

Menu 允许底层滚动时，不再传 `showBarrier: false`，而是：

```dart
barrier: const PopupBarrierConfig.hidden(),
```

DropMenu 使用 `DropMenu.single` 或 `DropMenu.nested`，标准 DropMenu 默认全局
`replaceExisting`。

### FlowSheet

```dart
final result = await Pop.flowSheet<Result>(
  FlowSheetConfig<Result>(
    controller: controller,
    initialPage: firstPage,
  ),
).result;
```

内部页面继续使用 `nav.push/pop/replace/completeCurrent/closeAll`。系统返回优先退出
内页，位于首页时关闭整个 FlowSheet。

## 5. 返回模型迁移

所有创建 API 返回 `PopupOpenResult<T>`：

```dart
final opened = Pop.confirm(config);

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

普通业务只需要：

```dart
final value = await Pop.confirm(config).result;
```

- opened/updated：等待 Handle 结果。
- toggled/rejected：立即返回 null。
- 不需要结果：直接忽略整个 `PopupOpenResult`。

## 6. 通用参数迁移

| v1 | v2 |
| --- | --- |
| animation/duration/curve | `PopupAnimationConfig` |
| showBarrier/barrierColor | `PopupBarrierConfig` |
| duration | `PopupLifetime.after` |
| 外部结束 Future | `PopupLifetime.until` |
| duration + Future | `PopupLifetime.anyOf` |
| dismissOnRouteChange | `PopupRoutePolicy` |
| onBackPressed | `PopupBackPolicy.delegate` / Config onBack |
| popup id | `PopupBehaviorConfig.key` |
| 业务分组 | `PopupBehaviorConfig.tags` |
| 类型批量管理 | 固定 `PopupChannel` + `dismissChannel` |
| 父子关系 | `PopupOwnership` |

Behavior 不再接收 channel。Channel 由 `Pop.toast/Pop.sheet/...` 能力固定：

```dart
const PopupBehaviorConfig(
  key: 'sync',
  conflictPolicy: PopupConflictPolicy.updateExisting,
)
```

`PopupLifetime.until` 观察 Future settled：成功和失败都会关闭 Popup；业务错误仍由
业务调用方处理。

## 7. 管理 API

| v1 | v2 |
| --- | --- |
| String id | `PopupHandle<T>` |
| `hide(id)` | `handle.dismiss()` |
| `hideLast()` | `Pop.dismissTop()` |
| `hideAll()` | `Pop.dismissAll()` |
| `hideByType(type)` | `Pop.dismissChannel(channel)` |
| `getCountByType(type)` | `Pop.countChannel(channel)` |
| `isVisible(id)` | Handle 状态 / `Pop.isVisibleKey(key)` |
| `maybePop(context)` | 自动返回桥 / `Pop.handleBack()` |

## 8. 推荐迁移顺序

1. 替换 MaterialApp 初始化。
2. 将所有调用改为 `Pop.xxx(Config)`。
3. 将 `await Pop.xxx(...)` 改为 `await Pop.xxx(config).result`。
4. 将 child 中的 `dismiss(value)` 改为 `handle.complete(value)`。
5. 将普通取消 `dismiss()` 改为 `handle.dismiss()`。
6. 将零散样式、Barrier、Lifetime 参数移入对应 Config。
7. 删除所有 `openXxx` 和 `PopupBehaviorConfig.channel`。
8. 根据需要处理 `PopupRejected/PopupToggledClosed`。
9. 接入 route observer，验证系统返回、路由切换和父子关闭。

完整参数见 [API 参考](API_REFERENCE.md)，实现原理见
[架构设计](ARCHITECTURE.md)。
