# unified_popups (English)

[![Pub Version](https://img.shields.io/pub/v/unified_popups.svg)](https://pub.dev/packages/unified_popups)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[中文](README.md) · [Docs hub](docs/README.md) · [API reference](docs/API_REFERENCE.md) · [Best practices](docs/BEST_PRACTICES.md)

## Overview

Unified Popups is a Flutter overlay toolkit. Everything goes through the `Pop` static API:

`toast` · `loading` · `confirm` · `sheet` · `flowSheet` · `date` · `menu`

### Capabilities

- **One entry point**: everyday use via `Pop.*`; fully custom overlays via `PopupManager.show`
- **Multi-instance overlays**: all types except singleton loading; independent animations
- **Async-safe**: `SafeOverlayEntry` avoids build-phase setState errors (`async` / `Future.then` / `Timer` OK)
- **Tunable motion**: `animationDuration` / `animationCurve` on each API
- **Back & routes**: `PopScopeWidget`, `PopupRouteObserver`, `dismissOnRouteChange`, `onBackPressed`
- **Sheet family**: directional panels, `dockToEdge`, drag-to-dismiss, keyboard lift; multi-step via `flowSheet`

Full parameter tables: [docs/API_REFERENCE.md](docs/API_REFERENCE.md) (Chinese; authoritative).

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

## API overview

### Toast

Short feedback. Supports typed icons, custom images, `messageWidget`, and toggle mode.

```dart
Pop.toast('Saved', toastType: ToastType.success);

Pop.toast(
  'Network error, try again',
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
      Text('Done'),
    ],
  ),
);
```

### Loading

Blocking indicator. **Singleton**: a new call dismisses any existing loading. Always use `try/finally`.

```dart
Pop.loading(message: 'Submitting...');
try {
  await submitData();
  Pop.toast('Submitted', toastType: ToastType.success);
} finally {
  Pop.hideLoading();
}

Pop.loading(
  message: 'Loading',
  customIndicator: Image.asset('assets/loading.png'),
  rotationDuration: const Duration(milliseconds: 800),
);
```

### Confirm

User confirmation. Returns `true` / `false` / `null` (barrier or close). Supports `confirmChild`, custom button widgets, and `onConfirm` / `onCancel`.

```dart
final ok = await Pop.confirm(
  title: 'Delete',
  content: 'This cannot be undone. Continue?',
  confirmText: 'Delete',
  cancelText: 'Cancel',
  confirmBgColor: Colors.red,
);
if (ok == true) { /* delete */ }

final named = await Pop.confirm(
  title: 'Details',
  content: 'Please fill in:',
  confirmChild: TextField(decoration: InputDecoration(labelText: 'Name')),
);
```

### Sheet

Directional panel for lists, forms, drawers. Close via injected `dismiss(result)`.

```dart
final action = await Pop.sheet<String>(
  title: 'Actions',
  childBuilder: (dismiss) => ListView(
    shrinkWrap: true,
    children: [
      ListTile(title: Text('Copy'), onTap: () => dismiss('copy')),
      ListTile(title: Text('Delete'), onTap: () => dismiss('delete')),
    ],
  ),
);

// Keep bottom nav tappable
await Pop.sheet<void>(
  title: 'Filter',
  dockToEdge: true,
  edgeGap: 84, // match NavigationBar height
  dragDismissMode: SheetDragDismissMode.contentWhenAtTop,
  childBuilder: (dismiss) => FilterForm(onDone: () => dismiss()),
);
```

Common options: `direction`, `dockToEdge` / `edgeGap`, `showDragHandle`, `dragDismissMode` (`fullBody` / `contentWhenAtTop` / `handleOnly`), `adjustForKeyboard`, `onBackPressed`.

### FlowSheet

Multi-page stack inside one sheet for wizards. Still backed by sheet; pages use `nav.push` / `pop` / `replace` / `completeCurrent` / `closeAll`. Prefer `completeCurrent` / `closeAll` to finish the whole flow.

```dart
final controller = FlowSheetController<bool>();
final done = await Pop.flowSheet<bool>(
  controller: controller,
  maxHeight: SheetDimension.fraction(0.9),
  initialPage: MyWizardFirstPage(controller: controller),
);
```

Extend `FlowSheetPage` / `FlowSheetPageState`; optional lifecycle hooks such as `onShow` / `onHide`. See [API reference · FlowSheet](docs/API_REFERENCE.md#flowsheet-api).

### Date

Date picker. Confirm → `DateTime`; cancel / barrier → `null`.

```dart
final birthday = await Pop.date(
  title: 'Birthday',
  minDate: DateTime(1970, 1, 1),
  maxDate: DateTime.now(),
  confirmText: 'OK',
  cancelText: 'Cancel',
);
```

### Menu

Anchored bubble menu. Close via injected `dismiss(result)`.

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
          ListTile(title: Text('Edit'), onTap: () => dismiss('edit')),
          ListTile(title: Text('Delete'), onTap: () => dismiss('delete')),
        ],
      ),
    );
  },
);
```

## PopupManager (low-level & global control)

`Pop.*` covers common cases. For a **fully custom** overlay or fine-grained lifecycle control, use `PopupManager` — the same layer `Pop.toast` / `confirm` / `sheet` build on.

### Custom overlay: `show` / `hide`

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
    // Return true to consume system back without closing the overlay
    return false;
  },
));

PopupManager.hide(id);
```

`show` returns a unique `popupId`. Only IDs from `PopupManager.show` (and internally managed loading) are meant to be closed by ID. `Pop.toast` / `confirm` / `sheet` / `date` / `menu` usually do not expose an ID — close them via their own UX or the global helpers below.

### Other static APIs

| Method | Role |
|--------|------|
| `initialize(navigatorKey:)` | Init (same key as `MaterialApp`) |
| `navigatorKey` | Current navigator key |
| `show(PopupConfig)` | Show custom overlay; returns `popupId` |
| `hide(popupId)` | Hide by ID |
| `hideLast()` | Hide topmost (any type) |
| `hideAll()` | Hide all |
| `hideByType(PopupType)` | Hide latest match (e.g. loading) |
| `hideLastNonToast()` | Hide latest non-toast; if `onBackPressed` returns `true`, only consume back |
| `hidePopupsOnRouteChange()` | Dismiss by route policy (usually via `PopupRouteObserver`) |
| `isVisible(popupId)` | Whether that ID is still shown |
| `hasNonToastPopup` | Any non-toast present (back-button checks) |
| `maybePop(context)` | Close non-toast if any, else `Navigator.pop` |
| `getDebugInfo()` | Debug summary of active popups |

```dart
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

Full `PopupConfig` fields: [API reference · PopupManager](docs/API_REFERENCE.md#popupmanager). The Lab page also demos `PopupManager.show`.

## Back button & routes

| Mechanism | Role |
|-----------|------|
| `PopScopeWidget` | System back closes latest non-toast via `hideLastNonToast` |
| `onBackPressed` | Popup may consume back first (e.g. pop an inner flowSheet page); `true` = handled |
| `PopupRouteObserver` | Dismisses by policy on push / pop / replace / remove |
| `dismissOnRouteChange` | Override defaults: confirm / sheet dismiss; toast / loading / date / menu keep |

## Example

`example/` is a FitPulse-style demo covering each popup type through product paths:

| Area | Covers |
|------|--------|
| Today | toast / loading / confirm |
| Workouts | sheet, menu, flowSheet |
| Progress | date, loading |
| Profile | sheet, flowSheet, settings routes |
| Lab (AppBar ⋯) | async / PopupManager edge cases |

```bash
cd example && flutter run
```

## Docs

- [Docs hub](docs/README.md)
- [API reference](docs/API_REFERENCE.md) — full parameters
- [Best practices](docs/BEST_PRACTICES.md)
- [CHANGELOG](CHANGELOG.md)
