import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../contracts/flow_sheet_entry.dart';
import '../contracts/flow_sheet_host_delegate.dart';
import '../contracts/flow_sheet_route_builder.dart';
import '../lifecycle/flow_sheet_lifecycle_controller.dart';
import '../pages/flow_sheet_page.dart';

/// 把 [FlowSheetEntry] 映射为声明式 [Page]。
///
/// - 栈底首页（[isRoot]）：无水平转场，只跟随外层 Sheet 的上滑打开；
///   避免 `replace` 换首页时出现「从右往左」的假入场。
///   `resetTo(animate: true)` 先把新页当非首页推入，因此仍走下方横向转场；
///   动画结束后再收成单页根。
/// - 非首页：默认 [CupertinoPageRoute] 横向滑动（含 iOS 侧滑返回）。
class _FlowPage extends Page<dynamic> {
  _FlowPage(
    this.entry,
    this.controller, {
    required this.pageBackgroundColor,
    required this.routeBuilder,
    required this.isRoot,
  }) : super(key: ValueKey<FlowSheetEntry>(entry));

  final FlowSheetEntry entry;
  final FlowSheetHostDelegate controller;
  final Color? pageBackgroundColor;
  final FlowSheetRouteBuilder? routeBuilder;

  /// 是否为 FlowSheet 内嵌栈的栈底页。
  final bool isRoot;

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
    if (isRoot) {
      // 首页：零时长转场。Sheet 打开动画负责入场；replace 换首页也不播右滑。
      return PageRouteBuilder<dynamic>(
        settings: this,
        maintainState: entry.page.maintainState,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) => child,
      );
    }
    // 禁用侧滑：不用 CupertinoPageRoute（其自带 iOS 边缘返回手势）。
    // animated resetTo also suppresses swipe so the incoming home cannot
    // be flicked back to the gate / password page.
    if (!entry.page.enableSwipePop || entry.suppressSwipePop) {
      return PageRouteBuilder<dynamic>(
        settings: this,
        maintainState: entry.page.maintainState,
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offset = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation);
          return SlideTransition(position: offset, child: child);
        },
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

/// FlowSheet 的展示宿主：用内嵌 [Navigator]（Pages API）承载页面栈。
///
/// - 栈底首页：无水平转场（见 [_FlowPage.isRoot]）
/// - push/pop 子页：默认 [CupertinoPageRoute] 横向滑动（含 iOS 侧滑返回）
/// - 保活页（maintainState）由路由 `maintainState` 控制
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
              for (var i = 0; i < entries.length; i++)
                _FlowPage(
                  entries[i],
                  widget.controller,
                  pageBackgroundColor: widget.pageBackgroundColor,
                  routeBuilder: widget.routeBuilder,
                  isRoot: i == 0,
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
