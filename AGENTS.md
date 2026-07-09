# Repository Guidelines

## Project Structure & Module Organization

Public exports live in `lib/unified_popups.dart`, while implementation details are grouped under `lib/src` (`apis`, `core`, `models`, `utils`, `widgets`, `flow_sheets`) so each widget or service has a single, predictable home. Package assets such as toast icons reside in `assets/images`. Usage docs live under `docs/`. The example app (`example/`) is a FitPulse-style fitness demo that exercises popups through real product flows, plus a Lab for edge-case regression. Tests belong in `test/` (e.g. `test/flow_sheet_test.dart`).

## Build, Test, and Development Commands

- `flutter pub get` — install dependencies for both the package and the bundled example.
- `flutter analyze` — run static analysis with the rules defined in `analysis_options.yaml`.
- `dart format lib test example/lib` — apply the standard 2-space Dart style before committing.
- `flutter test` — run the suite in `test/` (includes FlowSheet coverage).
- `cd example && flutter run` — smoke-test UX in the FitPulse demo.

## Coding Style & Naming Conventions

The repo inherits `flutter_lints`, so prefer const constructors and guard against async setState misuse. Use 2-space indentation, `lowerCamelCase` for methods/fields, `PascalCase` for classes and widgets, and `snake_case.dart` file names. Keep widget files focused: compose UI in `widgets/`, isolate logic in `core/` or `utils/`, and re-export only stable APIs from `lib/unified_popups.dart`. Document tricky behaviors with `///` doc comments.

## Testing Guidelines

Rely on `flutter_test` for widget and behavior coverage; product-style demos stay in the example app. Spec files end with `_test.dart` and should group by popup type. Assert async flows with `pumpAndSettle`. New features need at least one regression test; changes to `PopupManager` or FlowSheet must cover overlay / stack cleanup.

## Commit & Pull Request Guidelines

Follow conventional commit prefixes (`feat:`, `fix:`, `docs:`, `refactor:`). PRs should describe user-facing impact, list test commands run, and link related issues. Visual tweaks need before/after from the example app. When APIs or initialization steps change, update `docs/API_REFERENCE.md`, `CHANGELOG.md`, and the root README as needed. Keep CI (analysis + tests) green before review.
