import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_harness.dart';
import 'helpers/widget_tester_extensions.dart';
import 'mocks/common_mocks.dart';

void main() {
  testWidgets('test harness pumps a widget', (tester) async {
    await tester.pumpTestHarness(const Text('Testing foundation ready'));

    await tester.pumpUntilFound(find.text('Testing foundation ready'));

    expect(find.text('Testing foundation ready'), findsOneWidget);
  });

  test('fake async controls timer execution', () {
    fakeAsync((async) {
      var fired = false;
      Timer(const Duration(seconds: 1), () => fired = true);

      async.elapse(const Duration(milliseconds: 999));
      expect(fired, isFalse);

      async.elapse(const Duration(milliseconds: 1));
      expect(fired, isTrue);
    });
  });

  test('common mocks are available', () {
    expect(MockNavigatorObserver(), isA<NavigatorObserver>());
  });
}
