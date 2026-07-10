import 'package:flutter/widgets.dart';

final class PopupBarrierConfig {
  const PopupBarrierConfig({
    this.visible = true,
    this.dismissible = true,
    this.color = const Color(0x8A000000),
    this.semanticsLabel,
  });

  const PopupBarrierConfig.hidden()
      : visible = false,
        dismissible = false,
        color = const Color(0x00000000),
        semanticsLabel = null;

  final bool visible;
  final bool dismissible;
  final Color color;
  final String? semanticsLabel;
}
