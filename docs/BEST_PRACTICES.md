# 最佳实践指南

面向整套 `Pop` API 的使用建议：选型、初始化、各类型注意点，以及返回键 / 路由 / 异步等横切行为。

## 目录

- [选型](#选型)
- [初始化](#初始化)
- [各类型实践](#各类型实践)
- [返回键与路由](#返回键与路由)
- [异步与资源](#异步与资源)
- [常见错误](#常见错误)

## 选型

| 需求 | 推荐 |
|------|------|
| 操作结果轻提示 | `Pop.toast` |
| 阻塞等待（请求中） | `Pop.loading` + `try/finally` |
| 危险 / 不可逆确认 | `Pop.confirm` |
| 单页筛选、表单、抽屉 | `Pop.sheet` |
| 多步向导 | `Pop.flowSheet` |
| 选日期 | `Pop.date` |
| 锚定「更多」菜单 | `Pop.menu` |

同一交互不要叠多种反馈（例如 confirm 成功后再用超长 toast 复述全文）。

## 初始化

使用**同一个** `navigatorKey`，并同时注册 `PopupRouteObserver` 与 `PopScopeWidget`：

```dart
final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(MyApp(navigatorKey: navigatorKey));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PopupManager.initialize(navigatorKey: navigatorKey);
  });
}

MaterialApp(
  navigatorKey: navigatorKey,
  navigatorObservers: [PopupRouteObserver()],
  builder: (context, child) => PopScopeWidget(
    child: child ?? const SizedBox.shrink(),
  ),
  home: const HomePage(),
);
```

常见错误：`MaterialApp` 里又 `GlobalKey()` 了一个新 key，Overlay 挂不上。

## 各类型实践

### Toast

- 短文案 + `ToastType`；不要塞长说明或复杂交互。
- 需要自定义布局时用 `messageWidget`，而不是把一整页塞进 toast。
- 默认不因路由切换关闭；若页面离开后不应残留，显式传 `dismissOnRouteChange: true`。

```dart
Pop.toast('保存成功', toastType: ToastType.success);
```

### Loading

- **必须** `try/finally`，避免异常后卡住。
- 全局单例：重复调用会关掉旧的再开新的，不要自己缓存「loading id」。
- 默认不因路由切换关闭；长任务跨页时要想清楚是否应手动 `hideLoading`。

```dart
Pop.loading(message: '导出中...');
try {
  await exportReport();
  Pop.toast('导出完成', toastType: ToastType.success);
} finally {
  Pop.hideLoading();
}
```

### Confirm

- 删除、清空、不可逆操作用 confirm；纯告知用 toast。
- 需要输入时用 `confirmChild`，不要另开一层 sheet 套 confirm。
- 自定义按钮外观优先 `confirmButtonWidget` / `cancelButtonWidget`；接管点击用 `onConfirm` / `onCancel`（在内部关闭逻辑之前执行）。
- 默认路由切换会关闭。

```dart
final ok = await Pop.confirm(
  title: '删除确认',
  content: '删除后不可恢复',
  confirmText: '删除',
  confirmBgColor: Colors.red,
);
```

### Sheet

- 内容通过 `dismiss(result)` 关闭，不要再叠一层 Navigator。
- **dockToEdge**：需保留底部 / 侧边导航点击时开启；`edgeGap` 对齐导航栏实际高度（example 用 `FitPulseMetrics.sheetDockEdgeGap`）。
- **拖拽**：静态列表用 `fullBody`；可滚动内容用 `contentWhenAtTop`；带下拉刷新用 `handleOnly`。
- 表单保持 `adjustForKeyboard: true`（默认）。
- 默认路由切换会关闭。

```dart
await Pop.sheet<void>(
  title: '筛选',
  dockToEdge: true,
  edgeGap: 84,
  dragDismissMode: SheetDragDismissMode.contentWhenAtTop,
  childBuilder: (dismiss) => FilterList(onApply: () => dismiss()),
);
```

### FlowSheet

- 多步流程再用；单页筛选继续用 `sheet`。
- 结束整条流：`nav.completeCurrent(result)` 或 `nav.closeAll(result)`，避免先 `pop` 到空栈再关 sheet（双动画）。
- 同级步骤用 `replace`；需要返回上一页用 `push` / `pop`。
- 在 `onShow` / `onHide` / `onRemove` 启停轮询或订阅。
- 系统返回默认 `controller.handleBack`（先退内部页）。

```dart
final controller = FlowSheetController<bool>();
final ok = await Pop.flowSheet<bool>(
  controller: controller,
  maxHeight: SheetDimension.fraction(0.9),
  initialPage: WizardFirstPage(controller: controller),
);
```

### Date

- 约束用 `minDate` / `maxDate`；文案用 `title` / `confirmText` / `cancelText`。
- 默认不因路由切换关闭。

```dart
final date = await Pop.date(
  title: '选择生日',
  minDate: DateTime(1970, 1, 1),
  maxDate: DateTime.now(),
);
```

### Menu

- 必须提供稳定的 `anchorKey`（挂在触发按钮上）。
- 菜单项通过 `dismiss(result)` 回传；点击空白 / 遮罩返回 `null`。
- 默认不因路由切换关闭。

```dart
final result = await Pop.menu<String>(
  anchorKey: moreKey,
  builder: (dismiss) => ListTile(
    title: Text('删除'),
    onTap: () => dismiss('delete'),
  ),
);
```

## 返回键与路由

- **返回键**：`PopScopeWidget` → `hideLastNonToast()`。若配置了 `onBackPressed` 且返回 `true`，不关 Overlay（例如 flowSheet 退页）。
- **路由切换默认**：关闭 confirm / sheet；保留 toast / loading / date / menu。用各 API 的 `dismissOnRouteChange` 覆盖。
- **Observer**：须注册，并覆盖 `didRemove`（二级页 `remove` 路由时同样清理）。

自定义 AppBar 返回可用 `PopupManager.maybePop(context)`。

## 异步与资源

`SafeOverlayEntry` 会在 build 阶段延迟 `markNeedsBuild`，因此可在 `Future.then`、`async`、`Timer`、甚至 `build` 中直接 `Pop.*`。仍建议：

- loading 用 `try/finally`
- 页面 dispose 后不要再依赖该页 `setState`；多步流用生命周期钩子清理
- 动画时长按场景调：toast / loading 宜短，sheet 可稍长

## 常见错误

| 现象 | 排查 |
|------|------|
| 弹窗不显示 | `navigatorKey` 是否同一实例；是否在首帧后 `initialize` |
| 返回直接出 App | 是否包了 `PopScopeWidget` |
| 跳转后弹窗残留 / 误关 | 检查该类型默认策略与 `dismissOnRouteChange` |
| loading 关不掉 | 是否缺少 `finally` |
| dockToEdge 挡导航 | `edgeGap` 是否小于真实导航高度 |
| flowSheet 退出动画抖两下 | 是否用了 `completeCurrent` / `closeAll` |

更多参数见 [API_REFERENCE.md](API_REFERENCE.md)；场景演示见 [example/](../example/)。
