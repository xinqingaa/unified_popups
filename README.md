# unified_popups

面向 Flutter 的统一全局弹窗系统。业务代码只使用 `Pop.*`，不需要持有
`BuildContext`、`navigatorKey` 或到处注入 Controller。

支持 `toast`、`loading`、`confirm`、`sheet`、`flowSheet`、`date`、`menu`
和 `custom`。所有类型共享同一套 Runtime、路由/返回策略、生命周期和
`PopupHandle`。

## 安装与初始化

```yaml
dependencies:
  unified_popups: ^2.0.0
```

应用只需接入一次 Host 和路由观察者：

```dart
import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [Pop.routeObserver],
      builder: Pop.hostBuilder,
      home: const HomePage(),
    );
  }
}
```

初始化后，页面、Service、Flow、Timer 或网络回调中都直接调用：

```dart
Pop.toast('保存成功', toastType: ToastType.success);
```

无需传递 `context` 或 Controller。`Pop.ready` 可用于必须等待 Host 挂载的
启动任务；首帧前发起的弹窗也会由 Runtime 暂存，Host 就绪后再显示。

## 便捷 API

### Toast 与 Loading

```dart
Pop.toast(
  '同步完成',
  position: PopupPosition.bottom,
  duration: const Duration(seconds: 2),
);

final requestDone = fetchData();
Pop.toast(
  '正在同步',
  until: requestDone.then((_) {}),
);
```

`until` 允许外部 Future 决定关闭；同时传入 `duration` 和 `until` 时，任一条件
先完成即关闭。

```dart
final loading = Pop.loading(message: '第一阶段…');
Pop.loading(
  message: '第二阶段…',
  duration: const Duration(seconds: 2),
);

await loading.dismiss(); // 或 Pop.hideLoading()
```

Loading 使用稳定 key。重复调用不会叠加新层，而是更新当前内容并从新配置
重新开始计时；也可通过 `until` 或 handle 从外部关闭。

### Confirm

```dart
final confirmed = await Pop.confirm(
  title: '删除记录',
  content: '删除后无法恢复。',
  confirmText: '删除',
  cancelText: '取消',
  onConfirm: () => analytics.track('confirm_delete'),
  onCancel: () => analytics.track('cancel_delete'),
);

if (confirmed == true) {
  await deleteRecord();
}
```

`onConfirm` 和 `onCancel` 只对应各自按钮。遮罩、关闭按钮、返回键等关闭原因
不会伪装成取消按钮点击；业务仍可用 `Future<bool?>` 获取结果。

### Sheet 与 FlowSheet

```dart
final action = await Pop.sheet<String>(
  title: '选择操作',
  maxHeight: const SheetDimension.fraction(0.6),
  childBuilder: (dismiss) => ListView(
    shrinkWrap: true,
    children: [
      ListTile(title: const Text('复制'), onTap: () => dismiss('copy')),
      ListTile(title: const Text('删除'), onTap: () => dismiss('delete')),
    ],
  ),
);
```

Sheet 支持四个方向、键盘避让、边缘停靠以及
`fullBody` / `contentWhenAtTop` / `handleOnly` 三种拖拽策略。

```dart
final controller = FlowSheetController<bool>();
final completed = await Pop.flowSheet<bool>(
  controller: controller,
  initialPage: const FirstStepPage(),
  maxHeight: const SheetDimension.fraction(0.9),
);
```

FlowSheet 页面使用 `nav.push`、`nav.pop`、`nav.replace`、
`nav.completeCurrent` 和 `nav.closeAll`。它与 Sheet 共用渲染和关闭体系，但保留
内部页面栈与精细生命周期。

### Date 与 Menu

```dart
final birthday = await Pop.date(
  initialDate: DateTime(2000, 1, 1),
  minDate: DateTime(1960),
  maxDate: DateTime.now(),
);
```

Menu 使用合成图层跟随 Anchor，滚动时无需重新计算坐标：

```dart
final menuAnchor = PopupAnchorController();

PopupAnchor(
  controller: menuAnchor,
  child: IconButton(
    icon: const Icon(Icons.more_horiz),
    onPressed: () async {
      final action = await Pop.menu<String>(
        anchor: menuAnchor,
        builder: (dismiss) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('编辑'), onTap: () => dismiss('edit')),
            ListTile(title: const Text('删除'), onTap: () => dismiss('delete')),
          ],
        ),
      );
    },
  ),
);
```

Anchor 卸载时 Menu 会以 `PopupDismissReason.anchorDetached` 自动关闭。

## PopupHandle 与高级配置

便捷 API 面向日常调用；需要区分关闭原因、外部精确控制或定制策略时，使用
`openXxx(Config)`：

```dart
final handle = Pop.openSheet<String>(
  SheetConfig<String>(
    behavior: const PopupBehaviorConfig(
      channel: PopupChannel.sheet,
      tags: {'checkout'},
      routePolicy: PopupRoutePolicy.dismissWhenOwnerRouteChanges,
    ),
    builder: (context, handle) => ListTile(
      title: const Text('选择'),
      onTap: () => handle.complete('selected'),
    ),
  ),
);

final result = await handle.result;
final outcome = await handle.outcome;
await handle.dismissed;
```

- `complete(value)`：立即完成业务结果，然后执行退场动画。
- `dismiss()`：无业务结果地请求关闭。
- `result`：兼容 `T?` 业务结果。
- `outcome`：包含 value 与准确的 `PopupDismissReason`。
- `dismissed`：视觉节点彻底移除后完成。

完全自定义弹层使用 `Pop.custom(CustomPopupConfig)`，不再暴露巨型通用配置。

## 全局与外部关闭

```dart
await handle.dismiss();
await Pop.dismissTop();
await Pop.dismissChannel(PopupChannel.sheet);
await Pop.dismissTags({'checkout'});
await Pop.dismissAll();

final visible = Pop.hasChannel(PopupChannel.confirm);
final count = Pop.countChannel(PopupChannel.toast);
```

`key` 用于唯一资源/更新冲突，`tags` 用于业务批量管理，`channel` 用于类型查询
和批量关闭。它们不再隐式决定返回键或路由行为。

## 堆叠、返回键与跨路由

- Sheet / FlowSheet 上可继续显示 Toast、Confirm、Menu 等弹层。
- 系统返回键由 `Pop.routeObserver` 注册的 Route `PopEntry` 接管，优先处理最上层
  可拦截弹窗；弹窗处理完成后，下一次返回才退出路由。
- `PopupRoutePolicy.persist` 跨路由保留。
- `dismissWhenOwnerRouteChanges` 在所属路由变化时关闭。
- `dismissOnAnyRouteChange` 在任意根路由变化时关闭。
- FlowSheet 返回键优先退内部页面，位于首页时再关闭整个 FlowSheet。

不要创建多个全局 Host。测试需要隔离状态时可直接构造独立的 `PopupRuntime`。

更多内容见 [API_REFERENCE](docs/API_REFERENCE.md)、
[BEST_PRACTICES](docs/BEST_PRACTICES.md) 和可运行的 [example](example/lib/main.dart)。
