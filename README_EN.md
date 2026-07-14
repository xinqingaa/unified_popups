# unified_popups

A context-free global popup system for Flutter. It provides toast, loading,
confirm, sheet, FlowSheet, date, anchored menu, and custom popups through one
`Pop` facade and one declarative host.

## Setup

```dart
import 'package:unified_popups/unified_popups.dart';

MaterialApp(
  navigatorObservers: [Pop.routeObserver],
  builder: Pop.hostBuilder,
  home: const HomePage(),
);
```

No popup-specific navigator key, context lookup, controller injection, or
manual back wrapper is required. Calls from pages, services, timers, and flows
all use the same API:

```dart
Pop.toast('Saved', toastType: ToastType.success);

final loading = Pop.loading(message: 'Syncing…');
await repository.sync();
await loading.dismiss();

final accepted = await Pop.confirm(
  title: 'Delete item',
  content: 'This cannot be undone.',
  cancelText: 'Cancel',
  onConfirm: trackConfirmation,
  onCancel: trackCancellation,
);
```

## Handles and advanced configuration

Convenience APIs return plain business results. Use the typed Config APIs when
you need exact lifecycle and external control:

```dart
final handle = Pop.openSheet<String>(
  SheetConfig<String>(
    builder: (context, handle) => ListTile(
      title: const Text('Select'),
      onTap: () => handle.complete('selected'),
    ),
  ),
);

final value = await handle.result;
final outcome = await handle.outcome;
await handle.dismissed;
```

`result` completes with the business value, `outcome` also carries the exact
`PopupDismissReason`, and `dismissed` completes after visual removal.

Global operations include:

```dart
await handle.dismiss();
await Pop.dismissTop();
await Pop.dismissChannel(PopupChannel.sheet);
await Pop.dismissTags({'checkout'});
await Pop.dismissAll();
```

Loading updates the existing logical entry when called repeatedly and restarts
the new lifetime. Toast and Loading can close by duration, external Future, or
handle. Popups can stack above Sheet and FlowSheet. Root back handling and route
ownership are coordinated by `Pop.routeObserver`.

## Anchored menu

```dart
final anchor = PopupAnchorController();

PopupAnchor(
  controller: anchor,
  child: IconButton(
    icon: const Icon(Icons.more_horiz),
    onPressed: () => Pop.menu<void>(
      anchor: anchor,
      builder: (dismiss) => MenuContent(onDone: dismiss),
    ),
  ),
);
```

The menu follows scrolling and layout changes through composited layers and
closes automatically when its anchor detaches.

See the [API reference](docs/API_REFERENCE.md),
[best practices](docs/BEST_PRACTICES.md),
[v1 migration guide](docs/MIGRATION_V1_TO_V2.md), and
[example app](example/lib/main.dart).
