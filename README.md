# unified_popups

[![Pub Version](https://img.shields.io/pub/v/unified_popups.svg)](https://pub.dev/packages/unified_popups)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[English](README_EN.md) · [文档中心](docs/README.md) · [API 参考](docs/API_REFERENCE.md) · [最佳实践](docs/BEST_PRACTICES.md)

## 概述

Unified Popups 通过 `Pop` 静态 API 统一管理 Overlay 弹窗：toast、loading、confirm、sheet、**flowSheet**、date、menu。

### 核心能力

- **统一 API**：全部经 `Pop.*` 调用，类型安全
- **异步安全**：`SafeOverlayEntry` 避免 build 阶段 setState 错误
- **FlowSheet**：单 Sheet 内多页栈（`push` / `pop` / `replace` / `completeCurrent` / `closeAll`）+ 生命周期钩子
- **Sheet 拖拽**：`SheetDragDismissMode`（`fullBody` / `contentWhenAtTop` / `handleOnly`）、拖条、键盘上移
- **返回与路由**：`onBackPressed`、`PopScopeWidget`、`PopupRouteObserver`（含 `didRemove`）、`dismissOnRouteChange`
- **多实例**：除 loading 单例外可叠多层；动画时长/曲线可配

## 安装

```yaml
dependencies:
  unified_popups:
```

版本以 [pub.dev](https://pub.dev/packages/unified_popups) / `pubspec.yaml` 为准。

## 初始化

必须使用**同一个** `navigatorKey`，并注册观察者与返回拦截：

```dart
import 'package:unified_popups/unified_popups.dart';

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

## 基本用法

```dart
Pop.toast('保存成功', toastType: ToastType.success);

Pop.loading(message: '加载中...');
try {
  await fetchData();
} finally {
  Pop.hideLoading();
}

final ok = await Pop.confirm(
  title: '确认删除',
  content: '此操作不可撤销',
);
```

### Sheet

```dart
final selected = await Pop.sheet<String>(
  title: '筛选',
  dockToEdge: true,
  edgeGap: 84, // 与底部 NavigationBar 高度对齐
  dragDismissMode: SheetDragDismissMode.contentWhenAtTop,
  childBuilder: (dismiss) => ListTile(
    title: const Text('力量'),
    onTap: () => dismiss('strength'),
  ),
);
```

### FlowSheet

```dart
final controller = FlowSheetController<bool>();
final done = await Pop.flowSheet<bool>(
  controller: controller,
  maxHeight: SheetDimension.fraction(0.9),
  initialPage: StartWorkoutIntroPage(controller: controller),
);
```

业务页继承 `FlowSheetPage` / `FlowSheetPageState`，用 `nav.push` / `pop` / `replace` / `completeCurrent` / `closeAll`；结束整条流优先 `completeCurrent` / `closeAll`，避免双动画。

完整参数见 [docs/API_REFERENCE.md](docs/API_REFERENCE.md)。

## Example：FitPulse

`example/` 为健身健康风格演示：

| 入口 | 覆盖能力 |
|------|----------|
| 今日 | toast / loading / confirm |
| 训练 | sheet（含 dockToEdge）、menu、开始训练 FlowSheet |
| 数据 | date、导出 loading |
| 我的 | 资料 sheet、健康档案 FlowSheet、设置二级页（路由关弹框） |
| Lab（AppBar ⋯） | Async / PopupManager 边界回归 |

```bash
cd example && flutter run
```

## 文档

- [文档中心](docs/README.md)
- [API 参考](docs/API_REFERENCE.md)
- [最佳实践](docs/BEST_PRACTICES.md)
- [CHANGELOG](CHANGELOG.md)
