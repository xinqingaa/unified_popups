import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/unified_popups.dart';

void main() {
  setUp(Pop.resetForTest);
  tearDown(Pop.resetForTest);

  test('Config-first calls may ignore or consume the unified return model',
      () async {
    // Fire-and-forget callers do not need to bind the return value.
    Pop.toast(const ToastConfig.text('saved'));

    final loading = Pop.loading(
      const LoadingConfig.text('working'),
    );
    expect(loading, isA<PopupOpened<void>>());
    await loading.requireHandle().dismiss();

    final confirm = Pop.confirm(
      const ConfirmConfig(content: 'continue?'),
    );
    final completion = confirm.requireHandle().complete(true);
    expect(await confirm.result, isTrue);
    await completion;
  });

  test('ToastConfig constructors make text and Widget payloads exclusive', () {
    const text = ToastConfig.text('saved');
    const content = ToastConfig.content(SizedBox.shrink());

    expect(text.message, 'saved');
    expect(text.content, isNull);
    expect(content.message, isNull);
    expect(content.content, isA<SizedBox>());
  });

  test('LoadingConfig constructors make payload intent explicit', () {
    const indicator = LoadingConfig.indicator();
    const text = LoadingConfig.text('working');
    const content = LoadingConfig.content(SizedBox.shrink());

    expect(indicator.message, isNull);
    expect(indicator.content, isNull);
    expect(text.message, 'working');
    expect(text.content, isNull);
    expect(content.message, isNull);
    expect(content.content, isA<SizedBox>());
  });

  test('nullable behavior key can be explicitly cleared', () {
    const behavior = PopupBehaviorConfig(key: 'request');

    expect(behavior.copyWith().key, 'request');
    expect(behavior.copyWith(key: 'replacement').key, 'replacement');
    expect(behavior.copyWith(clearKey: true).key, isNull);
    expect(
      () => behavior.copyWith(key: 'replacement', clearKey: true),
      throwsArgumentError,
    );
  });

  test('text and Widget payload aliases cannot conflict', () {
    expect(
      () => ConfirmConfig(
        title: 'Title',
        titleWidget: const Text('Title'),
        content: 'Body',
      ),
      throwsAssertionError,
    );
    expect(
      () => ConfirmConfig(
        content: 'Body',
        contentWidget: const Text('Body'),
      ),
      throwsAssertionError,
    );
    expect(
      () => SheetHeaderConfig(
        title: 'Title',
        titleWidget: const Text('Title'),
      ),
      throwsAssertionError,
    );
  });

  test('ConfirmAction makes text and Widget buttons structurally exclusive',
      () {
    const text = ConfirmAction.text('Confirm');
    const content = ConfirmAction.content(Text('Confirm'));

    expect(text.text, 'Confirm');
    expect(text.child, isNull);
    expect(content.text, isNull);
    expect(content.child, isA<Text>());
  });
}
