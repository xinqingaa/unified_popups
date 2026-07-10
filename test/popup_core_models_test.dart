import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/src/configs/popup_channel.dart';
import 'package:unified_popups/src/controller/popup_dismiss_reason.dart';
import 'package:unified_popups/src/controller/popup_entry_state.dart';
import 'package:unified_popups/src/controller/popup_outcome.dart';

void main() {
  test('entry state separates business activity from host mounting', () {
    expect(PopupEntryState.pendingHost.isActive, isTrue);
    expect(PopupEntryState.pendingHost.isMounted, isFalse);
    expect(PopupEntryState.visible.isActive, isTrue);
    expect(PopupEntryState.visible.isMounted, isTrue);
    expect(PopupEntryState.exiting.isActive, isFalse);
    expect(PopupEntryState.exiting.isMounted, isTrue);
    expect(PopupEntryState.disposed.isTerminal, isTrue);
  });

  test('outcome keeps null completion distinct from dismissal', () {
    const completed = PopupOutcome<String>(
      reason: PopupDismissReason.completed,
    );
    const dismissed = PopupOutcome<String>(
      reason: PopupDismissReason.manual,
    );

    expect(completed.isCompleted, isTrue);
    expect(dismissed.isCompleted, isFalse);
    expect(completed, isNot(dismissed));
  });

  test('custom channels use value equality', () {
    expect(const PopupChannel('orders'), const PopupChannel('orders'));
    expect(const PopupChannel('orders'), isNot(const PopupChannel('profile')));
  });
}
