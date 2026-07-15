import 'package:flutter/widgets.dart';

/// 弹窗背后的遮罩：可见性、点击关闭、颜色与内边距。
final class PopupBarrierConfig {
  /// 创建一个带可见性与点击关闭行为的遮罩配置。
  ///
  /// 默认颜色为半透明黑色（`0x8A000000`）。
  const PopupBarrierConfig({
    this.visible = true,
    this.dismissible = true,
    this.color = const Color(0x8A000000),
    this.semanticsLabel,
    this.insets = EdgeInsets.zero,
  });

  /// 完全透明且不可点击关闭的遮罩（无遮罩色，点击外部无效）。
  const PopupBarrierConfig.hidden()
      : visible = false,
        dismissible = false,
        color = const Color(0x00000000),
        semanticsLabel = null,
        insets = EdgeInsets.zero;

  final bool visible;
  final bool dismissible;
  final Color color;
  final String? semanticsLabel;
  final EdgeInsets insets;

  /// 返回一个替换了 [insets] 的副本，其余字段保持不变。
  PopupBarrierConfig copyWith({EdgeInsets? insets}) {
    return PopupBarrierConfig(
      visible: visible,
      dismissible: dismissible,
      color: color,
      semanticsLabel: semanticsLabel,
      insets: insets ?? this.insets,
    );
  }
}
