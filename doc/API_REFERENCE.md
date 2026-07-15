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

返回值可以直接忽略：

```dart
Pop.toast(const ToastConfig.text('保存成功'));
```

也可以等待业务结果：

```dart
final value = await Pop.confirm(config).result;
```

或获取 Handle：

```dart
final handle = Pop.loading(config).requireHandle();
```

## 3. PopupOpenResult 与 PopupHandle

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
- `requireHandle()`：没有 Handle 时抛出 `StateError`。
- `result`：统一的 `Future<T?>` 业务结果。

`PopupHandle<T>`：

- `id/key/channel/state/isActive/isMounted`：逻辑 Entry 状态。
- `complete([T? value])`：业务正常完成并退出。
- `dismiss()`：无业务结果地关闭。
- `result`：`Future<T?>`。
- `outcome`：`Future<PopupOutcome<T>>`，包含 value 和 reason。
- `dismissed`：视觉节点彻底移除后完成。

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
  const LoadingConfig(
    message: '上传中',
    lifetime: PopupLifetime.manual(),
  ),
);
```

`LoadingConfig`：

- `message/content`：文本或 Widget 内容，也允许都为空。
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

```dart
final confirmed = await Pop.confirm(
  const ConfirmConfig(
    title: '删除记录',
    content: '删除后无法恢复。',
    confirmText: '删除',
    cancelText: '取消',
  ),
).result;
```

`ConfirmConfig`：

- `title/titleWidget`：标题。
- `content/contentWidget`：正文，至少提供一个。
- `bodyExtension`：正文下方扩展 Widget。
- `confirmText/confirmButton`：确认按钮。
- `cancelText/cancelButton`：取消按钮；不提供则不显示。
- `showCloseButton`：右上角关闭按钮。
- `imagePath/imageWidth/imageHeight`：顶部图片。
- `buttonLayout`：row/column。
- `style`：`ConfirmStyle`。
- `onConfirm/onCancel`：只由对应按钮触发。
- `behavior/ownership/barrier/position/animationConfig/lifecycle`。

`ConfirmStyle`：`buttonStyle`、四类 TextStyle、`padding`、`margin`、
`decoration`、`textAlign`、`buttonBorderRadius`、确认/取消背景与边框、
`dividerColor`、`dividerWidth`、`buttonSpacing`。

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

拖拽模式：`fullBody`、`contentWhenAtTop`、`handleOnly`。

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
- `canPop/handleBack`：内部返回能力。

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
| `Pop.isVisibleKey(key)` | keyed Entry 是否 visible |
| `Pop.isActiveKey(key)` | keyed Entry 是否仍活跃 |
| `Pop.hasChannel(channel)` | Channel 是否存在活跃 Entry |
| `Pop.countChannel(channel)` | Channel 活跃数量 |
| `Pop.shutdown()` | 关闭 Runtime |

## 15. PopupDismissReason

主要 reason：`completed`、`manual`、`barrier`、`back`、`timeout`、
`externalEvent`、`routeChanged`、`parentDismissed`、`replaced`、`toggled`、
`anchorDetached`、`hostDetached`、`hostUnavailable`、`runtimeDisposed`、
`queueOverflow`、`missingRenderer`。

具体实现原理见 [架构设计](ARCHITECTURE.md)，从 v1 升级见
[迁移指南](MIGRATION_V1_TO_V2.md)。
