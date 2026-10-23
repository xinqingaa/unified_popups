# Repository Guidelines

Guidance for agents working in this repository. `CLAUDE.md` is a symlink to
this file.

## Overview

`unified_popups` is a Flutter Overlay popup package. Public entry is the `Pop`
static API: toast, loading, confirm, date, sheet, flowSheet, menu, dropMenu,
custom. Configs are the only create-time contracts; no `BuildContext` required.

## Project Structure & Module Organization

Public exports live in `lib/unified_popups.dart`. Glass widgets also export
from `lib/liquid_glass.dart`. Confirm, Sheet, FlowSheet, Menu, and DropMenu
select a shell with `style.surface`. The field contract is
`doc/API_REFERENCE.md` 「玻璃容器」. Implementation is under `lib/src`:

| Area | Path |
| --- | --- |
| Public API | `api/` |
| Configs | `configs/` |
| Controller / Handle / lifetime | `controller/` |
| Runtime | `runtime/` |
| Overlay host | `host/` |
| Renderers / scene | `renderers/` |
| Route observer | `navigation/` |
| FlowSheet stack | `flow_sheets/` |
| Shared widgets | `widgets/` |
| Helpers | `utils/` |

Package assets (toast icons) live in `assets/images`. **Usage docs are under
`doc/`** (not `docs/`): `API_REFERENCE.md`, `ARCHITECTURE.md`,
`MIGRATION_V1_TO_V2.md`, `WHY_OVERLAY.md`. Consumer skill:
`skills/unified-popups-usage/`. Example app: `example/` (FitPulse + API Lab).
Tests: `test/` (e.g. `test/flow_sheet_v2_test.dart`, `test/drop_menu_test.dart`).

## Build, Test, and Development Commands

- `flutter pub get` — install dependencies for the package and example.
- `flutter analyze` — static analysis (`analysis_options.yaml`).
- `dart format lib test example/lib` — 2-space Dart style before commit.
- `flutter test` — package suite (controller, scene, FlowSheet, DropMenu, …).
- `cd example && flutter run` — smoke-test FitPulse / Lab UX.
- `cd example && flutter test` — example suite.

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
- Navigation: `push` / `pop` / `popToRoot` / `contains` / `popTo` / `replace` /
  `resetTo` / `completeCurrent` / `completeAndCloseAll` /
  `discardCompletedAbove` / `closeAll`
- `push` keeps one page per `id` (top match replaces; a lower match is spliced
  out, pages above stay). `identity` is lookup / logging only
- Prefer `completeCurrent` + `closeAll`, or `completeAndCloseAll`, to avoid a
  double exit animation. `closeAll` keeps the page tree until the outer exit
  finishes. Then `Pop.settleChannel` before the next full-screen route
- Root page has no horizontal transition. `enableSwipePop: false` disables the
  iOS edge swipe on non-root pages
- `FlowSheetPageState.onBack()` can consume system back; `updateDragDismissMode`
- `onPoppedTo` receives `popTo` payloads. `FlowSheetFocus` hands focus across
  inner pages

**Navigation** (`lib/src/navigation/`)
- `Pop.routeObserver` → route change dismiss per `routePolicy`

Design narrative: `doc/ARCHITECTURE.md`. Field contract: `doc/API_REFERENCE.md`.

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

Product apps should wrap `Pop` in an `AppPop` (or equivalent) facade — see
`example/lib/app/app_pop.dart` and `skills/unified-popups-usage/`. Happy-path
call shapes are in `README.md` "Quick start (30 seconds)". The Chinese
README is `README_zh.md`.

### Constraints

- Loading needs a clear dismiss path (`PopupLifetime` or `dismissChannel`)
- Sheet / Menu / Custom complete via injected Handle
- FlowSheet: `popToRoot` returns to root without closing the sheet; use
  `closeAll` or `completeAndCloseAll` to finish the session. `push` keeps one
  page per `id`
- Sheet default radius is 32 and content padding bottom is 16. Keyboard inset
  is immediate. Default Loading indicator is a Cupertino activity indicator
- Menu / DropMenu default transparent barrier blocks under-scroll; use
  `PopupBarrierConfig.hidden()` only when scroll-through is required
- Prefer `try/finally` (or `PopupLifetime.until`) around loading

## Coding Style & Naming Conventions

Inherits `flutter_lints`. Prefer const constructors; avoid async `setState`
misuse. Indentation: 2 spaces. Names: `lowerCamelCase` methods/fields,
`PascalCase` types, `snake_case.dart` files. Keep UI in `widgets/` /
`renderers/`, orchestration in `controller/` / `runtime/`, contracts in
`configs/`. Re-export only stable APIs from `lib/unified_popups.dart`. Document
non-obvious behavior with `///`.

## Testing Guidelines

Use `flutter_test`; product demos stay in `example/`. Specs end with
`_test.dart` and group by capability. Assert async UI with `pumpAndSettle`.
New features need at least one regression test. Changes to `PopupController`,
`PopupScene`, or FlowSheet must cover overlay / stack cleanup (including
`popToRoot`, `contains` / `popTo`, same-`id` `push`, and barrier
`dismissOnDrag` when those surfaces change).

## Documentation checklist (API / behavior changes)

Update as needed:

1. `doc/API_REFERENCE.md` — field/behavior contract. The glass contract lives
   in 「玻璃容器」.
2. `CHANGELOG.md` — under the **new** semver section (do not backfill into an
   already-published version)
3. `pubspec.yaml` version + `README.md` / `README_zh.md` — dependency example
   and user-facing behavior. Keep the two READMEs in sync. `README.md` stays
   primarily English so pub.dev can score it. Field tables stay in the API
   reference.
4. `AGENTS.md` — this file (`CLAUDE.md` is a symlink) when layout, modules,
   init, or agent guidance changes
5. `doc/ARCHITECTURE.md` — why the design works. Observable behavior stays in
   the API reference.
6. `doc/MIGRATION_V1_TO_V2.md` — v1 → v2 deltas only
7. `doc/WHY_OVERLAY.md` — when the product rationale versus official Dialog /
   Sheet changes
8. `example/README.md` — when the lab coverage matrix changes
9. `skills/unified-popups-usage/` — consumer guidance only. Fields stay in the
   API reference.

## Commit & Pull Request Guidelines

Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`. PRs should state
user-facing impact, list test commands, and link issues. Visual tweaks need
before/after from the example app. Keep analysis + tests green before review.
