# unified_popups 2.0 API Reference

## 应用接入

```dart
MaterialApp(
  navigatorObservers: [Pop.routeObserver],
  builder: Pop.hostBuilder,
  home: const HomePage(),
);
```

| API | 作用 |
| --- | --- |
| `Pop.routeObserver` | 路由归属、跨路由清理和系统返回桥 |
| `Pop.hostBuilder` | 在应用树顶层挂载唯一 `PopupHost` |
| `Pop.isReady` / `Pop.ready` | 查询或等待 Host 就绪 |
| `Pop.captureRoute()` | 获取当前稳定路由 token |
| `Pop.runtime` | 高级诊断或测试使用的默认 Runtime |

弹窗调用不需要 `BuildContext`。应用不再需要 Popup 专用 `navigatorKey`、
`PopupManager.initialize` 或 `PopScopeWidget`。

## 便捷 API

### Toast

```dart
Pop.toast(
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
});
```

无 Barrier 的 Toast 使用共享位置 lane，每个位置同时最多显示三个，超出的条目
进入队列。高级入口为 `Pop.openToast(ToastConfig)`，返回
`PopupOpenResult<void>`。

### Loading

```dart
LoadingHandle Pop.loading({
  String? message,
  Widget? messageWidget,
  Widget? customIndicator,
  Duration? duration,
  Future<void>? until,
});

Future<void> Pop.hideLoading();
```

高级入口 `Pop.openLoading(LoadingConfig)` 返回 `LoadingHandle`。默认 loading
key 为 `PopupKeys.globalLoading`，冲突策略为 `updateExisting`。
重复调用更新同一逻辑条目及其生命周期条件，而不是先退出再创建。

### Confirm

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
  Color? confirmBgColor,
  Color? cancelBgColor,
});
```

确认按钮完成 `true`，取消按钮完成 `false`，其他关闭方式返回 `null`。
`onConfirm` / `onCancel` 仅由对应按钮触发。高级入口
`Pop.openConfirm(ConfirmConfig)` 返回 `PopupHandle<bool>`。

### Sheet

```dart
Future<T?> Pop.sheet<T>({
  required Widget Function(void Function([T? result]) dismiss) childBuilder,
  String? title,
  Widget? titleWidget,
  SheetDirection direction = SheetDirection.bottom,
  bool showCloseButton = false,
  SheetDimension? width,
  SheetDimension? height,
  SheetDimension? maxWidth,
  SheetDimension? maxHeight,
  bool showBarrier = true,
  bool barrierDismissible = true,
  bool dockToEdge = false,
  double edgeGap = 16,
  bool showDragHandle = true,
  bool adjustForKeyboard = true,
  SheetDragDismissMode dragDismissMode = SheetDragDismissMode.fullBody,
  ValueListenable<SheetDragDismissMode>? dragDismissModeListenable,
  bool Function()? onBackPressed,
  // 另有颜色、圆角、阴影、padding 等样式参数
});
```

`SheetDimension` 支持固定值和屏幕比例。高级入口
`Pop.openSheet<T>(SheetConfig<T>)` 返回 `PopupHandle<T>`。

### FlowSheet

```dart
Future<R?> Pop.flowSheet<R>({
  required FlowSheetController<R> controller,
  required FlowSheetPage initialPage,
  SheetDirection direction = SheetDirection.bottom,
  SheetDimension? maxHeight,
  SheetDimension? maxWidth,
  bool barrierDismissible = false,
  SheetDragDismissMode dragDismissMode = SheetDragDismissMode.fullBody,
  Color? pageBackgroundColor,
  FlowSheetRouteBuilder? routeBuilder,
  // 另有 Barrier、样式、拖拽和键盘参数
});
```

一个 `FlowSheetController` 只承载一个 Popup Session。页面通过 state 中的 `nav`
执行：

| 方法 | 语义 |
| --- | --- |
| `push<T>(page)` | 压入页面并等待该页业务结果 |
| `pop<T>(result)` | 完成并移除当前页 |
| `completeCurrent<T>(result)` | 完成当前页等待者但不退页 |
| `replace(page)` | 替换当前页 |
| `closeAll(result)` | 关闭整个 FlowSheet |
| `handleBack()` | 有内部页时先退页，否则交给外层关闭 |

高级入口为 `Pop.openFlowSheet<R>(FlowSheetConfig<R>)`。

### Date

```dart
Future<DateTime?> Pop.date({
  DateTime? initialDate,
  DateTime? minDate,
  DateTime? maxDate,
  String title = 'Date of Birth',
  String confirmText = 'Confirm',
  String? cancelText,
  // 另有颜色、高度和圆角参数
});
```

高级入口 `Pop.openDate(DateConfig)` 返回 `PopupHandle<DateTime>`。

### Menu

```dart
Future<T?> Pop.menu<T>({
  required PopupAnchorController anchor,
  required Widget Function(void Function([T? result]) dismiss) builder,
  MenuPlacement placement = MenuPlacement.auto,
  Offset offset = Offset.zero,
  EdgeInsetsGeometry? padding,
  BoxConstraints? constraints,
  Decoration? decoration,
  bool barrierDismissible = true,
});
```

触发 Widget 必须由 `PopupAnchor(controller: anchor, child: ...)` 包裹。
`auto` 会根据 Anchor 的全局位置选择上方或下方；Follower 会在滚动时持续跟随。
高级入口 `Pop.openMenu<T>(MenuConfig<T>)` 返回 `PopupHandle<T>`，样式类型为
`PopupMenuStyle`。

### Custom

```dart
final handle = Pop.custom<void>(
  CustomPopupConfig<void>(
    builder: (context, handle) => MyPopup(
      onClose: handle.complete,
    ),
  ),
);
```

Custom 同样必须显式使用 Config，并自动接入统一动画、Barrier、返回键、路由和
Handle 生命周期。

## PopupHandle

| 成员 | 语义 |
| --- | --- |
| `id` / `key` / `channel` | 稳定身份与查询维度 |
| `state` / `isActive` / `isMounted` | 逻辑和渲染状态 |
| `complete([value])` | 产生 completed outcome 并退场 |
| `dismiss()` | 以 manual 原因请求关闭 |
| `result` | `Future<T?>`，业务结果完成时结束 |
| `outcome` | `Future<PopupOutcome<T>>`，包含值与关闭原因 |
| `dismissed` | 退场完成、视觉节点移除时结束 |

`UpdatablePopupHandle<T, C>.update(C)` 可更新支持更新的逻辑条目。Loading
默认支持；带稳定 key 的 Toast 可通过高级配置启用。

常见 `PopupDismissReason`：`completed`、`manual`、`timeout`、
`externalEvent`、`barrier`、`drag`、`back`、`routeChanged`、`replaced`、
`anchorDetached`、`parentDismissed`、`hostDetached`。

## 生命周期与策略

### PopupLifetime

```dart
const PopupLifetime.manual();
PopupLifetime.after(const Duration(seconds: 2));
PopupLifetime.until(requestFinished);
PopupLifetime.anyOf([after, until]);
```

更新现有 Loading 时，旧 lifetime 监听会失效，新 lifetime 从更新时重新开始。

### PopupBehaviorConfig

| 字段 | 作用 |
| --- | --- |
| `channel` | 类型查询/批量操作，不驱动其他行为 |
| `key` | 唯一身份及冲突匹配 |
| `tags` | 业务分组 |
| `conflictPolicy` | stack / update / replace / toggle / reject 等冲突行为 |
| `routePolicy` | persist / owner route change / any route change |
| `backPolicy` | dismiss / block / ignore / delegate |

### PopupLifecycleCallbacks

- `onPresented`：进入动画完成。
- `onOutcome`：业务 outcome 确定。
- `onDismissed`：退场结束、节点移除。

## 全局控制与查询

```dart
Pop.dismissTop();
Pop.dismissAll();
Pop.dismissChannel(PopupChannel.sheet);
Pop.dismissTags({'checkout'});
Pop.handleBack();

Pop.isVisibleKey('key');
Pop.isActiveKey('key');
Pop.hasChannel(PopupChannel.loading);
Pop.countChannel(PopupChannel.toast);
```

默认 Runtime 是全局且可替换的 facade 实现；测试可直接构造 `PopupRuntime` 与
`PopupHost` 获得完全隔离的实例。`Pop.shutdown()` 用于应用级永久收口，
`Pop.resetForTest()` 只用于测试。
