import 'package:flutter/widgets.dart';

import '../contracts/flow_sheet_navigator.dart';

abstract interface class FlowSheetLifecycleObserver {
  void handleLoad();
  void handleShow();
  void handleHide();
  void handleRemove();
  void handleClose();
}

enum FlowSheetLifecycleEndReason { remove, close }

class FlowSheetPageLifecycleController extends ChangeNotifier {
  final Set<FlowSheetLifecycleObserver> _observers =
      <FlowSheetLifecycleObserver>{};

  bool _loaded = false;
  bool _visible = false;
  bool _disposed = false;
  FlowSheetLifecycleEndReason? _endReason;

  bool get isLoaded => _loaded;
  bool get isVisible => _visible;
  bool get isDisposed => _disposed;

  void addObserver(FlowSheetLifecycleObserver observer) {
    if (_disposed) {
      switch (_endReason) {
        case FlowSheetLifecycleEndReason.remove:
          observer.handleRemove();
        case FlowSheetLifecycleEndReason.close:
        case null:
          observer.handleClose();
      }
      return;
    }
    _observers.add(observer);
    if (_loaded) observer.handleLoad();
    if (_visible) observer.handleShow();
  }

  void removeObserver(FlowSheetLifecycleObserver observer) {
    _observers.remove(observer);
  }

  void load() {
    if (_disposed || _loaded) return;
    _loaded = true;
    for (final observer in List<FlowSheetLifecycleObserver>.of(_observers)) {
      observer.handleLoad();
    }
    notifyListeners();
  }

  void show() {
    if (_disposed) return;
    load();
    if (_visible) return;
    _visible = true;
    for (final observer in List<FlowSheetLifecycleObserver>.of(_observers)) {
      observer.handleShow();
    }
    notifyListeners();
  }

  void hide() {
    if (_disposed || !_visible) return;
    _visible = false;
    for (final observer in List<FlowSheetLifecycleObserver>.of(_observers)) {
      observer.handleHide();
    }
    notifyListeners();
  }

  void disposeLifecycle(FlowSheetLifecycleEndReason reason) {
    if (_disposed) return;
    hide();
    _disposed = true;
    _endReason = reason;
    for (final observer in List<FlowSheetLifecycleObserver>.of(_observers)) {
      switch (reason) {
        case FlowSheetLifecycleEndReason.remove:
          observer.handleRemove();
        case FlowSheetLifecycleEndReason.close:
          observer.handleClose();
      }
    }
    _observers.clear();
    notifyListeners();
  }
}

class FlowSheetPageScope
    extends InheritedNotifier<FlowSheetPageLifecycleController> {
  const FlowSheetPageScope({
    super.key,
    required this.navigator,
    required FlowSheetPageLifecycleController lifecycleController,
    required super.child,
  }) : super(notifier: lifecycleController);

  final FlowSheetNavigator navigator;

  FlowSheetPageLifecycleController get lifecycleController => notifier!;

  static FlowSheetPageScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FlowSheetPageScope>();
  }
}
