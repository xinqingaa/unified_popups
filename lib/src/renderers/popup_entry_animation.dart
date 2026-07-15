import 'package:flutter/widgets.dart';

/// Exposes the entry/exit progress used by [PopupScene] for the current popup.
///
/// When [fadeContentOnly] is true (DropMenu default fade), consumers should
/// fade interior content themselves so [BackdropFilter] stays outside any
/// opacity save layer.
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

  @override
  bool updateShouldNotify(PopupEntryAnimation oldWidget) {
    return oldWidget.animation != animation ||
        oldWidget.fadeContentOnly != fadeContentOnly;
  }
}
