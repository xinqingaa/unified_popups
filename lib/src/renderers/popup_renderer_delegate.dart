import 'package:flutter/widgets.dart';

import '../configs/confirm_config.dart';
import '../configs/date_config.dart';
import '../configs/loading_config.dart';
import '../configs/popup_visual_config.dart';
import '../configs/toast_config.dart';
import '../controller/popup_entry_snapshot.dart';
import '../runtime/popup_runtime.dart';
import 'confirm_renderer.dart';
import 'date_renderer.dart';
import 'loading_renderer.dart';
import 'toast_renderer.dart';

/// Renders one config family without coupling [PopupScene] to every type.
abstract interface class PopupRendererDelegate {
  bool supports(Object config);

  PopupVisualConfig visualConfig(Object config);

  Widget build(
    BuildContext context,
    PopupRuntime runtime,
    PopupEntrySnapshot entry,
  );
}

/// Immutable ordered renderer lookup used by one host.
final class PopupRendererRegistry {
  PopupRendererRegistry(Iterable<PopupRendererDelegate> delegates)
      : delegates = List<PopupRendererDelegate>.unmodifiable(delegates);

  factory PopupRendererRegistry.builtIn() => PopupRendererRegistry(
        const <PopupRendererDelegate>[
          ToastPopupRendererDelegate(),
          LoadingPopupRendererDelegate(),
          ConfirmPopupRendererDelegate(),
          DatePopupRendererDelegate(),
        ],
      );

  final List<PopupRendererDelegate> delegates;

  PopupRendererDelegate? resolve(Object config) {
    for (final delegate in delegates) {
      if (delegate.supports(config)) return delegate;
    }
    return null;
  }

  PopupRendererRegistry extending(Iterable<PopupRendererDelegate> additions) {
    return PopupRendererRegistry(<PopupRendererDelegate>[
      ...additions,
      ...delegates,
    ]);
  }
}

final class ToastPopupRendererDelegate implements PopupRendererDelegate {
  const ToastPopupRendererDelegate();

  @override
  bool supports(Object config) => config is ToastConfig;

  @override
  PopupVisualConfig visualConfig(Object config) => config as ToastConfig;

  @override
  Widget build(
    BuildContext context,
    PopupRuntime runtime,
    PopupEntrySnapshot entry,
  ) {
    return ToastRenderer(config: entry.config! as ToastConfig);
  }
}

final class LoadingPopupRendererDelegate implements PopupRendererDelegate {
  const LoadingPopupRendererDelegate();

  @override
  bool supports(Object config) => config is LoadingConfig;

  @override
  PopupVisualConfig visualConfig(Object config) => config as LoadingConfig;

  @override
  Widget build(
    BuildContext context,
    PopupRuntime runtime,
    PopupEntrySnapshot entry,
  ) {
    return LoadingRenderer(config: entry.config! as LoadingConfig);
  }
}

final class ConfirmPopupRendererDelegate implements PopupRendererDelegate {
  const ConfirmPopupRendererDelegate();

  @override
  bool supports(Object config) => config is ConfirmConfig;

  @override
  PopupVisualConfig visualConfig(Object config) => config as ConfirmConfig;

  @override
  Widget build(
    BuildContext context,
    PopupRuntime runtime,
    PopupEntrySnapshot entry,
  ) {
    return ConfirmRenderer(
      runtime: runtime,
      entryId: entry.id,
      config: entry.config! as ConfirmConfig,
    );
  }
}

final class DatePopupRendererDelegate implements PopupRendererDelegate {
  const DatePopupRendererDelegate();

  @override
  bool supports(Object config) => config is DateConfig;

  @override
  PopupVisualConfig visualConfig(Object config) => config as DateConfig;

  @override
  Widget build(
    BuildContext context,
    PopupRuntime runtime,
    PopupEntrySnapshot entry,
  ) {
    return DateRenderer(
      runtime: runtime,
      entryId: entry.id,
      config: entry.config! as DateConfig,
    );
  }
}
