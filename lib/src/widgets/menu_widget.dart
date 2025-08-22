import 'package:flutter/material.dart';

class MenuWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Decoration? decoration;
  final BoxConstraints? constraints;

  const MenuWidget({
    super.key,
    required this.child,
    this.padding,
    this.decoration,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final defaultDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    );

    return ConstrainedBox(
      constraints: constraints ??
          const BoxConstraints(
            minWidth: 120,
            maxWidth: 280,
          ),
      child: Container(
        decoration: decoration ?? defaultDecoration,
        padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
        child: child,
      ),
    );
  }
}