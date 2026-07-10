# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Unified Popups is a Flutter package for Overlay-based popups. All entry points are on the `Pop` static API: toast, loading, confirm, sheet, flowSheet, date, and menu.

## Development Commands

### Code Quality
```bash
flutter analyze
cd example && flutter run
dart format .
```

### Testing
```bash
flutter test
cd example && flutter test
```

## Architecture

### Core Components

**PopupManager** (`lib/src/core/popup_manager.dart`)
- Singleton managing Overlay entries; tracks `_popups` + `_popupOrder`
- Per-popup AnimationController and optional auto-dismiss Timer
- `SafeOverlayEntry` defers rebuild during build phase
- Hide APIs: `hide(id)`, `hideLast()`, `hideAll()`, `hideByType()`, `hideLastNonToast()`
- `hideLastNonToast()` honors `onBackPressed` (`true` = consumed, keep overlay)
- Route-aware dismissal via `dismissOnRouteChange`

**Pop APIs** (`lib/src/apis/pop.dart`)
- Part files: toast, loading, confirm, sheet, flow_sheet, date, menu
- Loading is singleton (`hideByType(PopupType.loading)`); others allow multi-instance
- Most APIs expose optional `dismissOnRouteChange`; sheet / flowSheet also expose `onBackPressed`

**PopupConfig** (`lib/src/models/popup_config.dart`)
- Shared config: child, position, animation, barrier, type, `dismissOnRouteChange`, `onBackPressed`, dock-to-edge

**Widgets** (`lib/src/widgets/`)
- `popup_layout.dart` plus type widgets: toast, loading, confirm, sheet, date, menu
- Sheet: drag modes, drag handle, keyboard adjust
- `pop_scope_widget.dart`: system back → close popups before routes

**FlowSheet module** (`lib/src/flow_sheets/`)
- `Pop.flowSheet` wraps `Pop.sheet` with an internal page stack
- `FlowSheetController`, `FlowSheetPage` / `FlowSheetPageState`, lifecycle hooks
- Navigation: `push` / `pop` / `replace` / `completeCurrent` / `closeAll`

**PopupRouteObserver** (`lib/src/core/popup_route_observer.dart`)
- Watches push / pop / replace / didRemove → `hidePopupsOnRouteChange()`

### Key Design Patterns

1. **SafeOverlayEntry** — defer `markNeedsBuild` during build phase
2. **Part files** — Pop / PopupManager split while keeping privates
3. **Animation per popup** — independent controllers
4. **Type-based filtering** — back button and route-dismiss defaults
5. **Builder + dismiss** — sheet / menu inject close callback
6. **FlowSheet stack** — finish with `completeCurrent` / `closeAll` to avoid double exit animation

### Initialization Pattern

```dart
final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(MyApp(navigatorKey: navigatorKey));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PopupManager.initialize(navigatorKey: navigatorKey);
  });
}

MaterialApp(
  navigatorKey: navigatorKey,
  navigatorObservers: [PopupRouteObserver()],
  builder: (context, child) => PopScopeWidget(
    child: child ?? const SizedBox.shrink(),
  ),
  home: const HomePage(),
)
```

### Popup Types & Behavior

| Type | Multi-instance? | Auto-dismiss on route change | Back button |
|------|-----------------|------------------------------|-------------|
| Toast | Yes | No | Ignored by `hideLastNonToast` |
| Loading | No (singleton) | No | Closed via `hideLastNonToast()` |
| Confirm | Yes | Yes (default) | Close (or `onBackPressed`) |
| Sheet | Yes | Yes (default) | `onBackPressed` if set, else close |
| FlowSheet | Yes (via sheet) | Yes (sheet default) | Default `controller.handleBack` |
| Date | Yes | No | Close via `hideLastNonToast()` |
| Menu | Yes | No | Close via `hideLastNonToast()` |

### Animation defaults

Toast 200ms · Loading 150ms · Confirm / Date 250ms · Menu 200ms · Sheet / FlowSheet 400ms. All accept `animationDuration` / `animationCurve`.

### Common Patterns

```dart
Pop.toast('Message', toastType: ToastType.success);

Pop.loading(message: 'Loading...');
try { await operation(); } finally { Pop.hideLoading(); }

final ok = await Pop.confirm(title: 'Confirm', content: 'Description');

final selected = await Pop.sheet<String>(
  title: 'Select',
  childBuilder: (dismiss) => ListTile(
    title: Text('Option'),
    onTap: () => dismiss('opt'),
  ),
);

final controller = FlowSheetController<String>();
await Pop.flowSheet<String>(
  controller: controller,
  initialPage: MyFirstPage(controller: controller),
);

final date = await Pop.date(title: 'Birthday');

await Pop.menu<String>(
  anchorKey: key,
  builder: (dismiss) => ListTile(title: Text('Edit'), onTap: () => dismiss('edit')),
);
```

### Example app

FitPulse demo under `example/`: tabs Today / Workouts / Progress / Profile, Lab via AppBar ⋯, flows in `example/lib/flows/`. Run `cd example && flutter run`. Docs under `docs/` — update `API_REFERENCE` + CHANGELOG when APIs change.

### Constraints

- Loading singleton; toast not dismissible by id
- Sheet / menu close via injected `dismiss`
- FlowSheet: prefer `completeCurrent` / `closeAll` to finish
- `dockToEdge` only bottom / left / right; `edgeGap` must match nav height
- Always `try/finally` around loading
