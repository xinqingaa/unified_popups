# unified_popups v2 API 与参数参考

v2 只有一套公开创建 API：`Pop.xxx(Config)`。不存在便捷层和 `openXxx` 高级层。
Config 是唯一参数契约，所有创建方法统一返回 `PopupOpenResult<T>`。

## 1. 初始化

```dart
MaterialApp(
  navigatorObservers: [Pop.routeObserver],
  builder: Pop.hostBuilder,
);
```

| API | 说明 |
| --- | --- |
| `Pop.routeObserver` | 根 Navigator 路由观察者与系统返回桥 |
| `Pop.hostBuilder` | 在应用 child 上方安装统一 PopupHost |
| `Pop.ready` | 首个 Host 挂载后完成 |
| `Pop.isReady` | Host 当前是否可用 |
| `Pop.captureRoute()` | 捕获当前根路由 token，供异步 Ownership 使用 |
| `Pop.resetForTest()` | 关闭并替换全局 Runtime，仅用于测试隔离 |

## 2. 创建 API 总览

| 能力 | 签名 | 业务结果 |
| --- | --- | --- |
| Toast | `Pop.toast(ToastConfig)` | `void` |
| Loading | `Pop.loading(LoadingConfig)` | `void` |
| Confirm | `Pop.confirm(ConfirmConfig)` | `bool` |
| Date | `Pop.date(DateConfig)` | `DateTime` |
| Sheet | `Pop.sheet<T>(SheetConfig<T>)` | `T` |
| FlowSheet | `Pop.flowSheet<R>(FlowSheetConfig<R>)` | `R` |
| Menu | `Pop.menu<T>(MenuConfig<T>)` | `T` |
| DropMenu | `Pop.dropMenu<T>(DropMenuConfig<T>)` | `T` |
| Custom | `Pop.custom<T>(CustomPopupConfig<T>)` | `T` |

## 3. PopupOpenResult、result、requireHandle 与 Handle

### 3.1 唯一的起点

每个 `Pop.xxx(config)` 都是同步方法，调用后立即应用冲突策略并返回
`PopupOpenResult<T>`：

```dart
final opened = Pop.confirm(config); // PopupOpenResult<bool>
```

此时没有等待用户操作，也没有直接得到 Handle。`await` 不是返回模型的分界线；调用方
选择的成员才决定下一步拿到什么：

```text
Pop.confirm(config)
        │
        ▼
PopupOpenResult<bool>
   ├─ .result ──────────> Future<bool?>
   ├─ .requireHandle() ─> PopupHandle<bool>
   ├─ .handleOrNull ────> PopupHandle<bool>?
   └─ switch ───────────> opened / updated / rejected / toggled
```

| 使用场景 | 写法 | 返回类型 |
| --- | --- | --- |
| Fire-and-forget | `Pop.toast(config)` | 忽略 `PopupOpenResult<void>` |
| 普通业务结果 | `await Pop.confirm(config).result` | `bool?` |
| 确定会产生 Entry，且要外部控制 | `Pop.loading(config).requireHandle()` | `PopupHandle<void>` |
| 冲突拒绝/toggle 属于合法分支 | `Pop.menu(config).handleOrNull` | `PopupHandle<T>?` |
| 必须区分打开决策 | `switch (Pop.xxx(config))` | 四种 sealed subtype |

### 3.2 `.result`：普通业务值

`.result` 是 `PopupOpenResult<T>` 上的 getter，类型为 `Future<T?>`：

```dart
final confirmed = await Pop.confirm(config).result;
```

等价于：

```dart
final opened = Pop.confirm(config);
final resultFuture = opened.result;
final confirmed = await resultFuture;
```

它只是业务值的便利投影，不包含打开决策和关闭原因：

- opened/updated：等待对应 Entry 的 `handle.result`。
- rejected/toggled：立即完成并返回 `null`。
- 用户点遮罩、返回键、路由切换或外部 dismiss：也通常返回 `null`。

因此 `.result == null` 不能判断究竟是“用户取消”还是“请求未打开”。普通业务只关心
选择值时适合使用 `.result`；需要准确原因时使用 `PopupOutcome`。

### 3.3 `requireHandle()`：外部命令式控制

```dart
final handle = Pop.loading(config).requireHandle();
```

`requireHandle()` 同步提取 opened/updated 的 Handle。若结果是 rejected 或
toggledClosed，它会抛出 `StateError`。它适合默认全局 Loading 等调用方确定必然会
创建或更新 Entry 的场景。

冲突是正常业务分支时不要使用它：

```dart
final opened = Pop.menu(config);
final handle = opened.handleOrNull;
if (handle == null) {
  // rejected 或 toggle 已关闭旧 Entry
  return;
}
```

需要区分两种无 Handle 情况时对 sealed class 做模式匹配。

### 3.4 Builder Handle 与外部 Handle

Sheet、Menu 和 Custom Builder 的 Handle 由 SDK 自动传入：

```dart
SheetConfig<String>(
  builder: (context, handle) => ListTile(
    onTap: () => handle.complete('done'),
  ),
)
```

Builder 内不需要 `requireHandle()`。只有 Builder 外部还要更新或关闭 Entry 时，才从
`PopupOpenResult` 提取 Handle。两处拿到的是同一个稳定逻辑 Entry 引用。

### 3.5 四种打开决策

`PopupOpenResult<T>` 有四种结果：

| 类型 | 含义 | `handleOrNull` | `.result` |
| --- | --- | --- | --- |
| `PopupOpened<T>` | 创建了新 Entry | 新 Handle | 等待业务结果 |
| `PopupUpdated<T>` | 原地更新已有 Entry | 原 Handle | 等待该 Entry 最终结果 |
| `PopupToggledClosed<T>` | toggle 关闭旧 Entry，未创建新 Entry | null | 立即 null |
| `PopupRejected<T>` | 请求被冲突策略拒绝 | null | 立即 null |

公共成员：

- `handleOrNull`：opened/updated 的 Handle。
- `hasHandle`：是否产生 Handle。
- `requireHandle()`：提取 Handle；没有 Handle 时抛出 `StateError`。
- `result`：有损的 `Future<T?>` 业务值投影。

### 3.6 PopupHandle 的异步成员与时间点

Handle 是控制引用，不等于 Future，但它提供多个 Future：

- `id/key/channel/state/isActive/isMounted/isPaused`：逻辑 Entry 状态。
- `complete([T? value])`：提交 completed Outcome，并等待退出动画与移除。
- `dismiss()`：提交 manual Outcome，并等待退出动画与移除。
- `pause()` / `resume()`：临时挂起 / 恢复（Offstage 保活，跳过返回与路由关闭）。
- `result`：首个关闭决策确定时完成，只返回 nullable value。
- `outcome`：首个关闭决策确定时完成，包含 value 和 reason。
- `dismissed`：退出动画完成、视觉节点彻底移除后完成。

```dart
final handle = Pop.loading(config).requireHandle();
final outcomeFuture = handle.outcome;
final removedFuture = handle.dismissed;

await handle.dismiss(); // 等待视觉移除
final outcome = await outcomeFuture; // reason == manual
await removedFuture;
```

### 3.7 App 级二次封装

完整 Config 是 SDK 契约，不代表每个业务页面都应该重复构造。真实 App 建议用
`AppPop` 统一品牌样式、国际化、默认冲突策略和 null 到业务值的映射。Example 的
FitPulse 产品区使用 `AppPop`，API Lab 使用原始 `Pop`。

## 4. 通用配置

### PopupBehaviorConfig

```dart
const PopupBehaviorConfig(
  key: 'sync',
  tags: {'network'},
  conflictPolicy: PopupConflictPolicy.updateExisting,
  routePolicy: PopupRoutePolicy.dismissWhenOwnerRouteChanges,
  backPolicy: PopupBackPolicy.ignore,
)
```

字段：`key`、`tags`、`conflictPolicy`、`routePolicy`、`backPolicy`。

`copyWith()` 默认保留已有 key；需要显式清空时使用：

```dart
final unkeyed = behavior.copyWith(clearKey: true);
```

`key` 与 `clearKey: true` 不能同时提供，否则抛出 `ArgumentError`。

Behavior 不包含 channel。Channel 由 Toast、Sheet 等能力本身固定。

冲突策略：`stack`、`rejectNew`、`replaceExisting`、`toggle`、
`updateExisting`。

### PopupBarrierConfig

字段：

- `visible`：是否绘制/安装 Barrier。
- `dismissible`：点击是否关闭。
- `color`：颜色。
- `semanticsLabel`：无障碍描述。
- `insets`：Barrier 不覆盖的边缘范围。

`PopupBarrierConfig.hidden()` 不安装命中 Barrier，适合 Menu 滚动跟随。

### PopupAnimationConfig

字段：`type`、`duration`、`reverseDuration`、`curve`、`reverseCurve`、
`slideOffset`。类型包括 fade、scale 和四方向 slide。

### PopupLifetime

```dart
const PopupLifetime.manual();
const PopupLifetime.after(Duration(seconds: 2));
PopupLifetime.until(request);
PopupLifetime.anyOf([...]);
```

`until` 观察 Future settled：成功或失败都会以 `externalEvent` 关闭；业务异常仍由
业务调用方处理。Lifetime 在 Entry presented 后才开始。

### PopupOwnership

字段：`routeToken`、`parentEntryId`、`policy`。Owner policy 支持独立存在或随父
Popup 关闭。

### PopupLifecycleCallbacks<T>

- `onPresented`：入场完成。
- `onOutcome`：首个关闭请求确定结果。
- `onDismissed`：退场完成且节点移除。

## 5. Toast

文本：

```dart
Pop.toast(
  const ToastConfig.text(
    '保存成功',
    type: ToastType.success,
    position: PopupPosition.bottom,
  ),
);
```

Widget：

```dart
Pop.toast(const ToastConfig.content(MyToastContent()));
```

两个构造器的公共参数：

- `position`：top/center/bottom/left/right。
- `type`：success/warn/error/none。
- `icon`：`ToastIconConfig(assetPath, size, color)`。
- `layoutDirection`：图标与内容排列轴。
- `style`：`ToastStyle`。
- `toggle`：点击时替换 message/icon/type。
- `onTap`：点击回调。
- `behavior/ownership/barrier/animation/lifetime/lifecycle`：通用策略。

`ToastStyle` 字段：`padding`、`margin`、`decoration`、`textStyle`、
`textAlign`、`spacing`。

无 Barrier Toast 每个位置最多显示 3 个，超出后 FIFO queued。

## 6. Loading

```dart
Pop.loading(
  const LoadingConfig.text(
    '上传中',
    lifetime: PopupLifetime.manual(),
  ),
);
```

载荷使用三个互斥构造器：

- `LoadingConfig.indicator()`：只有默认指示器。
- `LoadingConfig.text(message)`：指示器与文本。
- `LoadingConfig.content(widget)`：指示器与自定义内容。

`LoadingConfig`：

- `message/content`：由命名构造器保证互斥。
- `style`：`LoadingStyle`。
- `indicator`：`LoadingIndicatorConfig`。
- `position`：显示位置。
- `behavior/ownership/barrier/animation/lifetime/lifecycle`。

`LoadingStyle`：`backgroundColor`、`borderRadius`、`padding`、`textStyle`、
`indicatorColor`、`indicatorStrokeWidth`。

`LoadingIndicatorConfig`：`child`、`rotationDuration`。

默认 key 为 `PopupKeys.globalLoading`，策略为 `updateExisting`，BackPolicy 为
`block`。`Pop.hideLoading()` 关闭默认全局 Loading。

## 7. Confirm

默认是强交互：只能通过确认 / 取消按钮关闭。点遮罩与系统返回 / 侧滑默认不会关闭；
右上角关闭按钮默认隐藏。

```dart
final confirmed = await Pop.confirm(
  const ConfirmConfig(
    title: '删除记录',
    content: '删除后无法恢复。',
    confirmAction: ConfirmAction.text('删除'),
    cancelAction: ConfirmAction.text('取消'),
  ),
).result;
```

若需要点遮罩、系统返回或关闭按钮关闭，显式打开对应能力：

```dart
Pop.confirm(
  const ConfirmConfig(
    content: '可取消的确认',
    confirmAction: ConfirmAction.text('确定'),
    cancelAction: ConfirmAction.text('取消'),
    showCloseButton: true,
    barrier: PopupBarrierConfig(dismissible: true),
    behavior: PopupBehaviorConfig(
      backPolicy: PopupBackPolicy.dismiss,
    ),
  ),
);
```

`ConfirmConfig`：

- `title/titleWidget`：标题。
- `content/contentWidget`：正文，至少提供一个。
- `bodyExtension`：正文下方扩展 Widget。
- `confirmAction`：确认操作，使用 `ConfirmAction.text` 或
  `ConfirmAction.content`，两种载荷结构互斥。
- `cancelAction`：可选取消操作；不提供则不显示取消按钮。
- `showCloseButton`：右上角关闭按钮，默认 `false`。
- `imagePath/imageWidth/imageHeight`：顶部图片。
- `buttonLayout`：row/column。
- `style`：`ConfirmStyle`。
- `onConfirm/onCancel`：只由对应按钮触发。
- `behavior`：默认 `backPolicy: block`。
- `barrier`：默认 `dismissible: false`。
- `ownership/position/animationConfig/lifecycle`。

`ConfirmStyle`：`buttonStyle`、四类 TextStyle、`padding`、`margin`、
`decoration`、`textAlign`、`buttonBorderRadius`、确认/取消背景与边框、
`dividerColor`、`dividerWidth`、`buttonSpacing`。

`title/titleWidget` 与 `content/contentWidget` 各自互斥；同时提供会触发断言。
`ConfirmAction.text` 与 `ConfirmAction.content` 则从构造层保证按钮载荷互斥。

## 8. Date

```dart
final date = await Pop.date(
  DateConfig(
    initialDate: DateTime(2000, 1, 1),
    minDate: DateTime(1960),
    maxDate: DateTime.now(),
  ),
).result;
```

主构造器参数：`initialDate`、`minDate`、`maxDate`、`labels`、`style`、
`behavior`、`ownership`、`barrier`、`position`、`animationConfig`、`lifecycle`。

日期会被标准化为 dateOnly，initial 超出范围时自动 clamp。`min > max` 会抛出
ArgumentError。已有 `DateRangeConfig` 时可用 `DateConfig.range(range: ...)`。

`DateLabels`：`title`、`confirm`、`cancel`。

`DateStyle`：`activeColor`、`inactiveColor`、`headerBackgroundColor`、`height`、
`radius`。

## 9. Sheet

```dart
final value = await Pop.sheet<String>(
  SheetConfig<String>(
    header: const SheetHeaderConfig(title: '选择'),
    builder: (context, handle) => ListTile(
      title: const Text('完成'),
      onTap: () => handle.complete('done'),
    ),
  ),
).result;
```

`SheetConfig<T>`：

- `builder`：`(BuildContext, PopupHandle<T>) -> Widget`。
- `direction`：top/bottom/left/right。
- `header`：`SheetHeaderConfig`。
- `size`：`SheetSizeConfig`。
- `style`：`SheetStyle`。
- `dock`：`SheetDockConfig`。
- `drag`：`SheetDragConfig`。
- `keyboard`：`SheetKeyboardConfig`。
- `useSafeArea`：null 时按方向使用默认值。
- `behavior/ownership/barrier/animation/lifecycle`。
- `onBack`：返回 true 表示已消费返回。

子配置字段：

- `SheetHeaderConfig`：title、titleWidget、showCloseButton、padding、titleStyle、titleAlign。
- `SheetSizeConfig`：width、height、maxWidth、maxHeight，值为 `SheetDimension`。
- `SheetStyle`：backgroundColor、borderRadius、boxShadow、padding、imagePath、imageSize、imageOffset。
- `SheetDockConfig`：enabled、edgeGap。
- `SheetDragConfig`：mode、modeListenable、showHandle、handleColor、dismissProgressThreshold、dismissVelocity。
- `SheetKeyboardConfig`：adjustForKeyboard、animationDuration。

拖拽模式：`disabled`、`fullBody`、`contentWhenAtTop`、`handleOnly`。

## 10. FlowSheet

```dart
final result = await Pop.flowSheet<OrderResult>(
  FlowSheetConfig<OrderResult>(
    controller: controller,
    initialPage: const FirstPage(),
  ),
).result;
```

`FlowSheetConfig<R>` 必需 `controller` 和 `initialPage`；其余参数为
`direction/header/size/style/dock/drag/keyboard/useSafeArea/pageBackgroundColor/`
`routeBuilder/behavior/ownership/barrier/animation/lifecycle`。

`FlowSheetController` 一次实例只服务一场会话：

- `push<T>(page)`、`replace<T>(page)`：进入内页并等待内页结果。
- `pop<T>(result)`：退出当前内页。
- `completeCurrent<T>(result)`：完成当前页面等待者但不播放内页返回动画。
- `closeAll(result)`：完成整个 FlowSheet。
- `canPop/handleBack`：内部返回能力；`handleBack` 会先询问当前页。
- `updateDragDismissMode(mode)`：动态更新拖拽关闭模式（含 `disabled`）。

`FlowSheetPageState`：

- `onBack()`：返回 `true` 时消费返回，阻止默认的内页 pop / 整张关闭。

## 11. Menu


```dart
final action = await Pop.menu<String>(
  MenuConfig<String>(
    anchor: anchor,
    builder: (context, handle) => ListTile(
      title: const Text('编辑'),
      onTap: () => handle.complete('edit'),
    ),
  ),
).result;
```

`MenuConfig<T>`：`anchor`、`builder`、`placement`、`offset`、`style`、
`behavior`、`ownership`、`barrier`、`animationConfig`、`lifecycle`。

`PopupMenuStyle`：`padding`、`constraints`、`decoration`。

`MenuPlacement`：auto、belowStart、belowEnd、aboveStart、aboveEnd。Anchor 必须通过
`PopupAnchor(controller: ...)` 挂载。Anchor detach 时 reason 为 `anchorDetached`。

## 12. DropMenu

```dart
final value = await Pop.dropMenu<String>(
  DropMenuConfig<String>(
    anchor: anchor,
    menu: const DropMenu<String>.single(
      items: [DropMenuItem(value: 'all', label: '全部')],
    ),
  ),
).result;
```

`DropMenuConfig<T>`：`anchor`、`menu`、`menuStyle`、`placement`、`offset`、
`onSelected`、`onOpenSectionChanged`、`behavior`、`ownership`、`barrier`、
`animationConfig`、`lifecycle`。

`DropMenu.single`：items、selectedValue、emptyText。

`DropMenu.nested`：sections、initialOpenSectionId、emptyText。

`DropMenuItem`：value、label/labelWidget、leading、selectedIcon、selected、disabled、
showUnselectedIndicator、closeOnSelect、onTap。

`DropMenuSection` 支持 nested 和 direct，字段包括 id、label/labelWidget、items、
disabled、initiallyExpanded、showBottomDivider、primaryVerticalPadding。

默认行为使用 `PopupKeys.globalDropMenu + replaceExisting`。

## 13. Custom

```dart
Pop.custom<String>(
  CustomPopupConfig<String>(
    builder: (context, handle) => MyCard(handle: handle),
  ),
);
```

`CustomPopupConfig<T>`：`builder`、`behavior`、`ownership`、`barrier`、`position`、
`animationConfig`、`lifecycle`。

## 14. 全局管理

| API | 说明 |
| --- | --- |
| `Pop.hideLoading()` | 关闭默认全局 Loading |
| `Pop.dismissTop()` | 关闭最上层活跃 Entry |
| `Pop.dismissChannel(channel)` | 关闭指定 Channel |
| `Pop.dismissTags(tags)` | 关闭包含任一 tag 的 Entry |
| `Pop.dismissAll()` | 关闭所有 Entry |
| `Pop.handleBack()` | 手动执行统一返回分发 |
| `Pop.interceptsSystemBack` | 当前是否应由弹层先处理系统返回（供页面 PopScope 同步） |
| `Pop.isVisibleKey(key)` | keyed Entry 是否 visible |
| `Pop.isActiveKey(key)` | keyed Entry 是否仍活跃 |
| `Pop.hasChannel(channel)` | Channel 是否存在活跃 Entry |
| `Pop.countChannel(channel)` | Channel 活跃数量 |
| `Pop.pauseLatest(channel)` | 挂起该 Channel 最新 Entry |
| `Pop.resume(id)` | 恢复已 pause 的 Entry |
| `Pop.shutdown()` | 关闭 Runtime |

## 15. PopupDismissReason

主要 reason：`completed`、`manual`、`barrier`、`back`、`timeout`、
`externalEvent`、`routeChanged`、`parentDismissed`、`replaced`、`toggled`、
`anchorDetached`、`hostDetached`、`hostUnavailable`、`runtimeDisposed`、
`queueOverflow`、`rendererUnavailable`。

## 16. 稳定公开边界

package 入口公开业务 Config、结果/Handle、FlowSheet 页面契约、Anchor、样式和必要
策略。以下实现类型不从 `unified_popups.dart` 导出：

- `PopupRuntime`
- `PopupController`
- `PopupHost`
- `PopupScene`
- Renderer 使用的 Config Base 类型
- `FlowSheetHost`

业务与 App 级封装不应从 `package:unified_popups/src/...` 导入任何类型。包内测试可以
直接测试内部模块，但这些路径不保证跨版本兼容。

具体实现原理见 [架构设计](ARCHITECTURE.md)，与官方 Dialog / Sheet 的对比见
[为何使用 Overlay](WHY_OVERLAY.md)，从 v1 升级见
[迁移指南](MIGRATION_V1_TO_V2.md)。
