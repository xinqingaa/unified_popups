# Unified Popups 文档中心

面向 Flutter 的统一弹窗方案。所有能力通过 `Pop` 静态 API 调用：

`toast` · `loading` · `confirm` · `sheet` · `flowSheet` · `date` · `menu`

## 文档导航

| 文档 | 说明 |
|------|------|
| [根 README（中文）](../README.md) | 快速开始与 API 速览 |
| [English README](../README_EN.md) | English quick start |
| [API 参考](API_REFERENCE.md) | 参数表与返回值（权威） |
| [最佳实践](BEST_PRACTICES.md) | 选型、各类型注意点、返回键与路由 |
| [Example](../example/) | FitPulse 场景演示 |

## 安装

```yaml
dependencies:
  unified_popups:
```

## 初始化要点

- 使用**同一个** `navigatorKey` 传给 `MaterialApp` 与 `PopupManager.initialize`
- 注册 `PopupRouteObserver`
- 用 `PopScopeWidget` 拦截系统返回

完整示例见 [根 README · 初始化](../README.md#初始化)。

## 能力矩阵

| API | 典型场景 | 多实例 | 默认路由切换关闭 |
|-----|----------|--------|------------------|
| `Pop.toast` | 轻反馈 | 是 | 否 |
| `Pop.loading` | 阻塞等待 | 否（单例） | 否 |
| `Pop.confirm` | 确认 / 危险操作 | 是 | 是 |
| `Pop.sheet` | 筛选、表单、抽屉 | 是 | 是 |
| `Pop.flowSheet` | 多步向导 | 是 | 随底层 sheet |
| `Pop.date` | 选日期 | 是 | 否 |
| `Pop.menu` | 锚定菜单 | 是 | 否 |
| `PopupManager.show` | 完全自定义 Overlay | 是 | 可配 |

全局控制还包括：`hide` / `hideLast` / `hideAll` / `hideByType` / `hideLastNonToast` / `maybePop` / `isVisible` / `hasNonToastPopup` 等，见 [根 README · PopupManager](../README.md#popupmanager底层与全局控制) 与 [API 参考](API_REFERENCE.md#popupmanager)。

## Example 地图

| 入口 | 覆盖 |
|------|------|
| 今日 | toast / loading / confirm |
| 训练 | sheet、menu、flowSheet |
| 数据 | date、loading |
| 我的 | sheet、flowSheet、设置页（路由关弹框） |
| Lab（AppBar ⋯） | 异步 / PopupManager 边界 |
