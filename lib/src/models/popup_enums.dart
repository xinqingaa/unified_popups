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

/// toast等级
enum ToastType { success , warn , error , none }