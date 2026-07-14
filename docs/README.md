# unified_popups 文档

推荐阅读顺序：

1. [根 README](../README.md)：安装、初始化和主要调用方式。
2. [API 参数参考](API_REFERENCE.md)：v2 完整调用签名、参数、默认值和语义。
3. [最佳实践](BEST_PRACTICES.md)：Service 调用、外部关闭、路由和堆叠建议。
4. [v1 → v2 API 能力对照](API_PARITY_V2.md)：破坏性升级映射。
5. [迁移指南](MIGRATION_V1_TO_V2.md)：项目迁移步骤与风险检查。
6. [v2 架构说明](ARCHITECTURE_V2.md)：Runtime、Controller、Host 和生命周期。
7. [v2 重构计划](PLAN_V2.md)：架构决策和阶段计划归档。

可运行示例位于 [`example/lib`](../example/lib)：

| 入口 | 覆盖能力 |
| --- | --- |
| 启动首页 | 双入口：FitPulse 真实 App / API 展柜 |
| FitPulse | Loading 分阶段、Toast、Confirm、Sheet、Menu、FlowSheet |
| API 展柜 | 按类型分页的整库能力矩阵（含通用 Config）；AppBar 常驻 Entry 计数 |

详见 [`example/README.md`](../example/README.md)。

最小接入：

```dart
MaterialApp(
  navigatorObservers: [Pop.routeObserver],
  builder: Pop.hostBuilder,
);
```

迁移到 v2 后，不再初始化 `PopupManager`，也不再需要 Popup 专用
`navigatorKey` 或 `PopScopeWidget`。
