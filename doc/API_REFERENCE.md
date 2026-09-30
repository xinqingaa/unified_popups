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
- `dismissOnDrag`：在可关闭 Barrier 上拖动/滑动是否关闭（手势由 Barrier 消费，不转发下层）。Menu / DropMenu 默认 `true`。
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

默认指示器是半径 14 的 `CupertinoActivityIndicator`。`LoadingStyle.indicatorColor`
会传给它；`indicatorStrokeWidth` 不影响该默认指示器。自定义
`LoadingIndicatorConfig.child` 仍按 `rotationDuration` 旋转。

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
右上角关闭按钮默认隐藏。默认按钮为胶囊（主 `FilledButton`、次 `OutlinedButton`）。

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

自定义整颗按钮时传入 builder，库不包 `InkWell`，须调用 `onTap`：

```dart
Pop.confirm(
  ConfirmConfig(
    content: '自定义按钮',
    confirmButton: (onTap) => FilledButton(
      onPressed: onTap,
      child: const Text('确定'),
    ),
    cancelText: '取消',
  ),
);
```

若需要点遮罩、系统返回或关闭按钮关闭，显式打开对应能力：

```dart
Pop.confirm(
  const ConfirmConfig(
    content: '可取消的确认',
    confirmText: '确定',
    cancelText: '取消',
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
- `confirmButton` / `cancelButton`：自定义按钮 builder；非空时忽略对应文案。
- `confirmText` / `cancelText`：默认胶囊按钮文案；`cancelText` 与
  `cancelButton` 都为空则不显示取消。
- `separator`：内容带与按钮带之间的通栏分隔。
- `buttonSeparator`：两按钮之间的分隔；非空时忽略 `buttonSpacing`。
- `showCloseButton`：右上角关闭按钮，默认 `false`。
- `imagePath/imageHeight/imageFit`：通栏顶图（在 `contentPadding` 之外、标题之上）。
  宽度铺满容器，高度默认 80，`imageFit` 默认 `BoxFit.cover`，受容器圆角裁切。
  `imageWidth` 已忽略。
- `buttonLayout`：row（取消左确认右）/ column（确认上取消下）。
- `style`：`ConfirmStyle`（仅容器：padding / gap / 标题正文样式）。
- `onConfirm/onCancel`：只由对应按钮触发。
- `behavior`：默认 `backPolicy: block`。
- `barrier`：默认 `dismissible: false`。
- `ownership/position/animationConfig/lifecycle`。

`ConfirmStyle`：`contentPadding`、`buttonPadding`、`margin`、`decoration`、
`titleStyle`、`contentStyle`、`textAlign`、`imageGap`、`titleGap`、
`bodyExtensionGap`、`contentButtonGap`、`buttonSpacing`。

`title/titleWidget` 与 `content/contentWidget` 各自互斥；同时提供会触发断言。
`confirmButton` 优先于 `confirmText`；`cancelButton` 优先于 `cancelText`。

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
  默认 `padding` 为 `EdgeInsets.fromLTRB(16, 8, 16, 16)`。未传 `borderRadius` 时，
  进入边的外角为 32，面板按该圆角裁切内容。
- `SheetDockConfig`：enabled、edgeGap。
- `SheetDragConfig`：mode、modeListenable、showHandle、handleColor、dismissProgressThreshold、dismissVelocity。
  底部拖拽条为 38×6，下方留 10。标题 `Text` 铺满头部宽度，`titleAlign` 生效。
- `SheetKeyboardConfig`：adjustForKeyboard、animationDuration。
  底部键盘避让直接使用 `viewInsets`，不播放过渡。`animationDuration` 仍保留在配置上，渲染器不读取。

拖拽模式：`disabled`、`fullBody`、`contentWhenAtTop`、`handleOnly`。

往关闭方向拖动一开始就失焦，退出动画开始时也会失焦，键盘与面板一起离开。
已经拖过一段再松手关闭时，退场时长按剩余进度缩短，曲线为线性；未拖动的关闭仍走
`reverseDuration` / `reverseCurve`。

`modeListenable` 若在非 idle / post-frame 阶段变化，拖拽模式会延到下一帧再刷新。

Sheet 的打开请求是 `updatable`。同一 key 且 `conflictPolicy` 为 `updateExisting`
时可以原地更新该 Entry。为某个 Handle 构建出的业务 child 会一直缓存到 Handle
变化，因此原地更新配置不会重新执行 `builder`。

带可见蒙层的全屏弹层用 `FocusScope` 接住焦点，内部输入框可以成为主焦点。
关闭时，只有弹层自己的焦点域仍握着焦点，才会把焦点还给打开前的节点。

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

- `push<T>(page)`、`replace<T>(page)`：进入内页并等待内页结果。`push` 按
  `id` 保唯一：栈顶同 `id` 则 `replace`；该 `id` 在下面则只卸那一页，上面
  留下，再把新页压到顶。再进同一类页直接 `push` 即可。
- `pop<T>(result)`：退出当前内页。
- `popToRoot(result)`：弹出到根页面（已在根页为 no-op）；栈顶等待者收
  `result`，其余被弹出页以 `null` 完成。不关闭整张 sheet。
- `contains(id, {identity})`：栈内（含当前页）是否存在该 page id。id 是路由键，
  不要用 `canPop` 代替。不传 `identity` 只问种类；传了再按对象键收窄。再进
  同一类页用 `push`，不要用本方法决定 pop 还是 push。
- `popTo(id, [result], [identity])`：弹出直到该 id 成为栈顶（会卸掉上面所有
  页）。没有匹配时 debug 断言、release no-op；已是栈顶则 no-op。`result` 只
  交给目标页 `onPoppedTo`。再进同一类并保留上面已压上的页时用 `push`。
- `completeCurrent<T>(result)`：完成当前页面等待者但不播放内页返回动画。
- `completeAndCloseAll<T>(result)`：交付当前页结果并关闭整张 Sheet（不播内页返回动画）。用于弹层内进入全屏 / 外部路由、且不再回到本 FlowSheet。
- `discardCompletedAbove()`：卸掉已经完成 push Future、但仍压在当前页上面的页面，不播返回动画。可连卸多层。
- `resetTo<T>(page, {animate})`：将内部栈重置为单一新首页。默认无水平转场。
  `animate: true` 时先右滑推入新页，动画结束后卸掉下方旧页；新页成为根，
  `popToRoot` 落到它，不能侧滑回门槛页。动画期间系统返回被消费，不会把新页弹回门槛。
  Sheet 打开时的 `initialPage` 仍无水平入场。
- `closeAll(result)`：立刻结束业务会话（pending future 完成，禁止再导航）并 complete 外层 handle；页面树保留到退出动画结束，再触发 onHide / onClose。
- `canPop/handleBack`：内部返回能力；`handleBack` 会先询问当前页。栈还能 pop 时，系统返回走 `handleBack`，不直接 `pop`。

`FlowSheetPage.id` / `identity` / `instanceId`：

- `id` 是页种类键。同一 `id` 整场会话栈内只允许一页：`push` 会卸掉旧的同
  `id` 页再放入新页（栈顶则 `replace`）。
- `identity` 是可选的业务对象键（如 `symbol`、`orderNo`），供查找与日志使用，
  不能让同一 `id` 并存多份。
- `instanceId`（`identity == null ? id : '$id#$identity'`）只是组合键，不是
  栈内唯一约束。
- `contains`/`popTo` 不传 `identity` 按 `id` 查种类，传了再按对象键收窄。
  `popTo` 会卸掉目标上面的页；再进同一类并保留上面已压上的页时用 `push`。
- `enableSwipePop`：非首页是否允许 iOS 侧滑返回，默认 `true`。为 `false` 时不用
  `CupertinoPageRoute`，侧滑不能绕过 `onBack`。首页始终是零时长路由。
- `updateDragDismissMode(mode)`：动态更新拖拽关闭模式（含 `disabled`）。

`FlowSheetFocus`：

- `handOffToPreviousPage(focusNode)`：pop 前把焦点交回上一页，避免键盘先收再弹。
- `waitForRouteNearComplete(context, {threshold})`：当前路由进度达到阈值（默认 0.85）后再 `requestFocus`。

`FlowSheetPageState`：

- `onLoad` / `onShow` / `onHide` / `onRemove` / `onClose`：页面生命周期。
- `onPoppedTo(result)`：因 `popTo` 重新成为栈顶时调用。普通 `pop` 只走 `onShow`。
- `onBack()`：返回 `true` 时消费返回，阻止默认的内页 pop / 整张关闭。

关 Sheet 后再打开全屏路由：先 `completeAndCloseAll` 或 `closeAll`，再
`await Pop.settleChannel(PopupChannel.flowSheet)`（或 `PopupChannel.sheet`）。
`settleChannel` 会关掉该 channel 上仍 active 的弹层，并等待含退出动画中的全部
`dismissed`。

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

默认 `barrier` 为透明可点击/拖动关闭（`dismissOnDrag: true`），阻止下层滚动。

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

默认 `barrier` 同 Menu：透明可点击/拖动关闭（`dismissOnDrag: true`）。

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
| `Pop.dismissChannel(channel)` | 关闭指定 Channel 上仍 active 的 Entry，返回关闭数量 |
| `Pop.settleChannel(channel)` | 先关闭该 Channel 上仍 active 的 Entry，再等待仍挂载（含退出动画中）的全部 `dismissed` |
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
