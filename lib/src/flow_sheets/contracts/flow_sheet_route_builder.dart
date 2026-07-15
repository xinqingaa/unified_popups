import 'package:flutter/widgets.dart';

/// 为 FlowSheet 内嵌导航器中的单个页面构建 [Route]。
///
/// `settings` 参数是拥有该路由的框架级 [Page]。`maintainState` 与所属
/// [FlowSheetPage.maintainState] 标志保持一致，使构建器可以在需要时保留离屏页面。
typedef FlowSheetRouteBuilder = Route<dynamic> Function(
  BuildContext context,
  Page<dynamic> settings,
  Widget child, {
  required bool maintainState,
});
