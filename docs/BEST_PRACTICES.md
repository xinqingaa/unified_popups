# unified_popups 2.0 最佳实践

## 1. 应用只接入一次

```dart
MaterialApp(
  navigatorObservers: [Pop.routeObserver],
  builder: Pop.hostBuilder,
);
```

不要在业务模块重复创建 Host，也不要把 Popup Controller 注入 Service。
Service、Flow 和页面统一调用 `Pop.*`。

## 2. 便捷 API 与高级 API 分工

- 只关心返回值：使用 `Pop.confirm`、`Pop.sheet` 等便捷 API。
- 需要外部关闭、准确关闭原因、key/tags、生命周期：使用
  `Pop.openXxx(Config)` 并保存 `PopupHandle`。
- 完全自定义内容：使用 `Pop.custom(CustomPopupConfig)`。

便捷 API 内部会组装对应类型的 Config，**不会与高级字段叠加或打架**。例如
`showBarrier: false` 等价于 `barrier: PopupBarrierConfig.hidden()`。
需要 `PopupBarrierConfig.insets`、`PopupBehaviorConfig.tags`、
`PopupOwnership.routeToken` 等能力时，直接走高级 Config。

不要依赖字符串 id。Handle 是类型安全且包含完整生命周期的稳定引用。

## 3. 正确理解完成与关闭

```dart
handle.complete(result); // 完成业务 Future，并启动退场
await handle.dismissed;  // 等待视觉彻底移除
```

提交业务后通常等待 `result`；必须在动画结束后执行的 UI 操作才等待
`dismissed`。需要区分取消、超时、返回键和路由变化时读取 `outcome`。

## 4. Loading 和 Toast 的外部事件

```dart
final request = repository.refresh();
Pop.loading(message: '刷新中', until: request.then((_) {}));
await request;
```

若同时配置 `duration` 与 `until`，任一条件先到即关闭。Loading 重复调用会
更新同一条目并重启新配置的计时；不需要先 `hideLoading()`。

无法把请求 Future 直接作为关闭信号时，使用 Completer：

```dart
final done = Completer<void>();
Pop.toast('处理中', duration: const Duration(seconds: 30), until: done.future);
eventBus.once('finished', (_) => done.complete());
```

## 5. Confirm 回调不替代返回值

`onConfirm` 和 `onCancel` 适合埋点或按钮专属副作用；真正业务分支继续读取
`Future<bool?>`。遮罩、关闭按钮和系统返回不会触发 `onCancel`。

## 6. Menu 必须使用 Anchor

每个可同时存在的触发点持有独立的 `PopupAnchorController`：

```dart
final anchor = PopupAnchorController();

PopupAnchor(
  controller: anchor,
  child: IconButton(
    onPressed: () => Pop.menu<void>(
      anchor: anchor,
      builder: (dismiss) => MenuContent(onDone: dismiss),
    ),
    icon: const Icon(Icons.more_horiz),
  ),
);
```

不要再用 `GlobalKey + RenderBox` 手算位置。Anchor/Follower 能随滚动、布局和
Transform 更新；Anchor 卸载会自动关闭 Menu。

`Pop.menu` 与 `Pop.dropMenu` **默认透明 Barrier**：点外关闭、底层不可滚。需要
打开后继续滚动底层列表并观察跟随时：

```dart
Pop.menu(
  anchor: anchor,
  showBarrier: false,
  builder: ...,
);
```

需要暗色蒙层时保留默认 `showBarrier: true`，并设置 `barrierColor`。

## 7. 路由与返回键

- 日常模态弹窗使用 `dismissWhenOwnerRouteChanges`。
- 真正的全局状态提示才使用 `persist`。
- 系统返回由 `Pop.routeObserver` 自动桥接，无需页面包 `PopScope`。
- 自定义 AppBar 若需要同样语义，可先 `await Pop.handleBack()`；返回 false 时
  再由业务 Navigator 退出页面。
- FlowSheet 有内部页面时优先退内部页。

弹窗上再开弹窗是允许的。返回键总是从最上层开始处理，不要在业务层自行维护
一份并行栈。

## 8. 选择 key、tags 与 channel

- `key`：一个逻辑资源，如全局 Loading 或某个唯一同步状态。
- `tags`：一个业务域，如 `checkout`，适合流程结束时批量关闭。
- `channel`：弹窗类型统计和批量管理。

Channel 不决定动画、Barrier、返回键或路由策略；这些行为必须显式配置。

## 9. Sheet 与 FlowSheet

- 单页选择/表单使用 Sheet。
- 多步且需要页面结果、保活、内部返回栈时使用 FlowSheet。
- `contentWhenAtTop` 适合含滚动内容的底部 Sheet。
- `handleOnly` 适合正文包含横向手势或复杂拖拽的内容。
- 拖拽指示器**仅在底部 Sheet** 显示；上/左/右即使 `showDragHandle: true` 也不渲染指示器，`handleOnly` 请配合标题栏等 chrome。
- 一个 `FlowSheetController` 只用于一次显示，下一次流程创建新 Controller。

## 10. 测试与诊断

Example 的 **技术实验室** 是整库能力矩阵（按类型分页），适合手测与回归；
业务 Tab 只保留真实用法。Widget 测试优先构造隔离的 `PopupRuntime`；测试默认
全局 facade 时在 teardown 调用 `Pop.resetForTest()`。断言异步生命周期时分别
检查 outcome 与 dismissed，不要用任意长延迟代替 `pumpAndSettle`。

常见问题：

| 现象 | 检查项 |
| --- | --- |
| 弹窗不显示 | `builder: Pop.hostBuilder` 是否接入；是否存在第二个 Host |
| 返回键直接退出页面 | `Pop.routeObserver` 是否注册在同一个根 Navigator |
| Menu 无法打开 | Anchor 是否已挂载；触发 Widget 是否被 `PopupAnchor` 包裹 |
| 路由切换未关闭 | Config 的 `routePolicy` 是否为 `persist` |
| Loading 不消失 | 是否配置 duration/until，或是否调用 handle/`hideLoading` |
