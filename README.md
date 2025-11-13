# unified_popups

[![Pub Version](https://img.shields.io/pub/v/unified_popups.svg)](https://pub.dev/packages/unified_popups)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[英文](README_EN.md)

## 📖 概述

Unified Popups 是一个专为企业级 Flutter 应用设计的统一弹窗解决方案。它提供了简洁、易用的 API，覆盖了常见的弹窗场景，包括轻提示、加载指示器、确认对话框、底部面板、日期选择器和锚定菜单等。

### ✨ 核心特性

- **🆕 异步弹框支持**：所有弹窗类型均支持在异步方法中调用，无需担心构建阶段错误。基于 `SafeOverlayEntry` 实现，自动检测构建阶段并延迟执行，完美支持 `Future.then()`、`async/await`、`Stream`、`Timer` 等异步场景
- **统一 API**：所有弹窗通过 `Pop` 静态类调用，API 设计简洁一致
- **类型安全**：完整的 TypeScript 类型支持，编译时错误检查
- **多实例支持**：基于 Overlay 实现，支持同时显示多个弹窗
- **动画时长配置**：每个API都支持自定义动画时长，为不同场景提供最佳体验
- **键盘适配**：自动处理键盘弹出时的布局调整和焦点管理
- **手势支持**：支持拖拽关闭、点击遮罩关闭等交互
- **主题化**：支持自定义样式和主题配置
- **无障碍支持**：内置可访问性支持，符合无障碍设计标准
- **性能优化**：基于 Overlay 实现，性能优异，内存占用低

### 🎯 适用场景

- 企业级应用中的各种弹窗需求
- 需要统一弹窗体验的大型项目
- 对键盘适配和用户体验有高要求的应用
- 需要支持多端（移动端、Web、桌面端）的项目

## 🚀 快速开始

### 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  unified_popups: ^1.1.0 # 选择最新版本
```

### 初始化

在 `main.dart` 中初始化：

```dart
import 'package:unified_popups/unified_popups.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
  // 确保 MaterialApp 构建完毕后，再初始化 PopupManager
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PopupManager.initialize(navigatorKey: navigatorKey);
  });
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: GlobalKey<NavigatorState>(), // 必须提供
      home: PopScopeWidget( // 可选：用于处理返回键
        child: HomePage(),
      ),
    );
  }
}
```

### 基本使用

```dart
// 显示轻提示
Pop.toast('操作成功', toastType: ToastType.success);

// 显示加载指示器
Pop.loading(message: '加载中...');
// ... 异步操作
Pop.hideLoading();

// 显示确认对话框
final result = await Pop.confirm(
  title: '确认删除',
  content: '此操作不可撤销，是否继续？',
  confirmText: '删除',
  cancelText: '取消',
  confirmBorder: Border.all(color: Colors.redAccent),
);
```

## 📚 API 参考

### Toast 轻提示

用于显示临时性的消息提示。

```dart
Pop.toast(
  String message, {
  PopupPosition position = PopupPosition.center,
  Duration duration = const Duration(milliseconds: 1200),
  bool showBarrier = false,
  bool barrierDismissible = false,
  ToastType toastType = ToastType.none,
  Duration animationDuration = const Duration(milliseconds: 200),
  String? customImagePath,
  double? imageSize,
  Color? imgColor,
  Axis layoutDirection = Axis.horizontal,
  EdgeInsetsGeometry? padding,
  EdgeInsetsGeometry? margin,
  Decoration? decoration,
  TextStyle? style,
  TextAlign? textAlign,
})
```

**参数说明：**
- `message`：消息文本（必填）
- `position`：显示位置，支持 `top`、`center`、`bottom`、`left`、`right`
- `duration`：显示时长，默认 1.2 秒
- `toastType`：提示类型，支持 `success`、`warn`、`error`、`none`
- `animationDuration`：动画持续时间，默认 200ms
- `customImagePath`：自定义图片路径，如果提供则覆盖 toastType 的图标
- `imageSize`：图片大小，默认 24.0
- `imgColor`：自定义图片的着色，仅在提供 `customImagePath` 时生效
- `layoutDirection`：布局方向，默认 `Axis.horizontal`（Row），`Axis.vertical` 为 Column（图片在上，文字在下）
- `showBarrier`：是否显示遮罩层
- `barrierDismissible`：点击遮罩是否关闭

**使用示例：**
```dart
// 成功提示
Pop.toast('保存成功', toastType: ToastType.success);

// 错误提示
Pop.toast('网络异常，请稍后重试', toastType: ToastType.error);

// 自定义图片
Pop.toast(
  '自定义图片提示',
  customImagePath: 'assets/custom_icon.png',
  imageSize: 32.0,
  imgColor: Colors.orange,
  layoutDirection: Axis.vertical, // 图片在上，文字在下
);

// 自定义动画时长
Pop.toast('快速提示', animationDuration: Duration(milliseconds: 100));

// 自定义样式
Pop.toast(
  '自定义样式提示',
  decoration: BoxDecoration(
    gradient: LinearGradient(colors: [Colors.purple, Colors.blue]),
    borderRadius: BorderRadius.circular(20),
  ),
  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
);
```

### Loading 加载指示器

用于显示加载状态，支持自定义样式和交互。

```dart
void loading({
  String? message,
  Color? backgroundColor,
  double? borderRadius,
  Color? indicatorColor,
  double? indicatorStrokeWidth,
  TextStyle? textStyle,
  Widget? customIndicator,
  Duration rotationDuration = const Duration(seconds: 1),
  bool showBarrier = true,
  bool barrierDismissible = false,
  Color barrierColor = Colors.black54,
  Duration animationDuration = const Duration(milliseconds: 150),
})
```

**注意：** 整个应用同时只能有一个 loading，调用此方法会自动关闭之前的 loading（如果存在）。不需要手动管理 loading ID。

**参数说明：**
- `customIndicator`：自定义 Widget（通常是图片），如果提供则替代默认的 CircularProgressIndicator，并自动添加旋转动画
- `rotationDuration`：旋转动画持续时间，默认 1 秒。仅在使用 customIndicator 时生效

**使用示例：**
```dart
// 基本使用
Pop.loading(message: '提交中...');
await submitData();
Pop.hideLoading();

// 使用自定义图片作为 loading 图标
Pop.loading(
  message: '加载中',
  customIndicator: Image.asset('assets/loading.png'),
  rotationDuration: Duration(milliseconds: 800),
);

// 自定义样式
Pop.loading(
  message: '自定义样式 Loading',
  backgroundColor: Colors.purple.withOpacity(0.9),
  borderRadius: 20,
  indicatorColor: Colors.white,
  indicatorStrokeWidth: 3,
  textStyle: TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
);

// 快速显示 Loading
Pop.loading(
  message: '快速加载',
  animationDuration: Duration(milliseconds: 100),
);
```

### Confirm 确认对话框

用于需要用户确认的操作，支持丰富的自定义选项。

```dart
Future<bool?> confirm({
  String? title,
  required String content,
  PopupPosition position = PopupPosition.center,
  String confirmText = 'confirm',
  String? cancelText = 'cancel',
  bool showCloseButton = true,
  TextStyle? titleStyle,
  TextStyle? contentStyle,
  TextStyle? confirmStyle,
  TextStyle? cancelStyle,
  String? imagePath,
  double? imageHeight = 80,
  double? imageWidth,
  TextAlign? textAlign = TextAlign.center,
  ConfirmButtonLayout? buttonLayout = ConfirmButtonLayout.row,
  BorderRadiusGeometry? buttonBorderRadius,
  BoxBorder? confirmBorder,
  BoxBorder? cancelBorder,
  Color? confirmBgColor,
  Color? cancelBgColor,
  EdgeInsetsGeometry? padding,
  EdgeInsetsGeometry? margin,
  Decoration? decoration,
  Widget? confirmChild,
  Duration animationDuration = const Duration(milliseconds: 250),
})
```

**新增参数亮点：**
- `confirmBorder` / `cancelBorder`：允许自定义按钮边框样式

**返回值：**
- `true`：用户点击确认
- `false`：用户点击取消
- `null`：用户点击遮罩或关闭按钮

**使用示例：**
```dart
// 基本确认对话框
final result = await Pop.confirm(
  title: '删除确认',
  content: '删除后将不可恢复，是否继续？',
  confirmText: '删除',
  cancelText: '取消',
);

// 带输入框的确认对话框
final result = await Pop.confirm(
  title: '输入信息',
  content: '请填写以下信息：',
  confirmChild: Column(
    children: [
      TextField(decoration: InputDecoration(labelText: '姓名')),
      TextField(decoration: InputDecoration(labelText: '邮箱')),
    ],
  ),
);

// 危险操作确认
final result = await Pop.confirm(
  title: '危险操作',
  content: '此操作不可撤销！',
  confirmText: '删除',
  confirmBgColor: Colors.red,
  confirmBorder: Border.all(color: Colors.redAccent),
  cancelBorder: Border.all(color: Colors.redAccent.withOpacity(0.3)),
  buttonLayout: ConfirmButtonLayout.column,
);

// 快速确认对话框
final result = await Pop.confirm(
  title: '快速确认',
  content: '快速确认操作',
  animationDuration: Duration(milliseconds: 150),
);
```

### Sheet 底部面板

用于显示从指定方向滑出的面板，常用于列表选择、表单填写等场景。

```dart
Future<T?> sheet<T>({
  required Widget Function(void Function([T? result]) dismiss) childBuilder,
  String? title,
  SheetDirection direction = SheetDirection.bottom,
  bool showCloseButton = false,
  bool? useSafeArea,
  SheetDimension? width,
  SheetDimension? height,
  SheetDimension? maxWidth,
  SheetDimension? maxHeight,
  String? imgPath,
  Color? backgroundColor,
  BorderRadius? borderRadius,
  List<BoxShadow>? boxShadow,
  EdgeInsetsGeometry? padding,
  EdgeInsetsGeometry? titlePadding,
  TextStyle? titleStyle,
  TextAlign? titleAlign,
  Duration animationDuration = const Duration(milliseconds: 400),
})
```

**参数说明：**
- `childBuilder`：内容构建器，接收 `dismiss` 函数用于关闭面板
- `direction`：滑出方向，支持 `top`、`bottom`、`left`、`right`
- `width`/`height`：尺寸，支持像素值和百分比
- `useSafeArea`：是否使用安全区域
- `showBarrier` / `barrierDismissible` / `barrierColor`：控制遮罩层是否显示、是否可点击关闭以及遮罩颜色
- `dockToEdge`：在 `bottom` / `left` / `right` 方向弹出时，是否保留原边缘的交互区域（遮罩和内容都会避开该区域）
- `edgeGap`：保留边缘区域的尺寸，默认 `kBottomNavigationBarHeight + 4`
- `animationDuration`：动画持续时间，默认 400ms

> `dockToEdge` 不支持 `top` 方向，启用后留白区域可透传到底部/侧边的 TabBar 或导航组件。

**使用示例：**
```dart
// 底部选择面板
final result = await Pop.sheet<String>(
  title: '选择操作',
  childBuilder: (dismiss) => ListView(
    children: [
      ListTile(
        title: Text('复制'),
        onTap: () => dismiss('copy'),
      ),
      ListTile(
        title: Text('删除'),
        onTap: () => dismiss('delete'),
      ),
    ],
  ),
);

// 表单面板
await Pop.sheet<void>(
  title: '用户信息',
  childBuilder: (dismiss) => Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        TextField(decoration: InputDecoration(labelText: '姓名')),
        TextField(decoration: InputDecoration(labelText: '邮箱')),
        ElevatedButton(
          onPressed: () => dismiss(),
          child: Text('提交'),
        ),
      ],
    ),
  ),
);

// 自定义样式面板
await Pop.sheet<void>(
  title: '自定义样式',
  backgroundColor: Colors.grey[100],
  borderRadius: BorderRadius.circular(20),
  childBuilder: (dismiss) => Container(
    padding: EdgeInsets.all(16),
    child: Text('自定义内容'),
  ),
);

// 自定义遮罩交互
await Pop.sheet<void>(
  title: '不可点击关闭',
  showBarrier: true,
  barrierDismissible: false,
  barrierColor: Colors.black87.withOpacity(0.6),
  childBuilder: (dismiss) => Container(
    padding: EdgeInsets.all(16),
    child: ElevatedButton(
      onPressed: () => dismiss(),
      child: Text('关闭'),
    ),
  ),
);

// TabBar 顶部弹出，保留底部导航
await Pop.sheet<void>(
  title: 'TabBar 顶部弹出',
  dockToEdge: true,
  edgeGap: 64, // 可选：自定义保留高度 / 宽度
  childBuilder: (dismiss) => ListView(
    shrinkWrap: true,
    children: [
      ListTile(title: Text('收藏'), onTap: () => dismiss()),
      ListTile(title: Text('分享'), onTap: () => dismiss()),
    ],
  ),
);
// TabBar 保持可点，遮罩和内容都会停在 TabBar 顶部

// 快速面板
await Pop.sheet<void>(
  title: '快速面板',
  animationDuration: Duration(milliseconds: 200),
  childBuilder: (dismiss) => Container(
    padding: EdgeInsets.all(16),
    child: Text('快速内容'),
  ),
);
```

### Date 日期选择器

用于日期选择，支持自定义范围和样式。

```dart
Future<DateTime?> date({
  DateTime? initialDate,
  DateTime? minDate,
  DateTime? maxDate,
  String title = 'Date of Birth',
  PopupPosition position = PopupPosition.bottom,
  String confirmText = 'Confirm',
  String? cancelText = 'Cancel',
  Color? activeColor = Colors.black,
  Color? noActiveColor = Colors.black38,
  Color? headerBg = Colors.blue,
  double? height = 180.0,
  double? radius = 24.0,
  Duration animationDuration = const Duration(milliseconds: 250),
})
```

**使用示例：**
```dart
// 基本日期选择
final date = await Pop.date(
  title: '选择生日',
  minDate: DateTime(1900, 1, 1),
  maxDate: DateTime.now(),
);

// 自定义样式
final date = await Pop.date(
  title: '选择入职日期',
  initialDate: DateTime.now(),
  minDate: DateTime(2020, 1, 1),
  maxDate: DateTime.now(),
  confirmText: '确定',
  cancelText: '取消',
  activeColor: Colors.green,
  headerBg: Colors.green,
  height: 200,
  radius: 16,
);

// 快速日期选择
final date = await Pop.date(
  title: '快速选择日期',
  animationDuration: Duration(milliseconds: 150),
);
```

### Menu 锚定菜单

用于在指定组件附近显示菜单或气泡。

```dart
Future<T?> menu<T>({
  required GlobalKey anchorKey,
  Offset anchorOffset = Offset.zero,
  required Widget Function(void Function([T? result]) dismiss) builder,
  bool showBarrier = true,
  bool barrierDismissible = true,
  Color barrierColor = Colors.transparent,
  PopupAnimation animation = PopupAnimation.fade,
  Duration animationDuration = const Duration(milliseconds: 200),
  BoxDecoration? decoration,
  EdgeInsetsGeometry? padding,
  BoxConstraints? constraints,
})
```

**使用示例：**
```dart
// 基本菜单
final GlobalKey buttonKey = GlobalKey();

ElevatedButton(
  key: buttonKey,
  onPressed: () async {
    final result = await Pop.menu<String>(
      anchorKey: buttonKey,
      anchorOffset: Offset(0, 8),
      builder: (dismiss) => Column(
        children: [
          ListTile(
            title: Text('复制'),
            onTap: () => dismiss('copy'),
          ),
          ListTile(
            title: Text('删除'),
            onTap: () => dismiss('delete'),
          ),
        ],
      ),
    );
  },
  child: Text('显示菜单'),
);

// 带图标的菜单
final result = await Pop.menu<String>(
  anchorKey: buttonKey,
  builder: (dismiss) => Column(
    children: [
      ListTile(
        leading: Icon(Icons.copy),
        title: Text('复制'),
        onTap: () => dismiss('copy'),
      ),
      ListTile(
        leading: Icon(Icons.delete, color: Colors.red),
        title: Text('删除', style: TextStyle(color: Colors.red)),
        onTap: () => dismiss('delete'),
      ),
    ],
  ),
);
```

## 🎨 样式定制

### 动画时长配置

每个弹窗API都支持自定义动画时长，为不同场景提供最佳的用户体验：

```dart
// 快速反馈场景
Pop.toast('快速提示', animationDuration: Duration(milliseconds: 100));
Pop.loading(message: '快速加载', animationDuration: Duration(milliseconds: 100));

// 重要操作场景
Pop.confirm(
  title: '危险操作',
  content: '此操作不可撤销！',
  animationDuration: Duration(milliseconds: 300), // 稍慢，给用户思考时间
);

// 复杂内容场景
Pop.sheet(
  title: '复杂操作',
  animationDuration: Duration(milliseconds: 500), // 较长动画，适合复杂内容
  childBuilder: (dismiss) => ComplexWidget(),
);
```

**默认动画时长：**
- `Pop.toast()`: 200ms (快速显示)
- `Pop.loading()`: 150ms (快速显示)
- `Pop.confirm()`: 250ms (适中时长)
- `Pop.date()`: 250ms (适中时长)
- `Pop.menu()`: 200ms (快速响应)
- `Pop.sheet()`: 400ms (较长动画，适合抽屉效果)

### 全局样式配置

可以通过自定义主题来统一配置弹窗样式：

```dart
// 在 MaterialApp 中配置主题
MaterialApp(
  theme: ThemeData(
    // 自定义弹窗样式
    dialogTheme: DialogTheme(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),
)
```

### 局部样式定制

每个弹窗 API 都支持局部样式定制：

```dart
// 自定义 Toast 样式
Pop.toast(
  '自定义样式',
  decoration: BoxDecoration(
    gradient: LinearGradient(colors: [Colors.purple, Colors.blue]),
    borderRadius: BorderRadius.circular(20),
  ),
  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
);

// 自定义 Confirm 样式
Pop.confirm(
  title: '自定义样式',
  content: '内容',
  decoration: BoxDecoration(
    gradient: LinearGradient(colors: [Colors.teal, Colors.white]),
    borderRadius: BorderRadius.circular(24),
  ),
  titleStyle: TextStyle(color: Colors.blue, fontSize: 20),
  confirmBgColor: Colors.green,
  cancelBgColor: Colors.pink,
);
```

## 🔧 最佳实践

### 1. 键盘适配

当弹窗包含输入框时，库会自动处理键盘弹出：

```dart
// 推荐：使用 confirmChild 添加输入框
Pop.confirm(
  title: '输入信息',
  content: '请填写以下信息：',
  confirmChild: Column(
    children: [
      TextField(decoration: InputDecoration(labelText: '姓名')),
      TextField(decoration: InputDecoration(labelText: '邮箱')),
    ],
  ),
);

// 推荐：在 Sheet 中使用 ListView 处理长内容
Pop.sheet(
  childBuilder: (dismiss) => ListView(
    children: [
      TextField(decoration: InputDecoration(labelText: '字段1')),
      TextField(decoration: InputDecoration(labelText: '字段2')),
      // ... 更多字段
    ],
  ),
);
```

### 2. 错误处理

```dart
// 推荐：使用 try-catch 处理异步操作
try {
  final result = await Pop.confirm(
    title: '确认操作',
    content: '是否继续？',
  );
  
  if (result == true) {
    await performOperation();
    Pop.toast('操作成功', toastType: ToastType.success);
  }
} catch (e) {
  Pop.toast('操作失败: $e', toastType: ToastType.error);
}
```

### 3. 加载状态管理

```dart
// 推荐：使用 Loading 包装异步操作
Future<void> submitForm() async {
  Pop.loading(message: '提交中...');
  
  try {
    await api.submit(formData);
    Pop.hideLoading();
    Pop.toast('提交成功', toastType: ToastType.success);
  } catch (e) {
    Pop.hideLoading();
    Pop.toast('提交失败: $e', toastType: ToastType.error);
  }
}
```

### 4. 返回键处理

```dart
// 推荐：使用 PopScopeWidget 包装应用
MaterialApp(
  home: PopScopeWidget(
    child: HomePage(),
  ),
);

// 或者手动处理返回键
WillPopScope(
  onWillPop: () async {
    if (PopupManager.hasNonToastPopup) {
      PopupManager.hideLastNonToast();
      return false; // 阻止页面返回
    }
    return true; // 允许页面返回
  },
  child: HomePage(),
)
```

## 🎉 v1.1.10 重大更新

### ⚡ 异步弹框支持（核心特性）

**所有弹窗类型现在完全支持异步调用！**

- ✅ 支持在 `Future.then()` 回调中调用
- ✅ 支持在 `async/await` 异步方法中调用
- ✅ 支持在 `Stream` 监听回调中调用
- ✅ 支持在 `Timer` 回调中调用
- ✅ 支持在 `postFrameCallback` 中调用
- ✅ 支持在 `initState` 中异步调用

**技术实现：**
- 基于 `SafeOverlayEntry` 实现，自动检测构建阶段
- 如果在构建阶段调用，自动延迟到 `postFrameCallback` 执行
- 彻底解决了 "setState() called during build" 错误
- 所有弹窗类型（Toast、Loading、Confirm、Sheet、Date、Menu）均支持

**使用示例：**
```dart
// ✅ 在 Future.then() 中调用
Future.delayed(Duration(seconds: 1)).then((_) {
  Pop.loading(message: '处理中...');
});

// ✅ 在 async/await 中调用
Future<void> fetchData() async {
  await Future.delayed(Duration(milliseconds: 100));
  Pop.loading(message: '加载中...');
  await api.fetch();
  Pop.hideLoading();
}

// ✅ 在 Stream 监听中调用
stream.listen((data) {
  Pop.toast('收到数据: $data');
});

// ✅ 在 Timer 回调中调用
Timer(Duration(seconds: 1), () {
  Pop.confirm(content: '确认操作？');
});

// ✅ 在 postFrameCallback 中调用
WidgetsBinding.instance.addPostFrameCallback((_) {
  Pop.loading(message: '初始化中...');
});
```

### Loading API 简化
- `Pop.loading()` 不再返回 ID，改为返回 `void`
- `Pop.hideLoading()` 不再需要参数
- 整个应用同时只能有一个 loading，内部自动管理

### PopupManager 增强
- 新增 `PopupManager.hideByType(PopupType type)` 方法
- 支持根据类型查找并关闭弹窗

## 🔧 v1.1.6 更新

### Toast 增强
- 新增 `imgColor` 参数，可在调用 `Pop.toast` 时为自定义图片着色

### Confirm 增强
- 新增 `confirmBorder`、`cancelBorder` 参数，支持为按钮定制边框
- Confirm 按钮改用容器结构渲染，背景色与边框自定义更直观一致

## 🔧 PopupManager 原理与 popupId 使用规则

### 核心原理

PopupManager 是一个单例模式的弹窗管理器，基于 Flutter 的 `Overlay` 系统实现。它的核心工作原理如下：

#### 1. 弹窗生命周期管理

每个弹窗都有唯一的 `popupId`，用于标识和管理：

```dart
// 弹窗 ID 生成规则
final popupId = 'popup_${DateTime.now().microsecondsSinceEpoch}_${_instance._popups.length}';
```

#### 2. 内部数据结构

```dart
class _PopupInfo {
  final OverlayEntry entry;        // UI 组件
  final AnimationController controller;  // 动画控制器
  final VoidCallback? onDismissCallback; // 关闭回调
  final PopupType type;            // 弹窗类型
  Timer? dismissTimer;             // 自动关闭定时器
}
```

#### 3. 弹窗显示流程

1. **创建资源**：为每个弹窗创建独立的 `AnimationController` 和 `OverlayEntry`
2. **存储信息**：将弹窗信息存储在 `_popups` Map 中，按显示顺序记录在 `_popupOrder` 列表中
3. **插入 UI**：将 `OverlayEntry` 插入到 Flutter 的 Overlay 系统中
4. **播放动画**：执行进入动画，完成后触发 `onShow` 回调
5. **启动定时器**：如果设置了 `duration`，启动自动关闭定时器

#### 4. 弹窗关闭流程

1. **立即移除**：从管理器中移除弹窗信息，防止重复关闭
2. **取消定时器**：取消可能存在的自动关闭定时器
3. **播放退出动画**：执行退出动画
4. **清理资源**：动画完成后移除 `OverlayEntry` 并释放 `AnimationController`
5. **触发回调**：调用 `onDismiss` 回调

### popupId 使用规则

#### ✅ 可以通过 popupId 关闭的弹窗

**1. Loading 弹窗**
```dart
// Loading 现在不需要 ID，内部自动管理
Pop.loading(message: '加载中...');
// ... 异步操作
Pop.hideLoading(); // ✅ 可以关闭，不需要参数
```

**2. 手动创建的弹窗**
```dart
// 通过 PopupManager.show() 直接创建的弹窗
final popupId = PopupManager.show(PopupConfig(
  child: CustomWidget(),
  // ... 其他配置
));
PopupManager.hide(popupId); // ✅ 可以关闭
```

#### ❌ 不能通过 popupId 关闭的弹窗

**1. Toast 弹窗**
```dart
// Toast 不返回 popupId，自动管理生命周期
Pop.toast('消息'); // ❌ 无法通过 popupId 关闭
```

**2. Confirm 弹窗**
```dart
// Confirm 通过用户交互关闭，不返回 popupId
await Pop.confirm(content: '确认？'); // ❌ 无法通过 popupId 关闭
```

**3. Sheet 弹窗**
```dart
// Sheet 通过 dismiss() 函数关闭，不返回 popupId
await Pop.sheet(childBuilder: (dismiss) => ...); // ❌ 无法通过 popupId 关闭
```

**4. Date 弹窗**
```dart
// Date 通过用户选择关闭，不返回 popupId
await Pop.date(); // ❌ 无法通过 popupId 关闭
```

**5. Menu 弹窗**
```dart
// Menu 通过 dismiss() 函数关闭，不返回 popupId
await Pop.menu(builder: (dismiss) => ...); // ❌ 无法通过 popupId 关闭
```

### 全局管理方法

#### 1. 隐藏最后一个弹窗
```dart
// 隐藏最新显示的弹窗（任何类型）
PopupManager.hideLast();
```

#### 2. 隐藏所有弹窗
```dart
// 隐藏所有当前显示的弹窗
PopupManager.hideAll();
```

#### 3. 隐藏最后一个非 Toast 弹窗
```dart
// 隐藏最后一个非 Toast 类型的弹窗
PopupManager.hideLastNonToast();
```

#### 4. 根据类型隐藏弹窗
```dart
// 隐藏指定类型的弹窗（从最新的开始查找）
PopupManager.hideByType(PopupType.loading);
PopupManager.hideByType(PopupType.toast);
// 主要用于单一实例的弹窗类型，如 loading
```

#### 4. 检查弹窗状态
```dart
// 检查指定 ID 的弹窗是否可见
bool isVisible = PopupManager.isVisible(popupId);

// 检查是否有非 Toast 弹窗
bool hasPopup = PopupManager.hasNonToastPopup;
```

#### 5. 智能返回处理
```dart
// 如果有弹窗则关闭弹窗，否则执行页面返回
PopupManager.maybePop(context);
```

### 最佳实践

#### 1. Loading 弹窗管理
```dart
// 现在不需要手动管理 loading ID，直接调用即可
class LoadingManager {
  static void show(String message) {
    Pop.loading(message: message);
  }
  
  static void hide() {
    Pop.hideLoading();
  }
}
```

#### 2. 返回键处理
```dart
// 使用 PopScopeWidget 自动处理返回键
MaterialApp(
  home: PopScopeWidget(
    child: HomePage(),
  ),
);

// 或手动处理
WillPopScope(
  onWillPop: () async {
    if (PopupManager.hasNonToastPopup) {
      PopupManager.hideLastNonToast();
      return false; // 阻止页面返回
    }
    return true; // 允许页面返回
  },
  child: HomePage(),
)
```

#### 3. 错误处理
```dart
// 确保 Loading 在异常情况下也能被关闭
Future<void> safeOperation() async {
  try {
    Pop.loading(message: '处理中...');
    await riskyOperation();
    Pop.hideLoading();
    Pop.toast('成功', toastType: ToastType.success);
  } catch (e) {
    Pop.hideLoading();
    Pop.toast('失败: $e', toastType: ToastType.error);
  }
}
```

## 🚀 性能优化

### 1. 避免频繁创建弹窗

```dart
// 不推荐：频繁创建相同弹窗
for (int i = 0; i < 100; i++) {
  Pop.toast('消息 $i');
}

// 推荐：批量处理或使用节流
Timer? _toastTimer;
void showToast(String message) {
  _toastTimer?.cancel();
  _toastTimer = Timer(Duration(milliseconds: 100), () {
    Pop.toast(message);
  });
}
```

### 2. 合理使用 Loading

```dart
// 推荐：为长时间操作显示 Loading
Future<void> longOperation() async {
  Pop.loading(message: '处理中...');
  
  try {
    await Future.delayed(Duration(seconds: 3)); // 模拟长时间操作
    Pop.hideLoading();
    Pop.toast('操作完成', toastType: ToastType.success);
  } catch (e) {
    Pop.hideLoading();
    Pop.toast('操作失败', toastType: ToastType.error);
  }
}
```

## 🔮 更新建议

### 短期计划

1. **动画增强**
   - 支持更多动画类型（弹性、缓动等）
   - 自定义动画曲线
   - 动画时长配置 ✅ 已完成

2. **主题系统**
   - 全局主题配置
   - 暗色模式支持
   - 主题切换动画

3. **无障碍优化**
   - 屏幕阅读器支持
   - 键盘导航支持
   - 焦点管理优化

### 中期计划

1. **新组件**
   - 进度条弹窗
   - 图片预览弹窗
   - 文件选择弹窗
   - 颜色选择器

2. **交互增强**
   - 拖拽排序
   - 手势识别
   - 多点触控支持

3. **性能优化**
   - 虚拟滚动支持
   - 懒加载优化
   - 内存使用优化

### 长期计划

1. **平台扩展**
   - Web 端优化
   - 桌面端支持
   - 移动端原生体验

2. **生态系统**
   - 插件系统
   - 第三方组件库
   - 社区贡献指南

3. **企业级功能**
   - 多语言支持
   - 权限控制
   - 审计日志

## 🐛 常见问题

### Q: 如何自定义弹窗位置？

A: 使用 `position` 参数或 `anchorKey` 进行定位：

```dart
// 使用预设位置
Pop.toast('消息', position: PopupPosition.bottom);

// 使用锚定定位
final GlobalKey key = GlobalKey();
Pop.menu(anchorKey: key, builder: (dismiss) => ...);
```

### Q: 如何处理键盘弹出？

A: 库会自动处理键盘适配，但建议使用 `confirmChild` 或 `ListView`：

```dart
// 推荐方式
Pop.confirm(
  confirmChild: TextField(decoration: InputDecoration(labelText: '输入')),
);

// 或使用 Sheet
Pop.sheet(
  childBuilder: (dismiss) => ListView(
    children: [TextField(...)],
  ),
);
```

### Q: 如何实现全局弹窗管理？

A: 使用 `PopupManager` 进行全局管理：

```dart
// 隐藏所有弹窗
PopupManager.hideAll();

// 隐藏最后一个非 Toast 弹窗
PopupManager.hideLastNonToast();

// 检查是否有弹窗
if (PopupManager.hasNonToastPopup) {
  // 处理返回键
}
```

### Q: 如何自定义动画时长？

A: 使用 `animationDuration` 参数：

```dart
// 快速显示
Pop.toast('快速提示', animationDuration: Duration(milliseconds: 100));

// 慢速显示
Pop.sheet(
  childBuilder: (dismiss) => YourWidget(),
  animationDuration: Duration(milliseconds: 600),
);
```

## 📄 许可证

本项目采用 MIT 许可证，详见 [LICENSE](LICENSE) 文件。


## 📚 更多文档

- [API 参考文档](doc/API_REFERENCE.md) - 详细的API说明和参数列表
- [最佳实践指南](doc/BEST_PRACTICES.md) - 使用建议和最佳实践
- [README 文档](doc/README.md) - 完整的用户指南


**Unified Popups** - 让弹窗开发更简单、更统一、更高效！

