# unified_popups Example

启动后进入**双入口首页**：

1. **FitPulse 真实 App** — 四个业务 Tab，用产品动机触发弹窗。
2. **API 展柜** — 按类型分页验收原始 SDK 能力。

```bash
cd example
flutter pub get
flutter run
```

## FitPulse（真实用法）

FitPulse 产品区统一通过 `lib/app/app_pop.dart` 二次封装调用 SDK。业务页面不重复
处理 `.result`、`requireHandle()`、中文文案和公共视觉；API 展柜则保留原始
`Pop.xxx(Config)`，用于解释完整契约。

| 区域 | 覆盖能力 |
| --- | --- |
| 今日 | AppLoading 分阶段更新、Confirm、成功/警告/错误 Toast |
| 训练 | DropMenu 筛选、Sheet、Menu Anchor、训练 FlowSheet |
| 数据 | Date、Loading 任务绑定、指标 Sheet |
| 我的 | 资料 Sheet、健康档案 FlowSheet、Confirm、Custom 会员卡 |

AppBar ⋯ 也可跳到 API 展柜。

## API 展柜（能力矩阵）

| 子页 | 覆盖 |
| --- | --- |
| 通用 Config | Config-first 单入口、统一 PopupOpenResult、Barrier / Behavior / Lifetime / tags |
| Toast | 类型/位置/样式、until 成功/失败、lane 排队、key 更新、toggle、barrier |
| Loading | 原地更新、until 失败关闭、分位置双 Loading、Handle、返回 block |
| Confirm / Date | 按钮 vs 遮罩/返回语义、outcome、堆叠、日期样式 |
| Sheet | 四方向、三种拖拽（指示器仅底部）、键盘、dockToEdge、堆叠 |
| FlowSheet | 全屏/半屏迷你栈、返回委托、产品 Flow 入口 |
| Menu Anchor | DropMenu 全局替换、透明 Barrier、滚动跟随、placement、卸载关闭 |
| Custom / Handle | CustomPopup、outcome/dismissed、tags/channel、查询 API |
| 策略 | 返回顺序、persist/owner 路由、captureRoute、Ownership |
| 异步边界 | Future/Stream/Timer/build 阶段调用 |

包文档见 [为何使用 Overlay](../doc/WHY_OVERLAY.md)、[架构](../doc/ARCHITECTURE.md)、
[API 参考](../doc/API_REFERENCE.md) 和 [迁移指南](../doc/MIGRATION_V1_TO_V2.md)。
