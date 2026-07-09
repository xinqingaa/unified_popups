part of '../flow_sheet.dart';

abstract class _FlowSheetLifecycleObserver {
  void handleLoad();

  void handleShow();

  void handleHide();

  void handleRemove();

  void handleClose();
}

enum _FlowSheetLifecycleEndReason {
  remove,
  close,
}

class _FlowSheetPageLifecycleController extends ChangeNotifier {
  final Set<_FlowSheetLifecycleObserver> _observers =
      <_FlowSheetLifecycleObserver>{};

  bool _loaded = false;
  bool _visible = false;
  bool _disposed = false;
  _FlowSheetLifecycleEndReason? _endReason;

  bool get isLoaded => _loaded;

  bool get isVisible => _visible;

  bool get isDisposed => _disposed;

  void addObserver(_FlowSheetLifecycleObserver observer) {
    if (_disposed) {
      switch (_endReason) {
        case _FlowSheetLifecycleEndReason.remove:
          observer.handleRemove();
        case _FlowSheetLifecycleEndReason.close:
        case null:
          observer.handleClose();
      }
      return;
    }
    _observers.add(observer);
    if (_loaded) observer.handleLoad();
    if (_visible) observer.handleShow();
  }

  void removeObserver(_FlowSheetLifecycleObserver observer) {
    _observers.remove(observer);
  }

  void load() {
    if (_disposed || _loaded) return;
    _loaded = true;
    for (final observer in List<_FlowSheetLifecycleObserver>.of(_observers)) {
      observer.handleLoad();
    }
    notifyListeners();
  }

  void show() {
    if (_disposed) return;
    load();
    if (_visible) return;
    _visible = true;
    for (final observer in List<_FlowSheetLifecycleObserver>.of(_observers)) {
      observer.handleShow();
    }
    notifyListeners();
  }

  void hide() {
    if (_disposed || !_visible) return;
    _visible = false;
    for (final observer in List<_FlowSheetLifecycleObserver>.of(_observers)) {
      observer.handleHide();
    }
    notifyListeners();
  }

  void disposeLifecycle(_FlowSheetLifecycleEndReason reason) {
    if (_disposed) return;
    hide();
    _disposed = true;
    _endReason = reason;
    for (final observer in List<_FlowSheetLifecycleObserver>.of(_observers)) {
      switch (reason) {
        case _FlowSheetLifecycleEndReason.remove:
          observer.handleRemove();
        case _FlowSheetLifecycleEndReason.close:
          observer.handleClose();
      }
    }
    _observers.clear();
    notifyListeners();
  }
}

class _FlowSheetPageScope
    extends InheritedNotifier<_FlowSheetPageLifecycleController> {
  const _FlowSheetPageScope({
    required this.navigator,
    required _FlowSheetPageLifecycleController lifecycleController,
    required super.child,
  }) : super(notifier: lifecycleController);

  final FlowSheetNavigator navigator;

  _FlowSheetPageLifecycleController get lifecycleController => notifier!;

  static _FlowSheetPageScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_FlowSheetPageScope>();
  }
}
