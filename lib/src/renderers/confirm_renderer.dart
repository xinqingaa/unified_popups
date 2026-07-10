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

  @override
  Widget build(BuildContext context) {
    final style = config.style;
    final decoration = style.decoration ??
        BoxDecoration(
          color: Theme.of(context).dialogTheme.backgroundColor ??
              Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        );
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: style.margin,
        padding: style.padding,
        decoration: decoration,
        constraints: const BoxConstraints(maxWidth: 480),
        child: Stack(
          children: <Widget>[
            Column(
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
                if (config.titleWidget != null || config.title != null) ...[
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
                const SizedBox(height: 24),
                _buttons(context),
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
    );
    final confirm = _button(
      context,
      child: config.confirmButton ?? Text(config.confirmText),
      confirm: true,
    );
    if (config.buttonLayout == ConfirmButtonLayout.row) {
      return Row(
        children: <Widget>[
          if (hasCancel) Expanded(child: cancel),
          if (hasCancel) const SizedBox(width: 12),
          Expanded(child: confirm),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (hasCancel) cancel,
        if (hasCancel) const SizedBox(height: 12),
        confirm,
      ],
    );
  }

  Widget _button(
    BuildContext context, {
    required Widget child,
    required bool confirm,
  }) {
    final style = config.style;
    final foreground =
        confirm ? style.confirmStyle?.color : style.cancelStyle?.color;
    return Material(
      color: confirm
          ? style.confirmBackgroundColor ??
              Theme.of(context).colorScheme.primary
          : style.cancelBackgroundColor ??
              Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: style.buttonBorderRadius,
        side: _sideFrom(confirm ? style.confirmBorder : style.cancelBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _choose(confirm),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: foreground ??
                (confirm
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  BorderSide _sideFrom(BoxBorder? border) {
    return border is Border ? border.top : BorderSide.none;
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
