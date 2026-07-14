import 'package:flutter/material.dart';

import '../configs/confirm_config.dart';
import '../controller/popup_dismiss_reason.dart';
import '../runtime/popup_runtime.dart';

class ConfirmRenderer extends StatelessWidget {
  const ConfirmRenderer({
    required this.runtime,
    required this.entryId,
    required this.config,
    super.key,
  });

  final PopupRuntime runtime;
  final String entryId;
  final ConfirmConfig config;

  bool get _isDivider => config.style.buttonStyle == ConfirmButtonStyle.divider;

  @override
  Widget build(BuildContext context) {
    final style = config.style;
    final decoration = style.decoration ??
        BoxDecoration(
          color: Theme.of(context).dialogTheme.backgroundColor ??
              Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        );
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: style.margin,
        decoration: decoration,
        clipBehavior: Clip.antiAlias,
        constraints: const BoxConstraints(maxWidth: 480),
        child: Stack(
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: style.padding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (config.imagePath != null) ...<Widget>[
                        Image.asset(
                          config.imagePath!,
                          width: config.imageWidth,
                          height: config.imageHeight,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (config.titleWidget != null ||
                          config.title != null) ...[
                        config.titleWidget ??
                            Text(
                              config.title!,
                              style: style.titleStyle ??
                                  Theme.of(context).textTheme.titleLarge,
                              textAlign: style.textAlign,
                            ),
                        const SizedBox(height: 12),
                      ],
                      config.contentWidget ??
                          Text(
                            config.content!,
                            style: style.contentStyle,
                            textAlign: style.textAlign,
                          ),
                      if (config.bodyExtension != null) ...<Widget>[
                        const SizedBox(height: 16),
                        config.bodyExtension!,
                      ],
                      if (!_isDivider) const SizedBox(height: 24),
                      if (!_isDivider) _buttons(context),
                    ],
                  ),
                ),
                if (_isDivider) _buttons(context),
              ],
            ),
            if (config.showCloseButton)
              PositionedDirectional(
                top: 0,
                end: 0,
                child: Semantics(
                  label: MaterialLocalizations.of(context).closeButtonTooltip,
                  button: true,
                  child: IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => runtime.controller.dismissEntry(
                      entryId,
                      reason: PopupDismissReason.manual,
                    ),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buttons(BuildContext context) {
    final hasCancel = config.cancelText != null || config.cancelButton != null;
    final cancel = _button(
      context,
      child: config.cancelButton ?? Text(config.cancelText ?? ''),
      confirm: false,
      hasCancel: hasCancel,
    );
    final confirm = _button(
      context,
      child: config.confirmButton ?? Text(config.confirmText),
      confirm: true,
      hasCancel: hasCancel,
    );
    final spacing = config.style.buttonSpacing;
    if (config.buttonLayout == ConfirmButtonLayout.row) {
      return Row(
        children: <Widget>[
          if (hasCancel) Expanded(child: cancel),
          if (hasCancel && !_isDivider) SizedBox(width: spacing),
          Expanded(child: confirm),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (hasCancel) cancel,
        if (hasCancel && !_isDivider) SizedBox(height: spacing),
        confirm,
      ],
    );
  }

  Widget _button(
    BuildContext context, {
    required Widget child,
    required bool confirm,
    required bool hasCancel,
  }) {
    final style = config.style;
    final scheme = Theme.of(context).colorScheme;
    final Color background;
    if (_isDivider) {
      background = confirm
          ? style.confirmBackgroundColor ?? Colors.transparent
          : style.cancelBackgroundColor ?? Colors.transparent;
    } else {
      background = confirm
          ? style.confirmBackgroundColor ?? scheme.primary
          : style.cancelBackgroundColor ?? scheme.surfaceContainerHighest;
    }

    final BoxBorder? border;
    if (style.confirmBorder != null && confirm) {
      border = style.confirmBorder;
    } else if (style.cancelBorder != null && !confirm) {
      border = style.cancelBorder;
    } else if (_isDivider) {
      border = _dividerBorder(
        context,
        confirm: confirm,
        hasCancel: hasCancel,
      );
    } else {
      border = null;
    }

    final borderRadius =
        _isDivider ? BorderRadius.zero : style.buttonBorderRadius;
    final defaultFg = _isDivider
        ? (confirm ? scheme.onSurface : scheme.onSurfaceVariant)
        : (confirm ? scheme.onPrimary : scheme.onSurface);

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          color: background,
          border: border,
          borderRadius: borderRadius,
        ),
        child: InkWell(
          onTap: () => _choose(confirm),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: defaultFg,
              fontWeight: confirm && _isDivider ? FontWeight.w600 : null,
            ).merge(confirm ? style.confirmStyle : style.cancelStyle),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }

  BoxBorder _dividerBorder(
    BuildContext context, {
    required bool confirm,
    required bool hasCancel,
  }) {
    final style = config.style;
    final color = style.dividerColor ?? Theme.of(context).dividerColor;
    final width = style.dividerWidth;
    final top = BorderSide(color: color, width: width);
    final isRow = config.buttonLayout == ConfirmButtonLayout.row;
    if (isRow && hasCancel && !confirm) {
      return Border(
        top: top,
        right: BorderSide(color: color, width: width),
      );
    }
    return Border(top: top);
  }

  void _choose(bool confirm) {
    runtime.controller.completeEntry<bool>(entryId, confirm);
    final callback = confirm ? config.onConfirm : config.onCancel;
    if (callback == null) return;
    try {
      callback();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'unified_popups',
          context: ErrorDescription(
            confirm ? 'while confirming a popup' : 'while cancelling a popup',
          ),
        ),
      );
    }
  }
}
