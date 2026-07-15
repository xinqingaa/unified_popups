import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../configs/confirm_config.dart';
import '../configs/custom_popup_config.dart';
import '../configs/date_config.dart';
import '../configs/drop_menu_config.dart';
import '../configs/flow_sheet_config.dart';
import '../configs/loading_config.dart';
import '../configs/menu_config.dart';
import '../configs/popup_barrier_config.dart';
import '../configs/popup_channel.dart';
import '../configs/popup_position.dart';
import '../configs/sheet_config.dart';
import '../configs/sheet_types.dart';
import '../configs/toast_config.dart';
import '../controller/popup_handle.dart';
import '../controller/popup_lifetime.dart';
import '../controller/popup_open_result.dart';
import '../flow_sheets/flow_sheet.dart';
import '../host/popup_host.dart';
import '../navigation/popup_route_token.dart';
import '../renderers/popup_scene.dart';
import '../runtime/popup_runtime.dart';
import '../utils/sheet_dimension.dart';
import '../widgets/popup_anchor.dart';
import 'popup_type_api.dart';

/// Context-free global popup facade backed by one replaceable runtime.
abstract final class Pop {
  static PopupRuntime _runtime = PopupRuntime();

  static PopupRuntime get runtime => _runtime;
  static NavigatorObserver get routeObserver => _runtime.routeObserver;
  static bool get isReady => _runtime.isReady;
  static Future<void> get ready => _runtime.ready;

  static Widget hostBuilder(BuildContext context, Widget? child) {
    return PopupHost(
      runtime: _runtime,
      sceneBuilder: (context, runtime, entries) => PopupScene(
        runtime: runtime,
        entries: entries,
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }

  static PopupRouteToken? captureRoute() => _runtime.captureRoute();

  static PopupTypeApi get _api => PopupTypeApi(_runtime);

  static PopupOpenResult<void> openToast(ToastConfig config) =>
      _api.openToast(config);

  static void toast(
    String? message, {
    Widget? messageWidget,
    PopupPosition position = PopupPosition.center,
    ToastType toastType = ToastType.none,
    Duration? duration,
    Future<void>? until,
    bool showBarrier = false,
    bool barrierDismissible = false,
    Color? barrierColor,
    String? customImagePath,
    double imageSize = 24,
    Color? imgColor,
    Axis layoutDirection = Axis.horizontal,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Decoration? decoration,
    TextStyle? style,
    TextAlign? textAlign,
    VoidCallback? onTap,
  }) {
    _api.openToast(
      ToastConfig(
        message: message,
        content: messageWidget,
        position: position,
        type: toastType,
        icon: customImagePath == null
            ? null
            : ToastIconConfig(
                assetPath: customImagePath,
                size: imageSize,
                color: imgColor,
              ),
        layoutDirection: layoutDirection,
        style: ToastStyle(
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          margin: margin ??
              const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          decoration: decoration,
          textStyle:
              style ?? const TextStyle(color: Colors.white, fontSize: 16),
          textAlign: textAlign ?? TextAlign.start,
        ),
        barrier: showBarrier
            ? PopupBarrierConfig(
                dismissible: barrierDismissible,
                color: barrierColor ?? Colors.black54,
              )
            : const PopupBarrierConfig.hidden(),
        lifetime: switch ((duration, until)) {
          (null, null) => const PopupLifetime.after(
              Duration(milliseconds: 1200),
            ),
          (final duration?, null) => PopupLifetime.after(duration),
          (null, final until?) => PopupLifetime.until(until),
          (final duration?, final until?) =>
            PopupLifetime.anyOf(<PopupLifetime>[
              PopupLifetime.after(duration),
              PopupLifetime.until(until),
            ]),
        },
        onTap: onTap,
      ),
    );
  }

  static LoadingHandle loading({
    String? message,
    Widget? messageWidget,
    Widget? customIndicator,
    Duration? duration,
    Future<void>? until,
  }) {
    final lifetime = _lifetime(duration: duration, until: until);
    return _api.loading(
      LoadingConfig(
        message: message,
        content: messageWidget,
        indicator: LoadingIndicatorConfig(child: customIndicator),
        lifetime: lifetime,
      ),
    );
  }

  static LoadingHandle openLoading(LoadingConfig config) =>
      _api.loading(config);

  static Future<void> hideLoading() => _api.hideLoading();

  static PopupHandle<bool> openConfirm(ConfirmConfig config) =>
      _api.confirm(config);

  static Future<bool?> confirm({
    String? title,
    Widget? titleWidget,
    String? content,
    Widget? contentWidget,
    String confirmText = 'confirm',
    Widget? confirmButtonWidget,
    String? cancelText,
    Widget? cancelButtonWidget,
    bool showCloseButton = true,
    Widget? confirmChild,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    ConfirmButtonLayout buttonLayout = ConfirmButtonLayout.row,
    ConfirmButtonStyle buttonStyle = ConfirmButtonStyle.divider,
    Color? confirmBgColor,
    Color? cancelBgColor,
    ConfirmStyle? style,
  }) {
    final base = style ?? const ConfirmStyle();
    return _api
        .confirm(
          ConfirmConfig(
            title: title,
            titleWidget: titleWidget,
            content: content,
            contentWidget: contentWidget,
            confirmText: confirmText,
            confirmButton: confirmButtonWidget,
            cancelText: cancelText,
            cancelButton: cancelButtonWidget,
            showCloseButton: showCloseButton,
            bodyExtension: confirmChild,
            buttonLayout: buttonLayout,
            onConfirm: onConfirm,
            onCancel: onCancel,
            style: ConfirmStyle(
              buttonStyle: buttonStyle,
              titleStyle: base.titleStyle,
              contentStyle: base.contentStyle,
              confirmStyle: base.confirmStyle,
              cancelStyle: base.cancelStyle,
              padding: base.padding,
              margin: base.margin,
              decoration: base.decoration,
              textAlign: base.textAlign,
              buttonBorderRadius: base.buttonBorderRadius,
              confirmBackgroundColor:
                  confirmBgColor ?? base.confirmBackgroundColor,
              cancelBackgroundColor:
                  cancelBgColor ?? base.cancelBackgroundColor,
              confirmBorder: base.confirmBorder,
              cancelBorder: base.cancelBorder,
              dividerColor: base.dividerColor,
              dividerWidth: base.dividerWidth,
              buttonSpacing: base.buttonSpacing,
            ),
          ),
        )
        .result;
  }

  static PopupHandle<T> openSheet<T>(SheetConfig<T> config) =>
      _api.sheet(config);

  static Future<T?> sheet<T>({
    required Widget Function(void Function([T? result]) dismiss) childBuilder,
    String? title,
    Widget? titleWidget,
    SheetDirection direction = SheetDirection.bottom,
    bool showCloseButton = false,
    bool? useSafeArea,
    SheetDimension? width,
    SheetDimension? height,
    SheetDimension? maxWidth,
    SheetDimension? maxHeight,
    bool showBarrier = true,
    bool barrierDismissible = true,
    Color? barrierColor,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    EdgeInsetsGeometry? padding,
    bool dockToEdge = false,
    double edgeGap = 16,
    bool showDragHandle = true,
    Color? dragHandleColor,
    bool adjustForKeyboard = true,
    SheetDragDismissMode dragDismissMode = SheetDragDismissMode.fullBody,
    ValueListenable<SheetDragDismissMode>? dragDismissModeListenable,
    bool Function()? onBackPressed,
  }) {
    late PopupHandle<T> handle;
    handle = _api.sheet<T>(
      SheetConfig<T>(
        direction: direction,
        header: SheetHeaderConfig(
          title: title,
          titleWidget: titleWidget,
          showCloseButton: showCloseButton,
        ),
        size: SheetSizeConfig(
          width: width,
          height: height,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        style: SheetStyle(
          backgroundColor: backgroundColor,
          borderRadius: borderRadius,
          boxShadow: boxShadow,
          padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 8),
        ),
        dock: SheetDockConfig(enabled: dockToEdge, edgeGap: edgeGap),
        drag: SheetDragConfig(
          mode: dragDismissMode,
          modeListenable: dragDismissModeListenable,
          showHandle: showDragHandle,
          handleColor: dragHandleColor,
        ),
        keyboard: SheetKeyboardConfig(adjustForKeyboard: adjustForKeyboard),
        useSafeArea: useSafeArea,
        barrier: showBarrier
            ? PopupBarrierConfig(
                dismissible: barrierDismissible,
                color: barrierColor ?? Colors.black54,
              )
            : const PopupBarrierConfig.hidden(),
        onBack: onBackPressed == null ? null : () async => onBackPressed(),
        builder: (context, popupHandle) {
          return childBuilder(([result]) => popupHandle.complete(result));
        },
      ),
    );
    return handle.result;
  }

  static PopupHandle<R> openFlowSheet<R>(FlowSheetConfig<R> config) =>
      _api.flowSheet(config);

  static Future<R?> flowSheet<R>({
    required FlowSheetController<R> controller,
    required FlowSheetPage initialPage,
    SheetDirection direction = SheetDirection.bottom,
    SheetDimension? maxHeight,
    SheetDimension? maxWidth,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    bool barrierDismissible = false,
    bool showBarrier = true,
    Color? barrierColor,
    bool showDragHandle = true,
    Color? dragHandleColor,
    bool adjustForKeyboard = true,
    SheetDragDismissMode dragDismissMode = SheetDragDismissMode.fullBody,
    Color? pageBackgroundColor,
    FlowSheetRouteBuilder? routeBuilder,
  }) {
    return _api
        .flowSheet<R>(
          FlowSheetConfig<R>(
            controller: controller,
            initialPage: initialPage,
            direction: direction,
            size: SheetSizeConfig(
              maxHeight: maxHeight,
              maxWidth: maxWidth,
            ),
            style: SheetStyle(
              backgroundColor: backgroundColor,
              padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 8),
            ),
            drag: SheetDragConfig(
              mode: dragDismissMode,
              showHandle: showDragHandle,
              handleColor: dragHandleColor,
            ),
            keyboard: SheetKeyboardConfig(adjustForKeyboard: adjustForKeyboard),
            barrier: showBarrier
                ? PopupBarrierConfig(
                    dismissible: barrierDismissible,
                    color: barrierColor ?? Colors.black54,
                  )
                : const PopupBarrierConfig.hidden(),
            pageBackgroundColor: pageBackgroundColor,
            routeBuilder: routeBuilder,
          ),
        )
        .result;
  }

  static PopupHandle<DateTime> openDate(DateConfig config) => _api.date(config);

  static Future<DateTime?> date({
    DateTime? initialDate,
    DateTime? minDate,
    DateTime? maxDate,
    String title = 'Date of Birth',
    String confirmText = 'Confirm',
    String? cancelText,
    Color? activeColor,
    Color? noActiveColor,
    Color? headerBg,
    double height = 216,
    double radius = 16,
  }) {
    final now = DateUtils.dateOnly(DateTime.now());
    final min = DateUtils.dateOnly(minDate ?? DateTime(1960));
    final max = DateUtils.dateOnly(maxDate ?? now);
    final initial = DateUtils.dateOnly(initialDate ?? now).clampDate(min, max);
    return _api
        .date(
          DateConfig(
            range: DateRangeConfig(
              initialDate: initial,
              minDate: min,
              maxDate: max,
            ),
            labels: DateLabels(
              title: title,
              confirm: confirmText,
              cancel: cancelText,
            ),
            style: DateStyle(
              activeColor: activeColor,
              inactiveColor: noActiveColor,
              headerBackgroundColor: headerBg,
              height: height,
              radius: radius,
            ),
          ),
        )
        .result;
  }

  static PopupHandle<T> openMenu<T>(MenuConfig<T> config) => _api.menu(config);

  static PopupHandle<T> openDropMenu<T>(DropMenuConfig<T> config) =>
      _api.dropMenu(config);

  /// Opens a theme-aware, data-driven one-level or two-level menu.
  static Future<T?> dropMenu<T>({
    required PopupAnchorController anchor,
    required DropMenu<T> menu,
    DropMenuStyle style = const DropMenuStyle(),
    MenuPlacement placement = MenuPlacement.auto,
    Offset offset = Offset.zero,
    ValueChanged<T>? onSelected,
    ValueChanged<String?>? onOpenSectionChanged,
    bool showBarrier = true,
    bool barrierDismissible = true,
    Color barrierColor = Colors.transparent,
  }) {
    return _api
        .dropMenu<T>(
          DropMenuConfig<T>(
            anchor: anchor,
            menu: menu,
            menuStyle: style,
            placement: placement,
            offset: offset,
            onSelected: onSelected,
            onOpenSectionChanged: onOpenSectionChanged,
            barrier: showBarrier
                ? PopupBarrierConfig(
                    dismissible: barrierDismissible,
                    color: barrierColor,
                  )
                : const PopupBarrierConfig.hidden(),
          ),
        )
        .result;
  }

  static Future<T?> menu<T>({
    required PopupAnchorController anchor,
    required Widget Function(void Function([T? result]) dismiss) builder,
    MenuPlacement placement = MenuPlacement.auto,
    Offset offset = Offset.zero,
    EdgeInsetsGeometry? padding,
    BoxConstraints? constraints,
    Decoration? decoration,
    bool showBarrier = true,
    bool barrierDismissible = true,
    Color barrierColor = Colors.transparent,
  }) {
    return _api
        .menu<T>(
          MenuConfig<T>(
            anchor: anchor,
            placement: placement,
            offset: offset,
            barrier: showBarrier
                ? PopupBarrierConfig(
                    dismissible: barrierDismissible,
                    color: barrierColor,
                  )
                : const PopupBarrierConfig.hidden(),
            style: PopupMenuStyle(
              padding: padding ?? EdgeInsets.zero,
              constraints: constraints ??
                  const BoxConstraints(minWidth: 120, maxWidth: 280),
              decoration: decoration,
            ),
            builder: (context, handle) {
              return builder(([result]) => handle.complete(result));
            },
          ),
        )
        .result;
  }

  static PopupHandle<T> custom<T>(CustomPopupConfig<T> config) =>
      _api.custom(config);

  static Future<int> dismissChannel(PopupChannel channel) =>
      _runtime.controller.dismissChannel(channel);
  static Future<int> dismissTags(Set<String> tags) =>
      _runtime.controller.dismissTags(tags);
  static Future<void> dismissAll() => _runtime.controller.dismissAll();
  static Future<bool> dismissTop() => _runtime.controller.dismissTop();
  static Future<bool> handleBack() => _runtime.controller.handleBack();
  static bool isVisibleKey(String key) => _runtime.controller.isVisibleKey(key);
  static bool isActiveKey(String key) => _runtime.controller.isActiveKey(key);
  static bool hasChannel(PopupChannel channel) =>
      _runtime.controller.hasChannel(channel);
  static int countChannel(PopupChannel channel) =>
      _runtime.controller.countChannel(channel);

  static Future<void> shutdown() => _runtime.shutdown();

  static Future<void> resetForTest() async {
    await _runtime.shutdown();
    _runtime = PopupRuntime();
  }

  static PopupLifetime _lifetime({Duration? duration, Future<void>? until}) {
    if (duration != null && until != null) {
      return PopupLifetime.anyOf(<PopupLifetime>[
        PopupLifetime.after(duration),
        PopupLifetime.until(until),
      ]);
    }
    if (duration != null) return PopupLifetime.after(duration);
    if (until != null) return PopupLifetime.until(until);
    return const PopupLifetime.manual();
  }
}

extension on DateTime {
  DateTime clampDate(DateTime min, DateTime max) {
    if (isBefore(min)) return min;
    if (isAfter(max)) return max;
    return this;
  }
}
