# Repository Guidelines

## Project Structure & Module Organization
Public exports live in `lib/unified_popups.dart`, while implementation details are grouped under `lib/src` (`apis`, `core`, `models`, `utils`, `widgets`) so each widget or service has a single, predictable home. Golden assets such as toast icons reside in `assets/images`, and additional usage notes are captured in `doc/`. The example app under `example/` mirrors a real host application and is the quickest way to validate visual changes. Tests belong in `test/`, matching the library path (e.g., `lib/src/core/popup_manager.dart` → `test/core/popup_manager_test.dart`) to keep intent obvious.

## Build, Test, and Development Commands
- `flutter pub get` — install dependencies for both the package and the bundled example.  
- `flutter analyze` — run static analysis with the rules defined in `analysis_options.yaml`.  
- `dart format lib test` — apply the standard 2-space Dart style before committing.  
- `flutter test --coverage` — execute the suite in `test/` and refresh `coverage/lcov.info`.  
- `flutter run example/lib/main.dart` — smoke-test new UX in the demo app.

## Coding Style & Naming Conventions
The repo inherits `flutter_lints`, so prefer const constructors, meaningful `BuildContext` extensions, and guard against async setState misuse. Use 2-space indentation, `lowerCamelCase` for methods/fields, `PascalCase` for classes and widgets, and `snake_case.dart` file names mirroring their primary type. Keep widget files focused: compose UI in `widgets/`, isolate logic in `core/` or `utils/`, and re-export only stable APIs from `lib/unified_popups.dart`. Document tricky behaviors with `///` doc comments so they surface in IDE tooltips.

## Testing Guidelines
Rely on `flutter_test` for widget and behavior coverage; integration-style demos can stay inside the example app. Each spec file should end with `_test.dart` and group cases by popup type (`group('toast', ...)`). Favor descriptive expectations over golden screenshots, and assert asynchronous flows by awaiting `pumpAndSettle`. New features must include at least one regression test and, when altering `PopupManager`, a scenario ensuring overlay cleanup.

## Commit & Pull Request Guidelines
Follow the conventional commit prefixes already in history (`feat:`, `fix:`, `docs:`, `refactor:`) so changelog automation stays accurate. Each pull request should describe the user-facing impact, list test commands run, and link related issues. Visual tweaks require before/after screenshots or screen recordings from the example app. Update `doc/` or `README.md` whenever APIs or initialization steps change, and ensure CI (analysis + tests) is green before requesting review.

