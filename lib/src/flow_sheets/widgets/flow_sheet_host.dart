part of '../flow_sheet.dart';

/// 把 [_FlowEntry] 映射为 Cupertino 风格转场的声明式 [Page]。
class _FlowPage extends Page<dynamic> {
  _FlowPage(
    this.entry,
    this.controller, {
    required this.pageBackgroundColor,
    required this.routeBuilder,
  }) : super(key: ValueKey<_FlowEntry>(entry));

  final _FlowEntry entry;
  final FlowSheetController controller;
  final Color? pageBackgroundColor;
  final FlowSheetRouteBuilder? routeBuilder;

  @override
  Route<dynamic> createRoute(BuildContext context) {
    final child = ColoredBox(
      color: _resolvePageBackgroundColor(context),
      child: _FlowSheetPageScope(
        navigator: controller,
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
/// 保活页（maintainState）由路由 `maintainState` 控制，系统返回由 [PopScope] 桥接。
class FlowSheetHost extends StatefulWidget {
  const FlowSheetHost({
    super.key,
    required this.controller,
    required this.initialPage,
    this.pageBackgroundColor,
    this.routeBuilder,
  });

  final FlowSheetController controller;
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
    _controllerUsable = !widget.controller._disposed;
    if (!_controllerUsable) return;
    widget.controller._attachHost(this);
    widget.controller._ensureInitial(widget.initialPage);
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (_controllerUsable) {
      widget.controller.removeListener(_onControllerChanged);
      widget.controller._detachHost(this);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controllerUsable || widget.controller._disposed) {
      return _wrapPopScope(const SizedBox.shrink());
    }
    final entries = widget.controller._stack;
    if (entries.isEmpty) {
      return _wrapPopScope(const SizedBox.shrink());
    }

    return _wrapPopScope(
      ClipRect(
        child: Navigator(
          key: widget.controller._navigatorKey,
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
              widget.controller._handleRemoved(page.entry);
            }
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }

  Widget _wrapPopScope(Widget child) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        widget.controller.handleBack(result);
      },
      child: child,
    );
  }
}
