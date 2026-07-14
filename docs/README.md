# unified_popups 文档

推荐阅读顺序：

1. [根 README](../README.md)：安装、初始化和主要调用方式。
2. [API Reference](API_REFERENCE.md)：v2 公共 API、Handle、策略和生命周期。
3. [Best Practices](BEST_PRACTICES.md)：Service 调用、外部关闭、路由和堆叠建议。
4. [v1 → v2 API Parity](API_PARITY_V2.md)：破坏性升级映射。
5. [Migration Guide](MIGRATION_V1_TO_V2.md)：项目迁移步骤与风险检查。
6. [v2 Architecture](ARCHITECTURE_V2.md)：Runtime、Controller、Host 和生命周期。
7. [v2 Architecture Plan](PLAN_V2.md)：架构决策和阶段计划归档。

可运行示例位于 [`example/lib`](../example/lib)：

| 页面 | 覆盖能力 |
| --- | --- |
| 今日 | Loading / Toast / Confirm |
| 训练 | Sheet / Menu Anchor / FlowSheet |
| 数据 | Date / Loading |
| 我的 | Confirm / Date / 业务 Flow |
| Lab | 异步无 context 调用、Handle 外部关闭、堆叠、返回键与全局批量关闭 |

最小接入：

```dart
MaterialApp(
  navigatorObservers: [Pop.routeObserver],
  builder: Pop.hostBuilder,
);
```

迁移到 v2 后，不再初始化 `PopupManager`，也不再需要 Popup 专用
`navigatorKey` 或 `PopScopeWidget`。
