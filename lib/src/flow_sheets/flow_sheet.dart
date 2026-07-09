import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/popup_manager.dart';

part 'contracts/flow_sheet_navigator.dart';
part 'controller/flow_sheet_controller.dart';
part 'lifecycle/flow_sheet_lifecycle_controller.dart';
part 'pages/flow_sheet_page.dart';
part 'widgets/flow_sheet_host.dart';

typedef FlowSheetRouteBuilder = Route<dynamic> Function(
  BuildContext context,
  Page<dynamic> settings,
  Widget child, {
  required bool maintainState,
});
