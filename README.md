# unified_popups

[![pub package](https://img.shields.io/pub/v/unified_popups.svg)](https://pub.dev/packages/unified_popups)
[![likes](https://img.shields.io/pub/likes/unified_popups?logo=flutter)](https://pub.dev/packages/unified_popups/score)
[![points](https://img.shields.io/pub/points/unified_popups?logo=flutter)](https://pub.dev/packages/unified_popups/score)
[![popularity](https://img.shields.io/pub/popularity/unified_popups?logo=flutter)](https://pub.dev/packages/unified_popups/score)
[![license](https://img.shields.io/github/license/xinqingaa/unified_popups)](https://github.com/xinqingaa/unified_popups/blob/master/LICENSE)

**语言 / Languages:** [中文](README.md) · [English](README_EN.md)

**Flutter Overlay 统一弹层系统**：Toast / Loading / Confirm / Date / Sheet /
FlowSheet / Menu / DropMenu / Custom —— **同一 Runtime、同一套冲突与生命周期、
同一套返回键与路由策略**。

不需要 `BuildContext`，不污染页面路由栈，Service / 网络回调 / ViewModel 也能直接弹。

```dart
Pop.xxx(Config) -> PopupOpenResult<T>
```

![Use unified_popups](doc/images/unified-popups-usage.png)

## 为什么选它

官方 `showDialog` / `showModalBottomSheet` 解决的是「弹出一个 Material
组件」；真实 App 还要解决：

| 痛点 | unified_popups |
| --- | --- |
| Service / 异步回调里没有 Context | 全局 `Pop.*`，无需传 Context |
| Toast、Loading、Confirm、Sheet 各写一套 | 一种打开模型，策略可配置 |
| 弹层塞进 Navigator，返回栈混乱 | 私有 Overlay，页面路由不被污染 |
| 返回键、侧滑、路由跳转行为不一致 | 统一 `backPolicy` / `routePolicy` |
| Loading 重复弹、Flow 多页关不干净 | key 冲突策略 + FlowSheet 内页栈 |

一句话：**官方能力是页面级路由弹层；本包是应用级弹层治理。** 详见
[为何使用 Overlay](doc/WHY_OVERLAY.md)。

## 能力一览 · 什么时候用哪种

| 能力 | 典型场景 | 默认返回键 |
| --- | --- | --- |
| **Toast** | 成功 / 失败 / 轻提示，不打断操作 | 忽略（不拦截） |
| **Loading** | 提交、上传、拉数等待 | 拦截（防误触退出） |
| **Confirm** | 删除、放弃编辑、二次确认 | 拦截（必须点按钮） |
| **Date** | 生日、预约日等日期选择 | 关闭弹层 |
| **Sheet** | 选项列表、筛选、单页表单 | 关闭弹层 |
| **FlowSheet** | 多步申请 / 向导（内嵌页面栈） | 先 pop 内页，再关 Sheet |
| **Menu** | 锚点「更多」自定义菜单 | 关闭弹层 |
| **DropMenu** | 筛选条、设置行、可嵌套分组菜单 | 关闭弹层 |
| **Custom** | 任意内容接入同一套生命周期 | 可配置 |

## 效果预览

截图来自 Example（FitPulse / API Lab）真实运行效果。

### Toast · 轻反馈

保存成功、网络错误、复制完成 —— 不打断当前页。

![Toast](doc/images/toast.jpg)

### Loading · 异步等待

提交、上传、拉取支付；可用 `PopupLifetime.until` 在 Future settled 后自动关掉。

![Loading](doc/images/loading.jpeg)

### Confirm · 强确认

删除、清空、离开未保存页 —— 默认点遮罩 / 返回键都关不掉。

![Confirm](doc/images/confirm.jpg)

### Sheet · 单页面板

选项列表、筛选、简易表单；可与 Confirm 叠加以做「面板内二次确认」。

| Sheet | Sheet + Confirm |
| :---: | :---: |
| ![Sheet](doc/images/sheet.jpg) | ![Sheet + Confirm](doc/images/sheet_叠加confrim.jpg) |

### FlowSheet · 多步流程

分步填写、申请向导：系统返回先退内页，再关整张 Sheet；Confirm 盖在上面时仍可拦截返回。

![FlowSheet](doc/images/flowSheet.jpg)

### DropMenu · 锚点菜单

筛选条一级选项，或设置里可展开的二级分组（含 liquid glass 样式）。

| 一级筛选 | 二级设置 |
| :---: | :---: |
| ![DropMenu 一级](doc/images/dropMenu_一级菜单.jpg) | ![DropMenu 二级](doc/images/dropMenu_二级菜单.jpg) |

## 30 秒上手

```yaml
dependencies:
  unified_popups: ^2.0.4
```

```dart
MaterialApp(
  navigatorObservers: [Pop.routeObserver],
  builder: Pop.hostBuilder,
  home: const HomePage(),
);
```

首次 Host 挂载前发起的 Popup 会暂存，Host 就绪后显示。

```dart
Pop.toast(const ToastConfig.text('已保存', type: ToastType.success));

Pop.loading(const LoadingConfig.text('提交中'));
try {
  await submit();
} finally {
  Pop.dismissChannel(PopupChannel.loading);
}

final ok = await Pop.confirm(
  const ConfirmConfig(
    title: '删除记录',
    content: '删除后无法恢复。',
    confirmAction: ConfirmAction.text('删除'),
    cancelAction: ConfirmAction.text('取消'),
  ),
).result;
```

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

Menu 默认使用透明、可点击/拖动关闭的 Barrier（`dismissOnDrag: true`），并阻止底层
滚动。只有需要底层滚动且菜单跟随 Anchor 时才传 `PopupBarrierConfig.hidden()`。

DropMenu 使用 `DropMenu.single` 或 `DropMenu.nested`；标准 DropMenu 默认全局
`replaceExisting`。

## 批量管理

```dart
await Pop.dismissTop();
await Pop.dismissChannel(PopupChannel.sheet);
await Pop.dismissTags({'network'});
await Pop.dismissAll();

// 临时挂起（跳转详情后恢复）
final paused = Pop.pauseLatest(PopupChannel.sheet);
try {
  await openDetail();
} finally {
  if (paused != null) Pop.resume(paused.id);
}
```

`PopupBehaviorConfig` 的 channel 由具体能力固定。业务只配置 key、tags、冲突、路由
和返回策略。已有 Behavior 需要清空 key 时使用 `copyWith(clearKey: true)`。

## 文档

- [English README](README_EN.md)
- [调用方规范用法（Skill）](skills/unified-popups-usage/SKILL.md) — 应用内包一层、按需读文档，勿猜 API
- [为何使用 Overlay，而不是官方 Dialog / Sheet](doc/WHY_OVERLAY.md)
- [架构设计与实现原理](doc/ARCHITECTURE.md)
- [完整 API、返回模型与参数参考](doc/API_REFERENCE.md)
- [v1 与 v2 对比及迁移](doc/MIGRATION_V1_TO_V2.md)

运行 Example：

```bash
cd example
flutter run
```
