/// Edge from which a sheet enters and toward which it is dismissed.
enum SheetDirection { top, bottom, left, right }

/// Determines which part of a sheet participates in drag-to-dismiss.
enum SheetDragDismissMode {
  fullBody,
  contentWhenAtTop,
  handleOnly,
}
