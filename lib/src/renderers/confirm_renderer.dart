import 'package:flutter/material.dart';

import '../configs/confirm_config.dart';
import '../controller/popup_dismiss_reason.dart';
import '../runtime/popup_runtime.dart';
import '../widgets/confirm_default_button.dart';

abstract final class ConfirmRendererKeys {
  static const headerImage =
      ValueKey<String>('unified_popups.confirm.header_image');
}

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
          borderRadius: BorderRadius.circular(12),
        );
    final headerImage = _headerImage();
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (headerImage != null) headerImage,
                if (headerImage != null && style.imageGap > 0)
                  SizedBox(height: style.imageGap),
                Padding(
                  padding: style.contentPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _contentChildren(context),
                  ),
                ),
                if (style.contentButtonGap > 0)
                  SizedBox(height: style.contentButtonGap),
                if (config.separator != null) config.separator!,
                Padding(
                  padding: style.buttonPadding,
                  child: _buttons(),
                ),
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

  Widget? _headerImage() {
    final path = config.imagePath;
    if (path == null || path.isEmpty) return null;
    final height = config.imageHeight ?? 80;
    return Image.asset(
      path,
      key: ConfirmRendererKeys.headerImage,
      width: double.infinity,
      height: height,
      fit: config.imageFit,
      alignment: Alignment.topCenter,
      errorBuilder: (context, error, stackTrace) => SizedBox(
        width: double.infinity,
        height: height,
      ),
    );
  }

  List<Widget> _contentChildren(BuildContext context) {
    final style = config.style;
    final children = <Widget>[];
    final hasTitle = config.titleWidget != null || config.title != null;
    if (hasTitle) {
      children.add(
        config.titleWidget ??
            Text(
              config.title!,
              style: style.titleStyle ?? Theme.of(context).textTheme.titleLarge,
              textAlign: style.textAlign,
            ),
      );
      if (style.titleGap > 0) {
        children.add(SizedBox(height: style.titleGap));
      }
    }
    children.add(
      config.contentWidget ??
          Text(
            config.content!,
            style: style.contentStyle,
            textAlign: style.textAlign,
          ),
    );
    if (config.bodyExtension != null) {
      if (style.bodyExtensionGap > 0) {
        children.add(SizedBox(height: style.bodyExtensionGap));
      }
      children.add(config.bodyExtension!);
    }
    return children;
  }

  Widget _buttons() {
    final cancelBuilder = config.cancelButton ??
        (config.cancelText == null
            ? null
            : ConfirmDefaultButton.outline(config.cancelText!));
    final confirmBuilder =
        config.confirmButton ?? ConfirmDefaultButton.filled(config.confirmText);
    final hasCancel = cancelBuilder != null;
    final cancel = hasCancel ? cancelBuilder(() => _choose(false)) : null;
    final confirm = confirmBuilder(() => _choose(true));
    final between = _buttonBetween(hasCancel);
    if (config.buttonLayout == ConfirmButtonLayout.row) {
      return Row(
        children: <Widget>[
          if (hasCancel) Expanded(child: cancel!),
          if (between != null) between,
          Expanded(child: confirm),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        confirm,
        if (between != null) between,
        if (hasCancel) cancel!,
      ],
    );
  }

  Widget? _buttonBetween(bool hasCancel) {
    if (!hasCancel) return null;
    if (config.buttonSeparator != null) return config.buttonSeparator;
    final spacing = config.style.buttonSpacing;
    if (spacing <= 0) return null;
    final isRow = config.buttonLayout == ConfirmButtonLayout.row;
    return isRow ? SizedBox(width: spacing) : SizedBox(height: spacing);
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
