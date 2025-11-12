# API 参考文档

## 目录

- [Pop 类](#pop-类)
- [Toast API](#toast-api)
- [Loading API](#loading-api)
- [Confirm API](#confirm-api)
- [Sheet API](#sheet-api)
- [Date API](#date-api)
- [Menu API](#menu-api)
- [PopupManager](#popupmanager)
- [枚举类型](#枚举类型)

## Pop 类

`Pop` 是统一弹窗库的主要入口类，提供所有弹窗相关的静态方法。

### 类定义

```dart
abstract class Pop {
  // 静态方法
  static void toast(...)
  static String loading(...)
  static void hideLoading(String id)
  static Future<bool?> confirm(...)
  static Future<T?> sheet<T>(...)
  static Future<DateTime?> date(...)
  static Future<T?> menu<T>(...)
}
```

## Toast API

### 方法签名

```dart
static void toast(
  String message, {
  PopupPosition position = PopupPosition.center,
  Duration duration = const Duration(milliseconds: 1200),
  bool showBarrier = false,
  bool barrierDismissible = false,
  ToastType toastType = ToastType.none,
  Duration animationDuration = const Duration(milliseconds: 200),
  String? customImagePath,
  double? imageSize,
  Axis layoutDirection = Axis.horizontal,
  EdgeInsetsGeometry? padding,
  EdgeInsetsGeometry? margin,
  Decoration? decoration,
  TextStyle? style,
  TextAlign? textAlign,
})
```

### 参数说明

| 参数 | 类型 | 默认值 | 必填 | 说明 |
|------|------|--------|------|------|
| `message` | `String` | - | ✅ | 要显示的消息文本 |
| `position` | `PopupPosition` | `center` | ❌ | 显示位置 |
| `duration` | `Duration` | `1200ms` | ❌ | 显示时长 |
| `showBarrier` | `bool` | `false` | ❌ | 是否显示遮罩层 |
| `barrierDismissible` | `bool` | `false` | ❌ | 点击遮罩是否关闭 |
| `toastType` | `ToastType` | `none` | ❌ | 提示类型 |
| `customImagePath` | `String?` | `null` | ❌ | 自定义图片路径，如果提供则覆盖 toastType 的图标 |
| `imageSize` | `double?` | `24.0` | ❌ | 图片大小 |
| `imgColor` | `Color?` | `null` | ❌ | 自定义图片的着色，仅在提供 `customImagePath` 时生效 |
| `layoutDirection` | `Axis` | `Axis.horizontal` | ❌ | 布局方向，`horizontal` 为 Row（图片在左，文字在右），`vertical` 为 Column（图片在上，文字在下） |
| `padding` | `EdgeInsetsGeometry?` | `null` | ❌ | 内边距 |
| `margin` | `EdgeInsetsGeometry?` | `null` | ❌ | 外边距 |
| `decoration` | `Decoration?` | `null` | ❌ | 装饰样式 |
| `style` | `TextStyle?` | `null` | ❌ | 文本样式 |
| `animationDuration` | `Duration` | `200ms` | ❌ | 动画持续时间 |
| `textAlign` | `TextAlign?` | `null` | ❌ | 文本对齐方式 |

### 使用示例

```dart
// 基本使用
Pop.toast('操作成功');

// 成功提示
Pop.toast('保存成功', toastType: ToastType.success);

// 错误提示
Pop.toast('网络异常', toastType: ToastType.error);

// 自定义位置和时长
Pop.toast(
  '自定义提示',
  position: PopupPosition.bottom,
  duration: Duration(seconds: 3),
);

// 自定义样式
Pop.toast(
  '自定义样式',
  decoration: BoxDecoration(
    gradient: LinearGradient(colors: [Colors.purple, Colors.blue]),
    borderRadius: BorderRadius.circular(20),
  ),
  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
);

// 带遮罩的 Toast
Pop.toast(
  '重要提示',
  showBarrier: true,
  barrierDismissible: true,
  duration: Duration(seconds: 5),
);

// 自定义图片
Pop.toast(
  '自定义图片提示',
  customImagePath: 'assets/custom_icon.png',
  imageSize: 32.0,
  imgColor: Colors.orange,
  layoutDirection: Axis.vertical, // 图片在上，文字在下
);

// 自定义动画时长
Pop.toast(
  '快速提示',
  animationDuration: Duration(milliseconds: 100),
);
```

## Loading API

### 方法签名

```dart
static String loading({
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

### 参数说明

| 参数 | 类型 | 默认值 | 必填 | 说明 |
|------|------|--------|------|------|
| `message` | `String?` | `null` | ❌ | 加载提示文本 |
| `backgroundColor` | `Color?` | `null` | ❌ | 背景颜色 |
| `borderRadius` | `double?` | `null` | ❌ | 圆角半径 |
| `indicatorColor` | `Color?` | `null` | ❌ | 指示器颜色 |
| `indicatorStrokeWidth` | `double?` | `null` | ❌ | 指示器线宽 |
| `textStyle` | `TextStyle?` | `null` | ❌ | 文本样式 |
| `customIndicator` | `Widget?` | `null` | ❌ | 自定义 Widget（通常是图片），如果提供则替代默认的 CircularProgressIndicator，并自动添加旋转动画 |
| `rotationDuration` | `Duration` | `1秒` | ❌ | 旋转动画持续时间，仅在使用 customIndicator 时生效 |
| `showBarrier` | `bool` | `true` | ❌ | 是否显示遮罩 |
| `barrierDismissible` | `bool` | `false` | ❌ | 点击遮罩是否关闭 |
| `barrierColor` | `Color` | `Colors.black54` | ❌ | 遮罩颜色 |
| `animationDuration` | `Duration` | `150ms` | ❌ | 动画持续时间 |

### 返回值

返回 `String` 类型的唯一 ID，用于后续关闭 Loading。

### 使用示例

```dart
// 基本使用
final loadingId = Pop.loading(message: '加载中...');
await someAsyncOperation();
Pop.hideLoading(loadingId);

// 自定义样式
final loadingId = Pop.loading(
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

// 可关闭的 Loading
final loadingId = Pop.loading(
  message: '可点击遮罩关闭',
  showBarrier: true,
  barrierDismissible: true,
  barrierColor: Colors.black26,
);

// 使用自定义图片作为 loading 图标
final loadingId = Pop.loading(
  message: '加载中',
  customIndicator: Image.asset('assets/loading.png'),
  rotationDuration: Duration(milliseconds: 800),
);

// 快速显示的 Loading
final loadingId = Pop.loading(
  message: '快速加载',
  animationDuration: Duration(milliseconds: 100),
);
```

### hideLoading 方法

```dart
static void hideLoading(String id)
```

用于关闭指定的 Loading 弹窗。

## Confirm API

### 方法签名

```dart
static Future<bool?> confirm({
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

### 参数说明

| 参数 | 类型 | 默认值 | 必填 | 说明 |
|------|------|--------|------|------|
| `title` | `String?` | `null` | ❌ | 对话框标题 |
| `content` | `String` | - | ✅ | 对话框内容 |
| `position` | `PopupPosition` | `center` | ❌ | 显示位置 |
| `confirmText` | `String` | `'confirm'` | ❌ | 确认按钮文本 |
| `cancelText` | `String?` | `'cancel'` | ❌ | 取消按钮文本 |
| `showCloseButton` | `bool` | `true` | ❌ | 是否显示关闭按钮 |
| `titleStyle` | `TextStyle?` | `null` | ❌ | 标题样式 |
| `contentStyle` | `TextStyle?` | `null` | ❌ | 内容样式 |
| `confirmStyle` | `TextStyle?` | `null` | ❌ | 确认按钮文本样式 |
| `cancelStyle` | `TextStyle?` | `null` | ❌ | 取消按钮文本样式 |
| `imagePath` | `String?` | `null` | ❌ | 图片路径 |
| `imageHeight` | `double?` | `80` | ❌ | 图片高度 |
| `imageWidth` | `double?` | `null` | ❌ | 图片宽度 |
| `textAlign` | `TextAlign` | `center` | ❌ | 文本对齐方式 |
| `buttonLayout` | `ConfirmButtonLayout` | `row` | ❌ | 按钮布局方式 |
| `buttonBorderRadius` | `BorderRadiusGeometry?` | `null` | ❌ | 按钮圆角 |
| `confirmBorder` | `BoxBorder?` | `null` | ❌ | 确认按钮边框样式 |
| `cancelBorder` | `BoxBorder?` | `null` | ❌ | 取消按钮边框样式 |
| `confirmBgColor` | `Color?` | `null` | ❌ | 确认按钮背景色 |
| `cancelBgColor` | `Color?` | `null` | ❌ | 取消按钮背景色 |
| `padding` | `EdgeInsetsGeometry?` | `null` | ❌ | 内边距 |
| `margin` | `EdgeInsetsGeometry?` | `null` | ❌ | 外边距 |
| `decoration` | `Decoration?` | `null` | ❌ | 装饰样式 |
| `confirmChild` | `Widget?` | `null` | ❌ | 在内容与按钮之间插入的自定义组件 |
| `animationDuration` | `Duration` | `250ms` | ❌ | 动画持续时间 |

> 提示：确认与取消按钮现使用容器进行渲染，可同时定制背景色与边框，便于保持样式一致性。

### 返回值

- `true`：用户点击确认按钮
- `false`：用户点击取消按钮
- `null`：用户点击遮罩或关闭按钮

### 使用示例

```dart
// 基本确认对话框
final result = await Pop.confirm(
  title: '删除确认',
  content: '删除后将不可恢复，是否继续？',
  confirmText: '删除',
  cancelText: '取消',
);

// 单按钮对话框
final result = await Pop.confirm(
  content: '操作已完成',
  confirmText: '知道了',
  cancelText: null, // 不显示取消按钮
);

// 带图片的对话框
final result = await Pop.confirm(
  title: '操作成功',
  content: '您的操作已完成',
  imagePath: 'assets/success.png',
  imageHeight: 100,
);

// 带输入框的对话框
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
  showCloseButton: true,
);

// 自定义样式
final result = await Pop.confirm(
  title: '自定义样式',
  content: '这是一个自定义样式的对话框',
  decoration: BoxDecoration(
    gradient: LinearGradient(colors: [Colors.teal, Colors.white]),
    borderRadius: BorderRadius.circular(24),
  ),
  titleStyle: TextStyle(color: Colors.blue, fontSize: 20),
  confirmBgColor: Colors.green,
  cancelBgColor: Colors.pink,
);

// 自定义动画时长
final result = await Pop.confirm(
  title: '快速确认',
  content: '快速确认对话框',
  animationDuration: Duration(milliseconds: 150),
);
```

## Sheet API

### 方法签名

```dart
static Future<T?> sheet<T>({
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
  bool? showBarrier,
  bool? barrierDismissible,
  Color? barrierColor,
  bool dockToEdge = false,
  double? edgeGap,
  Duration animationDuration = const Duration(milliseconds: 400),
})
```

### 参数说明

| 参数 | 类型 | 默认值 | 必填 | 说明 |
|------|------|--------|------|------|
| `childBuilder` | `Widget Function(void Function([T? result]) dismiss)` | - | ✅ | 内容构建器 |
| `title` | `String?` | `null` | ❌ | 面板标题 |
| `direction` | `SheetDirection` | `bottom` | ❌ | 滑出方向 |
| `showCloseButton` | `bool` | `false` | ❌ | 是否显示关闭按钮 |
| `useSafeArea` | `bool?` | `null` | ❌ | 是否使用安全区域 |
| `width` | `SheetDimension?` | `null` | ❌ | 宽度 |
| `height` | `SheetDimension?` | `null` | ❌ | 高度 |
| `maxWidth` | `SheetDimension?` | `null` | ❌ | 最大宽度 |
| `maxHeight` | `SheetDimension?` | `null` | ❌ | 最大高度 |
| `imgPath` | `String?` | `null` | ❌ | 图片路径 |
| `backgroundColor` | `Color?` | `null` | ❌ | 背景颜色 |
| `borderRadius` | `BorderRadius?` | `null` | ❌ | 圆角 |
| `boxShadow` | `List<BoxShadow>?` | `null` | ❌ | 阴影 |
| `padding` | `EdgeInsetsGeometry?` | `null` | ❌ | 内边距 |
| `titlePadding` | `EdgeInsetsGeometry?` | `null` | ❌ | 标题内边距 |
| `titleStyle` | `TextStyle?` | `null` | ❌ | 标题样式 |
| `titleAlign` | `TextAlign?` | `null` | ❌ | 标题对齐方式 |
| `showBarrier` | `bool?` | `true` | ❌ | 是否显示遮罩 |
| `barrierDismissible` | `bool?` | `true` | ❌ | 点击遮罩是否关闭 |
| `barrierColor` | `Color?` | `Colors.black54` | ❌ | 遮罩颜色 |
| `dockToEdge` | `bool` | `false` | ❌ | bottom/left/right 时是否保留边缘交互区域 |
| `edgeGap` | `double?` | `kBottomNavigationBarHeight + 4` | ❌ | 预留边缘尺寸 |
| `animationDuration` | `Duration` | `400ms` | ❌ | 动画持续时间 |

> `dockToEdge` 仅在 `bottom` / `left` / `right` 方向生效，启用后预留区域可透传点击。

### 返回值

- 通过 `dismiss(result)` 关闭时返回 `result`
- 点击遮罩关闭时返回 `null`

### 使用示例

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

// 左侧抽屉
final result = await Pop.sheet<String>(
  direction: SheetDirection.left,
  maxWidth: SheetDimension.fraction(0.75),
  title: '菜单',
  childBuilder: (dismiss) => ListView(
    children: [
      ListTile(
        leading: Icon(Icons.home),
        title: Text('首页'),
        onTap: () => dismiss('home'),
      ),
      ListTile(
        leading: Icon(Icons.settings),
        title: Text('设置'),
        onTap: () => dismiss('settings'),
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

// TabBar 顶部弹出，保留底部导航点击
await Pop.sheet<void>(
  title: 'TabBar 顶部弹出',
  dockToEdge: true,
  edgeGap: 64,
  childBuilder: (dismiss) => ListView(
    shrinkWrap: true,
    children: [
      ListTile(title: Text('收藏'), onTap: () => dismiss()),
      ListTile(title: Text('分享'), onTap: () => dismiss()),
    ],
  ),
);

// 自定义样式面板
await Pop.sheet<void>(
  title: '自定义样式',
  backgroundColor: Colors.grey[100],
  borderRadius: BorderRadius.circular(20),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      offset: Offset(0, -2),
    ),
  ],
  childBuilder: (dismiss) => Container(
    padding: EdgeInsets.all(16),
    child: Text('自定义内容'),
  ),
);

// 长列表面板
final result = await Pop.sheet<String>(
  title: '长列表',
  maxHeight: SheetDimension.pixel(400),
  childBuilder: (dismiss) => ListView.builder(
    itemCount: 50,
    itemBuilder: (context, index) => ListTile(
      title: Text('选项 ${index + 1}'),
      onTap: () => dismiss('option_${index + 1}'),
    ),
  ),
);

// 自定义动画时长
final result = await Pop.sheet<String>(
  title: '快速面板',
  animationDuration: Duration(milliseconds: 200),
  childBuilder: (dismiss) => ListView(
    children: [
      ListTile(title: Text('快速选项 1'), onTap: () => dismiss('option1')),
      ListTile(title: Text('快速选项 2'), onTap: () => dismiss('option2')),
    ],
  ),
);
```

## Date API

### 方法签名

```dart
static Future<DateTime?> date({
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

### 参数说明

| 参数 | 类型 | 默认值 | 必填 | 说明 |
|------|------|--------|------|------|
| `initialDate` | `DateTime?` | `null` | ❌ | 初始选中日期 |
| `minDate` | `DateTime?` | `null` | ❌ | 最小可选日期 |
| `maxDate` | `DateTime?` | `null` | ❌ | 最大可选日期 |
| `title` | `String` | `'Date of Birth'` | ❌ | 标题 |
| `position` | `PopupPosition` | `bottom` | ❌ | 显示位置 |
| `confirmText` | `String` | `'Confirm'` | ❌ | 确认按钮文本 |
| `cancelText` | `String?` | `'Cancel'` | ❌ | 取消按钮文本 |
| `activeColor` | `Color?` | `Colors.black` | ❌ | 选中颜色 |
| `noActiveColor` | `Color?` | `Colors.black38` | ❌ | 未选中颜色 |
| `headerBg` | `Color?` | `Colors.blue` | ❌ | 头部背景色 |
| `height` | `double?` | `180.0` | ❌ | 高度 |
| `radius` | `double?` | `24.0` | ❌ | 圆角 |
| `animationDuration` | `Duration` | `250ms` | ❌ | 动画持续时间 |

### 返回值

- 点击确认返回选中的 `DateTime`
- 点击取消或遮罩返回 `null`

### 使用示例

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
  noActiveColor: Colors.grey,
  headerBg: Colors.green,
  height: 200,
  radius: 16,
);

// 居中显示
final date = await Pop.date(
  title: '选择日期',
  position: PopupPosition.center,
  activeColor: Colors.blue,
  headerBg: Colors.blue,
);

// 自定义动画时长
final date = await Pop.date(
  title: '快速选择日期',
  animationDuration: Duration(milliseconds: 150),
);
```

## Menu API

### 方法签名

```dart
static Future<T?> menu<T>({
  required GlobalKey anchorKey,
  Offset anchorOffset = Offset.zero,
  required Widget Function(void Function([T? result]) dismiss) builder,
  bool showBarrier = true,
  bool barrierDismissible = true,
  Color barrierColor = Colors.transparent,
  PopupAnimation animation = PopupAnimation.fade,
  Duration animationDuration = const Duration(milliseconds: 200),
})
```

### 参数说明

| 参数 | 类型 | 默认值 | 必填 | 说明 |
|------|------|--------|------|------|
| `anchorKey` | `GlobalKey` | - | ✅ | 锚定目标的 GlobalKey |
| `anchorOffset` | `Offset` | `Offset.zero` | ❌ | 相对于目标的偏移 |
| `builder` | `Widget Function(void Function([T? result]) dismiss)` | - | ✅ | 内容构建器 |
| `showBarrier` | `bool` | `true` | ❌ | 是否显示遮罩 |
| `barrierDismissible` | `bool` | `true` | ❌ | 点击遮罩是否关闭 |
| `barrierColor` | `Color` | `Colors.transparent` | ❌ | 遮罩颜色 |
| `animation` | `PopupAnimation` | `fade` | ❌ | 动画类型 |
| `animationDuration` | `Duration` | `200ms` | ❌ | 动画时长 |

### 返回值

- 通过 `dismiss(result)` 关闭时返回 `result`
- 点击遮罩关闭时返回 `null`

### 使用示例

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

// 自定义样式菜单
final result = await Pop.menu<String>(
  anchorKey: buttonKey,
  anchorOffset: Offset(10, 40),
  builder: (dismiss) => Container(
    padding: EdgeInsets.all(8),
    child: Column(
      children: [
        _buildCustomMenuItem(
          icon: Icons.share,
          title: '分享',
          subtitle: '分享到社交媒体',
          onTap: () => dismiss('share'),
        ),
        Divider(height: 1),
        _buildCustomMenuItem(
          icon: Icons.favorite,
          title: '收藏',
          subtitle: '添加到收藏夹',
          onTap: () => dismiss('favorite'),
        ),
      ],
    ),
  ),
);
```

## PopupManager

PopupManager 是弹窗管理器，提供全局弹窗管理功能。它基于 Flutter 的 `Overlay` 系统实现，支持同时显示多个弹窗并独立管理它们的生命周期。

### 核心特性

- **单例模式**：全局唯一的弹窗管理器实例
- **ID 管理**：每个弹窗都有唯一的 `popupId` 用于精确控制
- **类型区分**：支持不同类型的弹窗（Toast、Loading、Confirm、Sheet、Date、Menu）
- **动画控制**：独立的动画控制器，支持进入和退出动画
- **自动清理**：自动管理资源释放，防止内存泄漏

### 静态方法

#### 初始化

```dart
static void initialize({required GlobalKey<NavigatorState> navigatorKey})
```

**说明：** 初始化 PopupManager，必须在 `main()` 函数中调用。

**参数：**
- `navigatorKey`：MaterialApp 的 navigatorKey，用于获取 Overlay

**使用示例：**
```dart
void main() {
  PopupManager.initialize(
    navigatorKey: GlobalKey<NavigatorState>(),
  );
  runApp(MyApp());
}
```

#### 显示弹窗

```dart
static String show(PopupConfig config)
```

**说明：** 显示弹窗并返回唯一的 popupId。

**参数：**
- `config`：弹窗配置对象

**返回值：** 弹窗的唯一 ID

**使用示例：**
```dart
final popupId = PopupManager.show(PopupConfig(
  child: CustomWidget(),
  position: PopupPosition.center,
  animation: PopupAnimation.fade,
  showBarrier: true,
  barrierDismissible: true,
));
```

#### 隐藏弹窗

```dart
static void hide(String popupId)
```

**说明：** 根据 popupId 隐藏指定的弹窗。

**参数：**
- `popupId`：要隐藏的弹窗 ID

**使用示例：**
```dart
PopupManager.hide(popupId);
```

#### 隐藏最后一个弹窗

```dart
static void hideLast()
```

**说明：** 隐藏最新显示的弹窗（任何类型）。

**使用示例：**
```dart
PopupManager.hideLast();
```

#### 隐藏所有弹窗

```dart
static void hideAll()
```

**说明：** 隐藏所有当前显示的弹窗。

**使用示例：**
```dart
PopupManager.hideAll();
```

#### 检查弹窗可见性

```dart
static bool isVisible(String popupId)
```

**说明：** 检查指定 ID 的弹窗是否仍然可见。

**参数：**
- `popupId`：要检查的弹窗 ID

**返回值：** 如果弹窗可见返回 `true`，否则返回 `false`

**使用示例：**
```dart
if (PopupManager.isVisible(popupId)) {
  print('弹窗仍然可见');
}
```

#### 检查非 Toast 弹窗

```dart
static bool get hasNonToastPopup
```

**说明：** 检查是否存在非 Toast 类型的弹窗。

**返回值：** 如果有非 Toast 弹窗返回 `true`，否则返回 `false`

**使用示例：**
```dart
if (PopupManager.hasNonToastPopup) {
  // 处理返回键逻辑
}
```

#### 隐藏最后一个非 Toast 弹窗

```dart
static bool hideLastNonToast()
```

**说明：** 隐藏最后一个非 Toast 类型的弹窗。

**返回值：** 如果成功隐藏了弹窗返回 `true`，否则返回 `false`

**使用示例：**
```dart
if (PopupManager.hideLastNonToast()) {
  print('成功隐藏了非 Toast 弹窗');
} else {
  print('没有找到非 Toast 弹窗');
}
```

#### 智能返回

```dart
static void maybePop(BuildContext context)
```

**说明：** 智能返回方法。如果有非 Toast 弹窗，则关闭最上层的弹窗；否则执行标准的 Navigator.pop()。

**参数：**
- `context`：BuildContext

**使用示例：**
```dart
// 在自定义返回按钮中使用
AppBar(
  leading: IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () => PopupManager.maybePop(context),
  ),
)
```

### popupId 使用规则

#### ✅ 可以通过 popupId 关闭的弹窗

1. **Loading 弹窗**：`Pop.loading()` 返回 popupId
2. **手动创建的弹窗**：通过 `PopupManager.show()` 直接创建

#### ❌ 不能通过 popupId 关闭的弹窗

1. **Toast 弹窗**：`Pop.toast()` 不返回 popupId，自动管理
2. **Confirm 弹窗**：`Pop.confirm()` 通过用户交互关闭
3. **Sheet 弹窗**：`Pop.sheet()` 通过 dismiss() 函数关闭
4. **Date 弹窗**：`Pop.date()` 通过用户选择关闭
5. **Menu 弹窗**：`Pop.menu()` 通过 dismiss() 函数关闭

### 内部工作原理

#### 弹窗 ID 生成

```dart
final popupId = 'popup_${DateTime.now().microsecondsSinceEpoch}_${_instance._popups.length}';
```

#### 弹窗信息存储

```dart
class _PopupInfo {
  final OverlayEntry entry;        // UI 组件
  final AnimationController controller;  // 动画控制器
  final VoidCallback? onDismissCallback; // 关闭回调
  final PopupType type;            // 弹窗类型
  Timer? dismissTimer;             // 自动关闭定时器
}
```

#### 弹窗显示流程

1. 创建独立的 `AnimationController` 和 `OverlayEntry`
2. 将弹窗信息存储在 `_popups` Map 中
3. 按显示顺序记录在 `_popupOrder` 列表中
4. 插入到 Flutter 的 Overlay 系统中
5. 播放进入动画
6. 启动自动关闭定时器（如果设置了 duration）

#### 弹窗关闭流程

1. 从管理器中立即移除弹窗信息
2. 取消自动关闭定时器
3. 播放退出动画
4. 动画完成后清理资源
5. 触发 onDismiss 回调

### 使用示例

```dart
// 初始化
void main() {
  PopupManager.initialize(
    navigatorKey: GlobalKey<NavigatorState>(),
  );
  runApp(MyApp());
}

// 全局管理
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: PopupManager.navigatorKey,
      home: PopScopeWidget(
        child: HomePage(),
      ),
    );
  }
}

// 处理返回键
WillPopScope(
  onWillPop: () async {
    if (PopupManager.hasNonToastPopup) {
      PopupManager.hideLastNonToast();
      return false;
    }
    return true;
  },
  child: HomePage(),
)
```

## 枚举类型

### PopupPosition

```dart
enum PopupPosition {
  top,    // 顶部
  center, // 居中
  bottom, // 底部
  left,   // 左侧
  right,  // 右侧
}
```

### PopupAnimation

```dart
enum PopupAnimation {
  none,      // 无动画
  fade,      // 淡入淡出
  slideDown, // 从上往下滑入
  slideUp,   // 从下往上滑入
  slideLeft, // 从左往右滑入
  slideRight,// 从右往左滑入
}
```

### SheetDirection

```dart
enum SheetDirection {
  top,    // 顶部
  bottom, // 底部
  left,   // 左侧
  right,  // 右侧
}
```

### ToastType

```dart
enum ToastType {
  success, // 成功
  warn,    // 警告
  error,   // 错误
  none,    // 无类型
}
```

### ConfirmButtonLayout

```dart
enum ConfirmButtonLayout {
  row,    // 水平排列
  column, // 垂直排列
}
```

### PopupType

```dart
enum PopupType {
  toast,   // Toast 类型
  loading, // Loading 类型
  confirm, // Confirm 类型
  sheet,   // Sheet 类型
  date,    // Date 类型
  menu,    // Menu 类型
  other,   // 其他类型
}
```

## SheetDimension

用于定义弹窗尺寸的工具类。

### 构造方法

```dart
// 固定像素值
SheetDimension.pixel(double value)

// 占屏幕可用空间的分数（0.0 to 1.0）
SheetDimension.fraction(double value)
```

### 使用示例

```dart
// 固定像素
width: SheetDimension.pixel(300)

// 百分比
width: SheetDimension.fraction(0.8) // 80%

// 在 Sheet 中使用
await Pop.sheet(
  maxWidth: SheetDimension.fraction(0.75),
  maxHeight: SheetDimension.pixel(400),
  childBuilder: (dismiss) => ...,
);
```
