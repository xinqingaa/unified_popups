import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/src/configs/popup_back_policy.dart';
import 'package:unified_popups/src/configs/popup_channel.dart';
import 'package:unified_popups/src/configs/popup_route_policy.dart';
import 'package:unified_popups/src/controller/popup_controller.dart';
import 'package:unified_popups/src/controller/popup_dismiss_reason.dart';
import 'package:unified_popups/src/controller/popup_entry_request.dart';
import 'package:unified_popups/src/controller/popup_open_result.dart';
import 'package:unified_popups/src/controller/popup_ownership.dart';
import 'package:unified_popups/src/navigation/popup_route_observer_v2.dart';

void main() {
  testWidgets('system back is delegated to the top popup before the route',
      (tester) async {
    final controller = PopupController()..attachHost();
    final observer = PopupRouteObserverV2(controller);
    addTearDown(() {
      observer.dispose();
      controller.dispose();
    });

    late BuildContext secondContext;
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: <NavigatorObserver>[observer],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (context) {
                  secondContext = context;
                  return const Scaffold(body: Text('second'));
                },
              ),
            ),
            child: const Text('push'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();

    final handle = (controller.open<void, String>(
      const PopupEntryRequest<void, String>(
        channel: PopupChannel.sheet,
        config: 'sheet',
        backPolicy: PopupBackPolicy.dismiss,
      ),
    ) as PopupOpened<void>)
        .handle;
    controller.markPresented(handle.id);
    expect(ModalRoute.of(secondContext)!.popGestureEnabled, isFalse);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pump();
    expect(find.text('second'), findsOneWidget);
    expect((await handle.outcome).reason, PopupDismissReason.back);

    controller.markDisposed(handle.id);
    expect(ModalRoute.of(secondContext)!.popGestureEnabled, isTrue);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('second'), findsNothing);
  });

  testWidgets('owner route policy dismisses an entry after navigation',
      (tester) async {
    final controller = PopupController()..attachHost();
    final observer = PopupRouteObserverV2(controller);
    addTearDown(() {
      observer.dispose();
      controller.dispose();
    });

    late BuildContext homeContext;
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: <NavigatorObserver>[observer],
        home: Builder(
          builder: (context) {
            homeContext = context;
            return const Scaffold(body: Text('home'));
          },
        ),
      ),
    );
    final owner = observer.currentToken;
    final handle = (controller.open<void, String>(
      PopupEntryRequest<void, String>(
        channel: PopupChannel.menu,
        config: 'menu',
        routePolicy: PopupRoutePolicy.dismissWhenOwnerRouteChanges,
        ownership: PopupOwnership(routeToken: owner),
      ),
    ) as PopupOpened<void>)
        .handle;
    controller.markPresented(handle.id);

    Navigator.of(homeContext).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('next')),
      ),
    );
    await tester.pumpAndSettle();

    expect((await handle.outcome).reason, PopupDismissReason.routeChanged);
    controller.markDisposed(handle.id);
  });
}
