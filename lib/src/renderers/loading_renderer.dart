import 'package:flutter/material.dart';

import '../configs/loading_config.dart';

class LoadingRenderer extends StatefulWidget {
  const LoadingRenderer({required this.config, super.key});

  final LoadingConfig config;

  @override
  State<LoadingRenderer> createState() => _LoadingRendererState();
}

class _LoadingRendererState extends State<LoadingRenderer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation;

  @override
  void initState() {
    super.initState();
    _rotation = AnimationController(
      vsync: this,
      duration: widget.config.indicator.rotationDuration,
    );
    _syncRotation();
  }

  @override
  void didUpdateWidget(LoadingRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.indicator.rotationDuration !=
        widget.config.indicator.rotationDuration) {
      _rotation.duration = widget.config.indicator.rotationDuration;
    }
    _syncRotation();
  }

  void _syncRotation() {
    if (widget.config.indicator.child != null) {
      if (!_rotation.isAnimating) _rotation.repeat();
    } else {
      _rotation.stop();
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final style = config.style;
    final custom = config.indicator.child;
    final indicator = custom == null
        ? CircularProgressIndicator(
            color: style.indicatorColor,
            strokeWidth: style.indicatorStrokeWidth,
          )
        : RotationTransition(turns: _rotation, child: custom);
    final message = config.content ??
        (config.message == null
            ? null
            : Text(
                config.message!,
                style: style.textStyle,
                textAlign: TextAlign.center,
              ));
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        indicator,
        if (message != null) ...<Widget>[
          const SizedBox(height: 16),
          Flexible(child: message),
        ],
      ],
    );
    final box = Container(
      padding: style.padding,
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(style.borderRadius),
      ),
      child: content,
    );

    if (message == null) return box;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? (constraints.maxWidth * 0.32).clamp(80.0, 160.0)
            : 160.0;
        return SizedBox.square(dimension: width, child: box);
      },
    );
  }
}
