# CLAUDE.md

Guidance for agents working in this repository.

## Overview

`unified_popups` is a Flutter Overlay popup package. Public entry is the `Pop`
static API: toast, loading, confirm, date, sheet, flowSheet, menu, dropMenu,
custom. Configs are the only create-time contracts; no `BuildContext` required.

## Development Commands

```bash
flutter analyze
flutter test
dart format lib test example/lib
cd example && flutter run
cd example && flutter test
```

## Architecture (v2)

### Core

**Pop** (`lib/src/api/pop.dart`)
- Single create entry: `Pop.xxx(Config)` → `PopupOpenResult<T>`
- `.result` for business values; Handle via `.requireHandle()` / `.handleOrNull`
- Host: `Pop.hostBuilder` + `Pop.routeObserver` (no navigatorKey bootstrap)

**PopupRuntime** (`lib/src/runtime/`)
- Owns Controller, route observer, at most one active Host
- Pending calls before first Host mount; `hostUnavailable` after Host gone

**PopupController** (`lib/src/controller/`)
- Sole state authority: registry, conflict, lifetime, back, route policies
- Hide/query: `Pop.dismiss*`, channel/tag/key helpers, pause/resume

**PopupHost + PopupScene** (`lib/src/host/`, `lib/src/renderers/popup_scene.dart`)
- Private Overlay above app child; Scene rebuild keeps Entry Keys stable
  (keys on outer Offstage Stack/Column children, not only inner animated entry)
- Barrier: `PopupBarrierConfig` (`dismissible`, `dismissOnDrag`, color, insets)

**Configs / Renderers** (`lib/src/configs/`, `lib/src/renderers/`)
- Per-capability Config + Renderer (toast, loading, confirm, date, sheet, menu…)

**FlowSheet** (`lib/src/flow_sheets/`)
- Outer sheet Entry + inner page stack via `FlowSheetController`
- Navigation: `push` / `pop` / `popToRoot` / `replace` / `completeCurrent` /
  `closeAll`
- Prefer `completeCurrent` + `closeAll` to avoid double exit animation
- `FlowSheetPageState.onBack()` can consume system back; `updateDragDismissMode`

**Navigation** (`lib/src/navigation/`)
- `Pop.routeObserver` → route change dismiss per `routePolicy`

### Layout under `lib/src`

`api` · `configs` · `controller` · `runtime` · `host` · `renderers` ·
`navigation` · `flow_sheets` · `widgets` · `utils`

Public exports: `lib/unified_popups.dart`. Usage docs: `doc/` (not `docs/`).

### Initialization

```dart
MaterialApp(
  navigatorObservers: [Pop.routeObserver],
  builder: Pop.hostBuilder,
  home: const HomePage(),
);
```

### Popup types & defaults (summary)

| Type | Multi? | Typical back |
|------|--------|--------------|
| Toast | Yes | ignore |
| Loading | Keyed singleton-style | block |
| Confirm | Yes | block + non-dismissible barrier |
| Date | Yes | dismiss |
| Sheet | Yes | dismiss (or `onBackPressed`) |
| FlowSheet | Yes (via sheet) | inner `handleBack` / `onBack` |
| Menu / DropMenu | Yes | dismiss; default barrier `dismissOnDrag: true` |
| Custom | Yes | configurable |

### Common patterns

```dart
Pop.toast(const ToastConfig.text('已保存', type: ToastType.success));

Pop.loading(const LoadingConfig.text('提交中'));
try {
  await submit();
} finally {
  Pop.dismissChannel(PopupChannel.loading);
}

final ok = await Pop.confirm(
  const ConfirmConfig(
    title: '确认',
    content: '继续？',
    confirmAction: ConfirmAction.text('确定'),
    cancelAction: ConfirmAction.text('取消'),
  ),
).result;

final controller = FlowSheetController<String>();
await Pop.flowSheet<String>(
  FlowSheetConfig(
    controller: controller,
    initialPage: MyFirstPage(),
  ),
).result;
// Inner: controller.push / pop / popToRoot / replace / completeCurrent / closeAll
```

Product apps should wrap `Pop` in an `AppPop` (or equivalent) facade — see
`example/lib/app/app_pop.dart` and `skills/unified-popups-usage/`.

### Docs to update when APIs change

- `doc/API_REFERENCE.md`
- `CHANGELOG.md`
- `README.md` / `README_EN.md` (version + user-facing behavior)
- `CLAUDE.md` / `AGENTS.md` when structure or agent guidance changes
- `doc/ARCHITECTURE.md` / `doc/MIGRATION_V1_TO_V2.md` when design contracts change

### Constraints

- Loading needs a clear dismiss path (`PopupLifetime` or `dismissChannel`)
- Sheet / Menu / Custom complete via injected Handle
- FlowSheet: `popToRoot` returns to root without closing the sheet; use
  `closeAll` to finish the session
- Menu / DropMenu default transparent barrier blocks under-scroll; use
  `PopupBarrierConfig.hidden()` only when scroll-through is required
- Prefer `try/finally` (or `PopupLifetime.until`) around loading
