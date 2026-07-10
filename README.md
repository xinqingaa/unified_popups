# unified_popups

[![Pub Version](https://img.shields.io/pub/v/unified_popups.svg)](https://pub.dev/packages/unified_popups)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[English](README_EN.md) · [文档中心](docs/README.md) · [API 参考](docs/API_REFERENCE.md) · [最佳实践](docs/BEST_PRACTICES.md)

## 概述

Unified Popups 是面向 Flutter 的统一弹窗方案。所有能力通过 `Pop` 静态 API 调用，覆盖：

`toast` · `loading` · `confirm` · `sheet` · `flowSheet` · `date` · `menu`

### 核心能力

- **统一入口**：日常场景经 `Pop.*`；底层可用 `PopupManager.show` 完全自定义弹层
- **Overlay 多实例**：除 loading 单例外可叠多层，各自独立动画
- **异步安全**：`SafeOverlayEntry` 避免 build 阶段 setState 错误，可在 `async` / `Future.then` / `Timer` 中直接调用
- **动画可配**：各 API 支持 `animationDuration` / `animationCurve`
- **返回与路由**：`PopScopeWidget`、`PopupRouteObserver`、`dismissOnRouteChange`、`onBackPressed`
- **Sheet 族**：方向滑出、`dockToEdge`、拖拽关闭、键盘跟随；多步场景用 `flowSheet`

完整参数表见 [docs/API_REFERENCE.md](docs/API_REFERENCE.md)。

## 安装

```yaml
dependencies:
  unified_popups:
```

版本以 [pub.dev](https://pub.dev/packages/unified_popups) / `pubspec.yaml` 为准。

## 初始化

必须使用**同一个** `navigatorKey`，并注册路由观察者与返回拦截：

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

## API 速览

### Toast

临时轻提示。支持类型图标、自定义图片、`messageWidget`、点击切换（`toggleable`）。

```dart
Pop.toast('保存成功', toastType: ToastType.success);

Pop.toast(
  '网络异常，请稍后重试',
  toastType: ToastType.error,
  position: PopupPosition.bottom,
  duration: const Duration(seconds: 2),
);

Pop.toast(
  messageWidget: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.check_circle, color: Colors.green),
      SizedBox(width: 8),
      Text('操作成功'),
    ],
  ),
);
```

### Loading

阻塞式加载指示。**全局单例**：再次调用会先关掉已有 loading。务必 `try/finally`。

```dart
Pop.loading(message: '提交中...');
try {
  await submitData();
  Pop.toast('提交成功', toastType: ToastType.success);
} finally {
  Pop.hideLoading();
}

Pop.loading(
  message: '加载中',
  customIndicator: Image.asset('assets/loading.png'),
  rotationDuration: const Duration(milliseconds: 800),
);
```

### Confirm

需用户确认的操作。返回 `true` / `false` / `null`（遮罩或关闭）。支持 `confirmChild`、自定义 Widget 按钮与 `onConfirm` / `onCancel`。

```dart
final ok = await Pop.confirm(
  title: '删除确认',
  content: '删除后将不可恢复，是否继续？',
  confirmText: '删除',
  cancelText: '取消',
  confirmBgColor: Colors.red,
);
if (ok == true) { /* 执行删除 */ }

final named = await Pop.confirm(
  title: '输入信息',
  content: '请填写：',
  confirmChild: TextField(decoration: InputDecoration(labelText: '姓名')),
);
```

### Sheet

从指定方向滑出的面板，适合列表选择、表单、抽屉。通过 `childBuilder` 注入的 `dismiss(result)` 关闭并回传。

```dart
final action = await Pop.sheet<String>(
  title: '选择操作',
  childBuilder: (dismiss) => ListView(
    shrinkWrap: true,
    children: [
      ListTile(title: Text('复制'), onTap: () => dismiss('copy')),
      ListTile(title: Text('删除'), onTap: () => dismiss('delete')),
    ],
  ),
);

// 保留底部导航可点
await Pop.sheet<void>(
  title: '筛选',
  dockToEdge: true,
  edgeGap: 84, // 与 NavigationBar 实际高度对齐
  dragDismissMode: SheetDragDismissMode.contentWhenAtTop,
  childBuilder: (dismiss) => FilterForm(onDone: () => dismiss()),
);
```

常用选项：`direction`、`dockToEdge` / `edgeGap`、`showDragHandle`、`dragDismissMode`（`fullBody` / `contentWhenAtTop` / `handleOnly`）、`adjustForKeyboard`、`onBackPressed`。

### FlowSheet

在单个 Sheet 内维护多页栈，适合多步向导。底层仍是 sheet；业务页用 `nav.push` / `pop` / `replace` / `completeCurrent` / `closeAll`。结束整条流优先 `completeCurrent` / `closeAll`。

```dart
final controller = FlowSheetController<bool>();
final done = await Pop.flowSheet<bool>(
  controller: controller,
  maxHeight: SheetDimension.fraction(0.9),
  initialPage: MyWizardFirstPage(controller: controller),
);
```

页面继承 `FlowSheetPage` / `FlowSheetPageState`，可按需实现 `onShow` / `onHide` 等生命周期。详见 [API 参考 · FlowSheet](docs/API_REFERENCE.md#flowsheet-api)。

### Date

日期选择弹窗。确认返回 `DateTime`，取消或遮罩返回 `null`。

```dart
final birthday = await Pop.date(
  title: '选择生日',
  minDate: DateTime(1970, 1, 1),
  maxDate: DateTime.now(),
  confirmText: '确定',
  cancelText: '取消',
);
```

### Menu

锚定到某个 Widget 的气泡菜单。通过 `builder` 注入的 `dismiss(result)` 关闭。

```dart
final key = GlobalKey();

IconButton(
  key: key,
  icon: const Icon(Icons.more_vert),
  onPressed: () async {
    final result = await Pop.menu<String>(
      anchorKey: key,
      anchorOffset: const Offset(0, 8),
      builder: (dismiss) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text('编辑'), onTap: () => dismiss('edit')),
          ListTile(title: Text('删除'), onTap: () => dismiss('delete')),
        ],
      ),
    );
  },
);
```

## PopupManager（底层与全局控制）

`Pop.*` 覆盖常见场景；需要**完全自定义内容**或精细控制生命周期时，使用 `PopupManager`。`Pop.toast` / `confirm` / `sheet` 等内部也是走这里。

### 自定义弹层：`show` / `hide`

```dart
final id = PopupManager.show(PopupConfig(
  child: YourCustomWidget(),
  type: PopupType.other,
  position: PopupPosition.center,
  animation: PopupAnimation.fade,
  showBarrier: true,
  barrierDismissible: true,
  dismissOnRouteChange: true,
  onBackPressed: () {
    // 返回 true 表示已消费系统返回，不关闭 Overlay
    return false;
  },
));

// 稍后按 ID 关闭
PopupManager.hide(id);
```

`show` 返回唯一 `popupId`。只有通过 `PopupManager.show` 拿到的 ID（以及内部管理的 loading）适合按 ID 关闭；`Pop.toast` / `confirm` / `sheet` / `date` / `menu` 一般不暴露 ID，应靠各自交互或下方全局方法关闭。

### 其它静态方法

| 方法 | 作用 |
|------|------|
| `initialize(navigatorKey:)` | 初始化（须与 `MaterialApp` 同一 key） |
| `navigatorKey` | 当前 Navigator key |
| `show(PopupConfig)` | 显示自定义弹层，返回 `popupId` |
| `hide(popupId)` | 按 ID 关闭 |
| `hideLast()` | 关闭最上层（任意类型） |
| `hideAll()` | 关闭全部 |
| `hideByType(PopupType)` | 从最新起关闭第一个匹配类型（如 loading） |
| `hideLastNonToast()` | 关闭最上层非 toast；若配置了 `onBackPressed` 且返回 `true` 则只消费返回 |
| `hidePopupsOnRouteChange()` | 按策略关闭应随路由消失的弹窗（通常由 `PopupRouteObserver` 调用） |
| `isVisible(popupId)` | 指定 ID 是否仍显示 |
| `hasNonToastPopup` | 是否存在非 toast 弹窗（返回键判断） |
| `maybePop(context)` | 有非 toast 则关弹窗，否则 `Navigator.pop` |
| `getDebugInfo()` | 调试用当前弹窗摘要 |

```dart
// AppBar 返回：有弹窗先关弹窗
IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () => PopupManager.maybePop(context),
);

PopupManager.hideLast();
PopupManager.hideAll();
PopupManager.hideByType(PopupType.loading);

if (PopupManager.hasNonToastPopup) {
  PopupManager.hideLastNonToast();
}
```

完整 `PopupConfig` 字段与行为见 [API 参考 · PopupManager](docs/API_REFERENCE.md#popupmanager)。Lab 页也有 `PopupManager.show` 演示。

## 返回键与路由

| 机制 | 作用 |
|------|------|
| `PopScopeWidget` | 系统返回优先关最上层非 toast（经 `hideLastNonToast`） |
| `onBackPressed` | 弹窗可先消费返回（如 flowSheet 退内部页）；返回 `true` 表示已处理 |
| `PopupRouteObserver` | push / pop / replace / remove 时按策略关弹窗 |
| `dismissOnRouteChange` | 覆盖类型默认：confirm / sheet 默认关；toast / loading / date / menu 默认保留 |

## Example

`example/` 为 FitPulse 健身风格演示，用产品路径覆盖各类弹窗：

| 入口 | 覆盖 |
|------|------|
| 今日 | toast / loading / confirm |
| 训练 | sheet、menu、flowSheet |
| 数据 | date、loading |
| 我的 | sheet、flowSheet、设置页（路由关弹框） |
| Lab（AppBar ⋯） | 异步调用 / PopupManager 边界 |

```bash
cd example && flutter run
```

## 文档

- [文档中心](docs/README.md)
- [API 参考](docs/API_REFERENCE.md) — 完整参数与返回值
- [最佳实践](docs/BEST_PRACTICES.md)
- [CHANGELOG](CHANGELOG.md)
