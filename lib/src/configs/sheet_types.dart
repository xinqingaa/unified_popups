/// Sheet 弹出的边缘方向，也是关闭时退出的方向。
enum SheetDirection {
  top,
  bottom,
  left,
  right,
}

/// 决定 sheet 中哪个区域参与拖拽关闭手势。
enum SheetDragDismissMode {
  /// 禁用拖拽关闭。
  disabled,
  fullBody,
  contentWhenAtTop,
  handleOnly,
}
