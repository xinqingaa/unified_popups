import 'package:flutter/material.dart';

import '../configs/toast_config.dart';

class ToastRenderer extends StatefulWidget {
  const ToastRenderer({required this.config, super.key});

  final ToastConfig config;

  @override
  State<ToastRenderer> createState() => _ToastRendererState();
}

class _ToastRendererState extends State<ToastRenderer> {
  bool _primary = true;

  @override
  void didUpdateWidget(ToastRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.toggle != widget.config.toggle) _primary = true;
  }

  void _tap() {
    if (widget.config.toggle != null) {
      setState(() => _primary = !_primary);
    }
    widget.config.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final toggle = _primary ? null : config.toggle;
    final message = toggle?.message ?? config.message;
    final icon = toggle?.icon ?? config.icon;
    final type = toggle?.type ?? config.type;
    final style = config.style;

    Widget? iconWidget;
    final asset = icon?.assetPath ?? _assetFor(type);
    if (asset != null) {
      iconWidget = Image.asset(
        asset,
        package: icon?.assetPath == null ? 'unified_popups' : null,
        width: icon?.size ?? 24,
        height: icon?.size ?? 24,
        color: icon?.assetPath == null ? null : icon?.color,
      );
    }

    final content = config.content ??
        Text(
          message ?? '',
          style: style.textStyle,
          textAlign: style.textAlign,
        );
    final children = <Widget>[
      if (iconWidget != null) iconWidget,
      if (iconWidget != null)
        SizedBox(
          width: config.layoutDirection == Axis.horizontal ? style.spacing : 0,
          height: config.layoutDirection == Axis.vertical ? style.spacing : 0,
        ),
      Flexible(child: content),
    ];
    final body = config.layoutDirection == Axis.horizontal
        ? Row(mainAxisSize: MainAxisSize.min, children: children)
        : Column(mainAxisSize: MainAxisSize.min, children: children);
    final decoration = style.decoration ??
        BoxDecoration(
          color: const Color(0xCC000000),
          borderRadius: BorderRadius.circular(12),
        );

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: config.onTap != null || config.toggle != null ? _tap : null,
        child: Container(
          margin: style.margin,
          padding: style.padding,
          decoration: decoration,
          child: body,
        ),
      ),
    );
  }

  String? _assetFor(ToastType type) => switch (type) {
        ToastType.success => 'assets/images/success.png',
        ToastType.warn => 'assets/images/warn.png',
        ToastType.error => 'assets/images/error.png',
        ToastType.none => null,
      };
}
