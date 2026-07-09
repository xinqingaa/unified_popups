# 最佳实践指南

对齐 FitPulse example 的真实场景：轻反馈、确认、筛选 Sheet、多步 FlowSheet、路由切换与系统返回。

## 目录

- [选型](#选型)
- [初始化](#初始化)
- [Toast / Loading / Confirm](#toast--loading--confirm)
- [Sheet](#sheet)
- [FlowSheet](#flowsheet)
- [返回键与路由](#返回键与路由)
- [异步安全](#异步安全)

## 选型

| 需求 | 推荐 |
|------|------|
| 操作结果轻提示 | `Pop.toast` |
| 阻塞等待（请求中） | `Pop.loading` + `try/finally` |
| 危险/不可逆确认 | `Pop.confirm` |
| 单页筛选、表单、抽屉 | `Pop.sheet` |
| 多步向导（训练开始、健康档案） | `Pop.flowSheet` |
| 生日 / 起始日 | `Pop.date` |
| 锚定「更多」菜单 | `Pop.menu` |

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

常见错误：`MaterialApp` 里又 `GlobalKey()` 了一个新 key，导致 Overlay 挂不上。

## Toast / Loading / Confirm

**Toast**：短文案 + `ToastType`；不要塞长说明或复杂交互。

**Loading**：必须 `try/finally`，避免异常后卡住：

```dart
Pop.loading(message: '导出中...');
try {
  await exportReport();
  Pop.toast('导出完成', toastType: ToastType.success);
} finally {
  Pop.hideLoading();
}
```

**Confirm**：删除课程、清空数据等用确认；需要输入时用 `confirmChild`。

## Sheet

- **dockToEdge**：底部/侧边 Sheet 需保留 NavigationBar 点击时开启；`edgeGap` 应等于导航栏实际高度（FitPulse 用 `FitPulseMetrics.sheetDockEdgeGap`，与 `NavigationBar` 高度对齐）。
- **拖拽**：`SheetDragDismissMode.fullBody` 适合静态列表；可滚动内容用 `contentWhenAtTop`；带下拉刷新用 `handleOnly`。
- **键盘**：表单 Sheet 保持 `adjustForKeyboard: true`（默认）。
- **关闭**：内容里用注入的 `dismiss(result)`，不要再叠一层 Navigator。

```dart
await Pop.sheet<void>(
  title: '筛选课程',
  dockToEdge: true,
  edgeGap: FitPulseMetrics.sheetDockEdgeGap,
  dragDismissMode: SheetDragDismissMode.contentWhenAtTop,
  childBuilder: (dismiss) => FilterList(onApply: () => dismiss()),
);
```

## FlowSheet

适合「开始训练」「完善健康档案」等多步流。

- 结束整条流：用 `nav.completeCurrent(result)` 或 `nav.closeAll(result)`，**避免**先 `pop` 到空栈再关 Sheet（双动画）。
- 同级步骤切换用 `replace`；需要返回上一页用 `push` / `pop`。
- 在 `onShow` / `onHide` / `onRemove` 启停轮询或订阅。
- 系统返回默认走 `controller.handleBack`（先退内部页）；可用 `onBackPressed` 覆盖。

```dart
final controller = FlowSheetController<bool>();
final ok = await Pop.flowSheet<bool>(
  controller: controller,
  maxHeight: SheetDimension.fraction(0.9),
  initialPage: HealthProfileIntroPage(controller: controller),
);
```

## 返回键与路由

- **返回键**：`PopScopeWidget` → `hideLastNonToast()`；若配置了 `onBackPressed` 且返回 `true`，不关 Overlay（FlowSheet 退页）。
- **路由切换**：默认关闭 confirm / sheet；toast / loading / date / menu 默认保留。可用各 API 的 `dismissOnRouteChange` 覆盖。
- **Observer**：须包含 `didRemove` 场景（FitPulse「设置」二级页可验证）。

## 异步安全

`SafeOverlayEntry` 会在 build 阶段延迟 `markNeedsBuild`，因此可在 `Future.then`、`async`、`Timer`、甚至 `build` 中直接 `Pop.*`。仍建议：

- loading 用 `try/finally`
- 页面 dispose 后不要再 `setState`；FlowSheet 用生命周期钩子清理

更多参数见 [API_REFERENCE.md](API_REFERENCE.md)；场景演示见 [example/](../example/)。
