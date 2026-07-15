import 'package:flutter/material.dart';

import '../configs/confirm_config.dart';
import '../configs/custom_popup_config.dart';
import '../configs/date_config.dart';
import '../configs/drop_menu_config.dart';
import '../configs/flow_sheet_config.dart';
import '../configs/loading_config.dart';
import '../configs/menu_config.dart';
import '../configs/popup_channel.dart';
import '../configs/sheet_config.dart';
import '../configs/toast_config.dart';
import '../controller/popup_open_result.dart';
import '../host/popup_host.dart';
import '../navigation/popup_route_token.dart';
import '../renderers/popup_scene.dart';
import '../runtime/popup_runtime.dart';
import 'popup_type_api.dart';

/// Context-free global popup facade backed by one replaceable runtime.
///
/// Every popup capability has exactly one Config-first entrypoint. The
/// returned [PopupOpenResult] may be ignored for fire-and-forget calls, awaited
/// through `result`, or used to obtain a handle for imperative control.
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

  static PopupOpenResult<void> toast(ToastConfig config) => _api.toast(config);

  static PopupOpenResult<void> loading(LoadingConfig config) =>
      _api.loading(config);

  static Future<void> hideLoading() => _api.hideLoading();

  static PopupOpenResult<bool> confirm(ConfirmConfig config) =>
      _api.confirm(config);

  static PopupOpenResult<DateTime> date(DateConfig config) => _api.date(config);

  static PopupOpenResult<T> sheet<T>(SheetConfig<T> config) =>
      _api.sheet(config);

  static PopupOpenResult<R> flowSheet<R>(FlowSheetConfig<R> config) =>
      _api.flowSheet(config);

  static PopupOpenResult<T> menu<T>(MenuConfig<T> config) => _api.menu(config);

  static PopupOpenResult<T> dropMenu<T>(DropMenuConfig<T> config) =>
      _api.dropMenu(config);

  static PopupOpenResult<T> custom<T>(CustomPopupConfig<T> config) =>
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
}
