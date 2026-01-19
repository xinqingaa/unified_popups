# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Unified Popups is a Flutter package providing a unified, enterprise-grade popup solution. All popups are accessed through the `Pop` static class API, supporting toast, loading, confirm dialogs, bottom sheets, date pickers, and anchored menus.

## Development Commands

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Run the example app
cd example && flutter run

# Format code
dart format .
```

### Testing
```bash
# Run tests (in package root)
flutter test

# Run example app tests
cd example && flutter test
```

## Architecture

### Core Components

**PopupManager** (`lib/src/core/popup_manager.dart`)
- Singleton that manages all popup overlays using Flutter's Overlay system
- Tracks active popups in `Map<String, _PopupInfo>` with display order in `_popupOrder` list
- Each popup has unique ID, independent AnimationController, and optional auto-dismiss Timer
- Uses `SafeOverlayEntry` to avoid setState errors during build phase
- Provides `show()` to insert popups and `hide()` variants (`hide(id)`, `hideLast()`, `hideAll()`, `hideByType()`)
- Supports route-change aware dismissal via `dismissOnRouteChange` configuration

**Pop APIs** (`lib/src/apis/pop.dart`)
- Static class with part files for each popup type: toast, loading, confirm, sheet, date, menu
- Each API method delegates to private implementation in part files
- Loading is singleton (only one at a time), managed internally via `hideByType(PopupType.loading)`
- Other types support multiple instances simultaneously

**PopupConfig** (`lib/src/models/popup_config.dart` - part of popup_manager.dart)
- Configuration model for all popup types
- Key parameters: `child`, `position`, `animation`, `animationDuration`, `animationCurve`, `showBarrier`, `barrierDismissible`, `type`, `dismissOnRouteChange`
- Controls popup behavior including dock-to-edge for bottom/side navigation preservation

**Widgets** (`lib/src/widgets/`)
- `popup_layout.dart`: Core layout wrapper handling positioning, animations, and barrier
- `toast_widget.dart`, `loading_widget.dart`, `confirm_widget.dart`, `sheet_widget.dart`, `date_picker_widget.dart`, `menu_widget.dart`: Specific popup UI implementations
- `pop_scope_widget.dart`: Widget for intercepting system back button to close popups before routes

**PopupRouteObserver** (`lib/src/core/popup_route_observer.dart`)
- NavigatorObserver that watches push/pop/replace events
- Automatically closes popups with `dismissOnRouteChange=true` on navigation
- Works with `PopScopeWidget` for comprehensive popup lifecycle management

### Key Design Patterns

1. **SafeOverlayEntry**: Extends OverlayEntry to defer `markNeedsBuild()` if called during build phase (SchedulerPhase.persistentCallbacks), preventing setState errors in async contexts

2. **Part Files**: PopupManager and Pop API use Dart's part/part-of pattern to split implementation while keeping access private

3. **Animation Per Popup**: Each popup gets its own AnimationController, allowing independent animations with custom curves and durations

4. **Type-Based Filtering**: `PopupType` enum drives behavior like back button interception (`hasNonToastPopup`) and route-change dismissal

5. **Builder Pattern**: APIs like `sheet` and `menu` receive `dismiss` callback in their builder, allowing child widgets to close themselves

### Initialization Pattern

```dart
void main() {
  final navigatorKey = GlobalKey<NavigatorState>();
  runApp(MyApp(navigatorKey: navigatorKey));

  // Must initialize AFTER MaterialApp builds
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PopupManager.initialize(navigatorKey: navigatorKey);
  });
}

MaterialApp(
  navigatorKey: navigatorKey,
  home: const PopScopeWidget(child: HomePage()),
  navigatorObservers: const [PopupRouteObserver()],
)
```

### Popup Types & Behavior

| Type | Multi-instance? | Auto-dismiss on route change | Back button behavior |
|------|-----------------|------------------------------|---------------------|
| Toast | Yes | No | Toast ignored, closes latest non-toast |
| Loading | No (singleton) | No | Toast ignored, closes latest non-toast |
| Confirm | Yes | Yes (default) | Closes via `hideLastNonToast()` |
| Sheet | Yes | Yes (default) | Closes via `hideLastNonToast()` |
| Date | Yes | No | Closes via `hideLastNonToast()` |
| Menu | Yes | No | Closes via `hideLastNonToast()` |

### Animation Configuration

Default animation durations vary by type:
- Toast: 200ms (fast feedback)
- Loading: 150ms (fast feedback)
- Confirm: 250ms (moderate)
- Date: 250ms (moderate)
- Menu: 200ms (quick response)
- Sheet: 400ms (drawer-style animation)

All APIs accept `animationDuration` and `animationCurve` (defaults to `Curves.easeInOut`) for customization.

### Asset Paths

Package assets in `lib/assets/images/` are for internal use (toast icons, loading indicators). Custom image paths provided by users should be relative to their app's assets directory.

### Common Patterns

**Showing toast:**
```dart
Pop.toast('Message', toastType: ToastType.success);
```

**Loading wrapper:**
```dart
Pop.loading(message: 'Loading...');
try {
  await operation();
} finally {
  Pop.hideLoading();
}
```

**Confirm with custom content:**
```dart
final result = await Pop.confirm(
  title: 'Confirm',
  content: 'Description',
  confirmChild: TextField(...), // Extra widget between content and buttons
);
if (result == true) { /* confirmed */ }
```

**Sheet with result:**
```dart
final selected = await Pop.sheet<String>(
  title: 'Select',
  childBuilder: (dismiss) => ListView(
    children: [
      ListTile(title: Text('Option 1'), onTap: () => dismiss('opt1')),
    ],
  ),
);
```

**Manual popup control:**
```dart
final id = PopupManager.show(PopupConfig(
  child: MyCustomPopup(),
  type: PopupType.other,
));
// Later
PopupManager.hide(id);
```

### Working with the Example App

The example app (`example/`) demonstrates all popup types. To test changes:
1. Modify package code in `lib/`
2. Run `cd example && flutter run` (example uses `path: ../` dependency)
3. Test specific popup scenarios from the example app UI

### Important Constraints

- Loading is single-instance: calling `Pop.loading()` automatically closes any existing loading
- Toast cannot be manually dismissed via ID (auto-dismiss only by duration or toggle)
- Sheet/Menu rely on injected `dismiss()` callback for programmatic closing
- `dockToEdge` only works for bottom/left/right directions, not top
- Always wrap async operations with try-finally when using loading to ensure cleanup
