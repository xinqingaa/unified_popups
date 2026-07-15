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
      const LoadingConfig(message: 'working'),
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
}
