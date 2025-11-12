# unified_popups (English)

[![Pub Version](https://img.shields.io/pub/v/unified_popups.svg)](https://pub.dev/packages/unified_popups)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 📖 Overview

[CHINESE](./README.md)

Unified Popups is a unified popup solution designed for enterprise-level Flutter applications. It provides a clean, easy-to-use API covering common popup scenarios, including toast messages, loading indicators, confirmation dialogs, bottom panels, date pickers, and anchored menus.

### ✨ Key Features

- **Unified API**: All popups are called through the `Pop` static class with a consistent API design
- **Type Safety**: Full type support with compile-time error checking
- **Multi-instance Support**: Based on Overlay implementation, supports displaying multiple popups simultaneously
- **Animation Duration Configuration**: Each API supports custom animation duration for optimal experience in different scenarios
- **Keyboard Adaptation**: Automatically handles layout adjustments and focus management when keyboard appears
- **Gesture Support**: Supports drag-to-close, tap barrier to close, and other interactions
- **Theming**: Supports custom styles and theme configuration
- **Accessibility Support**: Built-in accessibility support, compliant with accessibility design standards
- **Performance Optimized**: Based on Overlay implementation, excellent performance with low memory usage

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
  unified_popups:  # Use the latest version
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
final loadingId = Pop.loading(message: 'Loading...');
// ... async operation
Pop.hideLoading(loadingId);

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

**Parameters:**
- `message`: Message text (required)
- `position`: Display position, supports `top`, `center`, `bottom`, `left`, `right`
- `duration`: Display duration, default 1.2 seconds
- `toastType`: Toast type, supports `success`, `warn`, `error`, `none`
- `animationDuration`: Animation duration, default 200ms
- `customImagePath`: Custom image path, if provided will override toastType icon
- `imageSize`: Image size, default 24.0
- `imgColor`: Tint color for the custom image (only applied when `customImagePath` is provided)
- `layoutDirection`: Layout direction, default `Axis.horizontal` (Row), `Axis.vertical` for Column (image above, text below)
- `showBarrier`: Whether to show barrier
- `barrierDismissible`: Whether tapping barrier closes the popup

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
```

### Loading Indicator

Used to display loading state with support for custom styles and interactions.

```dart
String loading({
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

**Returns:** Returns the unique ID of the Loading for subsequent closing

**Parameters:**
- `customIndicator`: Custom Widget (typically an image), if provided will replace the default CircularProgressIndicator and automatically add rotation animation
- `rotationDuration`: Rotation animation duration, default 1 second. Only effective when using customIndicator

**Usage Examples:**
```dart
// Basic usage
final loadingId = Pop.loading(message: 'Submitting...');
await submitData();
Pop.hideLoading(loadingId);

// Use custom image as loading indicator
final loadingId = Pop.loading(
  message: 'Loading',
  customIndicator: Image.asset('assets/loading.png'),
  rotationDuration: Duration(milliseconds: 800),
);

// Custom style
final loadingId = Pop.loading(
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
final loadingId = Pop.loading(
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
  Duration animationDuration = const Duration(milliseconds: 400),
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

## 🔧 What's New in v1.1.4

### Toast Enhancements
- Added `customImagePath` parameter to support custom local images
- Added `imageSize` parameter to customize image size (default: 24.0)
- Added `layoutDirection` parameter to support Row/Column layout switching
- Custom images will override toastType icons when provided

### Loading Enhancements
- Added `customIndicator` parameter to support custom Widget as loading indicator
- Added `rotationDuration` parameter to configure rotation animation speed
- Custom indicator automatically includes rotation animation
- Container maintains square aspect ratio when both message and customIndicator are present (max 25% screen width, 100px)

## 🔧 What's New in v1.1.6

### Toast Enhancements
- Added `imgColor` parameter so custom images can be tinted directly from `Pop.toast`

### Confirm Enhancements
- Added `confirmBorder` and `cancelBorder` parameters for custom button borders
- Confirm buttons now use container-based styling, making it easier to match background colors and borders

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📚 More Documentation

- [API Reference](doc/API_REFERENCE.md) - Detailed API documentation and parameter lists
- [Best Practices](doc/BEST_PRACTICES.md) - Usage recommendations and best practices
- [Full Documentation](doc/README.md) - Complete user guide

---

**Unified Popups** - Making popup development simpler, more unified, and more efficient!

