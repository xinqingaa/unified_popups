import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Route PopEntry bridge spike', () {
    testWidgets(
      'a NavigatorObserver can register a global PopEntry on the current route',
      (tester) async {
        final bridge = _TestPopBridge();
        final observer = _TestRouteObserver(bridge);
        final navigatorKey = GlobalKey<NavigatorState>();

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            navigatorObservers: [observer],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const Scaffold(
                            body: Text('details'),
                          ),
                        ),
                      );
                    },
                    child: const Text('open'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('details'), findsOneWidget);

        bridge.canPopNotifier.value = false;
        expect(
          observer.currentRoute?.popDisposition,
          RoutePopDisposition.doNotPop,
        );
        expect(observer.currentRoute?.popGestureEnabled, isFalse);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('details'), findsOneWidget);
        expect(bridge.invocations, [false]);

        bridge.canPopNotifier.value = true;
        expect(observer.currentRoute?.popGestureEnabled, isTrue);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('details'), findsNothing);
        expect(bridge.invocations, [false, true]);

        observer.dispose();
        bridge.dispose();
      },
    );

    testWidgets(
      'the bridge follows the current route across push and pop',
      (tester) async {
        final bridge = _TestPopBridge();
        final observer = _TestRouteObserver(bridge);
        final navigatorKey = GlobalKey<NavigatorState>();

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            navigatorObservers: [observer],
            home: const Scaffold(body: Text('home')),
          ),
        );

        final homeRoute = observer.currentRoute;
        expect(homeRoute, isNotNull);

        navigatorKey.currentState!.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('second')),
          ),
        );
        await tester.pumpAndSettle();

        final secondRoute = observer.currentRoute;
        expect(secondRoute, isNotNull);
        expect(identical(homeRoute, secondRoute), isFalse);

        navigatorKey.currentState!.pop();
        await tester.pumpAndSettle();

        expect(identical(observer.currentRoute, homeRoute), isTrue);

        observer.dispose();
        bridge.dispose();
      },
    );
  });
}

class _TestPopBridge implements PopEntry<Object?> {
  @override
  final ValueNotifier<bool> canPopNotifier = ValueNotifier<bool>(true);

  final List<bool> invocations = <bool>[];

  @override
  void onPopInvoked(bool didPop) {
    invocations.add(didPop);
  }

  @override
  void onPopInvokedWithResult(bool didPop, Object? result) {
    invocations.add(didPop);
  }

  void dispose() {
    canPopNotifier.dispose();
  }
}

class _TestRouteObserver extends NavigatorObserver {
  _TestRouteObserver(this.bridge);

  final _TestPopBridge bridge;
  ModalRoute<dynamic>? currentRoute;

  void _attachTo(Route<dynamic>? route) {
    final previous = currentRoute;
    if (previous != null) {
      previous.unregisterPopEntry(bridge);
    }

    currentRoute = route is ModalRoute<dynamic> ? route : null;
    currentRoute?.registerPopEntry(bridge);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _attachTo(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (identical(currentRoute, route)) {
      currentRoute?.unregisterPopEntry(bridge);
      currentRoute = null;
    }
    _attachTo(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (identical(currentRoute, oldRoute) || oldRoute == null) {
      _attachTo(newRoute);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (identical(currentRoute, route)) {
      currentRoute?.unregisterPopEntry(bridge);
      currentRoute = null;
      _attachTo(previousRoute);
    }
  }

  void dispose() {
    currentRoute?.unregisterPopEntry(bridge);
    currentRoute = null;
  }
}
