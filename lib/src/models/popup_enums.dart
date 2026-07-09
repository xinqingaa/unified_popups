part of '../core/popup_manager.dart';

/// 定义弹出层在屏幕上的垂直位置
enum PopupPosition {
  /// 顶部，位于安全区域下方
  top,

  /// 居中，默认值
  center,

  /// 底部，位于安全区域上方
  bottom,

  /// 左侧，位于安全区域内
  left,

  /// 右侧，位于安全区域内
  right,
}

/// 定义弹出层的进入和退出动画类型
enum PopupAnimation {
  /// 无动画
  none,

  /// 淡入淡出
  fade,

  /// 从上往下滑入
  slideDown,

  /// 从下往上滑入
  slideUp,

  /// 从左往右滑入
  slideLeft,

  /// 从右往左滑入
  slideRight,
}

/// sheet 弹出方向
enum SheetDirection { top, bottom, left, right }

/// Sheet 下拉/侧滑关闭策略。
enum SheetDragDismissMode {
  /// 非滚动主体：整块内容均可拖动关闭。
  fullBody,

  /// 滚动内容滚到顶后继续下拉可关闭（适用于 SingleChildScrollView 等）。
  contentWhenAtTop,

  /// 仅 drag handle / 标题栏可拖动关闭（适用于 SmartRefresher 等下拉刷新页）。
  handleOnly,
}

/// toast 等级
enum ToastType { success, warn, error, none }

/// confirm 按钮的布局方式
enum ConfirmButtonLayout {
  row,
  column,
}

/// 弹层类型，用于系统返回事件处理等逻辑
enum PopupType {
  toast,
  loading,
  confirm,
  sheet,
  date,
  menu,
  other,
}
