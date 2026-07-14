# v2 架构说明

```text
业务页面 / 服务层 / 流程层
          │
          ▼
      全局 Pop 门面
          │
          ▼
 PopupRuntime ── 路由观察 / Host 所有权
          │
          ▼
 PopupController ── Entry / 策略 / Handle / Outcome
          │ 状态快照
          ▼
 单一 PopupHost + PopupScene
          │
          ├─ Toast / Loading 渲染器
          ├─ Confirm / Date 渲染器
          ├─ Sheet / FlowSheet 渲染器
          ├─ Menu 渲染器
          └─ Custom 渲染器
```

## 各层职责

- `Pop` 是业务唯一推荐入口。它持有默认 Runtime，并提供便捷 API、类型化
  Config API 和全局管理 API。
- `PopupRuntime` 持有一个 Controller、一个稳定路由观察者和一个 Host 绑定；
  不依赖 Navigator key 或业务 `BuildContext`。
- `PopupController` 是与 UI 无关的状态机，处理冲突策略、路由、返回键、父子
  归属、自动关闭竞争、Toast 排队、Outcome 和资源收口。
- `PopupHost` 根据 Controller 快照声明式渲染弹窗，应用 child 保持稳定。
- 各 Renderer 只处理对应类型的布局和交互。Channel 只用于查询，不隐式决定行为。

## 生命周期

```text
open → pendingHost / queued → entering → visible
                                      │
complete / dismiss / 策略 / 外部事件 ─┘
                  ↓
确定 outcome → exiting → 移除 Renderer → dismissed
```

业务完成与视觉移除是两个阶段。所有关闭路径都是幂等的，并且只会记录一个
`PopupDismissReason`。更新 Loading 或 Toast 时递增 lifetime generation，旧的
Timer 或 Future 即使稍后完成，也不能关闭新配置。

## 堆叠和导航

所有类型共享一个有序 Entry 列表，因此 Confirm、Menu、Toast 可以显示在 Sheet
或 FlowSheet 上方，而不需要关闭下层弹窗。

稳定的路由观察者会在当前根 Route 注册 `PopEntry`。系统返回先交给最上层符合
条件的弹窗；FlowSheet 则先委托给内部 Navigator。路由归属在打开 Config 时
捕获，跨路由保留、所属路由变化关闭、任意路由变化关闭均为显式策略。

## 性能模型

- 一个 Host 和一个私有 Overlay，替代每个弹窗一个全屏 OverlayEntry。
- 应用 child 保持稳定，只有 PopupScene 监听状态快照。
- 无 Barrier 的 Toast 共享位置 lane。
- Loading 更新保留同一个逻辑 Entry 和 Handle。
- Sheet 拖拽直接修改统一动画进度，Renderer 缓存重业务 child，不随每次指针移动
  重建。
- AnimationController 跟随 Widget 正常创建和销毁，不使用跨 State 对象池。

## 为什么保留全局 Pop

业务层不需要 `BuildContext` 是本项目的核心约束。Service、状态机、Flow、Timer
回调等场景无法可靠获得页面 context，如果强制使用 context，会产生跨异步间隙、
错误 Navigator、失效 Element 等问题。

因此 v2 保留全局 `Pop` 门面，但移除了旧版全局单例承担的 UI、Overlay、动画和
业务策略。全局层现在只负责定位默认 Runtime；真正状态由可独立构造和测试的
Controller 管理，渲染由 Host 管理。

这与旧架构的关键差别是：保留全局调用体验，不保留全局巨型对象的职责耦合。
