import 'package:flutter/painting.dart';

import 'popup_position.dart';

/// 无遮罩 Toast 在同一位置换场时的时间与位移。
abstract final class ToastLaneMotion {
  /// 入场结束并进入 visible 之后，至少停留这么久才允许被下一条换掉。
  static const Duration dwell = Duration(milliseconds: 500);

  /// 当前条开始换场退场后，下一条再入场的延迟。
  static const Duration enterDelay = Duration(milliseconds: 50);

  /// 被下一条换掉时，淡出并平移的时长。
  static const Duration exitDuration = Duration(milliseconds: 180);

  /// 换场平移距离，逻辑像素。
  static const double shift = 20;

  /// 被替换条的平移方向。
  ///
  /// 左右贴边时继续向外，其余位置向左。距离固定为 [shift]，不随 Toast 宽度变化。
  static Offset outgoingShift(PopupPosition position) => switch (position) {
        PopupPosition.left => const Offset(-shift, 0),
        PopupPosition.right => const Offset(shift, 0),
        _ => const Offset(-shift, 0),
      };
}
