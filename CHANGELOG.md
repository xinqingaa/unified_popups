# Changelog

Notable changes to `unified_popups`. Versions follow [Semantic Versioning](https://semver.org/).

## 2.2.0

### Breaking

- `FlowSheetNavigator.push` keeps one page per `id`. If that `id` is already
  the top, `push` replaces it. If it sits lower in the stack, only that old
  page is removed (pages above it stay) and the new page is pushed on top.
  Same-`id` instances no longer coexist via `identity`. `identity` remains an
  optional object key for lookup / logging. Re-entering a page kind can just
  `push`; `contains` / `popTo` stay for explicit “pop down to this page”.
  This supersedes the 2.1.0 rule that different `identity` values could share
  an `id`.

### Fixes

- A full-screen popup with a visible barrier now takes focus with a
  `FocusScopeNode` instead of a leaf `FocusNode`. A text field inside the
  popup can become the primary focus, so the keyboard opens. On dismiss, the
  previous route’s focus is restored only when that popup scope still holds
  focus.
- Sheet and FlowSheet clear the primary focus when the exit animation starts,
  and on the first drag in the dismiss direction, so the keyboard moves with
  the panel. Toast and Loading do not steal focus from the page underneath.
- A sheet that has already been dragged partway toward closed uses a reverse
  duration scaled by the remaining progress and `Curves.linear`. An undragged
  dismiss still uses `reverseDuration` (or `duration`) and `reverseCurve`.

### Docs

- API reference, architecture, READMEs, the example README, and the consumer
  skill now describe the 2.0.7–2.2.0 contracts, including behaviors that
  previously shipped only in code: `settleChannel`, `completeAndCloseAll`,
  `discardCompletedAbove`, `enableSwipePop`, `FlowSheetFocus`, sheet chrome,
  and the default loading indicator.

## 2.1.0

### Features

- `FlowSheetPage.identity` — optional business-object key (e.g. `symbol`,
  `orderNo`) alongside the existing `id` (page species). `FlowSheetPage.
  instanceId` (`identity == null ? id : '$id#$identity'`) is the actual
  uniqueness/lookup key used by the stack, so multiple instances of the same
  `id` can now coexist as long as their `identity` differs (e.g. the same
  trade-main page hosting AAPL and, separately, TSLA in one session).
- `FlowSheetNavigator.contains(id, {identity})` / `popTo(id, [result],
  [identity])` — the optional `identity` narrows a lookup from "does this
  species exist" (unchanged default behavior) to "does *this exact instance*
  exist". Existing call sites that never pass `identity` are unaffected.

### Fixes

- `push` / `replace` / `resetTo(animate: true)` now assert uniqueness on
  `instanceId`, not the raw `id`. Previously, two pages sharing an `id` but
  representing different business objects (e.g. a trade-main page reused for
  a different symbol reached through a nested "all orders" host) could not
  coexist, which forced call sites to reuse one page instance across unrelated
  objects — the reused instance then displayed stale data for fields it never
  re-bound. Declaring `identity` on such pages lets the stack tell them apart
  and lets business code find/replace the exact instance it means via
  `contains`/`popTo(identity: ...)` instead of ad-hoc equality checks.

### Note

Superseded by 2.2.0: the same `id` is again limited to one page in the stack.
`identity` is no longer a uniqueness key.

## 2.0.7

### Features

- `FlowSheetNavigator.contains(id)` — whether a page id is in the inner stack
  (including the current page). Use this instead of `canPop` when the question
  is "is this host present", not "is there a page above".
- `FlowSheetNavigator.popTo(id, [result])` — pop until that id is top
  (no-op if missing or already top). Removed pages complete their push Futures
  with `null`. The payload is delivered only to the target via
  `FlowSheetPageState.onPoppedTo`.
- `FlowSheetPage.id` is the routing key for the session. In this version a
  duplicate id asserts in debug. 2.1.0 allows a second page when `identity`
  differs; 2.2.0 replaces that with one page per `id`.
- `FlowSheetNavigator.resetTo(page, {animate})` — `animate: true` plays a
  forward horizontal enter, then collapses the stack so the new page is root
  (cannot swipe back to the previous gate). Default remains an instant
  replace. While that enter plays, system back is consumed and does not pop
  the incoming page onto the gate. The FlowSheet back path goes through
  `handleBack` when the stack can pop.
- `FlowSheetNavigator.completeAndCloseAll(result)` — complete the current page
  and close the whole sheet without an inner-page return transition. Use this
  when the next step is a full-screen route and the flow should not return.
- `FlowSheetNavigator.discardCompletedAbove()` — drop pages that already
  completed their push future and are still sitting above the current page,
  with no return transition.
- `FlowSheetPage.enableSwipePop` (default `true`). Set it to `false` to skip
  `CupertinoPageRoute` on non-root pages, so an iOS edge swipe cannot pop the
  inner route and bypass `onBack`.
- `FlowSheetFocus.handOffToPreviousPage` and `waitForRouteNearComplete` —
  hand focus back before pop, and wait until the route transition is near
  completion before requesting focus.
- `Pop.settleChannel(channel)` — close entries on that channel that are still
  active, then wait until every still-mounted entry (including ones already
  exiting) has finished `dismissed`.
- The FlowSheet root page uses a zero-duration route. The outer sheet
  animation is the entrance. Non-root pages keep a horizontal transition.
  `resetTo(animate: true)` still slides the new page in, then collapses it
  to the root.
- `closeAll` ends the business session immediately (pending futures complete,
  further navigation is rejected) and keeps the page tree until the outer
  exit animation finishes. `onHide` / `onClose` run after that animation.

### Fixes

- Sheet titles now honor `titleAlign` across the full header width. The title
  `Text` was previously centered by a `Stack`, so `titleAlign: left` still
  looked centered.
- Opening or dismissing a popup during `State.dispose` / route teardown no
  longer throws `setState() or markNeedsBuild() called when widget tree was
  locked`. `PopupController` defers notifications only in
  `persistentCallbacks`; other phases (including animation callbacks) still
  notify synchronously, so timing is unchanged.
- A `SheetDragConfig.modeListenable` change that arrives outside the idle or
  post-frame phase is applied on the next frame instead of calling `setState`
  on a locked tree.

### Changes

- Confirm `imagePath` is a full-bleed header above `contentPadding`: width
  stretches to the dialog, clipped by the container radius. `imageHeight`
  still applies (default 80). `imageFit` defaults to `BoxFit.cover`.
  `imageWidth` is ignored.
- The default Loading indicator is a `CupertinoActivityIndicator` with radius
  14. `LoadingStyle.indicatorStrokeWidth` does not affect that indicator. A
  custom `LoadingIndicatorConfig.child` is still rotated.
- Sheet default content padding is `EdgeInsets.fromLTRB(16, 8, 16, 16)`.
- Sheet default corner radius is 32 on the outer corners for that direction,
  and the panel clips its child to that radius.
- The bottom drag handle is 38×6 with 10px of padding below it.
- Bottom-sheet keyboard avoidance applies `viewInsets` immediately.
  `SheetKeyboardConfig.animationDuration` remains on the config and is not
  used by the renderer.
- Sheet open requests are updatable. The same key with
  `PopupConflictPolicy.updateExisting` can refresh that entry in place. The
  business child built for a handle is kept until the handle changes, so an
  in-place config update does not rerun `builder`.

### Breaking

- Confirm default is inset capsule buttons (`FilledButton` / `OutlinedButton`),
  not full-bleed divider chrome.
- Removed `ConfirmAction`, `ConfirmButtonStyle`, and button-skin fields on
  `ConfirmStyle` (`buttonStyle`, `confirmStyle`, `cancelStyle`,
  `buttonBorderRadius`, `confirmBackgroundColor`, `cancelBackgroundColor`,
  `confirmBorder`, `cancelBorder`, `dividerColor`, `dividerWidth`, `padding`).
- Slots are `confirmButton` / `cancelButton` builders, or `confirmText` /
  `cancelText` for the default capsule. Custom builders must call `onTap`.
- Layout uses `contentPadding` + `buttonPadding` plus named gaps
  (`titleGap`, `contentButtonGap`, `buttonSpacing`, …). Optional `separator`
  / `buttonSeparator` cover full-bleed divider recipes.

### Docs

- Documented the 2.0.7 FlowSheet, Confirm, Sheet, Loading, and
  `settleChannel` contracts in API §6–§10 and §14, ARCHITECTURE, READMEs,
  the example README, and the consumer skill.

## 2.0.6

### Fixes

- `PopupScene` / toast lanes now put `ValueKey(entry.id)` on the outer
  `Offstage` Stack/Column child (not only on the inner animated entry). Removing
  an earlier sibling no longer remounts later entries, which previously replayed
  enter animations or snapped exit animations to zero (e.g. dismiss menu then
  open sheet, or dismiss a lower entry while an upper one is exiting).

### Docs

- Clarified in `ARCHITECTURE.md` that Entry keys must sit on the Scene's direct
  layout children for identity to survive sibling removal.

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
