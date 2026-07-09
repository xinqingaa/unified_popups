# Unified Popups 文档中心

面向 Flutter 的统一弹窗方案。所有能力通过 `Pop` 静态 API 调用，覆盖 toast、loading、confirm、sheet、**flowSheet**、date、menu。

## 文档导航

| 文档 | 说明 |
|------|------|
| [API 参考](API_REFERENCE.md) | 参数表与返回值（权威） |
| [最佳实践](BEST_PRACTICES.md) | 选型、生命周期、路由与返回键 |
| [根 README（中文）](../README.md) | 快速开始与能力一览 |
| [English README](../README_EN.md) | English quick start |
| [FitPulse Example](../example/) | 场景化演示 App |

## 安装

```yaml
dependencies:
  unified_popups:
```

## 初始化

必须使用**同一个** `navigatorKey`，并注册路由观察者与返回拦截：

```dart
final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(MyApp(navigatorKey: navigatorKey));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PopupManager.initialize(navigatorKey: navigatorKey);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({required this.navigatorKey, super.key});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [PopupRouteObserver()],
      builder: (context, child) => PopScopeWidget(
        child: child ?? const SizedBox.shrink(),
      ),
      home: const HomePage(),
    );
  }
}
```

## 能力矩阵

| API | 典型场景 | 多实例 | 默认路由切换关闭 |
|-----|----------|--------|------------------|
| `Pop.toast` | 轻反馈 | 是 | 否 |
| `Pop.loading` | 阻塞等待 | 否（单例） | 否 |
| `Pop.confirm` | 确认/危险操作 | 是 | 是 |
| `Pop.sheet` | 筛选、表单、抽屉 | 是 | 是 |
| `Pop.flowSheet` | 多步流程（训练/档案） | 是 | 随底层 sheet |
| `Pop.date` | 生日、区间起始日 | 是 | 否 |
| `Pop.menu` | 锚定更多菜单 | 是 | 否 |

## Example：FitPulse

`example/` 是健身健康风格的演示 App：

- **今日**：toast / loading / confirm
- **训练**：sheet（含 dockToEdge）、menu、开始训练 FlowSheet
- **数据**：date、导出 loading
- **我的**：资料 sheet、健康档案 FlowSheet、设置二级页（验证路由关弹框）
- **Lab**（AppBar ⋯）：Async / PopupManager 边界回归
