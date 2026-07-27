import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../contracts/flow_sheet_entry.dart';
import '../contracts/flow_sheet_host_delegate.dart';
import '../contracts/flow_sheet_route_builder.dart';
import '../lifecycle/flow_sheet_lifecycle_controller.dart';
import '../pages/flow_sheet_page.dart';

/// 把 [FlowSheetEntry] 映射为 Cupertino 风格转场的声明式 [Page]。
class _FlowPage extends Page<dynamic> {
  _FlowPage(
    this.entry,
    this.controller, {
    required this.pageBackgroundColor,
    required this.routeBuilder,
  }) : super(key: ValueKey<FlowSheetEntry>(entry));

  final FlowSheetEntry entry;
  final FlowSheetHostDelegate controller;
  final Color? pageBackgroundColor;
  final FlowSheetRouteBuilder? routeBuilder;

  @override
  Route<dynamic> createRoute(BuildContext context) {
    final child = ColoredBox(
      color: _resolvePageBackgroundColor(context),
      child: FlowSheetPageScope(
        navigator: controller.navigator,
        lifecycleController: entry.lifecycleController,
        child: entry.page,
      ),
    );
    final customRouteBuilder = routeBuilder;
    if (customRouteBuilder != null) {
      return customRouteBuilder(
        context,
        this,
        child,
        maintainState: entry.page.maintainState,
      );
    }
    return CupertinoPageRoute<dynamic>(
      settings: this,
      maintainState: entry.page.maintainState,
      builder: (ctx) => child,
    );
  }

  Color _resolvePageBackgroundColor(BuildContext context) {
    return pageBackgroundColor ??
        Theme.of(context).bottomSheetTheme.backgroundColor ??
        Theme.of(context).colorScheme.surface;
  }
}

/// FlowSheet 的展示宿主：用内嵌 [Navigator]（Pages API）承载页面栈，
/// push/pop 默认由 [CupertinoPageRoute] 提供原生横向滑动转场（含 iOS 侧滑返回）；
/// 保活页（maintainState）由路由 `maintainState` 控制。
///
/// 系统返回不由本宿主直接处理：由外层 route observer → popup controller →
/// flowSheet `backPolicy.delegate` 依次 pop 内页或关闭整张 sheet。
/// 内嵌 Navigator 的 [NavigationNotification] 会被拦截，避免单页栈上报
/// `canHandlePop: false` 导致 Android 直接退出应用。
class FlowSheetHost extends StatefulWidget {
  const FlowSheetHost({
    super.key,
    required this.controller,
    required this.initialPage,
    this.pageBackgroundColor,
    this.routeBuilder,
  });

  final FlowSheetHostDelegate controller;
  final FlowSheetPage initialPage;
  final Color? pageBackgroundColor;
  final FlowSheetRouteBuilder? routeBuilder;

  @override
  State<FlowSheetHost> createState() => _FlowSheetHostState();
}

class _FlowSheetHostState extends State<FlowSheetHost> {
  /// controller 是否可用（未被延迟销毁握手回收）。
  /// 极端时序下（sheet Future 已完成后宿主被重挂载）controller 可能已销毁，
  /// 此时不再订阅，仅渲染空占位等待 overlay 移除。
  bool _controllerUsable = false;

  @override
  void initState() {
    super.initState();
    _controllerUsable = !widget.controller.isDisposed;
    if (!_controllerUsable) return;
    widget.controller.attachHost(this);
    widget.controller.ensureInitial(widget.initialPage);
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (_controllerUsable) {
      widget.controller.removeListener(_onControllerChanged);
      widget.controller.detachHost(this);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controllerUsable || widget.controller.isDisposed) {
      return const SizedBox.shrink();
    }
    final entries = widget.controller.entries;
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    // Absorb nested-navigator NavigationNotifications so a single-page stack
    // cannot set SystemNavigator.setFrameworkHandlesBack(false) and finish the
    // Android activity. When the nested stack reports it cannot handle pops,
    // re-dispatch canHandlePop: true so the outer popup back bridge remains
    // authoritative.
    return NotificationListener<NavigationNotification>(
      onNotification: (notification) {
        if (!notification.canHandlePop) {
          const NavigationNotification(canHandlePop: true).dispatch(context);
        }
        return true;
      },
      child: ClipRect(
        child: HeroControllerScope.none(
          child: Navigator(
            key: widget.controller.navigatorKey,
            pages: [
              for (final entry in entries)
                _FlowPage(
                  entry,
                  widget.controller,
                  pageBackgroundColor: widget.pageBackgroundColor,
                  routeBuilder: widget.routeBuilder,
                ),
            ],
            onDidRemovePage: (page) {
              if (page is _FlowPage) {
                widget.controller.handlePageRemoved(page.entry);
              }
              if (mounted) setState(() {});
            },
          ),
        ),
      ),
    );
  }
}
