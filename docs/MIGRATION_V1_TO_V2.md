# Migrating from v1 to v2

v2 is intentionally breaking. Remove v1 initialization and migrate low-level
manager calls to typed handles/configuration.

## 1. Application setup

```dart
// v1: navigatorKey + PopupManager.initialize + PopScopeWidget

// v2
MaterialApp(
  navigatorObservers: [Pop.routeObserver],
  builder: Pop.hostBuilder,
);
```

Business `Pop.toast/loading/confirm/sheet/flowSheet/date` calls mostly retain
their familiar shape. Delete Popup-specific Controller injection and context
lookup from services.

## 2. Low-level API mapping

| v1 | v2 |
| --- | --- |
| `PopupManager.show(PopupConfig)` | `Pop.custom(CustomPopupConfig)` |
| returned String id | typed `PopupHandle<T>` |
| `PopupManager.hide(id)` | `handle.dismiss()` |
| `hideLast()` | `Pop.dismissTop()` |
| `hideAll()` | `Pop.dismissAll()` |
| `hideByType(type)` | `Pop.dismissChannel(channel)` |
| `getCountByType(type)` | `Pop.countChannel(channel)` |
| `isVisible(id)` | handle state or `Pop.isVisibleKey(key)` |
| `maybePop(context)` | automatic route bridge or `Pop.handleBack()` |

Move animation, Barrier, lifetime, route, back, key/tags and ownership behavior
into the relevant typed Config. Do not map old `PopupType` to behavior; use
explicit policies.

## 3. External closing and results

```dart
final handle = Pop.openConfirm(ConfirmConfig(
  content: 'Continue?',
  cancelText: 'Cancel',
));

service.onAbort = handle.dismiss;
final outcome = await handle.outcome;
await handle.dismissed;
```

Use `complete(value)` for a business result and `dismiss()` for cancellation.
Read `outcome.reason` when `null` is a valid completed result or when different
close causes matter.

## 4. Menu

Replace `GlobalKey anchorKey` with a stable `PopupAnchorController`, wrap the
trigger in `PopupAnchor`, and pass `anchor:` to `Pop.menu`. Coordinate polling
and RenderBox retries must be removed.

## 5. Loading and Toast

- Repeated Loading calls update the existing entry; remove manual hide-before-show.
- Use `duration`, `until`, or both for automatic/external-event closure.
- Save the returned Loading handle when one caller owns the operation.
- Toast toggle behavior remains available through advanced `ToastConfig.toggle`;
  the compact facade intentionally keeps one clear message per call.

## 6. Verification order

1. Start the Example and verify all tabs/Lab.
2. Verify system back with one popup and with Sheet → Confirm stacking.
3. Push/replace/remove routes while owner-route popups are visible.
4. Scroll an anchored Menu trigger and remove the trigger while open.
5. Exercise repeated Loading calls and external Future completion.

The exhaustive parameter mapping is in [API_PARITY_V2](API_PARITY_V2.md).
