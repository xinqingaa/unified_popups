# Unified Popup SDK

一个强大、灵活、解耦的 Flutter 弹出层解决方案。统一管理您应用中的所有 Toast、模态框、确认框和自定义弹出层。

[![Pub Version](https://img.shields.io/pub/v/unified_popup.svg)](https://pub.dev/packages/unified_popup)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ 特性

- **统一 API**: 使用 `PopupManager.show()` 并用 `hide(id)`、`hideLast()`、`hideAll()` 精确控制关闭弹出层。
- **完全解耦**: 无需关心 `BuildContext`，在应用的任何地方（`ViewModel`, `BLoC`, `Service`...）都能调用。
- **高度自定义**:
    - **内容**: `child` 参数允许你传入任何 Widget。
    - **位置**: 支持顶部、中部、底部，或依附于任意 Widget 进行定位。
    - **动画**: 内置淡入淡出、滑动等多种动画，也可禁用。
    - **遮盖层**: 自由控制遮盖层的显示、颜色、透明度以及点击行为。
- **场景覆盖**:
    - **Toast**: 设置 `duration` 即可实现自动关闭。
    - **模态框 (Modal)**: 默认行为，需要用户交互才能关闭。
    - **确认框 (Confirm)**: 在 `child` 中构建你的确认/取消按钮。
    - **半屏弹窗**: 将 `child` 设置为特定高度的容器，并设置 `position` 为 `bottom`。

## 🚀 设计思路与原理

`unified_popup` 的核心是利用 Flutter 的 `Overlay` 和 `OverlayEntry`。`Overlay` 是一个可以在 `MaterialApp` 之上绘制 Widget 的堆栈。

1.  **全局访问**: 我们通过在 `MaterialApp` 上设置一个 `GlobalKey<NavigatorState>`，SDK 就可以获取到顶层的 `Overlay` 上下文。这使得我们可以在应用的任何地方，无需传递 `context`，就能显示弹出层。
2.  **单例与多实例管理**: `PopupManager` 采用单例模式，但其内部通过一个 `Map` 来管理所有当前活跃的弹窗实例。每次调用 `show()` 都会创建一个唯一的 ID 和一个独立的弹窗控制器。这确保了即使同时显示多个弹窗，它们的状态（动画、计时器等）也是完全隔离的，解决了旧版单实例管理的冲突问题。。
3.  **配置驱动**: 所有的弹出层样式和行为都通过一个 `PopupConfig` 对象进行配置。这种方式使得 API 调用非常清晰，并且易于扩展新功能。
4.  **解耦**:
    - **SDK 本身**: SDK 是一个独立的包，不依赖任何第三方库，具有良好的兼容性。
    - **业务与UI**: 在你的项目中，业务逻辑层（如 ViewModel）可以直接调用 `PopupManager.show()` 来显示一个加载中或错误提示，而无需与任何具体的页面 Widget 耦合。

## 🔧 安装

在你的 `pubspec.yaml` 文件中添加依赖：

```yaml
dependencies:
  unified_popup: ^1.0.0 # 使用最新版本
```

然后运行 `flutter pub get`。

## ⚙️ 初始化

为了让 SDK 能够全局工作，你需要在你的应用启动时进行初始化。

1.  在你的 `main.dart` 中，创建一个 `GlobalKey<NavigatorState>`。
2.  将它赋值给 `MaterialApp` 的 `navigatorKey` 属性。
3.  调用 `PopupManager.initialize()`。

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:unified_popup/unified_popup.dart';

// 1. 创建 GlobalKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
  // 3. 初始化 SDK
  PopupManager.initialize(navigatorKey: navigatorKey);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 2. 赋值给 navigatorKey
      navigatorKey: navigatorKey,
      title: 'Unified Popup Example',
      home: const ExampleHomePage(),
    );
  }
}
```

## 💡 使用方法

初始化后，你就可以在任何地方调用 `show` 和 `hide` 方法了。

### 示例 1: 显示一个简单的 Toast

一个位于底部、2秒后自动消失的 Toast。

```dart
void showMyToast() {
  PopupManager.show(
    PopupConfig(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Hello, this is a toast!', style: TextStyle(color: Colors.white)),
      ),
      position: PopupPosition.bottom,
      animation: PopupAnimation.slideUp,
      duration: const Duration(seconds: 2), // 自动关闭
      barrierDismissible: false, // Toast 点击背景不消失
      showBarrier: false, // Toast 不显示遮盖层
    ),
  );
}
```

### 示例 2: 显示一个确认对话框

一个位于中间的模态框，包含交互按钮。

```dart
void showConfirmDialog() {
  PopupManager.show(
    PopupConfig(
      child: Card(
        margin: const EdgeInsets.all(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Confirm Action', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              const Text('Are you sure you want to perform this action?'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => PopupManager.hide(), // 点击按钮关闭
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      print('Action Confirmed!');
                      PopupManager.hide(); // 关闭后执行操作
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      onDismiss: () {
        print('Dialog was dismissed.');
      },
    ),
  );
}
```

### 示例 3: 显示一个从底部滑出的半屏菜单

```dart
void showBottomSheet() {
  PopupManager.show(
    PopupConfig(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: Icon(Icons.share), title: Text('Share')),
            ListTile(leading: Icon(Icons.copy), title: Text('Copy Link')),
            ListTile(leading: Icon(Icons.edit), title: Text('Edit')),
          ],
        ),
      ),
      position: PopupPosition.bottom,
      animation: PopupAnimation.slideUp,
    ),
  );
}
```

### 示例 4: 依附于一个按钮下方显示

```dart
// 在你的 Widget build 方法中
final GlobalKey _buttonKey = GlobalKey();

// ...
ElevatedButton(
  key: _buttonKey, // 给按钮设置 key
  onPressed: () {
    PopupManager.show(
      PopupConfig(
        child: Container(
          padding: const EdgeInsets.all(10),
          color: Colors.blueAccent,
          child: const Text('I am anchored to the button!', style: TextStyle(color: Colors.white)),
        ),
        anchorKey: _buttonKey, // 传入 key
        anchorOffset: const Offset(0, 10), // 向下偏移 10 像素
        animation: PopupAnimation.fade,
        showBarrier: false,
      ),
    );
  },
  child: const Text('Show Anchored Popup'),
)
```

## API 参考

### `PopupManager`

核心弹窗管理器，负责所有弹窗的底层生命周期控制。

| 方法 | 描述 |
| :--- | :--- |
| `initialize({required navigatorKey})` | **(必须)** 初始化管理器，在 `main()` 函数中调用。 |
| `show(PopupConfig config)` | **(核心)** 显示一个弹出层，返回一个唯一的 `String` ID 用于手动控制。 |
| `hide(String popupId)` | 根据提供的 `popupId` 隐藏指定的弹出层。 |
| `hideLast()` | 隐藏最后显示的一个弹出层。 |
| `hideAll()` | 隐藏当前所有正在显示的弹出层。 |
| `isVisible(String popupId)` | 检查指定 `popupId` 的弹出层当前是否可见，返回 `bool`。 |

### `PopupConfig`

用于 `PopupManager.show()` 的配置对象，描述一个弹窗的所有属性。

| 参数 | 类型 | 默认值 | 描述 |
| :--- | :--- | :--- | :--- |
| `child` | `Widget` | **(必填)** | 你想要显示的任何 Widget。 |
| `position` | `PopupPosition` | `center` | `top`, `center`, `bottom`, `left`, `right`。 |
| `anchorKey` | `GlobalKey?` | `null` | 如果提供，弹出层会依附于此 `key` 对应的 Widget。 |
| `anchorOffset` | `Offset` | `Offset.zero` | 当使用 `anchorKey` 时的位置偏移量。 |
| `animation` | `PopupAnimation` | `fade` | `none`, `fade`, `slideUp`, `slideDown`, `slideLeft`, `slideRight`。 |
| `animationDuration` | `Duration` | `320ms` | 动画的持续时间。 |
| `showBarrier` | `bool` | `true` | 是否显示半透明的遮盖层。 |
| `barrierColor` | `Color` | `Colors.black54` | 遮盖层的颜色和透明度。 |
| `barrierDismissible` | `bool` | `true` | 点击遮盖层时是否关闭弹出层。 |
| `useSafeArea` | `bool` | `true` | 内容是否应避开系统的安全区域（如刘海、底部导航条）。 |
| `duration` | `Duration?` | `null` | 弹出层自动关闭的时间。`null` 表示不自动关闭。 |
| `onShow` | `VoidCallback?` | `null` | 弹出层完全显示后的回调。 |
| `onDismiss` | `VoidCallback?` | `null` | 弹出层完全关闭后的回调。 |

### `UnifiedPopups`

封装好的高级 API，推荐日常使用。

#### `showToast()`

显示一个 Toast 消息。返回 `void`。

| 参数 | 类型 | 默认值 | 描述 |
| :--- | :--- | :--- | :--- |
| `message` | `String` | **(必填)** | Toast 显示的文本内容。 |
| `position` | `PopupPosition` | `bottom` | Toast 显示的位置。 |
| `duration` | `Duration` | `2 seconds` | Toast 持续显示的时长。 |
| `showBarrier` | `bool` | `false` | 是否为 Toast 显示蒙层。 |
| `barrierDismissible` | `bool` | `false` | 点击蒙层时是否关闭 Toast。 |
| `padding` | `EdgeInsetsGeometry?` | `EdgeInsets.symmetric(h: 24, v: 12)` | 内容的内边距。 |
| `margin` | `EdgeInsetsGeometry?` | `EdgeInsets.symmetric(h: 20, v: 40)` | 容器的外边距。 |
| `decoration` | `Decoration?` | `BoxDecoration(...)` | 自定义容器样式（背景色、圆角等）。 |
| `style` | `TextStyle?` | `TextStyle(color: Colors.white, fontSize: 16)` | 文本样式。 |
| `textAlign` | `TextAlign?` | `center` | 文本对齐方式。 |

#### `showLoading()` & `hideLoading()`

显示和隐藏一个加载指示器。

| 方法/参数 | 类型 | 默认值 | 描述 |
| :--- | :--- | :--- | :--- |
| **`showLoading()`** | **`String`** | - | **(方法)** 显示加载框，**返回其唯一 ID**。 |
| `message` | `String?` | `null` | 加载框下方显示的文本。 |
| `backgroundColor` | `Color?` | `Colors.white` | 容器背景色。 |
| `borderRadius` | `double?` | `12.0` | 容器圆角半径。 |
| `indicatorColor` | `Color?` | `Colors.black` | 加载指示器的颜色。 |
| `indicatorStrokeWidth` | `double?` | `2.0` | 加载指示器的线条宽度。 |
| `textStyle` | `TextStyle?` | `null` | 文本样式。 |
| `barrierDismissible` | `bool` | `false` | 点击蒙层是否可关闭。 |
| `barrierColor` | `Color` | `Colors.black54` | 蒙层颜色。 |
| **`hideLoading(id)`** | **`void`** | - | **(方法)** 根据 `showLoading` 返回的 ID 关闭加载框。 |
| `id` | `String` | **(必填)** | `showLoading` 返回的唯一 ID。 |

#### `showConfirm()`

显示一个确认对话框。返回 `Future<bool?>` (`true`: 确认, `false`: 取消, `null`: 点击蒙层或关闭按钮)。

| 参数 | 类型 | 默认值 | 描述 |
| :--- | :--- | :--- | :--- |
| `title` | `String?` | `null` | 对话框标题。 |
| `content` | `String` | **(必填)** | 对话框的主要内容。 |
| `confirmText` | `String` | `'确认'` | 确认按钮的文本。 |
| `cancelText` | `String?` | `'取消'` | 取消按钮的文本。如果为 `null`，则只显示一个确认按钮。 |
| `showCloseButton` | `bool` | `true` | 是否显示右上角的关闭图标按钮。 |
| `titleStyle` | `TextStyle?` | `null` | 自定义标题样式。 |
| `contentStyle` | `TextStyle?` | `null` | 自定义内容样式。 |
| `confirmStyle` | `TextStyle?` | `null` | 自定义确认按钮文本样式。 |
| `cancelStyle` | `TextStyle?` | `null` | 自定义取消按钮文本样式。 |
| `confirmBgColor` | `Color?` | `null` | 自定义确认按钮背景色。 |
| `cancelBgColor` | `Color?` | `null` | 自定义取消按钮背景色。 |
| `padding` | `EdgeInsetsGeometry?` | `null` | 容器的内边距。 |
| `margin` | `EdgeInsetsGeometry?` | `null` | 容器的外边距。 |
| `decoration` | `Decoration?` | `null` | 自定义容器样式（背景、圆角等）。 |

#### `showSheet<T>()`

从指定方向滑出一个面板。返回 `Future<T?>`，其值由 `childBuilder` 中的 `dismiss` 函数决定。

| 参数 | 类型 | 默认值 | 描述 |
| :--- | :--- | :--- | :--- |
| `context` | `BuildContext` | **(必填)** | 用于获取屏幕尺寸等上下文信息。 |
| `childBuilder` | `Widget Function(Function)` | **(必填)** | 内容构建器。接收一个 `dismiss([T? result])` 函数用于关闭面板并返回值。 |
| `title` | `String?` | `null` | 面板的标题。 |
| `direction` | `SheetDirection` | `bottom` | 面板滑出的方向 (`top`, `bottom`, `left`, `right`)。 |
| `useSafeArea` | `bool?` | `false` | 内容是否使用 `SafeArea`。 |
| `width` | `double?` | `null` | 面板宽度。左右方向默认为屏幕宽度的 70%。 |
| `height` | `double?` | `null` | 面板高度。上下方向默认由内容自适应。 |
| `backgroundColor` | `Color?` | `Colors.white` | 面板背景色。 |
| `borderRadius` | `BorderRadius?` | (智能默认) | 面板圆角。默认会根据 `direction` 自动设置。 |
| `boxShadow` | `List<BoxShadow>?` | (默认阴影) | 面板的阴影效果。 |
| `padding` | `EdgeInsetsGeometry?` | `EdgeInsets.all(16)` | 内容的内边距。 |
| `titlePadding` | `EdgeInsetsGeometry?` | `EdgeInsets.only(bottom: 8)` | 标题的内边距。 |
| `titleStyle` | `TextStyle?` | (主题默认) | 标题的文本样式。 |
| `titleAlign` | `TextAlign?` | `center` | 标题的对齐方式。 |
| `titleSpacing` | `double?` | `16.0` | 标题和内容之间的间距。 |