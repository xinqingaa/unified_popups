# unified_popups Example

启动后进入**双入口首页**：

1. **FitPulse 真实 App** — 四个业务 Tab，用产品动机触发弹窗。
2. **API 展柜** — 按类型分页验收整库能力；AppBar 右上角常驻 Entry 计数。

```bash
cd example
flutter pub get
flutter run
```

## FitPulse（真实用法）

| 区域 | 覆盖能力 |
| --- | --- |
| 今日 | Loading 分阶段更新、Confirm、各类 Toast |
| 训练 | Sheet（含 dock）、Menu Anchor、训练 FlowSheet |
| 数据 | Date、Loading `until`、指标 Sheet |
| 我的 | 资料 Sheet、健康档案 FlowSheet、设置 Confirm |

AppBar ⋯ 也可跳到 API 展柜。

## API 展柜（能力矩阵）

| 子页 | 覆盖 |
| --- | --- |
| 通用 Config | 两层 API、Barrier / Behavior / Lifetime / tags |
| Toast | 类型/位置/样式、duration/until、lane 排队、key 更新、toggle、barrier |
| Loading | 原地更新、长文案、分位置双 Loading、Handle、until、返回 block |
| Confirm / Date | 按钮 vs 遮罩/返回语义、outcome、堆叠、日期样式 |
| Sheet | 四方向、三种拖拽（指示器仅底部）、键盘、dockToEdge、堆叠 |
| FlowSheet | 全屏/半屏迷你栈、返回委托、产品 Flow 入口 |
| Menu Anchor | 默认透明 Barrier 点外关闭、showBarrier: false 滚动跟随、边缘 placement、卸载关闭 |
| Custom / Handle | CustomPopup、outcome/dismissed、tags/channel、查询 API |
| 策略 | 返回顺序、persist/owner 路由、captureRoute、Ownership |
| 异步边界 | Future/Stream/Timer/build 阶段调用 |

包文档见 [文档中心](../docs/README.md)。
