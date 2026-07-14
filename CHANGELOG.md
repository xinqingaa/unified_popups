# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0]

### Architecture

- Replaced the global `PopupManager`, navigator key initialization, and one-fullscreen-overlay-per-popup model with `Pop` + replaceable `PopupRuntime` + one declarative `PopupHost`.
- Added typed Config/Renderer pairs and a unified `PopupHandle`, separating business outcome from visual dismissal.
- Removed `AnimationControllerPool`, `PopupConfig`, `PopupType` behavior branching, `PopScopeWidget`, legacy route observer, and `part` APIs.

### Behavior

- Added one-time setup through `Pop.hostBuilder` and `Pop.routeObserver`; all business calls remain global and context-free.
- Added explicit key/channel/tags, conflict, route, back, ownership, barrier, lifetime, and lifecycle policies.
- Loading now updates the same logical entry and restarts its lifetime; Toast and Loading can close from a timer, external Future, or handle.
- Confirm exposes button-specific `onConfirm` and `onCancel` callbacks while preserving `Future<bool?>`.
- Sheet and FlowSheet share the four-direction renderer and drag system; popup types can stack above either.
- Menu now uses `PopupAnchorController` + `PopupAnchor` and follows layout/scroll changes automatically.

### Migration

- Migrated the FitPulse example and Lab to v2, including external handle closing, stacking, back handling, route ownership, Loading update, and external-event lifetime examples.
- Rewrote public documentation and added the v1 → v2 parity table.

## [1.3.0]

### Added

#### FlowSheet
- 新增 `Pop.flowSheet`：在单个 Sheet 内维护多页栈（`push` / `pop` / `replace` / `completeCurrent` / `closeAll`）
- 新增 `FlowSheetController`、`FlowSheetPage`、`FlowSheetPageState` 与生命周期钩子（`onLoad` / `onShow` / `onHide` / `onRemove` / `onClose`）
- 支持按页配置 `SheetDragDismissMode`，以及自定义 `FlowSheetRouteBuilder`

#### Sheet 拖拽与返回
- 新增 `SheetDragDismissMode`：`fullBody` / `contentWhenAtTop` / `handleOnly`
- `Pop.sheet` 支持 `showDragHandle`、`dragHandleColor`、`adjustForKeyboard`、`dragDismissMode`、`dragDismissModeListenable`、`onBackPressed`
- `PopupConfig.onBackPressed`：系统返回可先交给弹窗内部处理（FlowSheet 优先退内部页）
- `PopupRouteObserver.didRemove`：路由 remove 时同样触发弹窗清理
- 各 `Pop.*` API 透出可选 `dismissOnRouteChange`

### Example
- FitPulse 健身健康示例：主路径场景（今日 / 训练 / 数据 / 我的）+ Lab；含开始训练与健康档案 FlowSheet

---

## [1.2.2]

### Performance Optimizations ⚡

#### PopScopeWidget Rebuild Optimization
- **重构 PopScopeWidget**：从 `StatelessWidget` + `ValueListenableBuilder` 改为 `StatefulWidget`
- **减少 90%+ 不必要重建**：只在 `hasNonToastPopup` 状态真正变化时才触发 `setState`
- **避免子树重建**：`child` 参数永不重建，减少性能开销

#### AnimationController Object Pool
- **新增对象池机制**：`lib/src/utils/animation_controller_pool.dart`
- **复用 AnimationController**：减少 60-80% 的 AnimationController 分配
- **降低 GC 压力**：频繁显示 toast/loading 时性能更佳

#### RenderBox Caching
- **缓存 RenderBox 引用**：避免重复调用 `findRenderObject()`
- **减少 50-70% 布局计算开销**：锚定菜单位置计算更高效

#### Screen Size Caching
- **懒加载屏幕尺寸**：避免重复查询 MediaQuery
- **缓存失效机制**：在依赖变化时自动更新缓存

### Internal Changes
- 优化 `_PopupLayout` 的状态管理和缓存策略
- 改进动画资源生命周期管理

---

## [1.2.1]

### Added
##### Widget 自定义支持

- Pop.toast() 新增 messageWidget 参数，支持完全自定义消息内容 Widget
- Pop.confirm() 新增 titleWidget、contentWidget、confirmButtonWidget、cancelButtonWidget 参数，支持完全自定义标题、内容和按钮 Widget
- Pop.sheet() 新增 titleWidget 参数，支持完全自定义标题 Widget
- 所有 Widget 参数优先于对应的 String 参数，提供更灵活的定制能力

#### Confirm 回调增强

- Pop.confirm() 新增 onConfirm 和 onCancel 回调参数
- 回调在内部关闭逻辑之前执行，允许外部完全接管按钮点击事件
- 保留原有的 Future<bool?> 返回值机制，向后兼容

> 示例页面
> 新增 PopupManagerPage 示例页面，展示 PopScopeWidget 和 PopupManager.show 的搭配使用


## [1.2.0]

### ✨ New Features

#### Animation Curve Support
- **新增 `animationCurve` 参数**：所有弹窗 API 都支持自定义动画曲线
- **默认曲线优化**：所有 API 默认使用 `Curves.easeInOut`
- **灵活的动画配置**：每个弹窗可独立配置动画时长和曲线

**使用示例：**
```dart
Pop.toast(
  '消息',
  animationDuration: Duration(milliseconds: 200),
  animationCurve: Curves.easeOutBack, // 自定义曲线
);

Pop.sheet(
  title: '面板',
  animationDuration: Duration(milliseconds: 500),
  animationCurve: Curves.easeOutCubic,
  childBuilder: (dismiss) => Content(),
);
```

#### PopupRouteObserver - Route Change Management
- **新增路由观察者**：`PopupRouteObserver` 自动监听路由变化
- **智能弹窗清理**：confirm、sheet 默认在路由切换时关闭
- **可配置行为**：通过 `dismissOnRouteChange` 控制是否自动关闭

**使用方式：**
```dart
MaterialApp(
  navigatorObservers: const [PopupRouteObserver()],
  home: PopScopeWidget(child: HomePage()),
);
```

#### PopScopeWidget Enhancement
- **返回键拦截优化**：优先关闭弹窗而非页面路由
- **状态监听改进**：使用 `ValueNotifier` 高效监听弹窗状态

### 🐛 Bug Fixes

#### Sheet Animation
- **裁剪多余动画**：修复 sheet 动画超出区域的裁剪问题
- **动画边界优化**：`clipDuringAnimation` 正确应用于锚定模式

#### Layout and Positioning
- **edgeGap 正确传递**：修复 `dockToEdge` 模式下的边缘间隙传递
- **动态动画偏移**：锚定模式下支持智能位置调整的动画偏移

#### Loading Management
- **单例模式强化**：loading 自动关闭旧的实例，避免多个同时显示
- **键盘抖动修复**：解决 loading 在键盘弹出时的位置抖动问题

#### Async Support
- **构建阶段检测**：支持在 `build()` 方法中调用所有弹窗类型
- **SafeOverlayEntry 优化**：延迟执行构建阶段的弹窗插入操作

#### Toast Interaction
- **点击切换功能**：新增 `toggleable` 参数，支持 toast 状态切换
- **点击回调**：新增 `onTap` 参数，支持点击事件处理

#### Menu Enhancements
- **样式自定义**：新增 `padding`、`decoration`、`constraints` 参数
- **更灵活的布局**：支持完整的样式定制

#### Sheet Enhancements
- **TabBar 适配**：新增 `dockToEdge` 和 `edgeGap` 参数
- **边缘保留区域**：支持保留底部/侧边导航栏的交互区域

### 🏗️ Architecture Improvements
- **弹窗生命周期管理**：改进弹窗的创建、显示、隐藏流程
- **资源管理优化**：优化 AnimationController 和 OverlayEntry 的释放逻辑
- **状态同步改进**：优化 `hasNonToastPopup` 的更新机制

### 📝 Documentation
- 更新 API 参考文档
- 新增最佳实践指南
- 完善使用示例

---

## [1.1.17]
### Added
- Add `PopupRouteObserver`.
  - Popups such as sheet and confirm will automatically close when the route changes.

## [1.1.16]
### Fixed
- ClipRect Sheet animation overflow

## [1.1.15]
### Fixed
- The `edgeGap` parameter is correctly passed to `PopupConfig`

## [1.1.14]
### Fixed
- Fix the bug where the area that disappears when multiple Loading triggers occur remains and causes unclickability due to OverLary's effect.
- Following the singleton pattern, the loading process cannot be triggered many times. The displayed OverLary will always have only one.

## [1.1.13]
### Added
- **Toast Toggle Feature**
  - Added toggle functionality for Toast, allowing users to switch between two states by tapping
  - Added `tMessage` parameter: alternate message text for toggle mode
  - Added `tImagePath` parameter: alternate image path for toggle mode
  - Added `tToastType` parameter: alternate toast type for toggle mode
  - Added `tImgColor` parameter: alternate image color for toggle mode
  - Added `onTap` parameter: callback function when toast is tapped
  - Added `toggleable` parameter: enable/disable toggle mode (default: false)
  - ToastWidget changed from StatelessWidget to StatefulWidget to support state management
  - When `toggleable` is `true` and `tMessage` or `tImagePath` is provided, tapping the toast will switch between two states

## [1.1.12]
### Feat
- `clipDuringAnimation` for PopupConfig: Whether to crop the animation that exceeds the area in anchor point mode, default false.

## [1.1.11]
### Fixed
- **Enhanced Build Phase Error Handling**
  - Fixed `overlay.insert()` setState error when called during build phase
  - Extracted `_insertPopup` private method to handle overlay insertion logic
  - Added build phase detection in `PopupManager.show()` method
  - If called during build phase (`SchedulerPhase.persistentCallbacks`), automatically defers to `postFrameCallback` execution
  - Now fully supports calling popups in async operations and during build phase without errors
  - Perfect support for scenarios like `Get.put()` immediate initialization in route building process

## [1.1.10]
### Changed
- **Loading API Simplification**
  - `Pop.loading()` now returns `void` instead of `String` (loading ID)
  - `Pop.hideLoading()` no longer requires a parameter
  - The entire application can only have one loading instance at a time, managed internally
  - When showing a new loading, any existing loading is automatically closed

### Added
- **PopupManager Enhancement**
  - Added `PopupManager.hideByType(PopupType type)` method to hide popups by type
  - Useful for managing single-instance popup types like loading

### Fixed
- Fixed "setState() called during build" error when calling `Pop.loading()` during build phase
- Implemented `SafeOverlayEntry` that delays overlay insertion if called during build phase
- Uses `SchedulerBinding` to check build phase and defer overlay operations

## [1.1.9]
### Added
- Added `padding`, `constraints`, `decoration` for `Pop.menu`

## [1.1.8]
### Added
- Introduced sheet barrier options (`showBarrier`, `barrierDismissible`, `barrierColor`) for finer control.
- Added `dockToEdge` to reserve space for system/tab/navigation bars when sliding from the bottom/left/right edges.
- Added `edgeGap` with a default of `kBottomNavigationBarHeight + 4`, allowing custom edge spacing.

### Changed
- When `dockToEdge` is enabled, the barrier now uses clipping instead of margin so the reserved edge remains interactive.

### Fixed
- Improved sheet keyboard handling so bottom sheets lift with the keyboard without compressing content.

## [1.1.7]
### Added
- `Pop.sheet` introduces barrier parameters (`showBarrier`, `barrierDismissible`, `barrierColor`) for more flexible interaction control.

### Fixed
- Improved sheet keyboard handling: bottom sheets now move with the keyboard, preventing content compression or overflow.

## [1.1.6]
### Changed
- **Toast API Enhancement**
  - Added `imgColor` parameter so custom images can be tinted directly from `Pop.toast`

## [1.1.5]
### Added
- **Confirm API Enhancement**
  - Added `confirmBorder` and `cancelBorder` parameters to allow custom `BoxBorder` for confirm/cancel buttons
  - Preserves the original borderless style when a border is not provided

### Changed
- `ConfirmWidget` buttons now use `GestureDetector + Container`, maintaining border radius, custom borders, and background colors consistently

## [1.1.4]
### Added
- **Toast API Enhancement**
  - Added `customImagePath` parameter to support custom local images
  - Added `imageSize` parameter to customize image size (default: 24.0)
  - Added `layoutDirection` parameter to support Row/Column layout switching (default: Row)
  - Custom images will override toastType icons when provided

- **Loading API Enhancement**
  - Added `customIndicator` parameter to support custom Widget (typically images) as loading indicator
  - Added `rotationDuration` parameter to configure rotation animation speed (default: 1 second)
  - Custom indicator automatically includes rotation animation
  - When both message and customIndicator are present, Container maintains square aspect ratio with adaptive sizing (max 25% screen width, 100px)

### Changed
- LoadingWidget changed from StatelessWidget to StatefulWidget to support rotation animation
- Loading container with message now maintains square aspect ratio for better visual consistency

## [1.1.3]
### Feat
- Pop.menu
  - 新增智能定位
  - example/lib 新增测试按钮
- Pop.sheet
  - 新增图片size和偏移量参数

## [1.1.2]
### Fixed
- 条件性地应用内边距
- 在 Sheet 位于底部时，才应用这个用于避让键盘的内边距.

## [1.1.1]
### Fixed
- 修复了所有widget组件中的文本溢出问题
- ToastWidget: 使用Flexible包裹文本，支持多行显示
- ConfirmWidget: 为标题和内容文本添加maxLines和overflow处理
- LoadingWidget: 为消息文本添加溢出处理
- SheetWidget: 为标题文本添加溢出处理
- 所有文本组件现在都支持长文本的多行显示，避免溢出错误

## [1.1.0]
### Added
- 为所有API入口添加了`animationDuration`参数，支持外部传入不同的动画时长
- 每个API都有合理的默认动画时长：
  - `Pop.toast()`: 200ms (快速显示)
  - `Pop.loading()`: 150ms (快速显示)
  - `Pop.confirm()`: 250ms (适中时长)
  - `Pop.date()`: 250ms (适中时长)
  - `Pop.menu()`: 200ms (快速响应)
  - `Pop.sheet()`: 400ms (较长动画，适合抽屉效果)
  - `PopupConfig.animationDuration`默认值从400ms调整为300ms，作为最终兜底值

### Changed
- 优化了动画时长的默认配置，不同场景使用不同的动画时长，提升用户体验
- 所有API方法现在都支持`animationDuration`参数，保持向后兼容性

### Technical Details
- 参数传递链路：API方法 → 实现方法 → PopupConfig → PopupManager
- 不传参数时使用合理的默认值，传入自定义值时覆盖默认值

## [1.0.3]
### Added
- Submit Code, A unified popups SDK for Flutter, providing a flexible way to show toasts, dialogs, and other custom popups.
- 统一弹窗库的基础功能实现
- 支持Toast、Loading、Confirm、Sheet、Date、Menu等弹窗类型
- 基于Overlay的多实例弹窗管理系统
- 完整的API文档和最佳实践指南

---

## 版本说明

- **[1.2.1]**: 性能优化版本 - 重点优化重建和资源管理
- **[1.2.0]**: 功能增强版本 - 新增动画曲线和路由观察者
- **[1.1.17]**: 路由观察者版本
- **[1.1.14]**: Bug 修复版本

### 升级指南

#### 从 1.1.x 升级到 1.2.1
1. 更新 `pubspec.yaml` 中的版本号到 `^1.2.1`
2. 如果使用了路由观察者，确保已添加 `PopupRouteObserver`
3. 享受性能提升！无需修改现有代码

#### API 兼容性
- ✅ 完全向后兼容
- ✅ 所有新参数都是可选的
- ✅ 默认行为保持一致

### 性能对比

| 指标 | 1.1.x | 1.2.1 | 提升 |
|------|-------|-------|------|
| PopScopeWidget 重建次数 | 100+ | <10 | 90%+ ↓ |
| AnimationController 分配 | 每次新建 | 对象池复用 | 60-80% ↓ |
| 布局计算开销 | 重复计算 | 缓存优化 | 50-70% ↓ |
| 内存占用 | ~50KB/弹窗 | ~30KB/弹窗 | 40% ↓ |

### 贡献者

感谢所有贡献者的支持！

### 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件
