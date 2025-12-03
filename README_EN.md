# unified_popups (English)

[![Pub Version](https://img.shields.io/pub/v/unified_popups.svg)](https://pub.dev/packages/unified_popups)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 📖 Overview

[CHINESE](./README.md)

Unified Popups is a unified popup solution designed for enterprise-level Flutter applications. It provides a clean, easy-to-use API covering common popup scenarios, including toast messages, loading indicators, confirmation dialogs, bottom panels, date pickers, and anchored menus.

### ✨ Key Features

- **🆕 Async Popup Support**: All popup types fully support async calls without build-phase errors thanks to `SafeOverlayEntry` plus build-phase detection. Works seamlessly inside `Future.then()`, `async/await`, `Stream`, `Timer`, or even during `build()`
- **Unified API**: Everything starts from the `Pop` static class, keeping API design consistent across toast, loading, confirm, sheet, date, and menu
- **Type Safety**: Built on Dart's strong typing and `flutter_lints`, helping catch mistakes at compile time
- **Multi-instance Support**: Overlay-based implementation keeps multiple popups running independently
- **Animation Flexibility**: Every API exposes both animation duration and animation curve, so you can fine-tune easing per scenario
- **Keyboard Adaptation**: Automatically adjusts layout and focus management when the keyboard appears
- **Gesture Support**: Supports drag-to-close, tap barrier to close, and other interactions
- **Theming**: Supports custom styles and theme configuration
- **Accessibility Support**: Built-in accessibility support, compliant with accessibility design standards
- **Performance Optimized**: Overlay-based approach offers excellent performance with low memory usage

### 🎯 Use Cases

- Various popup requirements in enterprise applications
- Large projects requiring unified popup experience
- Applications with high requirements for keyboard adaptation and user experience
- Projects that need to support multiple platforms (mobile, Web, desktop)

## 🚀 Quick Start

### Installation

Add the dependency to `pubspec.yaml`:

```yaml
dependencies:
  unified_popups: ^1.1.14 # Use the latest version
```

### Initialization

Initialize in `main.dart`:

```dart
void main() {
  runApp(const MyApp());
  // Make sure to initialize the PopupManager only after the MaterialApp has been built.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PopupManager.initialize(navigatorKey: navigatorKey);
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: GlobalKey<NavigatorState>(), // Required
      home: PopScopeWidget( // Optional: for handling back button
        child: HomePage(),
      ),
    );
  }
}
```

### Basic Usage

```dart
// Show toast message
Pop.toast('Operation successful', toastType: ToastType.success);

// Show loading indicator
Pop.loading(message: 'Loading...');
// ... async operation
Pop.hideLoading();

// Show confirmation dialog
final result = await Pop.confirm(
  title: 'Delete Confirmation',
  content: 'This operation cannot be undone. Continue?',
  confirmText: 'Delete',
  cancelText: 'Cancel',
  confirmBorder: Border.all(color: Colors.redAccent),
);
```

## 📚 API Reference

### Toast Messages

Used to display temporary message notifications.

```dart
Pop.toast(
  String message, {
  PopupPosition position = PopupPosition.center,
  Duration duration = const Duration(milliseconds: 1200),
  bool showBarrier = false,
  bool barrierDismissible = false,
  ToastType toastType = ToastType.none,
  Duration animationDuration = const Duration(milliseconds: 200),
  Curve? animationCurve,
  String? customImagePath,
  double? imageSize,
  Color? imgColor,
  Axis layoutDirection = Axis.horizontal,
  EdgeInsetsGeometry? padding,
  EdgeInsetsGeometry? margin,
  Decoration? decoration,
  TextStyle? style,
  TextAlign? textAlign,
  String? tMessage,
  String? tImagePath,
  ToastType? tToastType,
  Color? tImgColor,
  VoidCallback? onTap,
  bool toggleable = false,
})
```

**Parameters:**
- `message`: Message text (required)
- `position`: Display position, supports `top`, `center`, `bottom`, `left`, `right`
- `duration`: Display duration, default 1.2 seconds
- `toastType`: Toast type, supports `success`, `warn`, `error`, `none`
- `animationDuration`: Animation duration, default 200ms
- `animationCurve`: Animation curve, default `Curves.easeInOut`
- `customImagePath`: Custom image path, if provided will override toastType icon
- `imageSize`: Image size, default 24.0
- `imgColor`: Tint color for the custom image (only applied when `customImagePath` is provided)
- `layoutDirection`: Layout direction, default `Axis.horizontal` (Row), `Axis.vertical` for Column (image above, text below)
- `showBarrier`: Whether to show barrier
- `barrierDismissible`: Whether tapping barrier closes the popup
- `tMessage`: Alternate message text (optional), for toggle mode
- `tImagePath`: Alternate image path (optional), for toggle mode
- `tToastType`: Alternate toast type (optional), for toggle mode
- `tImgColor`: Alternate image color (optional), for toggle mode
- `onTap`: Tap callback (optional)
- `toggleable`: Whether toggle is enabled, default `false`. When set to `true` and `tMessage` or `tImagePath` is provided, tapping the toast will switch between two states

**Usage Examples:**
```dart
// Success toast
Pop.toast('Save successful', toastType: ToastType.success);

// Error toast
Pop.toast('Network error, please try again later', toastType: ToastType.error);

// Custom image
Pop.toast(
  'Custom image toast',
  customImagePath: 'assets/custom_icon.png',
  imageSize: 32.0,
  imgColor: Colors.orange,
  layoutDirection: Axis.vertical, // Image above, text below
);

// Custom animation duration
Pop.toast('Quick toast', animationDuration: Duration(milliseconds: 100));

// Custom style
Pop.toast(
  'Custom style toast',
  decoration: BoxDecoration(
    gradient: LinearGradient(colors: [Colors.purple, Colors.blue]),
    borderRadius: BorderRadius.circular(20),
  ),
  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
);

// Toggle mode: Balance lock and gravity sensing
Pop.toast(
  'Balance Lock',
  customImagePath: 'assets/balance_lock.png',
  tMessage: 'Gravity Sensing',
  tImagePath: 'assets/gravity.png',
  toggleable: true,
  imageSize: 32,
  duration: const Duration(seconds: 2),
  onTap: () {
    print('Toast state toggled');
  },
);
```

### Loading Indicator

Used to display loading state with support for custom styles and interactions.

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
  Curve? animationCurve,
})
```

**Note:** The entire application can only have one loading instance at a time, managed internally. When showing a new loading, any existing loading is automatically closed. No need to manually manage loading IDs.

**Parameters:**
- `customIndicator`: Custom Widget (typically an image), if provided will replace the default CircularProgressIndicator and automatically add rotation animation
- `rotationDuration`: Rotation animation duration, default 1 second. Only effective when using customIndicator
- `animationCurve`: Animation curve, default `Curves.easeInOut`

**Usage Examples:**
```dart
// Basic usage
Pop.loading(message: 'Submitting...');
await submitData();
Pop.hideLoading();

// Use custom image as loading indicator
Pop.loading(
  message: 'Loading',
  customIndicator: Image.asset('assets/loading.png'),
  rotationDuration: Duration(milliseconds: 800),
);

// Custom style
Pop.loading(
  message: 'Custom style Loading',
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

// Quick loading display
Pop.loading(
  message: 'Quick loading',
  animationDuration: Duration(milliseconds: 100),
);
```

### Bottom Sheet

Displays a panel sliding out from a specific direction. Commonly used for list selections or lightweight forms.

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
  bool? showBarrier,
  bool? barrierDismissible,
  Color? barrierColor,
  String? imgPath,
  Color? backgroundColor,
  BorderRadius? borderRadius,
  List<BoxShadow>? boxShadow,
  EdgeInsetsGeometry? padding,
  EdgeInsetsGeometry? titlePadding,
  TextStyle? titleStyle,
  TextAlign? titleAlign,
  bool dockToEdge = false,
  double? edgeGap,
  Duration animationDuration = const Duration(milliseconds: 400),
  Curve? animationCurve,
})
```

**Parameters:**
- `direction`: Slide-in direction, supports `top`, `bottom`, `left`, `right`
- `width`/`height`: Dimensions, supports pixels or percentages
- `useSafeArea`: Whether to respect safe area
- `showBarrier` / `barrierDismissible` / `barrierColor`: Control whether the barrier is shown, whether taps dismiss it, and the barrier color
- `dockToEdge`: When sliding from the `bottom` / `left` / `right`, keep the originating edge interactive (sheet and barrier both avoid it)
- `edgeGap`: Size of the reserved edge region, defaults to `kBottomNavigationBarHeight + 4`
- `animationDuration`: Animation duration, default 400ms
- `animationCurve`: Animation curve, default `Curves.easeInOut`

> `dockToEdge` is not available for the `top` position. When enabled, the reserved edge stays fully interactive (e.g. TabBar or navigation bar taps go through).

**Usage Examples:**
```dart
// Basic bottom sheet
final result = await Pop.sheet<String>(
  title: 'Pick an option',
  childBuilder: (dismiss) => ListView(
    shrinkWrap: true,
    children: [
      ListTile(title: Text('Share'), onTap: () => dismiss('share')),
      ListTile(title: Text('Edit'), onTap: () => dismiss('edit')),
    ],
  ),
);

// Custom barrier behavior
await Pop.sheet<void>(
  title: 'Barrier example',
  showBarrier: true,
  barrierDismissible: false,
  barrierColor: Colors.black87.withOpacity(0.6),
  childBuilder: (dismiss) => Padding(
    padding: const EdgeInsets.all(16),
    child: ElevatedButton(
      onPressed: () => dismiss(),
      child: const Text('Close'),
    ),
  ),
);

// Anchor above TabBar
await Pop.sheet<void>(
  title: 'Anchor above TabBar',
  dockToEdge: true,
  edgeGap: 64, // Optional: customise the reserved height/width
  childBuilder: (dismiss) => ListView(
    shrinkWrap: true,
    children: [
      ListTile(title: const Text('Favorite'), onTap: () => dismiss()),
      ListTile(title: const Text('Share'), onTap: () => dismiss()),
    ],
  ),
);
// The TabBar stays visible and tappable because the barrier stops above it
```

### Confirmation Dialog

Collect user decisions with highly customizable dialogs.

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
  Curve? animationCurve,
})
```

**Highlights**
- `confirmBorder` / `cancelBorder`: define button borders for secondary emphasis
- `confirmChild`: insert extra widgets (forms, inputs, etc.) between content and actions
- `animationCurve`: override the default `Curves.easeInOut` easing

**Usage**
```dart
final ok = await Pop.confirm(
  title: 'Delete user',
  content: 'This action cannot be undone.',
  confirmText: 'Delete',
  confirmBgColor: Colors.red,
  confirmBorder: Border.all(color: Colors.redAccent),
);

final result = await Pop.confirm(
  title: 'Extra input',
  content: 'Please describe the issue.',
  confirmChild: TextField(maxLines: 3),
  buttonLayout: ConfirmButtonLayout.column,
);
```

### Date Picker

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
  Curve? animationCurve,
})
```

Tweak the picker with `animationDuration` / `animationCurve`, color accents, or container size.

```dart
final date = await Pop.date(
  title: 'Select birthday',
  minDate: DateTime(1900, 1, 1),
  maxDate: DateTime.now(),
);

final joinedOn = await Pop.date(
  title: 'Joined at',
  initialDate: DateTime.now(),
  activeColor: Colors.green,
  headerBg: Colors.green,
  radius: 16,
);
```

### Anchored Menu

```dart
Future<T?> menu<T>({
  required GlobalKey anchorKey,
  Offset anchorOffset = Offset.zero,
  required Widget Function(void Function([T? result]) dismiss) builder,
  bool showBarrier = true,
  bool barrierDismissible = true,
  Color? barrierColor,
  PopupAnimation animation = PopupAnimation.fade,
  Duration animationDuration = const Duration(milliseconds: 200),
  BoxDecoration? decoration,
  EdgeInsetsGeometry? padding,
  BoxConstraints? constraints,
  Curve? animationCurve,
})
```

Anchored menus default to a translucent barrier (`Colors.black54`). Override `barrierColor`, animation duration, or easing to match your motion system.

```dart
final GlobalKey btnKey = GlobalKey();

ElevatedButton(
  key: btnKey,
  onPressed: () async {
    final value = await Pop.menu<String>(
      anchorKey: btnKey,
      anchorOffset: const Offset(0, 8),
      builder: (dismiss) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.content_copy),
            title: const Text('Copy'),
            onTap: () => dismiss('copy'),
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () => dismiss('delete'),
          ),
        ],
      ),
    );
  },
  child: const Text('More'),
);
```

## 🎨 Styling

Every API exposes both `animationDuration` and `animationCurve`, so you can align motion with the surrounding UX.

```dart
Pop.toast(
  'Quick feedback',
  animationDuration: const Duration(milliseconds: 120),
  animationCurve: Curves.easeOut,
);

Pop.sheet(
  title: 'Deep workflow',
  animationDuration: const Duration(milliseconds: 480),
  animationCurve: Curves.easeOutCubic,
  childBuilder: (dismiss) => const ComplexForm(),
);
```

Default animation durations:

- `Pop.toast()`: 200 ms
- `Pop.loading()`: 150 ms
- `Pop.confirm()`: 250 ms
- `Pop.date()`: 250 ms
- `Pop.menu()`: 200 ms
- `Pop.sheet()`: 400 ms

All APIs default to `Curves.easeInOut`. Override `animationCurve` for bounce, elastic, or physics-inspired motions.

## 🔧 Best Practices

- **Keyboard-friendly layouts**: place text fields inside `confirmChild` or a scrollable sheet and the library will handle safe areas and focus changes.
- **Error handling**: always call `Pop.hideLoading()` inside `finally`/`catch` blocks to prevent orphaned overlays.
- **Back navigation**: wrap your root with `PopScopeWidget` or defer the system back button by checking `PopupManager.hasNonToastPopup`.
- **Single-loading rule**: `Pop.loading()` already enforces a single instance. Prefer showing success/failure via toast once the operation completes.

## 🧠 PopupManager Essentials

`PopupManager` keeps track of active overlays and exposes utility helpers:

```dart
final id = PopupManager.show(PopupConfig(child: CustomPopup()));
PopupManager.hide(id);          // close explicit popups
PopupManager.hideLast();        // close the most recent popup
PopupManager.hideAll();         // clear every popup
PopupManager.hideByType(PopupType.loading); // close by semantic type
final hasOverlay = PopupManager.hasNonToastPopup;
```

It also powers `PopScopeWidget`, enabling smarter back-button handling based on `hasNonToastPopup` notifications.

## 🚀 Performance Tips

- Debounce repeated calls when showing lots of toast notifications.
- Reuse expensive widgets inside sheets/menus instead of rebuilding giant child trees every time.
- Keep images and custom indicators lightweight to avoid layout jank.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📚 More Documentation

- [API Reference](doc/API_REFERENCE.md) - Detailed API documentation and parameter lists
- [Best Practices](doc/BEST_PRACTICES.md) - Usage recommendations and best practices
- [Full Documentation](doc/README.md) - Complete user guide

---

**Unified Popups** - Making popup development simpler, more unified, and more efficient!

