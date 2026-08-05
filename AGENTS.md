# Repository Guidelines

## Project Structure & Module Organization

Public exports live in `lib/unified_popups.dart`. Implementation is under
`lib/src`:

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
`popToRoot` and barrier `dismissOnDrag` when those surfaces change).

## Documentation checklist (API / behavior changes)

Update as needed:

1. `doc/API_REFERENCE.md` — field/behavior contract
2. `CHANGELOG.md` — under the **new** semver section (do not backfill into an
   already-published version)
3. `pubspec.yaml` version + `README.md` / `README_EN.md` dependency example
4. `CLAUDE.md` — agent architecture map when modules or init change
5. `AGENTS.md` — this file, when layout or doc paths change
6. `doc/ARCHITECTURE.md` / `doc/MIGRATION_V1_TO_V2.md` — design or migration
   contracts
7. `skills/unified-popups-usage/` — only when consumer guidance changes

## Commit & Pull Request Guidelines

Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`. PRs should state
user-facing impact, list test commands, and link issues. Visual tweaks need
before/after from the example app. Keep analysis + tests green before review.
