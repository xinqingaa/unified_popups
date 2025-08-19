# unified_popups 设计文档

[![Pub Version](https://img.shields.io/pub/v/unified_popup.svg)](https://pub.dev/packages/unified_popups)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 一、 Flutter 弹窗之“痛”：我们到底在烦恼什么？

在动手之前，我仔细梳理了那些在日常开发中让我们感到“不爽”的具体场景，总结为三大痛点：

### 痛点一：API 的“碎片化”与“上下文”依赖

Flutter 提供了多种显示弹窗的方式，但它们散落在各处，API 形态各异：

*   **`showDialog` / `showGeneralDialog`**: 功能强大，但样板代码多。每次调用都需要传递 `context` 和 `builder`，并且返回一个 `Future`。
*   **`showModalBottomSheet`**: 专用于底部面板，API 同样需要 `context` 和 `builder`。
*   **`ScaffoldMessenger.of(context).showSnackBar`**: 主要用于 SnackBar，调用链路长，且强依赖 `Scaffold` 上下文。
*   **直接操作 `Overlay`**: 终极武器，无比灵活，但也意味着一切都要自己管理：`OverlayEntry` 的创建与销毁、动画控制器的 `AnimationController` 的初始化与 `dispose`、弹窗位置的计算、状态管理... 任何一个环节处理不当，都可能导致 UI 异常或内存泄漏。

这种碎片化导致我们在不同业务场景下需要记忆和使用不同的 API，增加了心智负担。而对 `context` 的强依赖，使得在一些非 Widget 类（如 Repository、BLoC）中直接调用弹窗变得非常棘手。

### 痛点二：模态的“枷锁”——一次只能显示一个

`showDialog` 和 `showModalBottomSheet` 本质上都是在路由栈中推入一个新页面，它们是**模态**的。这意味着当一个 Dialog 显示时，它会“锁死”下方的 UI，你无法再弹出另一个。

想象一个常见的场景：用户提交一个重要表单，我们弹出一个全屏的 `Loading` 指示器。此时，如果网络请求发生错误，我们希望弹出一个 `Toast` 提示用户“网络异常”。在原生 Android/iOS 中这是常规操作，但在 Flutter 的默认体系下，模态的 `Loading` 会阻止 `Toast` 的显示。这个限制在复杂交互场景下是致命的。

### 痛点三：状态管理的“黑洞”

当弹窗多起来，状态管理就成了一场噩梦：

*   **如何知道某个弹窗是否正在显示？**  我们需要自己维护一个布尔值状态吗？那多个弹窗怎么办？
*   **如何手动关闭一个特定的弹窗？**  `showLoading` 后，业务逻辑可能在任何地方需要 `hideLoading`。我们如何精准地找到并关闭它？
*   **如何实现“一键关闭所有弹ubs”或“关闭上一个弹窗”？**  这种产品需求并不少见，但官方 API 并没有提供直接的支持，需要我们自己构建一套复杂的管理机制。

这些痛点，最终都指向了一个清晰的目标：我们需要一个**统一入口、支持多实例、自带状态管理、与业务逻辑解耦**的弹窗解决方案。

## 二、 顶层设计：构建一个“分层解耦”的弹窗架构

为了实现上述目标，我将整个库的架构分成了职责清晰的四层，这是一种典型的“关注点分离”思想：

1.  **API 门面 (Facade Layer)** : 这是开发者唯一需要直接交互的层，即 `UnifiedPopups` 类。它提供简单明了的静态方法，如 `showToast()`、`showConfirm()`。它的职责是“意图表达”，将开发者的需求（如“显示一个内容为'Hello'的Toast”）转换为一个标准的配置对象。
2.  **配置层 (Configuration Layer)** : 即 `PopupConfig` 类。这是一个纯粹的数据模型（Model），用于承载一个弹窗的所有配置信息，包括要显示的 `Widget`、位置、动画、是否显示蒙层、持续时间等等。它是 API 层与核心管理器之间沟通的“标准协议”。
3.  **核心管理器 (Manager Layer)** : 这是整个库的“大脑”，即 `PopupManager`。它是一个单例，负责管理所有弹窗的生命周期。它接收 `PopupConfig` 对象，然后执行所有“脏活累活”：创建 `OverlayEntry`、管理 `AnimationController`、处理用户交互、维护弹窗队列、最终销毁并释放资源。
4.  **UI 组件层 (Widget Layer)** : 即你看到的 `ToastWidget`、`ConfirmWidget` 等。它们是“哑组件”（Dumb Components），只负责根据传入的参数渲染 UI，并通过回调函数将用户事件（如点击按钮）通知给上层。它们不包含任何业务逻辑或弹窗管理逻辑。

这个分层架构带来了巨大的好处：

*   **高内聚，低耦合**：每一层都只做自己的事。我可以随时替换 `ConfirmWidget` 的 UI 实现，而不用修改任何 `PopupManager` 的代码。
*   **清晰的调用链路**：`UnifiedPopups.show() -> PopupConfig -> PopupManager -> OverlayEntry(child: YourWidget)`，数据流和控制流一目了然。
*   **易于扩展**：未来想增加一种新的弹窗类型，比如“评分弹窗”，我只需要创建一个 `RatingWidget`，然后在 `UnifiedPopups` 中增加一个 `showRating()` 的静态方法即可，核心逻辑无需改动。

## 三、 核心原理：三大机制撑起整个框架

在清晰的架构之下，是三个关键的技术实现，它们共同解决了前面提到的痛点。

### 原理一：基于 ID 的多实例生命周期管理

为了打破“一次只能显示一个”的模态枷锁，我选择基于 `Overlay` 来实现。而为了管理多个并存的 `OverlayEntry`，我引入了 **唯一 ID 机制**。

`PopupManager` 内部维护着一个核心数据结构：

    final Map<String, _PopupInfo> _popups = {};

每当 `show()` 方法被调用，它都会：

1.  生成一个时间戳+长度的唯一 `popupId`。
2.  创建一个 `_PopupInfo` 对象，它像一个“档案袋”，封装了与这个 `popupId` 相关的所有资源：`OverlayEntry`（UI）、`AnimationController`（动画）、`Timer`（用于自动关闭）以及回调函数。
3.  将 `popupId` 和 `_PopupInfo` 存入 `_popups` 这个 Map 中。

当需要关闭弹窗时，`hide(popupId)` 方法就能通过 ID 精准地找到对应的“档案袋”，然后有条不紊地执行：取消 `Timer` -> 反转播放动画 -> 动画结束后移除 `OverlayEntry` -> 销毁 `AnimationController`。

这套机制，不仅实现了多实例共存，还顺便解决了状态管理的“黑洞”问题。想知道弹窗是否可见？`_popups.containsKey(popupId)` 即可。想关闭所有？遍历 `_popups` 的 `keys` 逐个 `hide` 就行。

### 原理二：用 `Completer` 优雅地处理异步交互

对于 `showConfirm` 这类需要用户反馈的弹窗，我们最期望的调用方式是 `async/await`。为了将 UI 的回调事件（`onPressed`）转换成一个可 `await` 的 `Future`，`Completer` 是不二之选。

`showConfirm` 的内部流程是这样的：

1.  **创建 `Completer`**: 在函数开头 `final completer = Completer<bool?>();`，它持有一个未完成的 `Future`。
2.  **定义 `dismiss` 函数**: 创建一个闭包函数 `dismiss(result)`，它的核心作用是调用 `completer.complete(result)`，并将弹窗从屏幕上移除。这个 `complete` 动作会立即让 `completer.future` 返回结果。
3.  **传递 `dismiss`**: 将这个 `dismiss` 函数作为回调，传递给底层的 `ConfirmWidget`。比如，确认按钮的 `onPressed` 会调用 `() => dismiss(true)`，取消按钮调用 `() => dismiss(false)`。
4.  **处理边缘情况**: 同时，`PopupConfig` 的 `onDismiss` 回调（当用户点击蒙层关闭时触发）也会调用 `dismiss(null)`。这样就保证了所有关闭路径都能让 `Future` 得到一个结果。
5.  **返回 `Future`**: 最后，`showConfirm` 函数将 `completer.future` 返回给调用者。

通过这个模式，我们将复杂的、基于回调的 UI 交互，在业务逻辑层转换成了极其清爽的、线性的同步代码，可读性和可维护性大大提升。

### 原理三：配置驱动与智能默认

所有的 `showXXX` 方法，其背后都收敛到 `PopupManager.show(PopupConfig config)`。这种**配置驱动**的设计，让 API 变得高度统一和可扩展。

更重要的是，在 API 层 (`UnifiedPopups`)，我为每个弹窗类型都提供了**智能默认值**。比如 `showToast`，它会根据你设置的 `position` 自动选择一个更合适的默认动画，顶部弹出则向下滑入，底部则向上滑入。这让开发者可以用最少的代码获得最佳的默认体验，同时又保留了通过传递自定义参数进行深度定制的能力。

## 四、 UI 组件的匠心：兼顾美观与灵活

一个好的弹窗库，不仅要有强大的内核，也要有美观且灵活的“外壳”。我在设计这些 `Widget` 时，遵循了“**默认优先，定制兜底**”的原则。

### 案例一：`ToastWidget` & `LoadingWidget` - “约定优于配置”

这两个是简单的展示型组件。它们的核心设计思想是：**内置一套美观的默认样式，同时开放所有样式参数的覆盖能力**。

```dart
// ToastWidget build method
final defaultDecoration = BoxDecoration(...);
const defaultStyle = TextStyle(...);

return Container(
  decoration: decoration ?? defaultDecoration, // 用户不传，就用我的默认值
  child: Text(
    message,
    style: style ?? defaultStyle, // 用户不传，就用我的默认值
  ),
);
```

这种使用空合并运算符 `??` 的模式贯穿所有组件，它让最简单的 `UnifiedPopups.showToast("Hi")` 也能得到一个不错的效果，而对于有特殊 UI 需求的用户，则可以通过 `decoration`、`style` 等参数完全接管样式。

### 案例二：`ConfirmWidget` - 驾驭复杂的布局与状态

`ConfirmWidget` 的设计则更复杂，它需要处理不同的按钮组合和交互回调。

*   **条件化构建 UI**: `_buildButtons` 方法中，通过 `if (cancelText == null)` 来判断是渲染单个确认按钮，还是双按钮布局。这让 API 变得更智能，用户只需决定是否传入 `cancelText` 即可。
*   **`Stack` 布局的应用**: 右上角的关闭按钮，是通过 `Stack` + `Positioned` 实现的，这是在 Flutter 中进行精确定位布局的经典技巧，能在不影响主内容流的情况下添加覆盖元素。
*   **`assert` 契约式编程**: `assert(cancelText == null || onCancel != null)` 这一行代码，是在开发阶段就强制约束了 API 的正确使用：如果你提供了取消按钮的文本，那么必须提供对应的 `onCancel` 回调。这能有效避免运行时错误。

### 案例三：`SheetWidget` - 动态适应与智能样式

`SheetWidget` 的设计体现了对不同场景的适应性。

*   **上下文感知样式**: `_getDefaultBorderRadius()` 方法会根据 `SheetDirection`（弹出方向）来返回不同的 `BorderRadius`。比如从底部滑出，则顶部是圆角；从左侧滑出，则右侧是圆角。这种细节让 UI 看起来更自然。
*   **布局自适应**: `SheetWidget` 会判断是水平方向 (`left`/`right`) 还是垂直方向 (`top`/`bottom`)，然后为 `child` 选择不同的包裹组件 (`Expanded` 或 `Flexible`)，并设置不同的默认 `width`/`height`。这确保了无论从哪个方向弹出，内容布局都能表现得体。

## 五、 实战演练：三行代码，优雅集成

### 简单调用

理论说尽，上代码才是硬道理。

**第一步：初始化**

在`pubspec.yaml`添加依赖

```yaml
dependencies:
  flutter:
    sdk: flutter
  unified_popups: ^1.0.3 # 稳定版本
```

在 `main.dart` 中，为你的 `MaterialApp` 配置 `navigatorKey` 并初始化管理器。

```dart
// main.dart
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // App 启动时只需初始化一次
  PopupManager.initialize(navigatorKey: navigatorKey);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // 注入 Key
      home: HomePage(),
    );
  }
}
```

**第二步：尽情调用**

现在，你可以在 App 的任何地方，无需 `context`（除了 `showSheet` 需要计算尺寸），直接调用 API。

```dart
// 显示一个简单的 Toast
UnifiedPopups.showToast("操作成功");

// 显示一个带消息的 Loading，并在 2 秒后关闭
void fetchData() async {
  final loadingId = UnifiedPopups.showLoading(message: "加载中...");
  await Future.delayed(const Duration(seconds: 2));
  UnifiedPopups.hideLoading(loadingId);
}

// 异步等待用户的确认操作
void confirmDelete() async {
  final confirmed = await UnifiedPopups.showConfirm(
    title: "确认删除",
    content: "此操作无法撤销，是否继续？",
  );
  if (confirmed == true) {
    print("用户确认了删除");
  }
}

// 从底部弹出一个可返回值的选择列表
void selectItem() async {
  final result = await UnifiedPopups.showSheet<String>(
    context,
    title: "选择你的语言",
    childBuilder: (dismiss) => ListView(
      children: [
        ListTile(title: Text("Dart"), onTap: () => dismiss("dart")),
        ListTile(title: Text("Kotlin"), onTap: () => dismiss("kotlin")),
      ],
    ),
  );
  if(result != null) {
    UnifiedPopups.showToast("你选择了: $result");
  }
}
```

### 项目中的应用

*   侧边全屏抽屉


```dart
UnifiedPopups.showSheet(
  context,
  direction: SheetDirection.left,
  width: MediaQuery.of(context).size.width * 0.82, // 定制高度
  childBuilder: (dismiss) => AddCollectContent( // 子元素完全自定义，通过构造函数传参
    adId: widget.adId,
    phoneNumber: widget.tel,
    clientId: widget.clientId,
  ),
);
```

*   多个弹框嵌套


```dart
PopupManager.show(
  PopupConfig(
    child: Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: CalendarView( // CalendarView 本身也是弹框
            controller: controller,
            showLunar: false,
            locale: const Locale('en', 'EN'),
            showSurroundingDays: true,
          ),
        ),
        Positioned(
          top: 0,
          right: 20,
          child: IconButton(
            onPressed: (){
              PopupManager.hideLast();
            },
            icon: Icon(Icons.close)
          )
        )
      ],
    ),
  ),
);
```

*   自定义弹框


```dart
PopupManager.show(
  PopupConfig(
    child: _delAccountPop(),
  )
);
Widget _delAccountPop(){
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 20),
    padding: EdgeInsets.symmetric(horizontal: 16,vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset("assets/images/account_pop.png" , height: 60,),
        Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            "Are you sure to delete the account?",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold , color: Colors.black),
          ),
        ),
        Container(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            "Need to delete your account? Our support team is here to help.",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500 , color: Colors.black)
          ),
        ),
        GradientButton(
          child: Center(
            child: Text("ok", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold , color: Colors.white)),
          ),
          onTap: (){
            PopupManager.hideLast();
          },
        )
      ],
    )
  );
}

```

*   顶层toast


```dart
UnifiedPopups.showToast(
  "Please select a repayment method",
  position: PopupPosition.top,
  duration: Duration(milliseconds: 800),
);
```

## api参考

### `PopupManager`

核心弹窗管理器，负责所有弹窗的底层生命周期控制。

| 方法                                    | 描述                                           |
| :------------------------------------ | :------------------------------------------- |
| `initialize({required navigatorKey})` | **(必须)** 初始化管理器，在 `main()` 函数中调用。            |
| `show(PopupConfig config)`            | **(核心)** 显示一个弹出层，返回一个唯一的 `String` ID 用于手动控制。 |
| `hide(String popupId)`                | 根据提供的 `popupId` 隐藏指定的弹出层。                    |
| `hideLast()`                          | 隐藏最后显示的一个弹出层。                                |
| `hideAll()`                           | 隐藏当前所有正在显示的弹出层。                              |
| `isVisible(String popupId)`           | 检查指定 `popupId` 的弹出层当前是否可见，返回 `bool`。         |

### `PopupConfig`

用于 `PopupManager.show()` 的配置对象，描述一个弹窗的所有属性。

| 参数                   | 类型               | 默认值              | 描述                                                                 |
| :------------------- | :--------------- | :--------------- | :----------------------------------------------------------------- |
| `child`              | `Widget`         | **(必填)**         | 你想要显示的任何 Widget。                                                   |
| `position`           | `PopupPosition`  | `center`         | `top`, `center`, `bottom`, `left`, `right`。                        |
| `anchorKey`          | `GlobalKey?`     | `null`           | 如果提供，弹出层会依附于此 `key` 对应的 Widget。                                    |
| `anchorOffset`       | `Offset`         | `Offset.zero`    | 当使用 `anchorKey` 时的位置偏移量。                                           |
| `animation`          | `PopupAnimation` | `fade`           | `none`, `fade`, `slideUp`, `slideDown`, `slideLeft`, `slideRight`。 |
| `animationDuration`  | `Duration`       | `320ms`          | 动画的持续时间。                                                           |
| `showBarrier`        | `bool`           | `true`           | 是否显示半透明的遮盖层。                                                       |
| `barrierColor`       | `Color`          | `Colors.black54` | 遮盖层的颜色和透明度。                                                        |
| `barrierDismissible` | `bool`           | `true`           | 点击遮盖层时是否关闭弹出层。                                                     |
| `useSafeArea`        | `bool`           | `true`           | 内容是否应避开系统的安全区域（如刘海、底部导航条）。                                         |
| `duration`           | `Duration?`      | `null`           | 弹出层自动关闭的时间。`null` 表示不自动关闭。                                         |
| `onShow`             | `VoidCallback?`  | `null`           | 弹出层完全显示后的回调。                                                       |
| `onDismiss`          | `VoidCallback?`  | `null`           | 弹出层完全关闭后的回调。                                                       |

### `UnifiedPopups`

封装好的高级 API，推荐日常使用。

#### `showToast()`

显示一个 Toast 消息。返回 `void`。

| 参数                   | 类型                    | 默认值                                            | 描述                |
| :------------------- | :-------------------- | :--------------------------------------------- | :---------------- |
| `message`            | `String`              | **(必填)**                                       | Toast 显示的文本内容。    |
| `position`           | `PopupPosition`       | `bottom`                                       | Toast 显示的位置。      |
| `duration`           | `Duration`            | `2 seconds`                                    | Toast 持续显示的时长。    |
| `showBarrier`        | `bool`                | `false`                                        | 是否为 Toast 显示蒙层。   |
| `barrierDismissible` | `bool`                | `false`                                        | 点击蒙层时是否关闭 Toast。  |
| `padding`            | `EdgeInsetsGeometry?` | `EdgeInsets.symmetric(h: 24, v: 12)`           | 内容的内边距。           |
| `margin`             | `EdgeInsetsGeometry?` | `EdgeInsets.symmetric(h: 20, v: 40)`           | 容器的外边距。           |
| `decoration`         | `Decoration?`         | `BoxDecoration(...)`                           | 自定义容器样式（背景色、圆角等）。 |
| `style`              | `TextStyle?`          | `TextStyle(color: Colors.white, fontSize: 16)` | 文本样式。             |
| `textAlign`          | `TextAlign?`          | `center`                                       | 文本对齐方式。           |

#### `showLoading()` & `hideLoading()`

显示和隐藏一个加载指示器。

| 方法/参数                  | 类型           | 默认值              | 描述                                      |
| :--------------------- | :----------- | :--------------- | :-------------------------------------- |
| **`showLoading()`**    | **`String`** | -                | **(方法)** 显示加载框，**返回其唯一 ID**。            |
| `message`              | `String?`    | `null`           | 加载框下方显示的文本。                             |
| `backgroundColor`      | `Color?`     | `Colors.white`   | 容器背景色。                                  |
| `borderRadius`         | `double?`    | `12.0`           | 容器圆角半径。                                 |
| `indicatorColor`       | `Color?`     | `Colors.black`   | 加载指示器的颜色。                               |
| `indicatorStrokeWidth` | `double?`    | `2.0`            | 加载指示器的线条宽度。                             |
| `textStyle`            | `TextStyle?` | `null`           | 文本样式。                                   |
| `barrierDismissible`   | `bool`       | `false`          | 点击蒙层是否可关闭。                              |
| `barrierColor`         | `Color`      | `Colors.black54` | 蒙层颜色。                                   |
| **`hideLoading(id)`**  | **`void`**   | -                | **(方法)** 根据 `showLoading` 返回的 ID 关闭加载框。 |
| `id`                   | `String`     | **(必填)**         | `showLoading` 返回的唯一 ID。                 |

#### `showConfirm()`

显示一个确认对话框。返回 `Future<bool?>` (`true`: 确认, `false`: 取消, `null`: 点击蒙层或关闭按钮)。

| 参数                | 类型                    | 默认值      | 描述                             |
| :---------------- | :-------------------- | :------- | :----------------------------- |
| `title`           | `String?`             | `null`   | 对话框标题。                         |
| `content`         | `String`              | **(必填)** | 对话框的主要内容。                      |
| `confirmText`     | `String`              | `'确认'`   | 确认按钮的文本。                       |
| `cancelText`      | `String?`             | `'取消'`   | 取消按钮的文本。如果为 `null`，则只显示一个确认按钮。 |
| `showCloseButton` | `bool`                | `true`   | 是否显示右上角的关闭图标按钮。                |
| `titleStyle`      | `TextStyle?`          | `null`   | 自定义标题样式。                       |
| `contentStyle`    | `TextStyle?`          | `null`   | 自定义内容样式。                       |
| `confirmStyle`    | `TextStyle?`          | `null`   | 自定义确认按钮文本样式。                   |
| `cancelStyle`     | `TextStyle?`          | `null`   | 自定义取消按钮文本样式。                   |
| `confirmBgColor`  | `Color?`              | `null`   | 自定义确认按钮背景色。                    |
| `cancelBgColor`   | `Color?`              | `null`   | 自定义取消按钮背景色。                    |
| `padding`         | `EdgeInsetsGeometry?` | `null`   | 容器的内边距。                        |
| `margin`          | `EdgeInsetsGeometry?` | `null`   | 容器的外边距。                        |
| `decoration`      | `Decoration?`         | `null`   | 自定义容器样式（背景、圆角等）。               |

#### `showSheet<T>()`

从指定方向滑出一个面板。返回 `Future<T?>`，其值由 `childBuilder` 中的 `dismiss` 函数决定。

| 参数                | 类型                          | 默认值                          | 描述                                              |
| :---------------- | :-------------------------- | :--------------------------- | :---------------------------------------------- |
| `context`         | `BuildContext`              | **(必填)**                     | 用于获取屏幕尺寸等上下文信息。                                 |
| `childBuilder`    | `Widget Function(Function)` | **(必填)**                     | 内容构建器。接收一个 `dismiss([T? result])` 函数用于关闭面板并返回值。 |
| `title`           | `String?`                   | `null`                       | 面板的标题。                                          |
| `direction`       | `SheetDirection`            | `bottom`                     | 面板滑出的方向 (`top`, `bottom`, `left`, `right`)。     |
| `useSafeArea`     | `bool?`                     | `false`                      | 内容是否使用 `SafeArea`。                              |
| `width`           | `double?`                   | `null`                       | 面板宽度。左右方向默认为屏幕宽度的 70%。                          |
| `height`          | `double?`                   | `null`                       | 面板高度。上下方向默认由内容自适应。                              |
| `backgroundColor` | `Color?`                    | `Colors.white`               | 面板背景色。                                          |
| `borderRadius`    | `BorderRadius?`             | (智能默认)                       | 面板圆角。默认会根据 `direction` 自动设置。                    |
| `boxShadow`       | `List<BoxShadow>?`          | (默认阴影)                       | 面板的阴影效果。                                        |
| `padding`         | `EdgeInsetsGeometry?`       | `EdgeInsets.all(16)`         | 内容的内边距。                                         |
| `titlePadding`    | `EdgeInsetsGeometry?`       | `EdgeInsets.only(bottom: 8)` | 标题的内边距。                                         |
| `titleStyle`      | `TextStyle?`                | (主题默认)                       | 标题的文本样式。                                        |
| `titleAlign`      | `TextAlign?`                | `center`                     | 标题的对齐方式。                                        |
| `titleSpacing`    | `double?`                   | `16.0`                       | 标题和内容之间的间距。                                     |

# 总结

`unified_popups` 的诞生，源于实际开发中的痛点，其核心在于通过**分层解耦的架构**和**基于 ID 的生命周期管理**，实现了一个统一、健壮且易于扩展的弹窗体系。它将开发者从繁琐的 `Overlay` 操作和混乱的状态管理中解放出来，回归到业务逻辑本身。

