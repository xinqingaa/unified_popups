import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

/// FitPulse's app-level popup facade.
///
/// Product code uses business-shaped methods and shared defaults. The API Lab
/// intentionally calls [Pop] directly to demonstrate the package contract.
abstract final class AppPop {
  static const _routeBehavior = PopupBehaviorConfig(
    routePolicy: PopupRoutePolicy.dismissWhenOwnerRouteChanges,
    backPolicy: PopupBackPolicy.dismiss,
  );

  static void info(String message) => _toast(message, ToastType.none);

  static void success(String message) => _toast(message, ToastType.success);

  static void warning(String message) => _toast(message, ToastType.warn);

  static void error(String message) => _toast(
        message,
        ToastType.error,
        position: PopupPosition.top,
      );

  static void _toast(
    String message,
    ToastType type, {
    PopupPosition position = PopupPosition.bottom,
  }) {
    Pop.toast(
      ToastConfig.text(
        message,
        type: type,
        position: position,
        lifetime: const PopupLifetime.after(Duration(milliseconds: 1800)),
      ),
    );
  }

  static AppLoading showLoading(
    String message, {
    Future<void>? until,
    Set<String> tags = const <String>{'fitpulse.loading'},
  }) {
    final config = _loadingConfig(message, until: until, tags: tags);
    final handle = Pop.loading(config).requireHandle()
        as UpdatablePopupHandle<void, LoadingConfig>;
    return AppLoading._(handle, tags);
  }

  static Future<T> runLoading<T>({
    required String message,
    required Future<T> task,
    Set<String> tags = const <String>{'fitpulse.loading'},
  }) async {
    final settled = task.then<void>((_) {});
    showLoading(message, until: settled, tags: tags);
    return task;
  }

  static LoadingConfig _loadingConfig(
    String message, {
    Future<void>? until,
    required Set<String> tags,
  }) {
    return LoadingConfig.text(
      message,
      behavior: PopupBehaviorConfig(
        key: PopupKeys.globalLoading,
        tags: tags,
        conflictPolicy: PopupConflictPolicy.updateExisting,
        backPolicy: PopupBackPolicy.block,
      ),
      lifetime: until == null
          ? const PopupLifetime.manual()
          : PopupLifetime.until(until),
    );
  }

  static Future<bool> confirm({
    String? title,
    required String content,
    Widget? bodyExtension,
    String confirmText = '确定',
    String cancelText = '取消',
    bool destructive = false,
  }) async {
    final value = await Pop.confirm(
      ConfirmConfig(
        title: title,
        content: content,
        bodyExtension: bodyExtension,
        confirmAction: ConfirmAction.text(confirmText),
        cancelAction: ConfirmAction.text(cancelText),
        style: ConfirmStyle(
          confirmStyle: destructive ? const TextStyle(color: Colors.red) : null,
        ),
      ),
    ).result;
    return value == true;
  }

  static Future<DateTime?> date({
    DateTime? initialDate,
    DateTime? minDate,
    DateTime? maxDate,
    String title = '选择日期',
  }) {
    return Pop.date(
      DateConfig(
        initialDate: initialDate,
        minDate: minDate,
        maxDate: maxDate,
        labels: DateLabels(title: title, confirm: '确定', cancel: '取消'),
      ),
    ).result;
  }

  static Future<T?> sheet<T>({
    required String title,
    required SheetContentBuilder<T> builder,
    SheetDirection direction = SheetDirection.bottom,
    SheetSizeConfig size = const SheetSizeConfig(
      maxHeight: SheetDimension.fraction(0.72),
    ),
    SheetDragConfig drag = const SheetDragConfig(),
    SheetDockConfig dock = const SheetDockConfig(),
    SheetKeyboardConfig keyboard = const SheetKeyboardConfig(),
  }) {
    return Pop.sheet<T>(
      SheetConfig<T>(
        header: SheetHeaderConfig(title: title, showCloseButton: true),
        direction: direction,
        size: size,
        drag: drag,
        dock: dock,
        keyboard: keyboard,
        behavior: _routeBehavior,
        builder: builder,
      ),
    ).result;
  }

  static Future<R?> flowSheet<R>({
    required FlowSheetController<R> controller,
    required FlowSheetPage initialPage,
    SheetSizeConfig size = const SheetSizeConfig(
      maxHeight: SheetDimension.fraction(0.9),
    ),
    SheetDragConfig drag = const SheetDragConfig(
      mode: SheetDragDismissMode.handleOnly,
    ),
  }) {
    return Pop.flowSheet<R>(
      FlowSheetConfig<R>(
        controller: controller,
        initialPage: initialPage,
        size: size,
        drag: drag,
        barrier: const PopupBarrierConfig(dismissible: true),
      ),
    ).result;
  }

  static Future<T?> menu<T>({
    required PopupAnchorController anchor,
    required Widget Function(BuildContext, PopupHandle<T>) builder,
  }) {
    return Pop.menu<T>(
      MenuConfig<T>(
        anchor: anchor,
        behavior: _routeBehavior,
        builder: builder,
      ),
    ).result;
  }

  static Future<T?> dropMenu<T>({
    required PopupAnchorController anchor,
    required DropMenu<T> menu,
    ValueChanged<T>? onSelected,
  }) {
    return Pop.dropMenu<T>(
      DropMenuConfig<T>(
        anchor: anchor,
        menu: menu,
        onSelected: onSelected,
      ),
    ).result;
  }

  static Future<T?> custom<T>({
    required Widget Function(BuildContext, PopupHandle<T>) builder,
    PopupPosition position = PopupPosition.center,
  }) {
    return Pop.custom<T>(
      CustomPopupConfig<T>(
        position: position,
        behavior: _routeBehavior,
        builder: builder,
      ),
    ).result;
  }
}

/// App-level loading control. It exposes business operations rather than the
/// package's config-shaped update contract.
final class AppLoading {
  AppLoading._(this._handle, this._tags);

  final UpdatablePopupHandle<void, LoadingConfig> _handle;
  final Set<String> _tags;

  bool get isActive => _handle.isActive;

  Future<PopupOutcome<void>> get outcome => _handle.outcome;

  bool update(String message, {Future<void>? until}) {
    return _handle.update(
      AppPop._loadingConfig(message, until: until, tags: _tags),
    );
  }

  Future<void> dismiss() => _handle.dismiss();
}
