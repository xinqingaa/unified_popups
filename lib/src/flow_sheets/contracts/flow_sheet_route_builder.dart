import 'package:flutter/widgets.dart';

typedef FlowSheetRouteBuilder = Route<dynamic> Function(
  BuildContext context,
  Page<dynamic> settings,
  Widget child, {
  required bool maintainState,
});
