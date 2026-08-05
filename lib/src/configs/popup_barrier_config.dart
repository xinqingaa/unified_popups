import 'package:flutter/widgets.dart';

/// 弹窗背后的遮罩：可见性、点击/拖动关闭、颜色与内边距。
final class PopupBarrierConfig {
  /// 创建一个带可见性与点击关闭行为的遮罩配置。
  ///
  /// 默认颜色为半透明黑色（`0x8A000000`）。
  ///
  /// [dismissOnDrag]：在可关闭遮罩上拖动/滑动时关闭（手势由 barrier 消费，
  /// 不转发到下层）。Menu / DropMenu 默认开启。
  const PopupBarrierConfig({
    this.visible = true,
    this.dismissible = true,
    this.dismissOnDrag = false,
    this.color = const Color(0x8A000000),
    this.semanticsLabel,
    this.insets = EdgeInsets.zero,
  });

  /// 完全透明且不可点击关闭的遮罩（无遮罩色，点击外部无效）。
  const PopupBarrierConfig.hidden()
      : visible = false,
        dismissible = false,
        dismissOnDrag = false,
        color = const Color(0x00000000),
        semanticsLabel = null,
        insets = EdgeInsets.zero;

  final bool visible;
  final bool dismissible;

  /// 在 [dismissible] 为 true 时，空白处拖动/滑动是否关闭弹层。
  final bool dismissOnDrag;
  final Color color;
  final String? semanticsLabel;
  final EdgeInsets insets;

  /// 返回一个替换了部分字段的副本，其余保持不变。
  PopupBarrierConfig copyWith({
    bool? visible,
    bool? dismissible,
    bool? dismissOnDrag,
    Color? color,
    String? semanticsLabel,
    EdgeInsets? insets,
  }) {
    return PopupBarrierConfig(
      visible: visible ?? this.visible,
      dismissible: dismissible ?? this.dismissible,
      dismissOnDrag: dismissOnDrag ?? this.dismissOnDrag,
      color: color ?? this.color,
      semanticsLabel: semanticsLabel ?? this.semanticsLabel,
      insets: insets ?? this.insets,
    );
  }
}
