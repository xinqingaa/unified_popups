import 'package:flutter/widgets.dart';

import '../configs/confirm_config.dart';
import '../configs/date_config.dart';
import '../configs/custom_popup_config.dart';
import '../configs/loading_config.dart';
import '../configs/menu_config.dart';
import '../configs/popup_visual_config.dart';
import '../configs/sheet_config.dart';
import '../configs/toast_config.dart';
import '../controller/popup_entry_snapshot.dart';
import '../controller/popup_dismiss_reason.dart';
import '../runtime/popup_runtime.dart';
import 'confirm_renderer.dart';
import 'date_renderer.dart';
import 'custom_popup_renderer.dart';
import 'loading_renderer.dart';
import 'menu_renderer.dart';
import 'sheet_renderer.dart';
import 'toast_renderer.dart';

/// Interactive access to the same normalized progress used for entry/exit.
abstract interface class PopupMotionController {
  double get value;

  set value(double value);

  Future<void> animateToVisible();

  void dismiss({PopupDismissReason reason});
}

/// Renders one config family without coupling [PopupScene] to every type.
abstract interface class PopupRendererDelegate {
  bool supports(Object config);

  PopupVisualConfig visualConfig(Object config);

  Widget build(
    BuildContext context,
    PopupRuntime runtime,
    PopupEntrySnapshot entry,
    PopupMotionController motion,
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
          SheetPopupRendererDelegate(),
          MenuPopupRendererDelegate(),
          CustomPopupRendererDelegate(),
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
    PopupMotionController motion,
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
    PopupMotionController motion,
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
    PopupMotionController motion,
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
    PopupMotionController motion,
  ) {
    return DateRenderer(
      runtime: runtime,
      entryId: entry.id,
      config: entry.config! as DateConfig,
    );
  }
}

final class SheetPopupRendererDelegate implements PopupRendererDelegate {
  const SheetPopupRendererDelegate();

  @override
  bool supports(Object config) => config is SheetConfigBase;

  @override
  PopupVisualConfig visualConfig(Object config) => config as SheetConfigBase;

  @override
  Widget build(
    BuildContext context,
    PopupRuntime runtime,
    PopupEntrySnapshot entry,
    PopupMotionController motion,
  ) {
    final handle = runtime.controller.handleForEntry(entry.id);
    if (handle == null) return const SizedBox.shrink();
    return SheetRenderer(
      config: entry.config! as SheetConfigBase,
      handle: handle,
      motion: motion,
    );
  }
}

final class MenuPopupRendererDelegate implements PopupRendererDelegate {
  const MenuPopupRendererDelegate();

  @override
  bool supports(Object config) => config is MenuConfigBase;

  @override
  PopupVisualConfig visualConfig(Object config) => config as MenuConfigBase;

  @override
  Widget build(
    BuildContext context,
    PopupRuntime runtime,
    PopupEntrySnapshot entry,
    PopupMotionController motion,
  ) {
    final handle = runtime.controller.handleForEntry(entry.id);
    if (handle == null) return const SizedBox.shrink();
    return MenuRenderer(
      config: entry.config! as MenuConfigBase,
      handle: handle,
      motion: motion,
    );
  }
}

final class CustomPopupRendererDelegate implements PopupRendererDelegate {
  const CustomPopupRendererDelegate();

  @override
  bool supports(Object config) => config is CustomPopupConfigBase;

  @override
  PopupVisualConfig visualConfig(Object config) =>
      config as CustomPopupConfigBase;

  @override
  Widget build(
    BuildContext context,
    PopupRuntime runtime,
    PopupEntrySnapshot entry,
    PopupMotionController motion,
  ) {
    final handle = runtime.controller.handleForEntry(entry.id);
    if (handle == null) return const SizedBox.shrink();
    return CustomPopupRenderer(
      config: entry.config! as CustomPopupConfigBase,
      handle: handle,
    );
  }
}
