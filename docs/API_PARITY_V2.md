# unified_popups v1 → v2 API parity

本文档冻结 v1 公开能力在 v2 中的去向。状态含义：

- `保留`：便捷 API 继续提供，调用形态尽量不变。
- `迁移`：能力保留，但归属到类型 Config、Handle 或公共策略对象。
- `替换`：使用新的明确模型替代旧语义。
- `移除`：v2 不再提供。

## 应用接入

| v1 | v2 | 状态 | 说明 |
| --- | --- | --- | --- |
| `PopupManager.initialize(navigatorKey:)` | 删除 | 移除 | Popup 不再依赖 navigatorKey。 |
| `PopScopeWidget` | `Pop.hostBuilder` 内部返回桥 | 替换 | 阶段 0 先验证 Route PopEntry、predictive back 与 iOS 侧滑。 |
| `PopupRouteObserver()` | `Pop.routeObserver` | 替换 | Runtime 生命周期内稳定实例。 |
| 每 Popup 一个 `OverlayEntry` | 单一 `PopupHost` | 替换 | Entry 声明式渲染。 |

目标初始化：

```dart
MaterialApp(
  navigatorObservers: [Pop.routeObserver],
  builder: Pop.hostBuilder,
);
```

## 通用生命周期与行为

| v1 | v2 | 状态 | 说明 |
| --- | --- | --- | --- |
| `PopupConfig.type` 驱动行为 | `PopupChannel` + 显式 Policy | 替换 | Channel 只用于查询，不驱动返回/路由。 |
| `animation` / `animationDuration` / `animationCurve` | `PopupAnimationConfig` | 迁移 | 便捷 API 继续透传常用参数。 |
| `showBarrier` / `barrierDismissible` / `barrierColor` | `PopupBarrierConfig` | 迁移 | 支持局部 Barrier insets。 |
| `useSafeArea` | 类型 Config | 迁移 | Sheet/Confirm/Menu 分别定义。 |
| `duration` | `PopupLifetime` | 替换 | 支持 manual/after/until/anyOf。 |
| `onShow` | `onPresented` | 替换 | 进入动画完成触发。 |
| `onDismiss` | `onOutcome` + `onDismissed` | 替换 | 区分业务关闭与视觉移除。 |
| `onBackPressed` | `PopupBackPolicy.delegate` | 替换 | 由 Host 统一分发。 |
| `dismissOnRouteChange` | `PopupRoutePolicy` | 替换 | 支持 owner route token。 |
| `dockToEdge` / `edgeGap` | Sheet/Custom Config + Barrier insets | 迁移 | 保留点击透传能力。 |
| `clipDuringAnimation` | 类型 Animation/Render Config | 迁移 | Menu/Custom 显式配置。 |

## Toast

| v1 参数/行为 | v2 | 状态 |
| --- | --- | --- |
| `message` / `messageWidget` | `ToastConfig.content` | 保留 |
| `position` | `ToastConfig.position` | 保留 |
| `duration` | `PopupLifetime.after` | 替换 |
| `showBarrier` / barrier 参数 | `ToastConfig.barrier` | 迁移 |
| `toastType` | `ToastConfig.type` | 保留 |
| `customImagePath` / `imageSize` / `imgColor` | `ToastConfig.icon` | 迁移 |
| `layoutDirection` | `ToastConfig.layoutDirection` | 保留 |
| `padding` / `margin` / `decoration` / 文本样式 | `ToastStyle` | 迁移 |
| `tMessage` / `tImagePath` / `tToastType` / `tImgColor` / `toggleable` | `ToastToggleConfig` | 迁移 |
| `onTap` | `ToastConfig.onTap` | 保留 |
| 每 Toast 一个全屏 Entry | 共享 Toast lane，位置最多 3 个 | 替换 |
| void 返回 | `ToastHandle`，允许忽略 | 替换 |

## Loading

| v1 参数/行为 | v2 | 状态 |
| --- | --- | --- |
| `message` | `LoadingConfig.message/content` | 保留 |
| 背景、圆角、indicator、文字样式 | `LoadingStyle` | 迁移 |
| `customIndicator` / `rotationDuration` | `LoadingIndicatorConfig` | 迁移 |
| barrier 参数 | `LoadingConfig.barrier` | 迁移 |
| 重复调用 hide + show | 同 key `updateExisting` | 替换 |
| `Pop.hideLoading()` | 保留，强制关闭默认 key | 保留 |
| void 返回 | `LoadingHandle`，允许忽略 | 替换 |
| 返回键关闭 | 默认 `PopupBackPolicy.block` | 行为变更 |
| 键盘出现时居中跳动规避 | Host 稳定屏幕坐标 | 保留 |

## Confirm

| v1 参数/行为 | v2 | 状态 |
| --- | --- | --- |
| title/content String 或 Widget | `ConfirmConfig` | 保留 |
| confirm/cancel String 或 Widget | `ConfirmButtonConfig` | 迁移 |
| `onConfirm` / `onCancel` | 保留并冻结按钮专属语义 | 保留 |
| `showCloseButton` | `ConfirmConfig.showCloseButton` | 保留 |
| image、文字、按钮布局和样式 | `ConfirmStyle` | 迁移 |
| `confirmChild` | `ConfirmConfig.bodyExtension` | 迁移 |
| `Future<bool?>` | 便捷 API 保留；高级 API 提供 Outcome/Handle | 保留 |
| Barrier/Back 调用 onCancel | 不调用，只返回 `null` Outcome | 明确化 |

## Sheet

| v1 参数/行为 | v2 | 状态 |
| --- | --- | --- |
| `childBuilder(dismiss)` | 便捷 API 保留 | 保留 |
| title/titleWidget | `SheetConfig.header` | 迁移 |
| direction | `SheetConfig.direction` | 保留 |
| width/height/maxWidth/maxHeight | `SheetSizeConfig` | 迁移 |
| showCloseButton、图片、背景、圆角、阴影、padding | `SheetStyle` | 迁移 |
| dockToEdge/edgeGap | `SheetDockConfig` | 迁移 |
| showDragHandle/dragHandleColor | `SheetDragConfig` | 迁移 |
| adjustForKeyboard | `SheetKeyboardConfig` | 迁移 |
| fullBody/contentWhenAtTop/handleOnly | 保留并补齐四方向 | 保留 |
| 固定 75px、无速度/回弹 | 比例 + velocity + 回弹 | 替换 |
| 每帧 setState | 统一进度控制器 | 替换 |
| `Future<T?>` | 便捷 API 保留；`Pop.openSheet` 返回 Handle | 保留 |

## FlowSheet

| v1 参数/行为 | v2 | 状态 |
| --- | --- | --- |
| 外层基于 `Pop.sheet` | 作为统一 PopupEntry 的专用 delegate | 替换 |
| 调用方传入 Controller | 保留；Session 接管 one-shot 所有权 | 保留 |
| push/pop/replace/completeCurrent/closeAll | 保留 | 保留 |
| 页面 lifecycle hooks | 保留 | 保留 |
| maintainState/dragDismissMode | 保留 | 保留 |
| pageBackgroundColor/routeBuilder | `FlowSheetConfig` | 迁移 |
| 外层销毁握手 | 通用 PopupHandle/Host 管理 | 替换 |

## Menu

| v1 参数/行为 | v2 | 状态 |
| --- | --- | --- |
| `GlobalKey anchorKey` | `PopupAnchorController` + `PopupAnchor` | 替换 |
| `anchorOffset` | `MenuAnchorConfig.offset` | 保留 |
| builder/dismiss/result | 保留 | 保留 |
| barrier、padding、constraints、decoration | `MenuConfig` / `MenuStyle` | 迁移 |
| animation 参数 | `PopupAnimationConfig` | 迁移 |
| post-frame RenderBox 重试 | Target/Follower + placement delegate | 替换 |
| Anchor 滚动后位置不变 | 自动跟随 | 修复 |
| Anchor 卸载 | 自动以 anchorDetached 关闭 | 新增 |

## Date

| v1 参数/行为 | v2 | 状态 |
| --- | --- | --- |
| initial/min/max date | `DateConfig.range` | 保留并增加参数校验 |
| title/confirm/cancel 文案 | `DateConfig.labels` | 迁移 |
| active/noActive/header/radius/height | `DateStyle` | 迁移 |
| `Future<DateTime?>` | 便捷 API 保留 | 保留 |

## PopupManager 与 Custom Popup

| v1 | v2 | 状态 |
| --- | --- | --- |
| `PopupManager.show(PopupConfig)` | `Pop.custom(CustomPopupConfig)` | 替换 |
| String popup id | `PopupHandle` | 替换 |
| `hide(id)` | `handle.dismiss()` | 替换 |
| `hideByType` | `dismissKey/channel/tags` | 替换 |
| `hideLast` | `dismissTop` | 替换 |
| `hideLastNonToast` | `handleBack` | 替换 |
| `hideAll` | `dismissAll` | 保留 |
| `isVisible(id)` | Handle/key 查询 | 替换 |
| `getCountByType` | `countChannel` | 替换 |
| `hasNonToastPopupNotifier` | Runtime snapshot/listenable | 替换 |
| `maybePop(context)` | `Pop.handleBack()` + 业务 Navigator | 替换 |

## 已确认移除

- `PopupManager` 公共单体。
- `PopupConfig` 巨型配置。
- `PopupType` 行为驱动。
- `SafeOverlayEntry`。
- `AnimationControllerPool`。
- `PopScopeWidget`。
- `part/part of` 组织方式。

## SDK 基线

v2 最低版本冻结为 Flutter `3.24.0`、Dart `3.5.0`。原因是正式返回桥使用 `PopEntry.onPopInvokedWithResult` 的稳定 API 形态；Flutter `3.16` 中的 `PopEntry` 接口仍不兼容当前实现。

完成旧 performance 基线迁移后，CI 矩阵将覆盖：

- Flutter `3.24.0`。
- 当前 Flutter stable。
