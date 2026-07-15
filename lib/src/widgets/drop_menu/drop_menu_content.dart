import 'package:flutter/material.dart';

import '../../configs/drop_menu_config.dart';
import '../../renderers/popup_entry_animation.dart';
import '../liquid_glass/liquid_glass.dart';
import '../liquid_glass/liquid_glass_style.dart';

class DropMenuContent<T> extends StatefulWidget {
  const DropMenuContent({
    required this.menu,
    required this.style,
    required this.onItemSelected,
    this.onOpenSectionChanged,
    super.key,
  });

  final DropMenu<T> menu;
  final DropMenuStyle style;
  final void Function(DropMenuItem<T> item, bool closeMenu) onItemSelected;
  final ValueChanged<String?>? onOpenSectionChanged;

  @override
  State<DropMenuContent<T>> createState() => _DropMenuContentState<T>();
}

class _DropMenuContentState<T> extends State<DropMenuContent<T>> {
  String? _openSectionId;
  final Map<DropMenuItem<T>, bool> _selectionOverrides =
      <DropMenuItem<T>, bool>{};

  @override
  void initState() {
    super.initState();
    _openSectionId = widget.menu.initialOpenSectionId ??
        _initiallyExpandedSectionId(widget.menu.sections);
  }

  String? _initiallyExpandedSectionId(List<DropMenuSection<T>> sections) {
    for (final section in sections) {
      if (section.initiallyExpanded &&
          section.type == DropMenuSectionType.nested) {
        return section.id;
      }
    }
    return null;
  }

  void _toggleSection(DropMenuSection<T> section) {
    if (section.disabled) return;
    if (section.type == DropMenuSectionType.direct) {
      _selectFlatOrDirect(section.directItem!);
      return;
    }
    setState(() {
      _openSectionId = _openSectionId == section.id ? null : section.id;
    });
    widget.onOpenSectionChanged?.call(_openSectionId);
  }

  void _selectFlatOrDirect(DropMenuItem<T> item) {
    if (item.disabled) return;
    if (!item.closeOnSelect) {
      setState(() {
        _selectionOverrides[item] = !_isSelected(item);
      });
    }
    widget.onItemSelected(item, item.closeOnSelect);
  }

  void _selectNested(
    DropMenuSection<T> section,
    DropMenuItem<T> item,
  ) {
    if (item.disabled) return;
    setState(() {
      for (final option in section.items) {
        _selectionOverrides[option] = identical(option, item);
      }
      if (item.closeOnSelect) _openSectionId = null;
    });
    widget.onItemSelected(item, false);
    if (item.closeOnSelect) widget.onOpenSectionChanged?.call(null);
  }

  bool _isSelected(DropMenuItem<T> item) {
    final override = _selectionOverrides[item];
    if (override != null) return override;
    return item.selected ||
        (widget.menu.mode == DropMenuMode.single &&
            widget.menu.selectedValue == item.value);
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    // Fade only labels/icons inside the glass. BackdropFilter must stay outside
    // any OpacityLayer or blur samples the wrong buffer until opacity hits 1.
    Widget body = Padding(
      padding: style.panelMargin,
      child: ClipRRect(
        borderRadius: style.nestedPanelRadius,
        child: SingleChildScrollView(
          child: widget.menu.mode == DropMenuMode.single
              ? _buildSingleMenu(context)
              : _buildNestedMenu(context),
        ),
      ),
    );
    final entryAnimation = PopupEntryAnimation.maybeOf(context);
    if (entryAnimation != null &&
        entryAnimation.fadeContentOnly &&
        !MediaQuery.disableAnimationsOf(context)) {
      body = FadeTransition(opacity: entryAnimation.animation, child: body);
    }
    return LiquidGlass(
      borderRadius: style.borderRadius,
      style: style.glassStyle,
      blurSigma: style.blurSigma,
      blurDelay: style.blurDelay,
      backdropBlendMode: BlendMode.src,
      enableShadow: style.enableShadow,
      child: body,
    );
  }

  Widget _buildSingleMenu(BuildContext context) {
    final items = widget.menu.items;
    if (items.isEmpty) return _EmptyRow(text: widget.menu.emptyText);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var index = 0; index < items.length; index++)
          _OptionRow<T>(
            item: items[index],
            selected: _isSelected(items[index]),
            style: widget.style,
            showDivider: index < items.length - 1,
            onTap: () => _selectFlatOrDirect(items[index]),
          ),
      ],
    );
  }

  Widget _buildNestedMenu(BuildContext context) {
    final sections = widget.menu.sections;
    if (sections.isEmpty) return _EmptyRow(text: widget.menu.emptyText);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var index = 0; index < sections.length; index++)
          _Section<T>(
            section: sections[index],
            expanded: _openSectionId == sections[index].id,
            isLast: index == sections.length - 1,
            emptyText: widget.menu.emptyText,
            style: widget.style,
            isSelected: _isSelected,
            onTap: () => _toggleSection(sections[index]),
            onItemTap: (item) => _selectNested(sections[index], item),
          ),
      ],
    );
  }
}

class _Section<T> extends StatelessWidget {
  const _Section({
    required this.section,
    required this.expanded,
    required this.isLast,
    required this.emptyText,
    required this.style,
    required this.isSelected,
    required this.onTap,
    required this.onItemTap,
  });

  final DropMenuSection<T> section;
  final bool expanded;
  final bool isLast;
  final String emptyText;
  final DropMenuStyle style;
  final bool Function(DropMenuItem<T>) isSelected;
  final VoidCallback onTap;
  final ValueChanged<DropMenuItem<T>> onItemTap;

  @override
  Widget build(BuildContext context) {
    final direct = section.type == DropMenuSectionType.direct;
    final colors = _ResolvedDropMenuColors.of(context, style);
    final primaryColor = section.disabled ? colors.disabled : colors.text;
    final showDivider =
        section.showBottomDivider && !isLast && !(expanded && !direct);
    return Opacity(
      opacity: section.disabled ? 0.38 : 1,
      child: IgnorePointer(
        ignoring: section.disabled,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _Pressable(
              color: style.glassStyle.resolve(context).pressHighlightColor,
              borderRadius: style.nestedPanelRadius,
              onTap: onTap,
              child: Stack(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: section.primaryVerticalPadding ?? 14,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: section.directItem?.labelWidget ??
                              section.labelWidget ??
                              Text(
                                section.directItem?.label ?? section.label!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: (style.textStyle ??
                                        Theme.of(context).textTheme.bodyMedium)
                                    ?.copyWith(color: primaryColor),
                              ),
                        ),
                        const SizedBox(width: 8),
                        if (direct)
                          _SelectionIndicator(
                            item: section.directItem!,
                            selected: isSelected(section.directItem!),
                            style: style,
                          )
                        else
                          _ExpandIndicator(expanded: expanded, style: style),
                      ],
                    ),
                  ),
                  if (showDivider)
                    Positioned(
                      left: style.dividerIndent,
                      right: style.dividerIndent,
                      bottom: 0,
                      child: ColoredBox(
                        color: colors.divider,
                        child: SizedBox(height: style.dividerThickness),
                      ),
                    ),
                ],
              ),
            ),
            if (!direct)
              _AnimatedSubmenu(
                expanded: expanded,
                sectionId: section.id,
                child: Padding(
                  padding: style.nestedPanelMargin,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.nestedPanel,
                      borderRadius: style.nestedPanelRadius,
                    ),
                    child: Padding(
                      padding: style.nestedPanelPadding,
                      child: section.items.isEmpty
                          ? _EmptyRow(text: emptyText)
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                for (var index = 0;
                                    index < section.items.length;
                                    index++)
                                  _OptionRow<T>(
                                    item: section.items[index],
                                    selected: isSelected(section.items[index]),
                                    style: style,
                                    showDivider:
                                        index < section.items.length - 1,
                                    onTap: () =>
                                        onItemTap(section.items[index]),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedSubmenu extends StatelessWidget {
  const _AnimatedSubmenu({
    required this.expanded,
    required this.sectionId,
    required this.child,
  });

  final bool expanded;
  final String sectionId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 160),
      reverseDuration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 160),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      child: expanded
          ? KeyedSubtree(
              key: ValueKey<String>('drop_menu_submenu_$sectionId'),
              child: child,
            )
          : SizedBox.shrink(
              key: ValueKey<String>('drop_menu_submenu_closed_$sectionId'),
            ),
    );
  }
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.item,
    required this.selected,
    required this.style,
    required this.showDivider,
    required this.onTap,
  });

  final DropMenuItem<T> item;
  final bool selected;
  final DropMenuStyle style;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _ResolvedDropMenuColors.of(context, style);
    final textColor = item.disabled
        ? colors.disabled
        : selected
            ? colors.selected
            : colors.secondaryText;
    final baseTextStyle = selected
        ? style.textStyle ?? Theme.of(context).textTheme.bodyMedium
        : style.secondaryTextStyle ?? Theme.of(context).textTheme.bodyMedium;
    return Opacity(
      opacity: item.disabled ? 0.38 : 1,
      child: IgnorePointer(
        ignoring: item.disabled,
        child: _Pressable(
          color: style.glassStyle.resolve(context).pressHighlightColor,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: showDivider
                  ? Border(
                      bottom: BorderSide(
                        color: colors.divider,
                        width: style.dividerThickness,
                      ),
                    )
                  : null,
            ),
            child: Padding(
              padding: style.itemPadding,
              child: Row(
                children: <Widget>[
                  if (item.leading != null) ...<Widget>[
                    item.leading!,
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: item.labelWidget ??
                        Text(
                          item.label!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: baseTextStyle?.copyWith(color: textColor),
                        ),
                  ),
                  const SizedBox(width: 8),
                  _SelectionIndicator<T>(
                    item: item,
                    selected: selected,
                    style: style,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator<T> extends StatelessWidget {
  const _SelectionIndicator({
    required this.item,
    required this.selected,
    required this.style,
  });

  final DropMenuItem<T> item;
  final bool selected;
  final DropMenuStyle style;

  @override
  Widget build(BuildContext context) {
    final colors = _ResolvedDropMenuColors.of(context, style);
    if (selected) {
      return SizedBox.square(
        dimension: style.iconSize,
        child: item.selectedIcon ??
            style.selectedIconBuilder?.call(context) ??
            Icon(
              Icons.check_rounded,
              size: style.iconSize,
              color: colors.selected,
            ),
      );
    }
    if (!item.showUnselectedIndicator) {
      return SizedBox.square(dimension: style.iconSize);
    }
    return SizedBox.square(
      dimension: style.iconSize,
      child: style.unselectedIconBuilder?.call(context) ??
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.secondaryText),
            ),
          ),
    );
  }
}

class _ExpandIndicator extends StatelessWidget {
  const _ExpandIndicator({required this.expanded, required this.style});

  final bool expanded;
  final DropMenuStyle style;

  @override
  Widget build(BuildContext context) {
    final custom = style.expandIconBuilder;
    if (custom != null) return custom(context, expanded);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final colors = _ResolvedDropMenuColors.of(context, style);
    return AnimatedRotation(
      turns: expanded ? 0.5 : 0,
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
      child: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: style.iconSize,
        color: colors.arrow,
      ),
    );
  }
}

class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    required this.color,
    required this.borderRadius,
    required this.onTap,
  });

  final Widget child;
  final Color color;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _pressed ? widget.color : Colors.transparent,
          borderRadius: widget.borderRadius,
        ),
        child: widget.child,
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

final class _ResolvedDropMenuColors {
  const _ResolvedDropMenuColors({
    required this.text,
    required this.secondaryText,
    required this.disabled,
    required this.divider,
    required this.selected,
    required this.nestedPanel,
    required this.arrow,
  });

  factory _ResolvedDropMenuColors.of(
    BuildContext context,
    DropMenuStyle style,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return _ResolvedDropMenuColors(
      text: style.textColor ?? colors.onSurface,
      secondaryText: style.secondaryTextColor ?? colors.onSurfaceVariant,
      disabled: style.disabledColor ?? colors.onSurface.withAlpha(0x61),
      divider: style.dividerColor ?? colors.outlineVariant.withAlpha(0x80),
      selected: style.selectedColor ?? colors.primary,
      nestedPanel:
          style.nestedPanelColor ?? colors.shadow.withAlpha(dark ? 0x38 : 0x12),
      arrow: style.arrowColor ?? colors.onSurfaceVariant,
    );
  }

  final Color text;
  final Color secondaryText;
  final Color disabled;
  final Color divider;
  final Color selected;
  final Color nestedPanel;
  final Color arrow;
}
