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
import 'popup_conflict_policy.dart';
import 'popup_keys.dart';
import 'popup_position.dart';
import 'popup_route_policy.dart';

/// 下拉菜单的布局模式：单层列表或两级嵌套区块。
enum DropMenuMode {
  single,
  nested,
}

/// [DropMenuSection] 是展开为子项，还是作为直接可点击项。
enum DropMenuSectionType {
  nested,
  direct,
}

/// 构建嵌套下拉菜单区块的展开/收起箭头图标。
typedef DropMenuExpandIconBuilder = Widget Function(
  BuildContext context,
  bool expanded,
);

/// 一个可选中的下拉菜单值。
@immutable
final class DropMenuItem<T> {
  /// 创建一个菜单项。
  ///
  /// [label] 与 [labelWidget] 必须提供且只能提供一个。
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
  final bool closeOnSelect;
  final VoidCallback? onTap;
}

/// 两级下拉菜单中的一个一级行。
@immutable
final class DropMenuSection<T> {
  /// 创建一个带嵌套 [items] 的可展开区块。
  ///
  /// [label] 与 [labelWidget] 必须提供且只能提供一个。
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

  /// 创建一个直接选中 [item] 而不展开的区块。
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

/// 单层或两级下拉菜单的不可变数据。
@immutable
final class DropMenu<T> {
  /// 从 [items] 创建单层扁平菜单。
  const DropMenu.single({
    required this.items,
    this.selectedValue,
    this.emptyText = '-',
  })  : mode = DropMenuMode.single,
        sections = const [],
        initialOpenSectionId = null;

  /// 从 [sections] 创建两级嵌套菜单。
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

/// 标准下拉菜单内容的视觉定制。
@immutable
final class DropMenuStyle {
  /// 创建下拉菜单外观默认值（默认液态玻璃面板）。
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

/// [Pop.dropMenu] 入口的完整配置。
final class DropMenuConfig<T> extends MenuConfigBase {
  /// 创建一个下拉菜单配置。
  ///
  /// 默认使用 [PopupKeys.globalDropMenu] 与
  /// [PopupConflictPolicy.replaceExisting]，确保同一时刻只有一个下拉菜单打开。
  DropMenuConfig({
    required this.anchor,
    required this.menu,
    this.menuStyle = const DropMenuStyle(),
    this.placement = MenuPlacement.auto,
    this.offset = Offset.zero,
    this.onSelected,
    this.onOpenSectionChanged,
    this.behavior = const PopupBehaviorConfig(
      key: PopupKeys.globalDropMenu,
      conflictPolicy: PopupConflictPolicy.replaceExisting,
      routePolicy: PopupRoutePolicy.dismissWhenOwnerRouteChanges,
      backPolicy: PopupBackPolicy.dismiss,
    ),
    this.ownership = const PopupOwnership(),
    this.barrier = const PopupBarrierConfig(color: Colors.transparent),
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
