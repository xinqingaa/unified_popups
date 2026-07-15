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

- 每种能力收敛为唯一的 `Pop.xxx(Config)` 入口，删除全部 `openXxx` 和零散参数
  重载；Config 成为唯一公开参数契约，`PopupTypeApi` 降为内部适配层。
- 所有创建 API 统一返回 `PopupOpenResult<T>`，并新增 `.result` 便捷访问，完整表达
  opened、updated、toggledClosed 与 rejected；打开决策不再伪装成 Entry 关闭原因。
- 收敛 package 导出面，`PopupRuntime`、`PopupController`、`PopupHost`、
  `PopupScene` 和 Renderer Base 类型不再构成稳定公开 API。
- `PopupBehaviorConfig` 不再接收 channel；channel 由具体能力内部固定，避免无效
  Config/channel 组合。
- `PopupLifetime.until` 改为观察 Future settled：成功或失败都会以
  `externalEvent` 关闭，业务异常继续由原 Future 调用方处理。
- PopupController 将 Entry Record、Handle 实现和 lifetime 资源拆入独立内部模块，
  Controller 继续作为唯一状态与迁移权威。
- 新增 key、channel、tags 以及冲突、路由、返回键、父子归属、遮罩、自动关闭和
  生命周期策略。
- 新增 `PopupOutcome` 和完整 `PopupDismissReason`。
- 新增按 Handle、顶部、channel、tags 和全部弹窗关闭的 API。
- Host 挂载前的调用进入 pendingHost；Host 就绪后继续展示。
- Toast 每个位置最多显示 3 个，超出后按 FIFO 排队，排队期间不启动 lifetime。

### 类型能力

- 标准 DropMenu 使用默认全局 key + `replaceExisting`，不同结果泛型之间也能安全
  替换，保证同时只有一个标准 DropMenu。
- 新增主题化液态玻璃组件，以及一级/二级数据驱动的 `Pop.dropMenu`；支持
  系统/自定义勾选图标、禁用项、保持打开的设置项和完整
  颜色覆盖。
- DropMenu 默认宽度收窄为 140–240，末项自动移除底部分隔线；液态玻璃降低默认
  背景不透明度，并新增独立于普通边框的 `topHighlightColor`。
- 二级 Section 新增尺寸 + 淡入展开/收起动画；选择二级选项只收起当前 Section，
  外层菜单保持显示，并通过 `onSelected` / Item `onTap` 通知业务。
- DropMenu 打开时只淡入菜单文字/图标，液态玻璃与 BackdropFilter 保持不透明，
  避免父级 OpacityLayer 导致模糊在末帧突然变实；BackdropFilter 仍使用
  `BlendMode.src` 作为额外防护。通用 LiquidGlass 仍保留默认 `srcOver`。
- Menu `auto` 改为先测量实际菜单尺寸，再结合 SafeArea、offset 和上下左右溢出
  决定 placement，并在菜单会话内锁定方向。
- 修正 Menu 在透明可见 Barrier 下的 Follower 命中范围，菜单内容可正常接收点击，
  点击外部仍由 Barrier 关闭。
- Loading 重复调用更新原逻辑 Entry，保留稳定 Handle，并从新配置重新开始计时。
- Loading 使用 `indicator/text/content` 三种互斥构造器；Confirm 和 Sheet Header
  拒绝同时提供 String 与 Widget 同义载荷。
- Toast 和 Loading 支持倒计时、外部 Future、Handle 手动关闭或组合条件。
- Confirm 新增按钮专属 `onConfirm` 与 `onCancel`，同时保留
  `Future<bool?>` 业务结果。
- Confirm 默认改为贴底分割线按钮（`ConfirmButtonStyle.divider`）；可通过
  `buttonStyle: ConfirmButtonStyle.filled` 恢复圆角填充/胶囊风格，并支持
  `dividerColor`、`dividerWidth`、`buttonSpacing` 等细调。
- Sheet 与 FlowSheet 统一四方向 Renderer、拖拽进度和退出动画；重业务 child
  不随拖拽指针反复重建。拖拽指示器仅底部方向渲染。
- 恢复 Sheet 双层 SafeArea（对齐层扣状态栏 + panel 内始终 SafeArea），修复
  `fraction(1)` 全屏底部 Sheet 顶到刘海，以及上/左/右方向内容顶入状态栏的问题。
- FlowSheet 接入统一外层 Handle，同时保留内部页面栈、页面结果和生命周期。
- Menu 改为 `PopupAnchorController + PopupAnchor`，随滚动和布局变化自动跟随，
  Anchor 卸载时自动关闭；**默认透明 Barrier**（与 DropMenu 一致：点外关闭、
  底层不可滚）。需要滚动跟随时传 `PopupBarrierConfig.hidden()`。
- 新增 `CustomPopupConfig`，自定义内容也接入统一生命周期和全局管理。

### 示例和文档

- FitPulse 产品区新增 App 级 `AppPop` 门面，统一品牌默认值与普通业务返回；产品流程
  覆盖 Toast、Loading、Confirm、Date、Sheet、FlowSheet、Menu、DropMenu 和 Custom，
  API Lab 保留原始 SDK 契约。
- 重写 `PopupOpenResult`、`.result`、`requireHandle()`、Builder Handle、Outcome 与
  dismissed 的调用决策和时序说明。
- Example 增加 Toast/Loading `until` 失败关闭、统一 `PopupOpenResult` 和 DropMenu
  全局替换验收入口。
- 详细文档收敛为架构原理、完整 API 参考、v1/v2 对比迁移三篇核心文档。
- Menu Lab 新增通用一级筛选和二级设置展开示例。
- FitPulse Example 全量迁移到 v2。
- Example 启动页双入口：FitPulse 真实 App / API 展柜；新增「通用 Config」页说明
  Config-first 单入口 API。
- Loading 有文案时自适应宽高；`LoadingConfig.position` 可错开多实例。
- 技术实验室按类型分页覆盖整库能力；业务 Tab 保留真实用法示例。
- Confirm Lab 增加默认线条与胶囊填充对照示例。
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
