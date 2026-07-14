# 从 v1 迁移到 v2

v2 是有意进行的破坏性升级。迁移的核心是删除 v1 初始化，将底层 Manager 调用
替换为类型安全的 Config 和 Handle。

## 1. 修改应用初始化

```dart
// v1：navigatorKey + PopupManager.initialize + PopScopeWidget

// v2
MaterialApp(
  navigatorObservers: [Pop.routeObserver],
  builder: Pop.hostBuilder,
);
```

页面、Service 和 Flow 中继续直接调用 `Pop.*`。删除 Popup 专用 Controller
注入、context 查找和 navigatorKey 传递。

## 2. 底层 API 对照

| v1 | v2 |
| --- | --- |
| `PopupManager.show(PopupConfig)` | `Pop.custom(CustomPopupConfig)` |
| 返回 String id | 返回类型安全的 `PopupHandle<T>` |
| `PopupManager.hide(id)` | `handle.dismiss()` |
| `hideLast()` | `Pop.dismissTop()` |
| `hideAll()` | `Pop.dismissAll()` |
| `hideByType(type)` | `Pop.dismissChannel(channel)` |
| `getCountByType(type)` | `Pop.countChannel(channel)` |
| `isVisible(id)` | Handle 状态或 `Pop.isVisibleKey(key)` |
| `maybePop(context)` | 自动返回桥或 `Pop.handleBack()` |

动画、遮罩、自动关闭、路由、返回键、key/tags 和父子归属应移动到对应类型的
Config。不要把旧 `PopupType` 直接映射为行为；v2 使用显式 Policy。

## 3. 外部关闭和结果

```dart
final handle = Pop.openConfirm(
  const ConfirmConfig(
    content: '是否继续？',
    cancelText: '取消',
  ),
);

service.onAbort = handle.dismiss;

final outcome = await handle.outcome;
await handle.dismissed;
```

产生业务结果时调用 `complete(value)`；无结果地关闭时调用 `dismiss()`。
当 `null` 也可能是合法业务结果，或业务需要区分返回键、遮罩、超时、路由变化时，
读取 `outcome.reason`。

## 4. Menu 迁移

将 `GlobalKey anchorKey` 替换为稳定的 `PopupAnchorController`，用
`PopupAnchor` 包裹触发 Widget，并把 `anchor:` 传给 `Pop.menu`。删除坐标轮询、
RenderBox 重试和手动滚动位置更新。

## 5. Loading 和 Toast 迁移

- Loading 重复调用会更新原 Entry，删除旧代码中的“先 hide 再 show”。
- 使用 `duration`、`until` 或二者组合控制自动关闭。
- 某个调用方明确拥有 Loading 时，保存返回的 `LoadingHandle`。
- Toast 切换状态仍可通过高级 `ToastConfig.toggle` 使用；便捷 API 保持一次调用
  表达一个清晰消息。

## 6. Confirm 迁移

`onConfirm` 与 `onCancel` 只对应两个按钮。不要再把 `false` 与所有非确认关闭
混为一谈：

- 确认按钮：回调 `onConfirm`，结果 `true`。
- 取消按钮：回调 `onCancel`，结果 `false`。
- 遮罩、关闭按钮、返回键、路由变化：不触发按钮回调，便捷结果为 `null`。

需要进一步区分后四种原因时使用 `openConfirm` 和 `handle.outcome`。

## 7. 建议验收顺序

1. 启动 Example，检查四个业务 Tab 和 Lab。
2. 分别验证一个弹窗，以及 Sheet → Confirm 堆叠时的系统返回顺序。
3. 在所属路由弹窗可见时执行 push、replace、remove。
4. 打开 Menu 后滚动 Anchor，并在 Menu 打开时移除 Anchor。
5. 验证 Loading 重复更新、重新计时和外部 Future 关闭。
6. 验证 Toast/Loading 文本样式、Sheet 指示器间距和键盘避让。

逐参数映射见 [v1 → v2 API 能力对照](API_PARITY_V2.md)，完整参数见
[API 参数参考](API_REFERENCE.md)。
