# v2 Architecture

```text
business / service / flow
          │
          ▼
     global Pop facade
          │
          ▼
 PopupRuntime ── route observer / host ownership
          │
          ▼
 PopupController ── entries / policies / handles / outcomes
          │ snapshots
          ▼
 one PopupHost + PopupScene
          │
          ├─ Toast / Loading renderer
          ├─ Confirm / Date renderer
          ├─ Sheet / FlowSheet renderer
          ├─ Menu renderer
          └─ Custom renderer
```

## Responsibilities

- `Pop` is the only recommended business entry. It owns the default replaceable
  Runtime and exposes convenience, typed Config, and global management APIs.
- `PopupRuntime` owns one Controller, one stable route observer, and one Host
  binding. It has no Navigator key or BuildContext dependency.
- `PopupController` is the UI-independent state machine. It resolves conflicts,
  route/back/ownership policies, lifetime races, queueing, outcome, and cleanup.
- `PopupHost` declaratively renders Controller snapshots above a stable app
  child. Popup changes do not rebuild the Navigator/application subtree.
- Renderers own type-specific UI and interaction. Channel is only a query
  category and never selects behavior implicitly.

## Lifecycle

```text
open → pendingHost/queued → entering → visible
                                  │
complete/dismiss/policy/event ─────┘
          ↓
outcome fixed → exiting → renderer removed → dismissed
```

Business completion and visual removal are separate. Every close path is
idempotent and records one `PopupDismissReason`. Lifetime generations prevent an
old timer/Future from closing a newly updated Loading or Toast.

## Stack and navigation

All popup types share one ordered entry list, so Confirm/Menu/Toast may appear
above Sheet or FlowSheet without closing the lower layer. The stable route
observer registers a `PopEntry` on the active root route. System back is routed
to the top eligible entry; FlowSheet delegates first to its internal Navigator.

Route ownership is captured when a Config requests owner-route behavior.
`persist`, owner-route dismissal, and any-route dismissal are explicit policies.

## Performance model

- One Host and one private Overlay replace one fullscreen OverlayEntry per popup.
- The app child remains stable while only the popup scene listens to snapshots.
- Toasts without a Barrier share positional lanes.
- Loading update preserves one logical entry and handle.
- Sheet drag mutates the shared animation progress; heavy content is cached by
  the renderer rather than rebuilt for each pointer update.
- Animation controllers follow Widget lifecycle; there is no unsafe object pool.
