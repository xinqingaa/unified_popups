# 为何使用 Overlay 统一弹层，而不是官方 Dialog / Sheet

官方 `showDialog` / `showModalBottomSheet` 解决的是「怎么弹出一个 Material
组件」；`unified_popups` 解决的是「整个 App 的弹层治理」——谁能弹、叠在谁上面、
返回键谁先吃、路由变了关不关、异步回调会不会弹错页。

一句话：

> **官方 Dialog / Sheet 是页面级路由弹层；Overlay 统一方案是应用级弹层系统。**

实现细节见 [架构设计](ARCHITECTURE.md)；API 与策略字段见
[API 参考](API_REFERENCE.md)。

## 1. 核心差异

| 维度 | Overlay 统一方案（本包） | 官方 Dialog / ModalBottomSheet |
| --- | --- | --- |
| 本质 | 业务树之上的私有 Overlay + Entry 栈 | 向 Navigator **再 push 一条 Route** |
| 调用 | `Pop.xxx(Config)`，不需要 `BuildContext` | 需要 Context，或自行维护 `navigatorKey` |
| 返回栈 | 不污染页面路由栈 | 页面与弹层混在同一返回栈 |
| 多类型协作 | Toast / Loading / Confirm / Sheet / Menu 同一 Runtime | 通常各自实现，行为不一致 |
| 返回键 | 统一 `PopupBackPolicy` | 每个 Dialog / Sheet 各自 `PopScope` |
| 路由生命周期 | 显式 `routePolicy` / Ownership / `captureRoute` | 与展示时的 Route 隐式耦合 |
| 关闭原因 | `outcome.reason` 可区分 barrier / back / completed 等 | 多为 `T?`，取消与销毁常都是 `null` |

## 2. 调用位置：业务层能直接弹

产品里常见「接口失败弹 Confirm」「上传中弹 Loading」。这些逻辑经常落在 Service、
网络回调、ViewModel 或 Timer，而不是 Widget。

| | Overlay 统一方案 | 官方方案 |
| --- | --- | --- |
| 非 UI 层调用 | 全局门面直接 `Pop.*` | 层层传 Context，或全局 `navigatorKey` 硬扯 |
| 页面注入 | 不需要弹层专用 Controller | 常把展示职责绑在页面上 |

初始化只需根 Navigator 挂观察者与 Host：

```dart
MaterialApp(
  navigatorObservers: [Pop.routeObserver],
  builder: Pop.hostBuilder,
  home: const HomePage(),
);
```

## 3. 不污染 Navigator：弹层 ≠ 再压一层路由

官方 Dialog / Sheet 本质是 Route：

- 返回栈里混着真页面和弹层
- 侧滑 / 系统返回与页面导航绑死
- 多弹层、嵌套 Navigator、Tab 切换时容易互相干扰

Overlay 方案把弹层放在业务 child 之上的私有 Overlay：

- 开/关弹层不会为了展示而把弹层塞进页面路由栈
- 系统返回由 `Pop.routeObserver` 桥接，先交给
  `PopupController.handleBack()`，再才允许 Route `pop`
- Sheet / Menu 默认 `dismiss`（关弹层）；Confirm 可配 `block`（拦截但不关）

弹层变化是 Scene 声明式更新，不会为弹一个 Toast 去重建整棵 Navigator / 业务页。

## 4. 多类型共存：一张总表，而不是各自为政

真实 App 往往同时存在：

```text
Toast（提示）
Loading（等待）
Confirm（确认）
Sheet / FlowSheet（流程）
Menu / DropMenu（锚点菜单）
```

若用官方能力拼装，常见结果是：

- Toast → 自写 Overlay 或第三方
- Loading → Dialog 或 Overlay
- Confirm → `showDialog`
- Sheet → `showModalBottomSheet`
- Menu → `showMenu` / `PopupMenuButton`

叠放顺序、返回键、点遮罩、路由切换是否关闭，每套各写一套，行为难统一。

本包把它们收进同一 Entry 栈与同一套策略：

- Toast 有独立 lane，可浮在 Loading / Sheet / Confirm 之上
- Loading 默认全局 key + `updateExisting`，重复调用更新同一层，而不是叠一堆
- Confirm / Date 默认可归属当前顶层模态弹窗；父 Sheet 关闭时子弹窗先关
- 冲突策略可配置：`stack` / `replaceExisting` / `rejectNew` / `toggle` /
  `updateExisting`

关键问题不是「Dialog 能不能弹」，而是「十种弹层同时出现时，谁说了算」。

## 5. 与路由对齐，但不被路由绑架

官方 Dialog 常见两类翻车：

1. 请求回来时页面已 pop → 弹在错误页，或 Context 失效
2. 想跨页保留 Loading → 要么跟着原 Route 一起消失，要么残留难收口

本包用显式策略拆开这两类问题：

- `PopupRoutePolicy`：owner 变了关 / 任意根路由变关 / 跨路由保留
- `captureRoute()`：异步开始时记下归属页，回来再决定能否展示
- `PopupBackPolicy` 与 `routePolicy` 可组合，而不是「弹层 = 一条 Route」绑死

## 6. 结果语义更适合产品与排错

| | Overlay 统一方案 | 官方 Dialog |
| --- | --- | --- |
| 业务值 | `.result` → `T?` | `await showDialog` → `T?` |
| 关闭原因 | `handle.outcome`（barrier / back / completed / routeChanged…） | 通常无法区分 |
| 视觉移除 | `dismissed`（退出动画与节点移除后） | 与业务 Future 混在一起 |

强交互 Confirm、埋点与回归测试可以明确回答「为什么关的」。

## 7. 常见产品需求对照

| 需求 | 官方做法 | Overlay 统一方案 |
| --- | --- | --- |
| Confirm：只能点确定 / 取消 | 自关 barrier + 自拦返回 | **默认** `backPolicy: block` + `barrier.dismissible: false` |
| Sheet / Menu：侧滑关弹层，不退页面 | 每个 Route 自写 `PopScope` | 默认 `PopupBackPolicy.dismiss` |
| Loading 与 Confirm 同时出现 | 各写各的顺序与返回 | 同一 Controller，从视觉顶向下扫描返回 |
| 网络层直接弹提示 / 确认 | 很难干净做到 | 全局 `Pop.*` 天然支持 |
| 全局只保留一个 Loading | 自己用 flag / key 拼 | 全局 key + `updateExisting` |

Confirm 默认为强交互。若需要点遮罩或系统返回关闭，显式打开：

```dart
Pop.confirm(
  const ConfirmConfig(
    content: '可取消的确认',
    confirmAction: ConfirmAction.text('确定'),
    cancelAction: ConfirmAction.text('取消'),
    showCloseButton: true,
    barrier: PopupBarrierConfig(dismissible: true),
    behavior: PopupBehaviorConfig(
      backPolicy: PopupBackPolicy.dismiss,
    ),
  ),
);
```

## 8. 什么时候仍用官方 Dialog / Sheet

诚实边界反而更有说服力：

- 只要偶尔一个标准 Material / Cupertino Alert → 官方够用
- 必须与系统 Dialog 外观完全一致、且无多类型治理需求 → 官方更省事
- 弹层种类多、跨模块调用、需要统一返回 / 冲突 / Loading / Toast → 本包优势才明显

## 9. 相关文档

- [架构设计与实现原理](ARCHITECTURE.md) — Runtime、返回桥、Ownership、冲突策略
- [API 与参数参考](API_REFERENCE.md) — `backPolicy`、`routePolicy`、Handle / outcome
- [v1 与 v2 对比及迁移](MIGRATION_V1_TO_V2.md) — 包内历史模型迁移，不是与官方对比
