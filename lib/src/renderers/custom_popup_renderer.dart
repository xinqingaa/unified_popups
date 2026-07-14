import 'package:flutter/widgets.dart';

import '../configs/custom_popup_config.dart';
import '../controller/popup_handle.dart';

class CustomPopupRenderer extends StatefulWidget {
  const CustomPopupRenderer({
    required this.config,
    required this.handle,
    super.key,
  });

  final CustomPopupConfigBase config;
  final PopupHandleBase handle;

  @override
  State<CustomPopupRenderer> createState() => _CustomPopupRendererState();
}

class _CustomPopupRendererState extends State<CustomPopupRenderer> {
  Widget? _child;

  @override
  Widget build(BuildContext context) {
    return _child ??= widget.config.buildContent(context, widget.handle);
  }
}
