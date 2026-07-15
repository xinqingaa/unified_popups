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

/// 全局弹窗门面：不依赖 [BuildContext]，每种能力只有一个 Config 入口。
///
/// 返回的 [PopupOpenResult] 可忽略（fire-and-forget）、通过 `.result` 等待业务值，
/// 或用 `requireHandle()` / `handleOrNull` 做命令式控制。
abstract final class Pop {
  static PopupRuntime _runtime = PopupRuntime();

  /// 根 Navigator 路由观察者；需挂到 [MaterialApp.navigatorObservers]。
  static NavigatorObserver get routeObserver => _runtime.routeObserver;

  /// Host 是否已挂载可用。
  static bool get isReady => _runtime.isReady;

  /// 首个 Host 挂载后完成；挂载前打开的弹窗会进入 pending。
  static Future<void> get ready => _runtime.ready;

  /// 安装统一 PopupHost，用作 [MaterialApp.builder]。
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

  /// 捕获当前根路由 token，供异步场景的 Ownership 使用。
  static PopupRouteToken? captureRoute() => _runtime.captureRoute();

  static PopupTypeApi get _api => PopupTypeApi(_runtime);

  /// 显示 Toast。
  static PopupOpenResult<void> toast(ToastConfig config) => _api.toast(config);

  /// 显示 Loading（默认同 key 更新已有实例）。
  static PopupOpenResult<void> loading(LoadingConfig config) =>
      _api.loading(config);

  /// 关闭当前全局 Loading。
  static Future<void> hideLoading() => _api.hideLoading();

  /// 显示确认框，业务结果为 `bool?`。
  static PopupOpenResult<bool> confirm(ConfirmConfig config) =>
      _api.confirm(config);

  /// 显示日期选择。
  static PopupOpenResult<DateTime> date(DateConfig config) => _api.date(config);

  /// 显示 Sheet。
  static PopupOpenResult<T> sheet<T>(SheetConfig<T> config) =>
      _api.sheet(config);

  /// 显示带内部页面栈的 FlowSheet。
  static PopupOpenResult<R> flowSheet<R>(FlowSheetConfig<R> config) =>
      _api.flowSheet(config);

  /// 显示锚定自定义菜单。
  static PopupOpenResult<T> menu<T>(MenuConfig<T> config) => _api.menu(config);

  /// 显示数据驱动的 DropMenu（单级或二级）。
  static PopupOpenResult<T> dropMenu<T>(DropMenuConfig<T> config) =>
      _api.dropMenu(config);

  /// 显示完全自定义内容的弹窗。
  static PopupOpenResult<T> custom<T>(CustomPopupConfig<T> config) =>
      _api.custom(config);

  /// 关闭指定 channel 下的全部弹窗，返回关闭数量。
  static Future<int> dismissChannel(PopupChannel channel) =>
      _runtime.controller.dismissChannel(channel);

  /// 关闭带有任一给定 tag 的弹窗，返回关闭数量。
  static Future<int> dismissTags(Set<String> tags) =>
      _runtime.controller.dismissTags(tags);

  /// 关闭全部弹窗。
  static Future<void> dismissAll() => _runtime.controller.dismissAll();

  /// 关闭栈顶弹窗；若无可关项返回 `false`。
  static Future<bool> dismissTop() => _runtime.controller.dismissTop();

  /// 将系统返回委托给当前弹窗策略；已消费返回 `true`。
  static Future<bool> handleBack() => _runtime.controller.handleBack();

  /// 指定 key 的弹窗是否处于可见渲染态。
  static bool isVisibleKey(String key) => _runtime.controller.isVisibleKey(key);

  /// 指定 key 的弹窗是否仍可完成 / 关闭 / 更新。
  static bool isActiveKey(String key) => _runtime.controller.isActiveKey(key);

  /// 指定 channel 是否存在活跃弹窗。
  static bool hasChannel(PopupChannel channel) =>
      _runtime.controller.hasChannel(channel);

  /// 指定 channel 当前活跃弹窗数量。
  static int countChannel(PopupChannel channel) =>
      _runtime.controller.countChannel(channel);

  /// 关闭全部弹窗并关闭 Runtime（一般仅测试或热重载场景）。
  static Future<void> shutdown() => _runtime.shutdown();

  /// 测试专用：关闭并替换全局 Runtime，隔离用例状态。
  static Future<void> resetForTest() async {
    await _runtime.shutdown();
    _runtime = PopupRuntime();
  }
}
