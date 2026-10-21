import 'package:flutter/widgets.dart';

/// Exposes the entry/exit progress used by [PopupScene] for the current popup.
///
/// When [fadeContentOnly] is true, consumers should fade interior content
/// themselves so [BackdropFilter] stays outside any opacity save layer.
/// Glass and builder shells (Confirm, Sheet, FlowSheet, Menu, DropMenu) use
/// this path when their animation is a fade.
class PopupEntryAnimation extends InheritedWidget {
  const PopupEntryAnimation({
    required this.animation,
    required this.fadeContentOnly,
    required super.child,
    super.key,
  });

  final Animation<double> animation;

  /// When true, [PopupScene] skipped wrapping this entry in [FadeTransition].
  final bool fadeContentOnly;

  static PopupEntryAnimation? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PopupEntryAnimation>();
  }

  /// Fades [child] when this entry keeps its backdrop shell outside opacity.
  static Widget fadeContent(BuildContext context, Widget child) {
    final entry = maybeOf(context);
    if (entry == null ||
        !entry.fadeContentOnly ||
        MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return FadeTransition(opacity: entry.animation, child: child);
  }

  @override
  bool updateShouldNotify(PopupEntryAnimation oldWidget) {
    return oldWidget.animation != animation ||
        oldWidget.fadeContentOnly != fadeContentOnly;
  }
}
