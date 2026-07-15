# unified_popups v2 API 与参数参考

本文档以当前 `2.0.0` 代码为准，完整说明初始化、便捷 API、高级 Config、
`PopupHandle`、全局关闭、路由策略和 FlowSheet。代码中的类名、枚举值属于
公开 API，因此保留原始英文标识；所有解释均使用中文。

## 目录

- [应用初始化](#应用初始化)
- [两种调用层级](#两种调用层级)
- [Toast](#toast)
- [Loading](#loading)
- [Confirm](#confirm)
- [Sheet](#sheet)
- [FlowSheet](#flowsheet)
- [Date](#date)
- [Menu](#menu)
- [Custom Popup](#custom-popup)
- [PopupHandle](#popuphandle)
- [通用配置](#通用配置)
- [全局关闭与查询](#全局关闭与查询)
- [路由、返回键和堆叠](#路由返回键和堆叠)

## 应用初始化

只在根 `MaterialApp` 接入一次：

```dart
MaterialApp(
  navigatorObservers: [Pop.routeObserver],
  builder: Pop.hostBuilder,
  home: const HomePage(),
);
```

| API | 类型 | 说明 |
| --- | --- | --- |
| `Pop.routeObserver` | `NavigatorObserver` | 维护根路由栈、路由归属和系统返回桥。必须使用同一个稳定实例，因此直接使用此属性。 |
| `Pop.hostBuilder` | `TransitionBuilder` 兼容函数 | 挂载唯一的 `PopupHost`，弹窗变化不会重建传入的应用 child。 |
| `Pop.isReady` | `bool` | Host 当前是否已经挂载。 |
| `Pop.ready` | `Future<void>` | 等待 Host 第一次挂载。适合必须等初始化完成才继续的启动任务。 |
| `Pop.captureRoute()` | `PopupRouteToken?` | 捕获当前根路由 token，供高级异步归属控制使用。 |
| `Pop.runtime` | `PopupRuntime` | 默认全局运行时。主要用于诊断和测试，普通业务不应直接操作。 |

不再需要：

- Popup 专用 `navigatorKey`。
- `PopupManager.initialize()`。
- `PopScopeWidget`。
- 在 Service 或业务模块注入 `PopupController`。
- 为调用 Toast、Loading 等方法获取 `BuildContext`。

Host 挂载前发起的调用会进入 `pendingHost`，Host 就绪后再显示；不会因为首帧
尚未完成而丢失。

## 两种调用层级

### 便捷 API

适合大多数业务，只传常用参数并直接等待结果：

```dart
Pop.toast('保存成功');
final ok = await Pop.confirm(content: '确认提交吗？');
final value = await Pop.sheet<String>(childBuilder: ...);
```

### 高级 Config API

需要外部精确关闭、完整样式、key/tags、路由策略、生命周期回调或准确关闭原因时
使用：

| 类型 | 高级入口 | 返回值 |
| --- | --- | --- |
| Toast | `Pop.openToast(ToastConfig)` | `PopupOpenResult<void>` |
| Loading | `Pop.openLoading(LoadingConfig)` | `PopupOpenResult<void>` |
| Confirm | `Pop.openConfirm(ConfirmConfig)` | `PopupOpenResult<bool>` |
| Sheet | `Pop.openSheet<T>(SheetConfig<T>)` | `PopupOpenResult<T>` |
| FlowSheet | `Pop.openFlowSheet<R>(FlowSheetConfig<R>)` | `PopupOpenResult<R>` |
| Date | `Pop.openDate(DateConfig)` | `PopupOpenResult<DateTime>` |
| Menu | `Pop.openMenu<T>(MenuConfig<T>)` | `PopupOpenResult<T>` |
| DropMenu | `Pop.openDropMenu<T>(DropMenuConfig<T>)` | `PopupOpenResult<T>` |
| Custom | `Pop.custom<T>(CustomPopupConfig<T>)` | `PopupOpenResult<T>` |

所有高级入口统一返回 `PopupOpenResult<T>`，明确表达 opened、updated、
toggledClosed 或 rejected。只有 opened/updated 带 Handle；可以模式匹配，也可以读取
`handleOrNull`。当配置的策略确定一定会产生 Handle 时，可使用 `requireHandle()`。

便捷 API 的扁平参数会在内部组装到类型 Config，二者不会同时生效或互相覆盖。
常见映射：

| 便捷参数 | Config 字段 |
| --- | --- |
| `showBarrier` / `barrierDismissible` / `barrierColor` | `PopupBarrierConfig`（`false` → `PopupBarrierConfig.hidden()`） |
| `duration` / `until` | `PopupLifetime` |
| `onBackPressed` | `PopupBackPolicy.delegate` + `onBack` |
| Sheet `showDragHandle` | `SheetDragConfig.showHandle`（仅底部方向实际渲染） |

## Toast

### `Pop.toast`

```dart
void Pop.toast(
  String? message, {
  Widget? messageWidget,
  PopupPosition position = PopupPosition.center,
  ToastType toastType = ToastType.none,
  Duration? duration,
  Future<void>? until,
  bool showBarrier = false,
  bool barrierDismissible = false,
  Color? barrierColor,
  String? customImagePath,
  double imageSize = 24,
  Color? imgColor,
  Axis layoutDirection = Axis.horizontal,
  EdgeInsetsGeometry? padding,
  EdgeInsetsGeometry? margin,
  Decoration? decoration,
  TextStyle? style,
  TextAlign? textAlign,
  VoidCallback? onTap,
)
```

`message` 与 `messageWidget` 至少提供一个；同时提供时优先使用
`messageWidget`。

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `message` | 无 | 文字内容。使用纯 Widget 时可传 `null`。 |
| `messageWidget` | `null` | 完全自定义内容，优先级高于 `message`。 |
| `position` | `center` | `top`、`center`、`bottom`、`left`、`right`。不同位置使用独立 Toast 队列。 |
| `toastType` | `none` | `success`、`warn`、`error`、`none`，前三种显示包内默认图标。 |
| `duration` | 未显式设置 | 自动关闭时间。`duration` 和 `until` 都不传时使用 1200ms。 |
| `until` | `null` | Future 成功或失败结束时均以 `externalEvent` 关闭。只传它时不再使用默认 1200ms。 |
| `showBarrier` | `false` | 是否显示全屏遮罩。普通 Toast 建议保持关闭。 |
| `barrierDismissible` | `false` | 遮罩是否允许点击关闭，仅在 `showBarrier=true` 时生效。 |
| `barrierColor` | `Colors.black54` | 遮罩颜色。 |
| `customImagePath` | `null` | 自定义资源路径；提供后覆盖 `toastType` 默认图标。 |
| `imageSize` | `24` | 图标宽高。 |
| `imgColor` | `null` | 自定义资源着色。 |
| `layoutDirection` | `Axis.horizontal` | 图标与内容横排或竖排。 |
| `padding` | 水平 24、垂直 12 | Toast 内容内边距。 |
| `margin` | 水平 20、垂直 40 | Toast 相对对应位置边缘的外边距。 |
| `decoration` | 黑色半透明、圆角 12 | 容器装饰。 |
| `style` | 白色、16px | 文字样式。 |
| `textAlign` | `TextAlign.start` | 文字对齐。 |
| `onTap` | `null` | 点击 Toast 时触发，不会自动改变关闭语义。 |

关闭条件规则：

| `duration` | `until` | 行为 |
| --- | --- | --- |
| 不传 | 不传 | 1200ms 后关闭 |
| 传 | 不传 | 指定时间后关闭 |
| 不传 | 传 | 外部 Future 成功或失败结束时关闭 |
| 传 | 传 | 任一条件先完成即关闭 |

无 Barrier Toast 使用共享 lane，每个位置同时最多显示 3 个；更多 Toast 按
FIFO 排队，排队期间不启动倒计时。

### `ToastConfig`

```dart
final result = Pop.openToast(
  ToastConfig(
    message: '点击切换状态',
    position: PopupPosition.bottom,
    type: ToastType.success,
    toggle: const ToastToggleConfig(
      message: '已切换',
      type: ToastType.warn,
    ),
    onTap: onToastTap,
    lifetime: PopupLifetime.until(done.future),
  ),
);
```

| 字段 | 默认值 | 说明 |
| --- | --- | --- |
| `message` / `content` | 无 | 二者至少一个非空，Widget 优先。 |
| `position` | `center` | 位置及默认入场方向。更新已有 Toast 时不可改变。 |
| `type` | `none` | 默认图标类型。 |
| `icon` | `null` | `ToastIconConfig(assetPath, size, color)`。 |
| `layoutDirection` | `horizontal` | 图标与内容方向。 |
| `style` | `ToastStyle()` | padding、margin、decoration、textStyle、textAlign、spacing。 |
| `toggle` | `null` | 第二状态的 message/icon/type；点击时在主状态与第二状态之间切换。 |
| `onTap` | `null` | 每次点击回调。 |
| `behavior` | Toast channel、stack、persist、ignore back | key/tags 与冲突、路由、返回策略。 |
| `ownership` | independent | 父弹窗归属。 |
| `barrier` | hidden | 遮罩配置。更新时不可改变遮罩拓扑。 |
| `animation` | 根据位置自动选择 | 可覆盖完整动画。 |
| `lifetime` | 1200ms | 自动关闭条件。 |
| `lifecycle` | 空回调 | 通用生命周期。 |

## Loading

### `Pop.loading`

```dart
LoadingHandle Pop.loading({
  String? message,
  Widget? messageWidget,
  Widget? customIndicator,
  Duration? duration,
  Future<void>? until,
})
```

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `message` | `null` | Loading 文本。 |
| `messageWidget` | `null` | 自定义内容，优先于 `message`。 |
| `customIndicator` | `null` | 自定义指示器；提供后会按配置持续旋转。 |
| `duration` | `null` | 自动关闭时间。不传且无 `until` 时为手动关闭。 |
| `until` | `null` | 外部 Future 成功或失败结束时关闭。与 duration 同传时取先完成者。 |

```dart
final handle = Pop.loading(message: '第一阶段…');

// 不新建第二层：更新原 Entry、保留同一逻辑 Handle、重新开始计时。
Pop.loading(
  message: '第二阶段…',
  duration: const Duration(seconds: 2),
);

await handle.dismiss();
// 或 await Pop.hideLoading();
```

### `LoadingConfig`

| 字段 | 默认值 | 说明 |
| --- | --- | --- |
| `message` / `content` | `null` | 文字或自定义内容。允许都不传，只显示指示器。 |
| `style` | `LoadingStyle()` | 背景色、圆角、内边距、文字样式、指示器颜色和线宽。 |
| `indicator` | `LoadingIndicatorConfig()` | 自定义 child 与旋转周期，默认周期 1 秒。 |
| `behavior` | loading channel、全局 key、updateExisting、persist、block back | 保证默认 Loading 原地更新且阻止系统返回。 |
| `ownership` | independent | 父子归属。 |
| `barrier` | 可见、不可点击关闭 | 默认阻断下层交互。 |
| `animation` | 150ms fade | 进出场。 |
| `lifetime` | manual | 自动关闭条件。 |
| `lifecycle` | 空回调 | onPresented / onOutcome / onDismissed。 |
| `position` | `center` | 全局对齐；多 Loading 并存时可分别用 top/bottom 错开。 |

有文案时 Loading 面板按内容自适应宽高（最大宽约 280），不再强制正方形，避免长文截断。
仅指示器时保持紧凑方盒。

`LoadingStyle` 参数：

| 参数 | 默认值 |
| --- | --- |
| `backgroundColor` | `Color(0xCC000000)` |
| `borderRadius` | `12` |
| `padding` | `EdgeInsets.all(24)` |
| `textStyle` | 白色、16px |
| `indicatorColor` | 白色 |
| `indicatorStrokeWidth` | `2` |

## Confirm

### `Pop.confirm`

```dart
Future<bool?> Pop.confirm({
  String? title,
  Widget? titleWidget,
  String? content,
  Widget? contentWidget,
  String confirmText = 'confirm',
  Widget? confirmButtonWidget,
  String? cancelText,
  Widget? cancelButtonWidget,
  bool showCloseButton = true,
  Widget? confirmChild,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  ConfirmButtonLayout buttonLayout = ConfirmButtonLayout.row,
  ConfirmButtonStyle buttonStyle = ConfirmButtonStyle.divider,
  Color? confirmBgColor,
  Color? cancelBgColor,
  ConfirmStyle? style,
})
```

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `title` / `titleWidget` | `null` | 标题；Widget 优先。 |
| `content` / `contentWidget` | 无 | 内容；二者至少一个非空，Widget 优先。 |
| `confirmText` | `'confirm'` | 确认按钮文案。 |
| `confirmButtonWidget` | `null` | 完全自定义确认按钮内容。 |
| `cancelText` | `null` | 取消按钮文案；为 null 且无自定义按钮时不显示取消按钮。 |
| `cancelButtonWidget` | `null` | 完全自定义取消按钮内容。 |
| `showCloseButton` | `true` | 是否显示右上角关闭按钮。 |
| `confirmChild` | `null` | 按钮上方的扩展业务区域，例如输入框。 |
| `onConfirm` | `null` | 只在确认按钮点击时执行。 |
| `onCancel` | `null` | 只在取消按钮点击时执行。遮罩、关闭按钮和返回键不会触发它。 |
| `buttonLayout` | `row` | 按钮横排或竖排。 |
| `buttonStyle` | `divider` | 按钮风格：`divider` 贴底分割线（默认），`filled` 圆角填充/胶囊。 |
| `confirmBgColor` | 见下 | 确认按钮背景色；`filled` 默认主题 primary，`divider` 默认透明。 |
| `cancelBgColor` | 见下 | 取消按钮背景色；`filled` 默认 surfaceContainerHighest，`divider` 默认透明。 |
| `style` | `ConfirmStyle()` | 细调标题/正文/分割线/圆角/内边距等；`buttonStyle` / `*BgColor` 会覆盖其中对应字段。 |

结果语义：确认按钮返回 `true`；取消按钮返回 `false`；关闭按钮、遮罩、返回键、
路由切换等返回 `null`。需要知道具体原因时，从 `openConfirm` 返回的
`PopupOpenResult` 取得 Handle 后读取 `outcome`。

### `ConfirmConfig` 与 `ConfirmStyle`

`ConfirmConfig` 在便捷参数之外增加：`imagePath`、`imageWidth`、
`imageHeight`（默认 80）、`behavior`、`ownership`、`barrier`、`position`、
`animationConfig` 和 `lifecycle`。

`ConfirmStyle` 完整参数：

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `buttonStyle` | `divider` | `divider` 线条贴底按钮；`filled` 圆角填充/胶囊。 |
| `titleStyle` | 主题 titleLarge | 标题样式。 |
| `contentStyle` | 默认文本样式 | 内容样式。 |
| `confirmStyle` / `cancelStyle` | 自动前景色 | 两个按钮的文字样式。 |
| `padding` | `16` 四周 | 内容区内边距；`divider` 下不作用于按钮区，`filled` 下包住按钮。 |
| `margin` | 水平 32 | 相对屏幕外边距。 |
| `decoration` | 主题 surface、圆角 12 | 整体装饰。 |
| `textAlign` | `center` | 标题和内容对齐。 |
| `buttonBorderRadius` | 圆角 10 | 仅 `filled` 生效；线条按钮无独立圆角（由卡片裁剪）。 |
| `confirmBackgroundColor` / `cancelBackgroundColor` | 随 `buttonStyle` | 按钮背景色。 |
| `confirmBorder` / `cancelBorder` | `null` | 自定义按钮边框；未设时 `divider` 自动画分割线。 |
| `dividerColor` | 主题 dividerColor | 线条风格分割线颜色。 |
| `dividerWidth` | `0.5` | 线条风格分割线宽度。 |
| `buttonSpacing` | `12` | 仅 `filled`：横排水平间距 / 竖排垂直间距。 |

## Sheet

### `Pop.sheet<T>`

```dart
Future<T?> Pop.sheet<T>({
  required Widget Function(void Function([T? result]) dismiss) childBuilder,
  String? title,
  Widget? titleWidget,
  SheetDirection direction = SheetDirection.bottom,
  bool showCloseButton = false,
  bool? useSafeArea,
  SheetDimension? width,
  SheetDimension? height,
  SheetDimension? maxWidth,
  SheetDimension? maxHeight,
  bool showBarrier = true,
  bool barrierDismissible = true,
  Color? barrierColor,
  Color? backgroundColor,
  BorderRadius? borderRadius,
  List<BoxShadow>? boxShadow,
  EdgeInsetsGeometry? padding,
  bool dockToEdge = false,
  double edgeGap = 16,
  bool showDragHandle = true,
  Color? dragHandleColor,
  bool adjustForKeyboard = true,
  SheetDragDismissMode dragDismissMode = SheetDragDismissMode.fullBody,
  ValueListenable<SheetDragDismissMode>? dragDismissModeListenable,
  bool Function()? onBackPressed,
})
```

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `childBuilder` | 必填 | 构建业务内容；调用 `dismiss(result)` 完成结果并关闭。 |
| `title` / `titleWidget` | `null` | 标题；Widget 优先。 |
| `direction` | `bottom` | 从 `top`、`bottom`、`left`、`right` 进入并向同一边缘拖拽关闭。 |
| `showCloseButton` | `false` | 标题区域是否显示关闭按钮。 |
| `useSafeArea` | bottom 默认 true，其余 false | 控制**外层**对齐 SafeArea（底部 Sheet 扣状态栏，避免全屏顶到刘海）。panel 内始终有 SafeArea（对齐 v1），因此上/左/右即使默认 false，标题与内容仍会避开状态栏与 Home Indicator。 |
| `width` / `height` | 自动 | 固定或比例尺寸。 |
| `maxWidth` / `maxHeight` | 屏幕尺寸 | 最大尺寸约束。只设置最大高度时内容仍可按实际高度收缩。 |
| `showBarrier` | `true` | 是否显示遮罩。 |
| `barrierDismissible` | `true` | 是否可点击遮罩关闭。 |
| `barrierColor` | `Colors.black54` | 遮罩颜色。 |
| `backgroundColor` | 主题 surface | Sheet 背景色。 |
| `borderRadius` | 根据方向自动 | 远离屏幕边缘的一侧默认圆角 20。 |
| `boxShadow` | 默认轻阴影 | Sheet 阴影。 |
| `padding` | 左右 16、顶部 0、底部 10 | 内容内边距。指示器自身距离边缘 6，不再叠加顶部内容间距。 |
| `dockToEdge` | `false` | 是否在对应边缘保留可交互间隙。 |
| `edgeGap` | `16` | 保留间隙，例如底部 NavigationBar 高度。 |
| `showDragHandle` | `true` | 是否请求显示拖拽指示器。**实际仅 `SheetDirection.bottom` 会渲染**；上/左/右方向忽略该视觉（`handleOnly` 仍可通过标题栏等 chrome 拖关）。 |
| `dragHandleColor` | BottomSheetTheme 或 onSurfaceVariant | 指示器颜色（仅底部 Sheet）。 |
| `adjustForKeyboard` | `true` | 底部 Sheet 是否随键盘 viewInsets 上移。 |
| `dragDismissMode` | `fullBody` | 拖拽参与范围。 |
| `dragDismissModeListenable` | `null` | 运行时动态切换拖拽模式。 |
| `onBackPressed` | `null` | 返回 true 表示已由业务处理；返回 false 时继续按 Sheet 默认语义关闭。 |

`SheetDimension`：

```dart
const SheetDimension.pixel(420);   // 固定逻辑像素
const SheetDimension.fraction(.8); // 屏幕对应维度的 80%
```

`SheetDragDismissMode`：

| 值 | 说明 |
| --- | --- |
| `fullBody` | 整个 Sheet 都可拖拽。 |
| `contentWhenAtTop` | 滚动内容到达关闭方向边缘后，继续拖动才带动 Sheet。 |
| `handleOnly` | 只有指示器/标题等 chrome 区域可拖拽，适合正文包含复杂手势。底部 Sheet 有指示器；其他方向依赖标题栏等。 |

### `SheetConfig<T>`

```dart
final handle = Pop.openSheet<String>(
  SheetConfig<String>(
    direction: SheetDirection.bottom,
    header: const SheetHeaderConfig(title: '请选择'),
    size: const SheetSizeConfig(
      maxHeight: SheetDimension.fraction(.7),
    ),
    drag: const SheetDragConfig(
      mode: SheetDragDismissMode.contentWhenAtTop,
      dismissProgressThreshold: .28,
      dismissVelocity: 700,
    ),
    builder: (context, handle) => ListTile(
      title: const Text('完成'),
      onTap: () => handle.complete('done'),
    ),
  ),
).requireHandle();
```

拆分配置：

| 配置 | 字段 |
| --- | --- |
| `SheetHeaderConfig` | title、titleWidget、showCloseButton、padding（默认垂直 12）、titleStyle、titleAlign |
| `SheetSizeConfig` | width、height、maxWidth、maxHeight |
| `SheetStyle` | backgroundColor、borderRadius、boxShadow、padding、imagePath、imageSize（60）、imageOffset（16, -40） |
| `SheetDockConfig` | enabled、edgeGap（16） |
| `SheetDragConfig` | mode、modeListenable、showHandle、handleColor、dismissProgressThreshold（0.28）、dismissVelocity（700）。`showHandle` 仅在 `direction == bottom` 时渲染指示器。 |
| `SheetKeyboardConfig` | adjustForKeyboard、animationDuration（主题动画时长） |

`SheetConfig<T>` 另外提供 `behavior`、`ownership`、`barrier`、`animation`、
`lifecycle` 和异步 `onBack`。

## FlowSheet

### `Pop.flowSheet<R>`

```dart
Future<R?> Pop.flowSheet<R>({
  required FlowSheetController<R> controller,
  required FlowSheetPage initialPage,
  SheetDirection direction = SheetDirection.bottom,
  SheetDimension? maxHeight,
  SheetDimension? maxWidth,
  Color? backgroundColor,
  EdgeInsetsGeometry? padding,
  bool barrierDismissible = false,
  bool showBarrier = true,
  Color? barrierColor,
  bool showDragHandle = true,
  Color? dragHandleColor,
  bool adjustForKeyboard = true,
  SheetDragDismissMode dragDismissMode = SheetDragDismissMode.fullBody,
  Color? pageBackgroundColor,
  FlowSheetRouteBuilder? routeBuilder,
})
```

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `controller` | 必填 | 一次性 Session Controller；同一实例不能重复打开。 |
| `initialPage` | 必填 | 流程首页。 |
| `direction` | `bottom` | 外层 Sheet 方向。 |
| `maxHeight` / `maxWidth` | 屏幕尺寸 | 外层最大尺寸。 |
| `backgroundColor` | 主题 surface | 外层背景色。 |
| `padding` | 左右 16、顶部 0、底部 10 | 外层内容内边距。 |
| `barrierDismissible` | `false` | 默认不允许点击遮罩退出多步流程。 |
| `showBarrier` | `true` | 是否显示遮罩。 |
| `barrierColor` | `Colors.black54` | 遮罩颜色。 |
| `showDragHandle` | `true` | 是否请求显示指示器；仅底部方向实际渲染。 |
| `dragHandleColor` | 主题值 | 指示器颜色（仅底部）。 |
| `adjustForKeyboard` | `true` | 键盘避让。 |
| `dragDismissMode` | `fullBody` | 默认拖拽模式；每个页面可覆盖。 |
| `pageBackgroundColor` | `null` | 内部页面背景色。 |
| `routeBuilder` | 默认 CupertinoPage | 自定义内部页面路由。 |

### Controller 导航方法

| 方法 | 返回值 | 说明 |
| --- | --- | --- |
| `push<T>(page)` | `Future<T?>` | 压入页面并等待该页面完成结果。 |
| `replace<T>(page)` | `Future<T?>` | 替换当前页，旧页以 remove 生命周期结束。 |
| `pop<T>([result])` | `void` | 完成并移除当前内部页；栈底页不会用 pop 关闭整个流程。 |
| `completeCurrent<T>([result])` | `void` | 完成当前页等待者但保留页面。 |
| `closeAll([result])` | `void` | 完成整个 FlowSheet 结果并关闭全部页面。 |
| `handleBack([result])` | `bool` | 有内部页时先 pop；在首页时关闭整个 FlowSheet。 |
| `canPop` | `bool` | 当前是否存在首页之上的内部页。 |
| `isDisposed` | `bool` | Session 是否已完成视觉销毁。 |

### FlowSheet 页面

```dart
class DetailPage extends FlowSheetPage<String> {
  const DetailPage()
      : super(
          id: 'detail',
          maintainState: true,
          dragDismissMode: SheetDragDismissMode.handleOnly,
        );

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState
    extends FlowSheetPageState<DetailPage, String> {
  @override
  void onShow() {}

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => nav.pop('selected'),
      child: const Text('完成'),
    );
  }
}
```

页面参数：`id` 用于标识；`maintainState` 控制被覆盖时是否保活；
`dragDismissMode` 覆盖当前页的拖拽模式。

生命周期顺序：

- 首次显示：`onLoad → onShow`。
- 被新页面覆盖：`onHide`。
- 上层页面返回后重新出现：`onShow`。
- pop/replace：`onHide → onRemove`。
- 整个 FlowSheet 关闭：`onHide → onClose`。

高级 `FlowSheetConfig<R>` 复用 Sheet 的 header、size、style、dock、drag、
keyboard、barrier 和 animation 配置，并增加 controller、initialPage、
pageBackgroundColor、routeBuilder、behavior、ownership、lifecycle。

## Date

### `Pop.date`

```dart
Future<DateTime?> Pop.date({
  DateTime? initialDate,
  DateTime? minDate,
  DateTime? maxDate,
  String title = 'Date of Birth',
  String confirmText = 'Confirm',
  String? cancelText,
  Color? activeColor,
  Color? noActiveColor,
  Color? headerBg,
  double height = 216,
  double radius = 16,
})
```

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `initialDate` | 今天 | 初始日期；便捷 API 会自动限制在 min/max 之间。 |
| `minDate` | `DateTime(1960)` | 最早日期。 |
| `maxDate` | 今天 | 最晚日期。 |
| `title` | `'Date of Birth'` | 标题。建议业务传入中文文案。 |
| `confirmText` | `'Confirm'` | 确认文案。 |
| `cancelText` | `null` | 取消文案；为 null 时不显示取消按钮。 |
| `activeColor` | 主题色 | 当前选中项颜色。 |
| `noActiveColor` | 主题默认 | 未选中项颜色。 |
| `headerBg` | 主题默认 | 头部背景色。 |
| `height` | `216` | 日期选择区域高度，必须大于 0。 |
| `radius` | `16` | 顶部圆角，不能小于 0。 |

高级 `DateConfig` 使用：

- `DateRangeConfig(initialDate, minDate, maxDate)`：严格校验范围，非法值抛
  `ArgumentError`。
- `DateLabels(title, confirm, cancel)`：文案。
- `DateStyle(activeColor, inactiveColor, headerBackgroundColor, height, radius)`：样式。
- 另有 behavior、ownership、barrier、position、animationConfig、lifecycle。

## Menu

### Anchor 初始化

每个可独立打开的触发点持有一个稳定的 `PopupAnchorController`：

```dart
final menuAnchor = PopupAnchorController();

PopupAnchor(
  controller: menuAnchor,
  child: IconButton(
    icon: const Icon(Icons.more_horiz),
    onPressed: openMenu,
  ),
);
```

### `Pop.dropMenu<T>`

`dropMenu` 是建立在 Menu Runtime 上的数据驱动快捷 API，适合标准一级选择和
二级展开菜单。定位仍使用同一个 `PopupAnchorController`：

```dart
final status = await Pop.dropMenu<String>(
  anchor: menuAnchor,
  menu: const DropMenu<String>.single(
    selectedValue: 'all',
    items: [
      DropMenuItem(value: 'all', label: '全部'),
      DropMenuItem(value: 'active', label: '处理中'),
      DropMenuItem(value: 'done', label: '已完成'),
    ],
  ),
);
```

二级模式：

```dart
await Pop.dropMenu<String>(
  anchor: menuAnchor,
  onSelected: handleSelection,
  menu: DropMenu<String>.nested(
    sections: [
      DropMenuSection(
        id: 'displayMode',
        label: '标准显示',
        items: const [
          DropMenuItem(value: 'standard', label: '标准显示', selected: true),
          DropMenuItem(value: 'compact', label: '紧凑显示'),
        ],
      ),
      DropMenuSection.direct(
        id: 'confirm',
        item: DropMenuItem(
          value: 'confirm',
          label: '操作前确认',
          selected: true,
          showUnselectedIndicator: true,
          closeOnSelect: false,
          onTap: toggleConfirm,
        ),
      ),
    ],
  ),
);
```

主要模型：

- `DropMenu.single`：一级列表，`selectedValue` 标记当前值。
- `DropMenu.nested`：二级菜单，同一时间只展开一个 Section。
- `DropMenuItem<T>`：支持文字或 Widget、leading、禁用、选中、保持打开和自定义
  `selectedIcon`。
- `DropMenuSection<T>`：可展开分组；`DropMenuSection.direct` 表示一级直接操作。
- `DropMenuStyle`：约束、圆角、玻璃样式、文本/分隔线/选中/箭头/二级面板颜色、
  文字样式和图标 Builder。默认宽度范围为 140–240。

`Pop.dropMenu` 与 `Pop.menu` 默认交互一致：透明且可关闭的 Barrier，因此点击菜单
外关闭但不会绘制暗色遮罩，同时挡住底层滚动。需要底层继续滚动并跟随 Anchor 时可传
`showBarrier: false`。一级选项返回 `T` 并关闭；
二级选项通过 `onSelected` / Item `onTap` 通知业务，只以尺寸 + 淡入动画收起当前
Section，不关闭外层菜单。此时外层 Future 会在菜单最终关闭时结束，通常返回 null。
direct 项仍由 `closeOnSelect` 决定关闭整个菜单还是仅更新选中态。

高级入口 `Pop.openDropMenu<T>(DropMenuConfig<T>)` 返回 `PopupOpenResult<T>`，并支持
behavior、ownership、barrier、animationConfig 和 lifecycle。默认使用
`PopupKeys.globalDropMenu + replaceExisting`，确保同时只有一个标准 DropMenu；不同
结果泛型的标准 DropMenu 也可以互相替换。

### Liquid Glass

DropMenu 默认使用从 `ThemeData.colorScheme` 解析的液态玻璃样式，自动适配明暗
主题。`LiquidGlassStyle` 对外暴露背景、普通边框、顶部高光、按压高亮、阴影、
模糊和描边配置；顶部高光可通过 `topHighlightColor` 独立于 `borderColor` 设置。
`DropMenuStyle` 进一步暴露文字、禁用态、分隔线、选中色、二级背景和箭头颜色。
颜色为 null 时采用主题默认值。

通用 `LiquidGlass.backdropBlendMode` 默认为 Flutter 的 `BlendMode.srcOver`。
DropMenu 打开动画只淡入面板内的文字/图标，玻璃与 `BackdropFilter` 保持不透明，
避免父级 OpacityLayer 改变模糊采样；DropMenu 的 BackdropFilter 额外使用
`BlendMode.src`。

```dart
const style = DropMenuStyle(
  constraints: BoxConstraints(minWidth: 140, maxWidth: 220),
  glassStyle: LiquidGlassStyle(
    backgroundColor: Color(0x88334455),
    borderColor: Color(0x44556677),
    topHighlightColor: Color(0xCCFFFFFF),
  ),
);
```

默认玻璃背景 Alpha 为浅色主题 `0xB3`、深色主题 `0x8C`。调用方传入带 Alpha 的
`backgroundColor` 即可进一步控制透明度。一级菜单、二级选项以及一级 Section 的
最后一项均自动省略底部分隔线。

### 定位与偏移

`MenuPlacement.auto` 会先完成一次不可见布局，取得菜单实际宽高，再按以下规则决定
方向：

- 在 SafeArea 内，下方能够容纳实际菜单时优先向下弹出。
- 下方放不下而上方能够容纳时向上弹出；两侧都放不下时选择溢出更少的一侧。
- 横向使用实际菜单宽度检查 start/end；两侧都能放下时按 Anchor 所在屏幕半区选择。
- `offset` 会参与可用空间计算。方向在本次菜单打开期间锁定，二级展开不会让整个
  菜单突然翻到另一侧。

需要固定方向时传 `belowStart`、`belowEnd`、`aboveStart` 或 `aboveEnd`。`offset`
在完成 Anchor 对齐后应用，坐标始终是正 X 向右、正 Y 向下：

```dart
await Pop.dropMenu<String>(
  anchor: menuAnchor,
  placement: MenuPlacement.belowEnd,
  offset: const Offset(8, 12), // 向右 8、向下留 12 间距
  menu: menu,
);

await Pop.dropMenu<String>(
  anchor: menuAnchor,
  placement: MenuPlacement.aboveEnd,
  offset: const Offset(8, -12), // 向上弹出时，负 Y 才是远离 Anchor
  menu: menu,
);
```

`LiquidGlass`、`LiquidGlassButton` 和 `LiquidGlassActionButton` 也作为独立公共组件
导出，可在菜单之外复用。

### `Pop.menu<T>`

```dart
Future<T?> Pop.menu<T>({
  required PopupAnchorController anchor,
  required Widget Function(void Function([T? result]) dismiss) builder,
  MenuPlacement placement = MenuPlacement.auto,
  Offset offset = Offset.zero,
  EdgeInsetsGeometry? padding,
  BoxConstraints? constraints,
  Decoration? decoration,
  bool showBarrier = true,
  bool barrierDismissible = true,
  Color barrierColor = Colors.transparent,
})
```

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `anchor` | 必填 | 已挂载的 Anchor Controller；未挂载时调用会抛 `StateError`。 |
| `builder` | 必填 | 菜单内容；调用 dismiss(result) 返回选择结果。 |
| `placement` | `auto` | `belowStart`、`belowEnd`、`aboveStart`、`aboveEnd` 或自动判断空间。 |
| `offset` | `Offset.zero` | 相对锚点对齐位置的额外偏移。 |
| `padding` | `EdgeInsets.zero` | 菜单容器内边距。 |
| `constraints` | 最小宽 120、最大宽 280 | 菜单尺寸约束。 |
| `decoration` | 主题 surface、圆角 8、阴影 | 菜单装饰。 |
| `showBarrier` | `true` | 是否显示全屏遮罩。默认开启（透明），点外关闭且挡住底层滚动。 |
| `barrierDismissible` | `true` | 遮罩可点关；仅在 `showBarrier=true` 时生效。 |
| `barrierColor` | `Colors.transparent` | 遮罩颜色；默认透明不可见。需要暗色蒙层时自行传入。 |

`Pop.menu` 与 `Pop.dropMenu` 默认交互一致：透明可点关 Barrier、底层不可滚、点空白关闭。
Menu 通过 `CompositedTransformTarget/Follower` 跟随 Anchor；滚动、布局变化和
Transform 不需要重新计算坐标。Anchor 卸载时以
`PopupDismissReason.anchorDetached` 自动关闭。

#### 高级：允许底层滚动并跟随

关闭 Barrier 后事件落到下层，列表可滚，菜单继续跟随 Anchor：

```dart
await Pop.menu<String>(
  anchor: anchor,
  showBarrier: false,
  builder: (dismiss) => ...,
);
```

需要暗色遮罩时保留 `showBarrier: true` 并设置 `barrierColor`（例如
`Color(0x8A000000)`）。

高级 `MenuConfig<T>` 的 `barrier` 默认亦为透明可关闭
`PopupBarrierConfig(color: Colors.transparent)`；要滚动跟随时传入
`PopupBarrierConfig.hidden()`。另支持 `PopupMenuStyle`、behavior、ownership、
animationConfig 和 lifecycle。

## Custom Popup

```dart
final handle = Pop.custom<String>(
  CustomPopupConfig<String>(
    position: PopupPosition.center,
    barrier: const PopupBarrierConfig(
      dismissible: true,
    ),
    animationConfig: const PopupAnimationConfig(
      type: PopupAnimationType.scale,
    ),
    builder: (context, handle) => MyCard(
      onSelected: (value) => handle.complete(value),
      onClose: handle.dismiss,
    ),
  ),
).requireHandle();
```

| 字段 | 默认值 | 说明 |
| --- | --- | --- |
| `builder` | 必填 | 返回自定义 Widget，并获得类型安全 Handle。 |
| `behavior` | custom channel、stack、persist、dismiss back | 通用行为。 |
| `ownership` | independent | 父弹窗归属。 |
| `barrier` | 可见、可点击关闭 | 遮罩。 |
| `position` | center | 全局对齐位置。 |
| `animationConfig` | fade、200ms | 动画。 |
| `lifecycle` | 空回调 | 生命周期。 |

Custom 只自定义内容，不绕开 Runtime；因此仍然拥有统一堆叠、返回键、路由、
动画、关闭原因和资源清理。

## PopupHandle

```dart
final handle = Pop.openSheet<String>(config).requireHandle();

final value = await handle.result;
final outcome = await handle.outcome;
await handle.dismissed;
```

| 成员 | 类型 | 说明 |
| --- | --- | --- |
| `id` | `String` | Runtime 内稳定唯一 id。 |
| `key` | `String?` | 业务稳定 key。 |
| `channel` | `PopupChannel` | 查询分类。 |
| `state` | `PopupEntryState` | 当前状态。 |
| `isActive` | `bool` | 业务上仍可完成或关闭。 |
| `isMounted` | `bool` | Renderer 是否仍挂载，包括退场阶段。 |
| `result` | `Future<T?>` | 业务结果确定时完成。 |
| `outcome` | `Future<PopupOutcome<T>>` | 业务值与准确关闭原因。 |
| `dismissed` | `Future<void>` | 退场完成、Renderer 移除后完成。 |
| `complete([value])` | `Future<void>` | 立即确定 completed outcome，返回的 Future 等视觉移除。 |
| `dismiss()` | `Future<void>` | 以 manual 原因关闭，并等待视觉移除。 |

`UpdatablePopupHandle<T, C>.update(config)` 返回 bool。只有条目仍活跃且新配置
不改变 Renderer 的不可变拓扑时才成功；成功后更新原 Entry 并重启 lifetime。

`PopupOutcome<T>`：

| 属性 | 说明 |
| --- | --- |
| `value` | 业务值，可以合法为 null。 |
| `reason` | 准确关闭原因。 |
| `isCompleted` | reason 是否为 `completed`。 |

常见 `PopupDismissReason`：

| 值 | 含义 |
| --- | --- |
| `completed` | 调用了 `complete`，产生业务结果。 |
| `manual` | Handle 或关闭按钮手动关闭。 |
| `timeout` | Duration 到期。 |
| `externalEvent` | 外部 Future 成功或失败结束。 |
| `barrier` | 点击遮罩。 |
| `drag` | 拖拽关闭。 |
| `back` | 系统返回。 |
| `routeChanged` | 路由策略触发。 |
| `replaced` | 冲突策略替换。 |
| `toggled` | toggle 冲突策略关闭。 |
| `anchorDetached` | Menu Anchor 卸载。 |
| `parentDismissed` | 父弹窗关闭后级联关闭。 |
| `hostDetached` / `hostUnavailable` | Host 卸载或不可用。 |
| `rendererUnavailable` | 没有匹配 Renderer。 |
| `queueOverflow` | Host 前队列容量溢出。 |
| `runtimeDisposed` | Runtime 关闭。 |

## 通用配置

### `PopupBehaviorConfig`

```dart
const PopupBehaviorConfig(
  channel: PopupChannel.sheet,
  key: 'checkout-address',
  tags: {'checkout'},
  conflictPolicy: PopupConflictPolicy.replaceExisting,
  routePolicy: PopupRoutePolicy.dismissWhenOwnerRouteChanges,
  backPolicy: PopupBackPolicy.dismiss,
)
```

| 字段 | 默认值 | 说明 |
| --- | --- | --- |
| `channel` | 必填 | 查询和批量关闭分类，不隐式决定任何行为。 |
| `key` | `null` | Runtime 内唯一逻辑身份，用于冲突匹配和查询。 |
| `tags` | 空集合 | 业务分组，可按 tags 批量关闭。 |
| `conflictPolicy` | `stack` | 同 key 冲突行为。 |
| `routePolicy` | `persist` | 跨路由行为。 |
| `backPolicy` | `dismiss` | 系统返回行为。 |

`PopupConflictPolicy`：

| 值 | 说明 |
| --- | --- |
| `stack` | 普通无 key 条目继续堆叠；同 key 不允许产生两个逻辑实例。 |
| `rejectNew` | 保留旧条目，拒绝新调用。 |
| `replaceExisting` | 旧条目以 replaced 关闭，然后创建新条目。 |
| `toggle` | 已存在则关闭，不存在则打开。 |
| `updateExisting` | 保留原 Entry/Handle，更新 Config 并重启 lifetime。 |

打开结果：

| 类型 | 含义 |
| --- | --- |
| `PopupOpened<T>` | 创建了新 Entry，`handle` 指向新 Entry。 |
| `PopupUpdated<T>` | 原 Entry 已更新，`handle` 是原稳定 Handle。 |
| `PopupToggledClosed<T>` | toggle 关闭旧 Entry，没有新 Handle。 |
| `PopupRejected<T>` | 新请求被拒绝，没有创建 Entry。 |

`PopupRejected` 是打开决策，不是 Entry 的关闭原因。replace/toggle 不复用旧 Handle，
因此同 channel、同 key 的不同结果泛型可以互相替换；只有 `updateExisting` 要求 Config
与结果泛型完全一致。同 key 跨 channel 始终拒绝。

`PopupRoutePolicy`：

| 值 | 说明 |
| --- | --- |
| `persist` | 根路由变化时继续保留。Toast、Loading 默认使用。 |
| `dismissWhenOwnerRouteChanges` | 离开打开弹窗时所属路由后关闭。 |
| `dismissOnAnyRouteChange` | 任意根路由变化都关闭。 |

`PopupBackPolicy`：

| 值 | 说明 |
| --- | --- |
| `dismiss` | 返回键关闭当前弹窗。 |
| `block` | 消费返回键但不关闭，例如默认 Loading。 |
| `ignore` | 不参与返回处理，例如默认 Toast。 |
| `delegate` | 调用类型提供的内部返回逻辑，例如 FlowSheet。 |

### `PopupBarrierConfig`

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `visible` | `true` | 是否显示遮罩。 |
| `dismissible` | `true` | 是否允许点击关闭。 |
| `color` | `Color(0x8A000000)` | 遮罩颜色。 |
| `semanticsLabel` | `null` | 无障碍语义。 |
| `insets` | `EdgeInsets.zero` | 局部遮罩留白；dock Sheet 会自动设置对应边缘。 |

`PopupBarrierConfig.hidden()` 创建不可见且不可点击关闭的遮罩配置。

### `PopupAnimationConfig`

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `type` | `fade` | none、fade、四方向 slide、scale。 |
| `duration` | 200ms | 入场时长。 |
| `reverseDuration` | `null` | 退场时长；null 时使用 duration。 |
| `curve` | `easeOutCubic` | 入场曲线。 |
| `reverseCurve` | `easeInCubic` | 退场曲线。 |
| `slideOffset` | `0.15` | 相对自身尺寸的滑动距离；Sheet 默认使用 1。 |

### `PopupLifetime`

```dart
const PopupLifetime.manual();
PopupLifetime.after(const Duration(seconds: 2));
PopupLifetime.until(requestDone);
PopupLifetime.anyOf([timeout, externalEvent]);
```

Lifetime 在进入动画完成后启动。更新 Entry 时旧 Timer/Future 通过 generation
失效，新 lifetime 从更新时重新开始。`until` 观察 Future 是否 settled，不判断业务
成功或失败；Popup 不重复上报业务异常，原 Future 的错误仍由业务调用方处理。

### `PopupOwnership`

| 字段 | 默认值 | 说明 |
| --- | --- | --- |
| `routeToken` | 自动捕获或 null | 所属根路由。 |
| `parentEntryId` | `null` | 所属父弹窗 id。 |
| `policy` | `independent` | independent 或 dismissWithParent。 |

Confirm 和 Date 默认尝试归属于当前顶层模态弹窗；父 Sheet/FlowSheet 关闭时会先
关闭这些子弹窗。

### `PopupLifecycleCallbacks<T>`

| 回调 | 触发时间 |
| --- | --- |
| `onPresented` | 入场动画完成，条目进入 visible。 |
| `onOutcome(outcome)` | 业务 outcome 首次确定。 |
| `onDismissed(outcome)` | 退场完成并移除 Renderer。 |

回调抛出的异常会报告给 Flutter，但不会中断清理流程。

## 全局关闭与查询

```dart
await handle.dismiss();
await Pop.dismissTop();
await Pop.dismissChannel(PopupChannel.sheet);
await Pop.dismissTags({'checkout'});
await Pop.dismissAll();

final handled = await Pop.handleBack();
final visible = Pop.isVisibleKey('checkout-address');
final active = Pop.isActiveKey('checkout-address');
final hasLoading = Pop.hasChannel(PopupChannel.loading);
final toastCount = Pop.countChannel(PopupChannel.toast);
```

| API | 返回值 | 说明 |
| --- | --- | --- |
| `dismissTop()` | `Future<bool>` | 关闭当前最上层活跃弹窗；无可关闭条目时 false。 |
| `dismissChannel(channel)` | `Future<int>` | 关闭该 channel 全部条目，返回命中数量。 |
| `dismissTags(tags)` | `Future<int>` | 关闭命中任意指定 tag 的条目。 |
| `dismissAll()` | `Future<void>` | 关闭 Runtime 中全部条目。 |
| `handleBack()` | `Future<bool>` | 执行一次与系统返回相同的顶层分发。 |
| `isVisibleKey(key)` | `bool` | key 对应条目是否处于 entering、visible 或退出动画阶段。 |
| `isActiveKey(key)` | `bool` | key 对应条目业务上是否仍活跃。 |
| `hasChannel(channel)` | `bool` | channel 是否存在活跃条目。 |
| `countChannel(channel)` | `int` | channel 活跃条目数量。 |
| `hideLoading()` | `Future<void>` | 关闭默认全局 Loading key。 |
| `shutdown()` | `Future<void>` | 永久关闭默认 Runtime，应用退出级操作。 |
| `resetForTest()` | `Future<void>` | 仅测试使用，关闭旧 Runtime 并创建新实例。 |

## 路由、返回键和堆叠

- Sheet 或 FlowSheet 不会因为打开 Toast、Confirm、Menu 而自动关闭。
- Toast 默认位于瞬态提示层，不参与系统返回。
- Loading 默认消费返回键但不关闭。
- 其他默认模态弹窗由最上层开始响应返回键。
- FlowSheet 有内部页面时优先退出内部页面；在首页时才关闭整个 FlowSheet。
- `dismissWhenOwnerRouteChanges` 依赖 `Pop.routeObserver` 捕获的稳定 route token。
- 系统返回通过当前根 Route 的 `PopEntry` 桥接，不需要额外 `PopScope`。
- 自定义 AppBar 返回若要复用相同语义，可先调用 `Pop.handleBack()`；返回 false
  时再执行自己的 Navigator pop。

完整迁移说明见 [v1 与 v2 对比及迁移指南](MIGRATION_V1_TO_V2.md)，架构原理见
[架构设计与实现原理](ARCHITECTURE.md)。
