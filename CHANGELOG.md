# Changelog

Notable changes to `unified_popups`. Versions follow [Semantic Versioning](https://semver.org/).

## 2.0.5

### Features

- `FlowSheetNavigator.popToRoot([result])` — pop the inner stack to the root
  page without closing the sheet (no-op when already on root). Topmost waiter
  receives `result`; intermediate pages complete with `null`.

### Docs

- Documented `popToRoot` across API reference, architecture, migration guide,
  READMEs, example README, and consumer skill.
- Rewrote `CLAUDE.md` for the v2 Runtime/Controller/Host model (removed stale
  PopupManager guidance).
- Updated `AGENTS.md`: correct `lib/src` layout, `doc/` paths, and a docs
  checklist that forbids backfilling changelog into already-published versions.

## 2.0.4

### Features

- `PopupBarrierConfig.dismissOnDrag` — when `dismissible` is true, drag/swipe
  on the barrier dismisses the popup (gesture consumed, not forwarded).
- Menu / DropMenu default barrier sets `dismissOnDrag: true` so outside drag
  closes like a tap, without scrolling content underneath.

### Docs

- Documented `dismissOnDrag` in API reference; clarified Menu barrier defaults.

## 2.0.3

### Fixes

- Fixed `PopupAnimationType.none`: after `markPresented`, animation stayed at `0`,
  so the barrier faded out while content remained visible.
- FlowSheet system back now asks the current page before default pop/close, and
  the type API no longer re-enters `handleBack` when the stack can pop.

### Features

- `FlowSheetPageState.onBack()` — return `true` to consume back and block
  default inward pop / sheet dismiss.
- `Pop.interceptsSystemBack` — sync flag for page-level `PopScope` so it does
  not race the global route back bridge on the same event.
- `SheetDragDismissMode.disabled` and
  `FlowSheetNavigator.updateDragDismissMode()` for dynamic drag-dismiss control.
- Exported `popup_entry_animation.dart` from the package entry.

### Docs

- Added consumer usage skill at `skills/unified-popups-usage/`: wrap in an
  app-level facade (`AppPop`), read docs on demand, keep Handle/Config out of
  business code. Linked from README / README_EN.

## 2.0.2

### Features

- Added pause/resume for temporary overlay hang:
  - `PopupHandleBase.pause()` / `resume()` / `isPaused`
  - `Pop.pauseLatest(PopupChannel)` / `Pop.resume(id)`
- Paused entries stay mounted (Offstage + IgnorePointer) so FlowSheet /
  form state survives; they skip system back and route auto-dismiss.
- `Pop.isVisibleKey` returns `false` while paused; `hasChannel` still counts
  the active paused entry.
- Example Lab: **Pause / Resume**.

### Docs

- Documented pause/resume in API reference and README.

## 2.0.1

### Fixes

- Fixed FlowSheet system back: nested Navigator `NavigationNotification` no
  longer reports `canHandlePop: false` (which made Android finish the app).
  Back is owned by the route observer → popup controller → flowSheet
  `delegate` path, so confirm-on-top blocks and multi-page stacks pop inward
  first.
- DropMenu nested section expand/collapse no longer uses
  `SizeTransition.alignment` (Flutter 3.41+) or deprecated `axisAlignment`;
  uses `ClipRect` + `Align` so `flutter >= 3.24` stays warning-free.

### Docs

- Expanded README capability / use-case gallery (including Loading preview).
- Added [README_EN.md](README_EN.md) with cross-links between Chinese and
  English.

## 2.0.0

### Architecture

- Replaced the old `PopupManager`, navigatorKey bootstrap, and one-fullscreen-
  OverlayEntry-per-popup model with `Pop + PopupRuntime + PopupController +
  PopupHost`.
- Introduced per-capability Config/Renderer pairs and a unified `PopupHandle`
  that separates business outcome from visual removal.
- Removed `AnimationControllerPool`, the monolithic `PopupConfig`,
  `PopupType`-driven behavior, `PopScopeWidget`, the legacy route observer, and
  the old `part`-file API surface.
- Apps only need `Pop.hostBuilder` and `Pop.routeObserver`; business calls stay
  global and context-free.

### Lifecycle and management

- Every capability now has exactly one `Pop.xxx(Config)` entrypoint. All
  `openXxx` helpers and loose parameter overloads were removed. Config is the
  only public parameter contract; `PopupTypeApi` is an internal adapter.
- All open APIs return `PopupOpenResult<T>` with a `.result` convenience getter,
  covering opened, updated, toggledClosed, and rejected. Opening decisions are
  no longer disguised as entry dismiss reasons.
- Narrowed the package export surface: `PopupRuntime`, `PopupController`,
  `PopupHost`, `PopupScene`, and renderer base types are no longer stable
  public API.
- `PopupBehaviorConfig` no longer accepts channel; each capability fixes its
  own channel to avoid invalid Config/channel combinations.
- `PopupLifetime.until` now observes Future settlement: success or failure both
  dismiss with `externalEvent`, while business errors remain the caller's
  responsibility.
- PopupController splits entry records, handle implementations, and lifetime
  resources into internal modules; the controller remains the sole state and
  transition authority.
- Added key, channel, tags, plus conflict, route, back, ownership, barrier,
  auto-dismiss, and lifecycle policies.
- Added `PopupOutcome` and a complete `PopupDismissReason` set.
- Added dismiss APIs by handle, top entry, channel, tags, and all popups.
- Calls before Host mount enter `pendingHost` and resume when Host is ready.
- Toast shows at most three items per position; extras queue FIFO without
  starting lifetime until presented.

### Capability features

- Standard DropMenu uses a default global key + `replaceExisting`, including
  across result generics, so only one standard DropMenu is visible at a time.
- Added themed liquid-glass widgets and data-driven `Pop.dropMenu` with single
  or nested sections, system/custom check icons, disabled items, keep-open
  settings rows, and full color overrides.
- DropMenu default width is 140–240; the last item drops its bottom divider.
  Liquid glass lowers default background opacity and adds
  `topHighlightColor` independent of the normal border.
- Nested sections animate size + fade; selecting a nested option collapses only
  that section while the outer menu stays open, notifying via `onSelected` /
  item `onTap`.
- DropMenu fades only text/icons on open so BackdropFilter stays opaque and
  avoids an end-frame blur pop from a parent OpacityLayer. BackdropFilter still
  uses `BlendMode.src` as an extra guard. Generic LiquidGlass keeps `srcOver`.
- Menu `auto` placement measures real menu size, then chooses direction from
  SafeArea, offset, and edge overflow, locking that direction for the session.
- Fixed Menu follower hit-testing under a transparent visible barrier so menu
  content receives taps while outside taps still dismiss via the barrier.
- Loading updates keep the same logical entry and handle, restarting lifetime
  from the new config.
- Loading uses mutually exclusive `indicator` / `text` / `content` constructors;
  Confirm and Sheet header reject providing both String and Widget for the same
  payload.
- Toast and Loading support countdown, external Future, manual handle dismiss,
  or combined lifetime conditions.
- Confirm adds button-specific `onConfirm` / `onCancel` while keeping the
  `Future<bool?>` business result.
- Confirm defaults to edge-to-edge divider buttons
  (`ConfirmButtonStyle.divider`); use `ConfirmButtonStyle.filled` for rounded /
  capsule buttons, with `dividerColor`, `dividerWidth`, and `buttonSpacing`.
- Confirm defaults to strong modal interaction: `backPolicy: block`,
  `barrier.dismissible: false`, and `showCloseButton: false`. Only confirm /
  cancel buttons close it unless those options are opened explicitly.
- Sheet and FlowSheet share a four-direction renderer, drag progress, and exit
  animation; heavy child trees are not rebuilt on every drag pointer update.
  Drag handles render only for the bottom direction.
- Restored dual SafeArea for Sheet (alignment layer subtracts status bar +
  panel always SafeArea), fixing full-height bottom sheets under the notch and
  top/left/right content colliding with the status bar.
- FlowSheet attaches to the unified outer handle while keeping its internal
  page stack, page results, and lifecycle hooks.
- Menu uses `PopupAnchorController + PopupAnchor`, follows scroll/layout, and
  auto-dismisses when the anchor unmounts. Default barrier is transparent
  (same as DropMenu: tap outside to dismiss, block underlying scroll). Pass
  `PopupBarrierConfig.hidden()` when the page must keep scrolling under the
  menu.
- Added `CustomPopupConfig` so custom content joins the shared lifecycle and
  global management.

### Example and docs

- FitPulse product area adds an app-level `AppPop` facade for brand defaults and
  simple business returns; product flows cover Toast, Loading, Confirm, Date,
  Sheet, FlowSheet, Menu, DropMenu, and Custom. The API Lab keeps raw SDK
  contracts.
- Rewrote guidance for `PopupOpenResult`, `.result`, `requireHandle()`, builder
  handles, outcome, and dismissed timing.
- Example adds Toast/Loading `until` failure dismiss, unified
  `PopupOpenResult`, and DropMenu global-replace checks.
- Detailed docs converge on architecture, full API reference, and v1/v2
  migration.
- Added [WHY_OVERLAY.md](doc/WHY_OVERLAY.md): Overlay unified popups vs official
  `showDialog` / `showModalBottomSheet` (call site, route stack, multi-type
  governance, back/route policies, and when native dialogs are enough).
- README embeds architecture, lifecycle, and usage diagrams from
  `doc/images/`.
- Menu Lab adds single-level filter and nested settings examples.
- FitPulse example fully migrated to v2.
- Example launch screen offers dual entry: FitPulse app / API gallery, plus a
  shared Config page for the Config-first single entrypoint.
- Loading with text sizes to content; `LoadingConfig.position` can stagger
  multiple instances.
- Tech lab pages cover the full capability matrix; business tabs keep real
  product usage.
- Confirm Lab contrasts divider vs filled button styles.
- Rewrote README, API reference, architecture notes, and the v1 → v2 migration
  guide. Project usage docs are Chinese.

## 1.3.0

### FlowSheet

- Added `Pop.flowSheet` with internal `push`, `pop`, `replace`,
  `completeCurrent`, and `closeAll`.
- Added `FlowSheetController`, `FlowSheetPage`, `FlowSheetPageState`, and page
  lifecycle hooks `onLoad`, `onShow`, `onHide`, `onRemove`, `onClose`.
- Supported per-page drag modes and custom internal route builders.

### Sheet and routing

- Added `fullBody`, `contentWhenAtTop`, and `handleOnly` drag modes.
- Sheet gained drag handle, keyboard avoidance, dynamic drag mode, and back
  callbacks.
- Route observer also cleans popups on route remove.
- Example added FitPulse product flows and a tech lab.

## 1.2.2

- Narrowed rebuild scope for legacy `PopScopeWidget`.
- Experimented with an AnimationController pool; removed in v2 due to lifecycle
  risk.
- Optimized legacy Menu RenderBox and screen-size reads.

## 1.2.1

- Toast added `messageWidget`.
- Confirm added custom title, content, and button widgets.
- Sheet added `titleWidget`.
- Confirm added `onConfirm` and `onCancel`.

## 1.2.0

- Added animation duration and curve options per type.
- Added legacy `PopupRouteObserver` and route-change cleanup.
- Improved Sheet animation clipping, edge docking, keyboard handling, and
  async build-phase safety.
- Toast added tap toggle and custom tap callbacks.
- Menu added padding, constraints, and decoration.

## 1.1.17

- Fixed known popup interaction issues.

## 1.1.16

- Fixed Sheet animation clipping overflow.

## 1.1.15

- Fixed residual hit areas after popup dismiss.

## 1.1.14

- Fixed leftover untappable regions after repeated Loading calls.

## 1.1.13

- Toast added secondary-state text, image, type, color, and tap-toggle.

## 1.1.12

- Improved legacy base popup behavior.

## 1.1.11

- Fixed `setState` errors from inserting Overlay during build.

## 1.1.10

- Simplified Loading API.
- Added batch dismiss by legacy `PopupType`.

## 1.1.9

- Menu added padding, constraints, and decoration.

## 1.1.8

- Sheet added `dockToEdge` and `edgeGap`.

## 1.1.7

- Fixed Sheet interaction with bottom UI regions.

## 1.1.6

- Toast added custom image tinting.

## 1.1.5

- Confirm buttons gained custom borders.

## 1.1.4

- Toast added custom local images, image size, and horizontal/vertical layout.
- Loading added a custom rotating indicator.

## 1.1.3

- Improved base popup presentation.

## 1.1.2

- Applied keyboard avoidance padding only for bottom sheets.

## 1.1.1

- Fixed base style and layout issues.

## 1.1.0

- Introduced the unified `Pop` entry facade.
- Unified management for Toast, Loading, Confirm, Sheet, Date, and Menu.

## 1.0.3 and earlier

- Initial release and base popup capabilities.
