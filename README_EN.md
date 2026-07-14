# unified_popups 中文快速说明

> 此文件名为历史兼容保留。项目文档统一使用中文，完整说明请阅读
> [README](README.md) 和 [API 参数参考](docs/API_REFERENCE.md)。

`unified_popups` 是 Flutter 的全局无 context 弹窗系统，通过一个 `Pop` 门面和
一个声明式 Host 提供 Toast、Loading、Confirm、Sheet、FlowSheet、Date、
Menu 与自定义弹窗。

## 初始化

```dart
MaterialApp(
  navigatorObservers: [Pop.routeObserver],
  builder: Pop.hostBuilder,
  home: const HomePage(),
);
```

不需要 Popup 专用 navigatorKey、context 查找、Controller 注入或额外返回键
Widget。页面、Service、Timer 和 Flow 使用完全相同的调用方式：

```dart
Pop.toast('保存成功', toastType: ToastType.success);

final loading = Pop.loading(message: '同步中…');
await repository.sync();
await loading.dismiss();

final accepted = await Pop.confirm(
  title: '删除数据',
  content: '删除后无法恢复。',
  cancelText: '取消',
  onConfirm: trackConfirmation,
  onCancel: trackCancellation,
);
```

## Handle 和高级配置

便捷 API 返回普通业务结果。需要准确生命周期与外部控制时使用类型 Config：

```dart
final handle = Pop.openSheet<String>(
  SheetConfig<String>(
    builder: (context, handle) => ListTile(
      title: const Text('选择'),
      onTap: () => handle.complete('selected'),
    ),
  ),
);

final value = await handle.result;
final outcome = await handle.outcome;
await handle.dismissed;
```

`result` 是业务值，`outcome` 还包含准确的 `PopupDismissReason`，`dismissed`
在视觉节点移除后完成。

```dart
await handle.dismiss();
await Pop.dismissTop();
await Pop.dismissChannel(PopupChannel.sheet);
await Pop.dismissTags({'checkout'});
await Pop.dismissAll();
```

Loading 重复调用会更新原逻辑 Entry 并重新开始新 lifetime。Toast 和 Loading
都支持倒计时、外部 Future 或 Handle 关闭。所有类型可以在 Sheet 和 FlowSheet
上继续堆叠，根路由返回键与路由归属由 `Pop.routeObserver` 统一协调。

## Menu Anchor

```dart
final anchor = PopupAnchorController();

PopupAnchor(
  controller: anchor,
  child: IconButton(
    icon: const Icon(Icons.more_horiz),
    onPressed: () => Pop.menu<void>(
      anchor: anchor,
      builder: (dismiss) => MenuContent(onDone: dismiss),
    ),
  ),
);
```

Menu 使用组合图层跟随滚动与布局变化，Anchor 卸载时自动关闭。
