import 'dart:async';

import '../lifecycle/flow_sheet_lifecycle_controller.dart';
import '../pages/flow_sheet_page.dart';

/// Internal session record shared through the restricted host delegate.
final class FlowSheetEntry {
  FlowSheetEntry(this.page);

  final FlowSheetPage page;
  final FlowSheetPageLifecycleController lifecycleController =
      FlowSheetPageLifecycleController();
  final Completer<dynamic> completer = Completer<dynamic>();

  dynamic pendingResult;
  bool disposed = false;

  void completeIfPending([dynamic result]) {
    if (!completer.isCompleted) completer.complete(result);
  }
}
