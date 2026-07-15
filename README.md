# unified_popups

面向 Flutter 的统一全局弹窗系统。业务代码只使用 `Pop.*`，不需要持有
`BuildContext`、`navigatorKey` 或在页面间传递弹窗 Controller。

支持 Toast、Loading、Confirm、Date、Sheet、FlowSheet、Menu、DropMenu 和
Custom。v2 遵循一个明确规则：**一种能力、一个 `Pop.xxx(Config)` 入口、一个
`PopupOpenResult<T>` 返回模型。**

## 安装与初始化

```yaml
dependencies:
  unified_popups: ^2.0.0
```

```dart
MaterialApp(
  navigatorObservers: [Pop.routeObserver],
  builder: Pop.hostBuilder,
  home: const HomePage(),
);
```

首次 Host 挂载前发起的 Popup 会进入 `pendingHost`，Host 就绪后再显示。

## 唯一 API 形式

```dart
Pop.toast(const ToastConfig.text('保存成功'));
Pop.loading(const LoadingConfig(message: '提交中'));
Pop.confirm(const ConfirmConfig(content: '确定继续吗？'));
Pop.date(DateConfig(initialDate: DateTime.now()));
Pop.sheet<String>(SheetConfig<String>(builder: ...));
Pop.flowSheet<Result>(FlowSheetConfig<Result>(...));
Pop.menu<String>(MenuConfig<String>(...));
Pop.dropMenu<String>(DropMenuConfig<String>(...));
Pop.custom<String>(CustomPopupConfig<String>(...));
```

所有方法都返回 `PopupOpenResult<T>`。不关心返回值时直接忽略：

```dart
Pop.toast(const ToastConfig.text('保存成功'));
```

需要业务值时使用 `.result`：

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

需要命令式控制时获取 Handle：

```dart
final handle = Pop.loading(
  const LoadingConfig(message: '上传中'),
).requireHandle();

await handle.dismiss();
```

## Toast 与 Loading

Toast 用命名构造器区分文本和 Widget 内容：

```dart
Pop.toast(
  const ToastConfig.text(
    '同步完成',
    type: ToastType.success,
    position: PopupPosition.bottom,
    lifetime: PopupLifetime.after(Duration(seconds: 2)),
  ),
);

Pop.toast(
  const ToastConfig.content(
    Row(children: [Icon(Icons.check), Text('自定义内容')]),
  ),
);
```

`PopupLifetime.until` 在 Future 成功或失败结束时都会关闭 Popup：

```dart
final request = saveData();
Pop.loading(
  LoadingConfig(
    message: '保存中',
    lifetime: PopupLifetime.until(request),
  ),
);
await request; // 业务错误仍由业务代码处理
```

Loading 默认使用全局 key 和 `updateExisting`。重复调用会更新原 Entry，而不是先关
再开：

```dart
Pop.loading(const LoadingConfig(message: '10%'));
Pop.loading(const LoadingConfig(message: '80%')); // PopupUpdated
```

## V2 PopupHandle

Sheet、Menu 和 Custom 的 Builder 直接获得稳定的 `PopupHandle<T>`：

```dart
final selected = await Pop.sheet<String>(
  SheetConfig<String>(
    header: const SheetHeaderConfig(title: '选择操作'),
    size: const SheetSizeConfig(
      maxHeight: SheetDimension.fraction(0.6),
    ),
    builder: (context, handle) => Column(
      children: [
        ListTile(
          title: const Text('复制'),
          onTap: () => handle.complete('copy'),
        ),
        TextButton(
          onPressed: handle.dismiss,
          child: const Text('取消'),
        ),
      ],
    ),
  ),
).result;
```

- `complete(value)`：业务正常完成，可携带结果，reason 为 `completed`。
- `dismiss()`：普通取消或外部关闭，不携带业务结果。
- `outcome`：value 与准确的 `PopupDismissReason`。
- `dismissed`：退出动画完成、视觉节点彻底移除后完成。

## Menu 与 DropMenu

```dart
final anchor = PopupAnchorController();

PopupAnchor(
  controller: anchor,
  child: IconButton(
    icon: const Icon(Icons.more_horiz),
    onPressed: () async {
      final action = await Pop.menu<String>(
        MenuConfig<String>(
          anchor: anchor,
          builder: (context, handle) => Column(
            children: [
              ListTile(
                title: const Text('编辑'),
                onTap: () => handle.complete('edit'),
              ),
            ],
          ),
        ),
      ).result;
    },
  ),
);
```

Menu 默认使用透明、可点击关闭的 Barrier。需要底层继续滚动并让菜单跟随 Anchor：

```dart
barrier: const PopupBarrierConfig.hidden(),
```

DropMenu 使用 `DropMenu.single` 或 `DropMenu.nested` 数据模型。标准 DropMenu 默认
使用全局 key 和 `replaceExisting`，因此同一时刻只保留一个标准 DropMenu。

## FlowSheet

```dart
final controller = FlowSheetController<OrderResult>();
final result = await Pop.flowSheet<OrderResult>(
  FlowSheetConfig<OrderResult>(
    controller: controller,
    initialPage: const FirstStepPage(),
    size: const SheetSizeConfig(
      maxHeight: SheetDimension.fraction(0.9),
    ),
  ),
).result;
```

内部页面使用 `nav.push`、`nav.replace`、`nav.pop(result)`、
`nav.completeCurrent(result)` 和 `nav.closeAll(result)`。

## 冲突与批量管理

`PopupBehaviorConfig` 不包含 channel；channel 由 `Pop.toast/Pop.sheet/...` 能力本身
确定：

```dart
behavior: const PopupBehaviorConfig(
  key: 'sync-status',
  tags: {'network'},
  conflictPolicy: PopupConflictPolicy.updateExisting,
  routePolicy: PopupRoutePolicy.dismissWhenOwnerRouteChanges,
),
```

冲突结果包括 `PopupOpened`、`PopupUpdated`、`PopupToggledClosed` 和
`PopupRejected`。

```dart
await Pop.dismissTop();
await Pop.dismissChannel(PopupChannel.sheet);
await Pop.dismissTags({'network'});
await Pop.dismissAll();
```

## 文档

- [架构设计与实现原理](doc/ARCHITECTURE.md)
- [完整 API 与参数参考](doc/API_REFERENCE.md)
- [v1 与 v2 对比及迁移](doc/MIGRATION_V1_TO_V2.md)

Example 包含 FitPulse 产品流程和按能力划分的 Lab：

```bash
cd example
flutter run
```
