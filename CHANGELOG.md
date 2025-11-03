# Changelog

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