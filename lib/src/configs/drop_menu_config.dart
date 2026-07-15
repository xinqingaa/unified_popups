import 'package:flutter/material.dart';

import '../controller/popup_handle.dart';
import '../controller/popup_lifecycle_callbacks.dart';
import '../controller/popup_ownership.dart';
import '../widgets/drop_menu/drop_menu_content.dart';
import '../widgets/liquid_glass/liquid_glass_style.dart';
import '../widgets/popup_anchor.dart';
import 'menu_config.dart';
import 'popup_animation_config.dart';
import 'popup_back_policy.dart';
import 'popup_barrier_config.dart';
import 'popup_behavior_config.dart';
import 'popup_channel.dart';
import 'popup_conflict_policy.dart';
import 'popup_keys.dart';
import 'popup_position.dart';
import 'popup_route_policy.dart';

enum DropMenuMode { single, nested }

enum DropMenuSectionType { nested, direct }

typedef DropMenuExpandIconBuilder = Widget Function(
  BuildContext context,
  bool expanded,
);

/// One selectable drop-menu value.
@immutable
final class DropMenuItem<T> {
  const DropMenuItem({
    required this.value,
    this.label,
    this.labelWidget,
    this.leading,
    this.selectedIcon,
    this.selected = false,
    this.disabled = false,
    this.showUnselectedIndicator = false,
    this.closeOnSelect = true,
    this.onTap,
  }) : assert(
          (label == null) != (labelWidget == null),
          'Provide exactly one of label or labelWidget.',
        );

  final T value;
  final String? label;
  final Widget? labelWidget;
  final Widget? leading;
  final Widget? selectedIcon;
  final bool selected;
  final bool disabled;
  final bool showUnselectedIndicator;

  /// For flat/direct items, closes the whole menu. For nested options, closes
  /// only the currently expanded section.
  final bool closeOnSelect;
  final VoidCallback? onTap;
}

/// A primary row in a two-level drop menu.
@immutable
final class DropMenuSection<T> {
  const DropMenuSection({
    required this.id,
    required this.items,
    this.label,
    this.labelWidget,
    this.disabled = false,
    this.initiallyExpanded = false,
    this.showBottomDivider = true,
    this.primaryVerticalPadding,
  })  : type = DropMenuSectionType.nested,
        directItem = null,
        assert(
          (label == null) != (labelWidget == null),
          'Provide exactly one of label or labelWidget.',
        );

  const DropMenuSection.direct({
    required this.id,
    required DropMenuItem<T> item,
    this.disabled = false,
    this.showBottomDivider = true,
    this.primaryVerticalPadding,
  })  : type = DropMenuSectionType.direct,
        directItem = item,
        items = const [],
        label = null,
        labelWidget = null,
        initiallyExpanded = false;

  final String id;
  final DropMenuSectionType type;
  final String? label;
  final Widget? labelWidget;
  final List<DropMenuItem<T>> items;
  final DropMenuItem<T>? directItem;
  final bool disabled;
  final bool initiallyExpanded;
  final bool showBottomDivider;
  final double? primaryVerticalPadding;
}

/// Immutable data for either a flat or a two-level drop menu.
@immutable
final class DropMenu<T> {
  const DropMenu.single({
    required this.items,
    this.selectedValue,
    this.emptyText = '-',
  })  : mode = DropMenuMode.single,
        sections = const [],
        initialOpenSectionId = null;

  const DropMenu.nested({
    required this.sections,
    this.initialOpenSectionId,
    this.emptyText = '-',
  })  : mode = DropMenuMode.nested,
        items = const [],
        selectedValue = null;

  final DropMenuMode mode;
  final List<DropMenuItem<T>> items;
  final List<DropMenuSection<T>> sections;
  final T? selectedValue;
  final String? initialOpenSectionId;
  final String emptyText;
}

/// Visual customization for the standard drop-menu content.
@immutable
final class DropMenuStyle {
  const DropMenuStyle({
    this.constraints = const BoxConstraints(
      minWidth: 140,
      maxWidth: 240,
      maxHeight: 420,
    ),
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.glassStyle = LiquidGlassStyle.standard,
    this.blurSigma,
    this.blurDelay = Duration.zero,
    this.enableShadow = true,
    this.panelMargin = const EdgeInsets.fromLTRB(4, 2, 4, 4),
    this.itemPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
    this.nestedPanelMargin = const EdgeInsets.fromLTRB(8, 0, 8, 8),
    this.nestedPanelPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.nestedPanelRadius = const BorderRadius.all(Radius.circular(14)),
    this.textColor,
    this.secondaryTextColor,
    this.disabledColor,
    this.dividerColor,
    this.selectedColor,
    this.nestedPanelColor,
    this.arrowColor,
    this.textStyle,
    this.secondaryTextStyle,
    this.iconSize = 18,
    this.dividerIndent = 16,
    this.dividerThickness = 0.5,
    this.selectedIconBuilder,
    this.unselectedIconBuilder,
    this.expandIconBuilder,
  })  : assert(iconSize >= 0),
        assert(dividerIndent >= 0),
        assert(dividerThickness >= 0);

  final BoxConstraints constraints;
  final BorderRadius borderRadius;
  final LiquidGlassStyle glassStyle;
  final double? blurSigma;
  final Duration blurDelay;
  final bool enableShadow;
  final EdgeInsetsGeometry panelMargin;
  final EdgeInsetsGeometry itemPadding;
  final EdgeInsetsGeometry nestedPanelMargin;
  final EdgeInsetsGeometry nestedPanelPadding;
  final BorderRadius nestedPanelRadius;
  final Color? textColor;
  final Color? secondaryTextColor;
  final Color? disabledColor;
  final Color? dividerColor;
  final Color? selectedColor;
  final Color? nestedPanelColor;
  final Color? arrowColor;
  final TextStyle? textStyle;
  final TextStyle? secondaryTextStyle;
  final double iconSize;
  final double dividerIndent;
  final double dividerThickness;
  final WidgetBuilder? selectedIconBuilder;
  final WidgetBuilder? unselectedIconBuilder;
  final DropMenuExpandIconBuilder? expandIconBuilder;
}

/// Advanced configuration for the handle-returning drop-menu API.
final class DropMenuConfig<T> extends MenuConfigBase {
  DropMenuConfig({
    required this.anchor,
    required this.menu,
    this.menuStyle = const DropMenuStyle(),
    this.placement = MenuPlacement.auto,
    this.offset = Offset.zero,
    this.onSelected,
    this.onOpenSectionChanged,
    this.behavior = const PopupBehaviorConfig(
      channel: PopupChannel.menu,
      key: PopupKeys.globalDropMenu,
      conflictPolicy: PopupConflictPolicy.replaceExisting,
      routePolicy: PopupRoutePolicy.dismissWhenOwnerRouteChanges,
      backPolicy: PopupBackPolicy.dismiss,
    ),
    this.ownership = const PopupOwnership(),
    this.barrier = const PopupBarrierConfig(color: Colors.transparent),
    // Entry progress still drives content fade; PopupScene skips wrapping the
    // glass/BackdropFilter in FadeTransition so blur stays correct.
    this.animationConfig = const PopupAnimationConfig(
      type: PopupAnimationType.fade,
      duration: Duration(milliseconds: 140),
      reverseDuration: Duration(milliseconds: 100),
    ),
    PopupLifecycleCallbacks<T>? lifecycle,
  }) : lifecycle = lifecycle ?? PopupLifecycleCallbacks<T>();

  @override
  final PopupAnchorController anchor;
  final DropMenu<T> menu;
  final DropMenuStyle menuStyle;
  @override
  final MenuPlacement placement;
  @override
  final Offset offset;

  /// Receives every selection. This is the primary result channel for nested
  /// options because selecting them keeps the outer menu open.
  final ValueChanged<T>? onSelected;
  final ValueChanged<String?>? onOpenSectionChanged;
  final PopupBehaviorConfig behavior;
  final PopupOwnership ownership;
  @override
  final PopupBarrierConfig barrier;
  @override
  final PopupAnimationConfig animationConfig;
  final PopupLifecycleCallbacks<T> lifecycle;

  @override
  PopupPosition get position => PopupPosition.center;

  @override
  PopupMenuStyle get style => PopupMenuStyle(
        constraints: menuStyle.constraints,
        decoration: const BoxDecoration(),
      );

  @override
  Widget buildContent(BuildContext context, PopupHandleBase handle) {
    final typedHandle = handle as PopupHandle<T>;
    return DropMenuContent<T>(
      menu: menu,
      style: menuStyle,
      onOpenSectionChanged: onOpenSectionChanged,
      onItemSelected: (item, closeMenu) {
        item.onTap?.call();
        onSelected?.call(item.value);
        if (closeMenu) typedHandle.complete(item.value);
      },
    );
  }
}
