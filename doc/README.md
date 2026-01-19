# Unified Popups 文档速览

## 📖 概述

Unified Popups 是一个面向企业级 Flutter 应用的统一弹窗解决方案。所有弹窗都通过 `Pop` 静态类调用，具备以下特点：

- **异步安全**：基于 `SafeOverlayEntry` 与构建阶段检测，可在 `Future.then`、`async/await`、`Stream`、`Timer`，甚至 `build()` 中直接调用
- **强类型**：依托 Dart 类型系统与 `flutter_lints` 规则，常见错误在编译期即可发现
- **动画可塑性**：每个 API 提供 `animationDuration` 与 `animationCurve`，方便调校动效节奏
- **键盘/手势适配**：内置键盘避让、遮罩点击、拖拽关闭等常用交互
- **多实例与性能优化**：Overlay 驱动，可同时展示多个弹窗并保持流畅

## 🚀 快速开始

### 安装依赖

```yaml
dependencies:
  unified_popups: ^1.1.14
```

### 初始化

```dart
void main() {
  final navigatorKey = GlobalKey<NavigatorState>();

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
      home: const PopScopeWidget(child: HomePage()),
      navigatorObservers: const [PopupRouteObserver()],
    );
  }
}
```

> `PopScopeWidget` 拦截系统返回键并优先关闭弹窗；`PopupRouteObserver` 监听路由 push/pop/replace，在页面切换时自动关闭 confirm、sheet（可通过 `dismissOnRouteChange` 自定义）。

### 基本调用

```dart
Pop.toast('保存成功', toastType: ToastType.success);

Pop.loading(message: '提交中...');
await submitForm();
Pop.hideLoading();

final ok = await Pop.confirm(
  title: '删除确认',
  content: '此操作不可撤销，是否继续？',
);
```

## 📚 API 速览

### Toast 轻提示

```dart
Pop.toast(
  '消息',
  position: PopupPosition.center,
  duration: const Duration(milliseconds: 1200),
  toastType: ToastType.none,
  animationDuration: const Duration(milliseconds: 200),
  animationCurve: Curves.easeInOut,
  customImagePath: 'assets/icon.png',
  layoutDirection: Axis.horizontal,
  messageWidget: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.check_circle, color: Colors.green),
      SizedBox(width: 8),
      Text('操作成功'),
    ],
  ),
  tMessage: '切换内容',
  tImagePath: 'assets/alt.png',
  toggleable: true,
);
```

> 通过 `messageWidget` 可完全自定义消息内容；通过 `tMessage` / `tImagePath` + `toggleable` 可实现点击切换；`showBarrier`/`barrierDismissible` 可控制遮罩。

### Loading 加载指示器

```dart
Pop.loading(
  message: '处理中...',
  customIndicator: Image.asset('assets/loading.png'),
  rotationDuration: const Duration(milliseconds: 800),
  showBarrier: true,
  barrierDismissible: false,
  animationDuration: const Duration(milliseconds: 150),
  animationCurve: Curves.easeInOut,
);
// 最多一个实例，Pop.hideLoading() 自动关闭
```

### Confirm 确认对话框

```dart
final result = await Pop.confirm(
  title: '危险操作',
  titleWidget: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.warning, color: Colors.orange),
      SizedBox(width: 8),
      Text('Widget 标题'),
    ],
  ),
  content: '此操作不可撤销！',
  contentWidget: Column(
    children: [
      Text('这是自定义内容 Widget'),
      Icon(Icons.info, color: Colors.blue),
    ],
  ),
  confirmText: '删除',
  confirmButtonWidget: Container(
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.red,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text('删除', style: TextStyle(color: Colors.white)),
  ),
  cancelText: '取消',
  confirmBgColor: Colors.red,
  confirmBorder: Border.all(color: Colors.redAccent),
  buttonLayout: ConfirmButtonLayout.column,
  confirmChild: TextField(decoration: InputDecoration(labelText: '备注')),
  onConfirm: () {
    print('确认按钮被点击');
  },
  onCancel: () {
    print('取消按钮被点击');
  },
  animationCurve: Curves.easeOutCubic,
);
```

> 通过 `titleWidget`、`contentWidget`、`confirmButtonWidget`、`cancelButtonWidget` 可完全自定义标题、内容和按钮；通过 `onConfirm` 和 `onCancel` 回调可完全接管按钮点击事件。

### Sheet 底部/侧边面板

```dart
final value = await Pop.sheet<String>(
  title: '选择操作',
  titleWidget: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.settings, color: Colors.blue),
      SizedBox(width: 8),
      Text('设置面板', style: TextStyle(fontWeight: FontWeight.bold)),
    ],
  ),
  direction: SheetDirection.bottom,
  dockToEdge: true,
  showBarrier: true,
  barrierDismissible: true,
  width: SheetDimension.fraction(0.9),
  childBuilder: (dismiss) => ListView(
    shrinkWrap: true,
    children: [
      ListTile(title: const Text('复制'), onTap: () => dismiss('copy')),
      ListTile(title: const Text('删除'), onTap: () => dismiss('delete')),
    ],
  ),
  animationCurve: Curves.easeOutQuint,
);
```

> 通过 `titleWidget` 可完全自定义标题 Widget。

### Date 日期选择器

```dart
final picked = await Pop.date(
  title: '选择日期',
  position: PopupPosition.bottom,
  minDate: DateTime(1960),
  maxDate: DateTime.now(),
  activeColor: Colors.green,
  headerBg: Colors.green,
  height: 220,
  animationCurve: Curves.easeOut,
);
```

### Menu 锚定菜单

```dart
final GlobalKey anchorKey = GlobalKey();

ElevatedButton(
  key: anchorKey,
  onPressed: () async {
    final action = await Pop.menu<String>(
      anchorKey: anchorKey,
      anchorOffset: const Offset(0, 8),
      showBarrier: true,
      barrierColor: Colors.black45,
      animation: PopupAnimation.slideDown,
      animationCurve: Curves.easeOutBack,
      builder: (dismiss) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: const Text('分享'), onTap: () => dismiss('share')),
          ListTile(title: const Text('删除'), onTap: () => dismiss('delete')),
        ],
      ),
    );
    debugPrint('选中: $action');
  },
  child: const Text('更多'),
);
```

## 🧠 管理器与返回键

- `PopupManager.show(PopupConfig)`：直接插入自定义弹窗
- `PopupManager.hide(String id)` / `hideLast()` / `hideAll()` / `hideByType(type)`：按需关闭
- `PopupManager.hasNonToastPopup`：判断是否存在遮挡页面的弹窗，可结合 `PopScopeWidget` 或 `WillPopScope` 优雅拦截返回键
- `PopupManager.maybePop(context)`：智能处理返回，有弹窗则关闭弹窗，否则返回上一页
- 示例工程中提供了 `PopupManagerPage` 示例页面，展示 `PopScopeWidget` 和 `PopupManager.show` 的搭配使用

## 🔗 更多资源

- [API_REFERENCE.md](API_REFERENCE.md)：完整参数与类型信息
- [BEST_PRACTICES.md](BEST_PRACTICES.md)：设计建议与常见场景
- 根目录 `README.md` / `README_EN.md`：图文教程与示例
