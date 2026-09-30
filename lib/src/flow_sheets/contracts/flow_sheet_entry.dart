import 'dart:async';

import '../lifecycle/flow_sheet_lifecycle_controller.dart';
import '../pages/flow_sheet_page.dart';

/// Internal session record shared through the restricted host delegate.
final class FlowSheetEntry {
  FlowSheetEntry(this.page, {this.suppressSwipePop = false});

  final FlowSheetPage page;

  /// When true, the host must not use a Cupertino route (no iOS edge swipe).
  /// Used by animated [FlowSheetNavigator.resetTo] so the incoming home page
  /// cannot be swiped back to the previous root during the enter transition.
  final bool suppressSwipePop;
  final FlowSheetPageLifecycleController lifecycleController =
      FlowSheetPageLifecycleController();
  final Completer<dynamic> completer = Completer<dynamic>();

  dynamic pendingResult;
  bool disposed = false;

  void completeIfPending([dynamic result]) {
    if (!completer.isCompleted) completer.complete(result);
  }
}
