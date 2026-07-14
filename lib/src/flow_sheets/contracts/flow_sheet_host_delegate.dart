import 'package:flutter/widgets.dart';

import 'flow_sheet_entry.dart';
import 'flow_sheet_navigator.dart';
import '../pages/flow_sheet_page.dart';

/// Restricted bridge between the internal Navigator host and its controller.
abstract interface class FlowSheetHostDelegate implements Listenable {
  bool get isDisposed;
  List<FlowSheetEntry> get entries;
  GlobalKey<NavigatorState> get navigatorKey;
  FlowSheetNavigator get navigator;

  void attachHost(Object host);
  void detachHost(Object host);
  void ensureInitial(FlowSheetPage page);
  void handlePageRemoved(FlowSheetEntry entry);
  bool handleBack([Object? result]);
}
