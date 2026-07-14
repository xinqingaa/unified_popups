# 更新日志

本文记录 `unified_popups` 的重要变化。版本号遵循语义化版本规范。

## 2.0.0

### 架构

- 使用 `Pop + PopupRuntime + PopupController + PopupHost` 替换旧的
  `PopupManager`、navigatorKey 初始化和“每个弹窗一个全屏 OverlayEntry”。
- 为每种弹窗建立独立 Config/Renderer，并引入统一 `PopupHandle`，明确区分业务
  Outcome 与视觉移除。
- 删除 `AnimationControllerPool`、巨型 `PopupConfig`、由 `PopupType` 驱动行为、
  `PopScopeWidget`、旧路由观察者和旧 `part` API。
- 应用只需接入 `Pop.hostBuilder` 和 `Pop.routeObserver`；业务调用保持全局且不依赖
  `BuildContext`。

### 生命周期和管理

- 新增 key、channel、tags 以及冲突、路由、返回键、父子归属、遮罩、自动关闭和
  生命周期策略。
- 新增 `PopupOutcome` 和完整 `PopupDismissReason`。
- 新增按 Handle、顶部、channel、tags 和全部弹窗关闭的 API。
- Host 挂载前的调用进入 pendingHost；Host 就绪后继续展示。
- Toast 每个位置最多显示 3 个，超出后按 FIFO 排队，排队期间不启动 lifetime。

### 类型能力

- Loading 重复调用更新原逻辑 Entry，保留稳定 Handle，并从新配置重新开始计时。
- Toast 和 Loading 支持倒计时、外部 Future、Handle 手动关闭或组合条件。
- Confirm 新增按钮专属 `onConfirm` 与 `onCancel`，同时保留
  `Future<bool?>` 业务结果。
- Sheet 与 FlowSheet 统一四方向 Renderer、拖拽进度和退出动画；重业务 child
  不随拖拽指针反复重建。拖拽指示器仅底部方向渲染。
- 恢复 Sheet 双层 SafeArea（对齐层扣状态栏 + panel 内始终 SafeArea），修复
  `fraction(1)` 全屏底部 Sheet 顶到刘海，以及上/左/右方向内容顶入状态栏的问题。
- FlowSheet 接入统一外层 Handle，同时保留内部页面栈、页面结果和生命周期。
- Menu 改为 `PopupAnchorController + PopupAnchor`，随滚动和布局变化自动跟随，
  Anchor 卸载时自动关闭；**默认无全屏遮罩**（`showBarrier: false`），需要点外部
  关闭时再显式打开。
- 新增 `CustomPopupConfig`，自定义内容也接入统一生命周期和全局管理。

### 示例和文档

- FitPulse Example 全量迁移到 v2。
- Example 启动页双入口：FitPulse 真实 App / API 展柜；展柜 AppBar 常驻 Entry
  计数，并新增「通用 Config」页说明两层 API。
- Loading 有文案时自适应宽高；`LoadingConfig.position` 可错开多实例。
- 技术实验室按类型分页覆盖整库能力；业务 Tab 保留真实用法示例。
- 重写 README、API 参数参考、最佳实践、架构说明和 v1 → v2 迁移指南。
- 项目使用文档统一为中文。

## 1.3.0

### FlowSheet

- 新增 `Pop.flowSheet`，支持内部 `push`、`pop`、`replace`、
  `completeCurrent` 和 `closeAll`。
- 新增 `FlowSheetController`、`FlowSheetPage`、`FlowSheetPageState` 以及
  `onLoad`、`onShow`、`onHide`、`onRemove`、`onClose` 页面生命周期。
- 支持页面级拖拽模式与自定义内部路由构建器。

### Sheet 和路由

- 新增 `fullBody`、`contentWhenAtTop`、`handleOnly` 三种拖拽模式。
- Sheet 新增拖拽指示器、键盘避让、动态拖拽模式和返回回调。
- 路由观察者补齐路由 remove 时的弹窗清理。
- Example 增加 FitPulse 业务流程和技术实验室。

## 1.2.2

- 优化旧版 `PopScopeWidget` 重建范围。
- 尝试使用 AnimationController 对象池降低分配；该方案在 v2 中因生命周期风险
  被完整移除。
- 优化旧版 Menu RenderBox 和屏幕尺寸读取。

## 1.2.1

- Toast 新增 `messageWidget`。
- Confirm 新增标题、内容和按钮 Widget 自定义能力。
- Sheet 新增 `titleWidget`。
- Confirm 新增 `onConfirm` 和 `onCancel`。

## 1.2.0

- 各类型新增动画时长和曲线配置。
- 新增旧版 `PopupRouteObserver` 与路由变化清理。
- 优化 Sheet 动画裁剪、边缘停靠、键盘适配和异步构建阶段调用。
- Toast 新增点击切换和自定义点击回调。
- Menu 新增 padding、constraints、decoration。

## 1.1.17

- 修复已知弹窗交互问题。

## 1.1.16

- 修复 Sheet 动画裁剪溢出。

## 1.1.15

- 修复弹窗关闭后的残留区域问题。

## 1.1.14

- 修复多次触发 Loading 后不可点击区域残留。

## 1.1.13

- Toast 新增第二状态文案、图片、类型、颜色和点击切换能力。

## 1.1.12

- 优化旧版弹窗基础行为。

## 1.1.11

- 修复 build 阶段插入 Overlay 导致的 `setState` 错误。

## 1.1.10

- 简化 Loading API。
- 新增按旧 `PopupType` 批量关闭能力。

## 1.1.9

- Menu 新增 padding、constraints 和 decoration。

## 1.1.8

- Sheet 新增 `dockToEdge` 和 `edgeGap`。

## 1.1.7

- 修复 Sheet 与底部区域交互问题。

## 1.1.6

- Toast 新增自定义图片着色。

## 1.1.5

- Confirm 按钮新增自定义边框。

## 1.1.4

- Toast 新增自定义本地图片、图片大小与横竖布局。
- Loading 新增自定义旋转指示器。

## 1.1.3

- 优化基础弹窗展示。

## 1.1.2

- 仅在底部 Sheet 应用键盘避让内边距。

## 1.1.1

- 修复基础样式和布局问题。

## 1.1.0

- 建立统一 `Pop` 调用入口。
- 增加 Toast、Loading、Confirm、Sheet、Date、Menu 的统一管理。

## 1.0.3 及更早版本

- 完成项目初始发布和基础弹窗能力。
