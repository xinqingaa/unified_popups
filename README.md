# unified_popups

Flutter 的统一全局弹窗系统。Toast、Loading、Confirm、Date、Sheet、FlowSheet、
Menu、DropMenu 和 Custom 共用一个 Runtime、一套冲突规则和一套生命周期。

v2 的公开创建形式只有一种：

```dart
Pop.xxx(Config) -> PopupOpenResult<T>
```

不需要 `BuildContext`、Popup 专用 `navigatorKey` 或页面间传递 Controller。

![Use unified_popups](doc/images/unified-popups-usage.png)

## 效果预览

Example Lab 中的真实效果（FitPulse demo）：

| Toast | Confirm | Sheet |
| :---: | :---: | :---: |
| ![Toast](doc/images/toast.jpg) | ![Confirm](doc/images/confirm.jpg) | ![Sheet](doc/images/sheet.jpg) |

| Sheet 叠加 Confirm | FlowSheet |
| :---: | :---: |
| ![Sheet + Confirm](doc/images/sheet_叠加confrim.jpg) | ![FlowSheet](doc/images/flowSheet.jpg) |

| DropMenu · 一级 | DropMenu · 二级 |
| :---: | :---: |
| ![DropMenu 一级](doc/images/dropMenu_一级菜单.jpg) | ![DropMenu 二级](doc/images/dropMenu_二级菜单.jpg) |

## 初始化

```dart
MaterialApp(
  navigatorObservers: [Pop.routeObserver],
  builder: Pop.hostBuilder,
  home: const HomePage(),
);
```

首次 Host 挂载前发起的 Popup 会暂存，Host 就绪后显示。

## 架构

业务、Service、网络回调等均可经 `Pop.xxx(Config)` 进入同一 Runtime；弹层渲染在
私有 Overlay 上，不污染页面路由栈。

![Unified Popups Architecture](doc/images/unified-popups-architecture.png)

分层职责与返回桥细节见 [架构设计](doc/ARCHITECTURE.md)；与官方 Dialog / Sheet
的取舍见 [为何使用 Overlay](doc/WHY_OVERLAY.md)。

## 生命周期

Entry 从 `created` 到 `disposed` 共用一套状态机。冲突策略决定叠放、拒绝、替换或
原地更新；关闭可由 complete / manual / back / barrier / route / lifetime 触发。
首个关闭请求决定 `result` / `outcome`，退出动画结束后 `dismissed` 才完成，后续
关闭幂等。

![Popup Entry Lifecycle](doc/images/unified-popups-lifecycle.png)

## 先理解返回模型

`Pop.xxx(config)` 本身是同步调用，始终返回 `PopupOpenResult<T>`。`await` 不决定
返回的是结果还是 Handle；真正的区别是调用方从 `PopupOpenResult` 读取什么。

| 目的 | 写法 | 得到什么 |
| --- | --- | --- |
| 不关心后续 | `Pop.toast(config)` | 忽略打开决策 |
| 等待业务值 | `await Pop.confirm(config).result` | `bool?` |
| 外部控制 | `Pop.loading(config).requireHandle()` | `PopupHandle<void>` |
| 处理冲突 | `final opened = Pop.menu(config)` | `PopupOpenResult<T>` |

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

普通业务结果：

```dart
final confirmed = await Pop.confirm(
  const ConfirmConfig(
    title: '删除记录',
    content: '删除后无法恢复。',
    confirmAction: ConfirmAction.text('删除'),
    cancelAction: ConfirmAction.text('取消'),
  ),
).result;
```

外部命令式控制：

```dart
final handle = Pop.loading(
  const LoadingConfig.text('上传中'),
).requireHandle();

await handle.dismiss();
```

`.result` 是便捷但有损的业务值：用户取消、外部关闭、冲突拒绝或 toggle 都可能得到
`null`。需要准确原因时读取 `handle.outcome`；冲突可能合法发生时使用
`handleOrNull`，不要使用可能抛出 `StateError` 的 `requireHandle()`。

## 推荐在 App 内再封装一层

SDK 的 Config 负责完整能力；真实 App 通常还需要统一视觉、中文文案、埋点、错误
处理和默认策略。建议业务页面依赖自己的 `AppPop`：

```dart
abstract final class AppPop {
  static void success(String message) {
    Pop.toast(
      ToastConfig.text(message, type: ToastType.success),
    );
  }

  static Future<bool> confirm({
    required String title,
    required String content,
  }) async {
    return await Pop.confirm(
          ConfirmConfig(
            title: title,
            content: content,
            confirmAction: const ConfirmAction.text('确定'),
            cancelAction: const ConfirmAction.text('取消'),
          ),
        ).result ??
        false;
  }
}
```

业务使用：

```dart
final confirmed = await AppPop.confirm(
  title: '删除记录',
  content: '删除后无法恢复',
);
```

Example 中 FitPulse 产品区使用 `AppPop`，API Lab 保留原始 `Pop.xxx(Config)`，分别
展示真实项目封装和 SDK 完整契约。

## Builder Handle

Sheet、Menu、Custom 的 Builder 会自动获得 Handle，不需要 `requireHandle()`：

```dart
final selected = await Pop.sheet<String>(
  SheetConfig<String>(
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

- `complete(value)`：业务正常完成并携带结果。
- `dismiss()`：取消或无结果关闭。
- `result`：只返回 nullable value。
- `outcome`：返回 value 与准确 `PopupDismissReason`。
- `dismissed`：退出动画完成、视觉节点移除后完成。

## Loading 与 until

Loading 的载荷构造互斥且明确：

```dart
const LoadingConfig.indicator();
const LoadingConfig.text('提交中');
const LoadingConfig.content(MyLoadingContent());
```

`PopupLifetime.until` 在 Future 成功或失败 settled 时都会关闭 Popup，业务异常仍由
业务调用方处理：

```dart
final request = saveData();

Pop.loading(
  LoadingConfig.text(
    '保存中',
    lifetime: PopupLifetime.until(request),
  ),
);

await request;
```

默认 Loading 使用全局 key 与 `updateExisting`，重复调用更新同一个 Entry 和 Handle。

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
          builder: (context, handle) => ListTile(
            title: const Text('编辑'),
            onTap: () => handle.complete('edit'),
          ),
        ),
      ).result;
    },
  ),
);
```

Menu 默认使用透明、可点击关闭的 Barrier，并阻止底层滚动。只有需要底层滚动且菜单
跟随 Anchor 时才传 `PopupBarrierConfig.hidden()`。

DropMenu 使用 `DropMenu.single` 或 `DropMenu.nested`；标准 DropMenu 默认全局
`replaceExisting`。

## 批量管理

```dart
await Pop.dismissTop();
await Pop.dismissChannel(PopupChannel.sheet);
await Pop.dismissTags({'network'});
await Pop.dismissAll();
```

`PopupBehaviorConfig` 的 channel 由具体能力固定。业务只配置 key、tags、冲突、路由
和返回策略。已有 Behavior 需要清空 key 时使用 `copyWith(clearKey: true)`。

## 文档

- [为何使用 Overlay，而不是官方 Dialog / Sheet](doc/WHY_OVERLAY.md)
- [架构设计与实现原理](doc/ARCHITECTURE.md)
- [完整 API、返回模型与参数参考](doc/API_REFERENCE.md)
- [v1 与 v2 对比及迁移](doc/MIGRATION_V1_TO_V2.md)

运行 Example：

```bash
cd example
flutter run
```
