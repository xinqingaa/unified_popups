# unified_popups (English)

[![Pub Version](https://img.shields.io/pub/v/unified_popups.svg)](https://pub.dev/packages/unified_popups)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[中文](README.md) · [Docs hub](docs/README.md) · [API reference](docs/API_REFERENCE.md) · [Best practices](docs/BEST_PRACTICES.md)

## Overview

Unified Popups exposes Overlay-based UI through the `Pop` static API: toast, loading, confirm, sheet, **flowSheet**, date, and menu.

### Highlights

- **One API surface**: everything via `Pop.*`
- **Async-safe**: `SafeOverlayEntry` avoids build-phase setState errors
- **FlowSheet**: multi-page stack inside one sheet (`push` / `pop` / `replace` / `completeCurrent` / `closeAll`) with lifecycle hooks
- **Sheet drag**: `SheetDragDismissMode` (`fullBody` / `contentWhenAtTop` / `handleOnly`), drag handle, keyboard lift
- **Back & routes**: `onBackPressed`, `PopScopeWidget`, `PopupRouteObserver` (including `didRemove`), `dismissOnRouteChange`
- **Multi-instance**: all types except singleton loading; customizable animation duration/curve

## Install

```yaml
dependencies:
  unified_popups:
```

Use the version from [pub.dev](https://pub.dev/packages/unified_popups) / your `pubspec.yaml`.

## Initialize

Use the **same** `navigatorKey`, plus the route observer and back interceptor:

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

## Basic usage

```dart
Pop.toast('Saved', toastType: ToastType.success);

Pop.loading(message: 'Loading...');
try {
  await fetchData();
} finally {
  Pop.hideLoading();
}

final ok = await Pop.confirm(
  title: 'Delete',
  content: 'This cannot be undone',
);
```

### Sheet

```dart
final selected = await Pop.sheet<String>(
  title: 'Filter',
  dockToEdge: true,
  edgeGap: 84, // match NavigationBar height
  dragDismissMode: SheetDragDismissMode.contentWhenAtTop,
  childBuilder: (dismiss) => ListTile(
    title: const Text('Strength'),
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

Pages extend `FlowSheetPage` / `FlowSheetPageState` and navigate with `nav.push` / `pop` / `replace` / `completeCurrent` / `closeAll`. Prefer `completeCurrent` / `closeAll` to finish the whole flow (avoids double animations).

Full parameter tables: [docs/API_REFERENCE.md](docs/API_REFERENCE.md) (Chinese; authoritative).

## Example: FitPulse

`example/` is a fitness-style demo:

| Area | Covers |
|------|--------|
| Today | toast / loading / confirm |
| Workouts | sheet (dockToEdge), menu, start-workout FlowSheet |
| Progress | date, export loading |
| Profile | profile sheet, health-profile FlowSheet, settings routes (route-dismiss) |
| Lab (AppBar ⋯) | Async / PopupManager edge cases |

```bash
cd example && flutter run
```

## Docs

- [Docs hub](docs/README.md)
- [API reference](docs/API_REFERENCE.md)
- [Best practices](docs/BEST_PRACTICES.md)
- [CHANGELOG](CHANGELOG.md)
