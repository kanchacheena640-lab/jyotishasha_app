import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/core/utils/startup_timeout.dart';

/// Release-gate fix (P0) regression coverage — proves the exact contract
/// `main()` relies on for its one pre-`runApp()` optional platform-channel
/// probe (`FirebaseMessaging.instance.getInitialMessage()`): no matter how
/// that operation fails, this helper never lets the failure propagate, so
/// it can never block `main()` from reaching `runApp()`.
void main() {
  group('withStartupTimeout (P0 startup-safety helper)', () {
    test(
      'a slow/never-completing operation is bounded by the timeout and '
      'resolves to null rather than hanging forever',
      () async {
        final neverCompletes = Completer<String>();

        final result = await withStartupTimeout(
          () => neverCompletes.future,
          timeout: const Duration(milliseconds: 50),
        );

        expect(result, isNull);
      },
    );

    test(
      'a synchronously-thrown exception (e.g. a platform-channel failure '
      'on a device with Play Services not ready) is swallowed, not '
      'rethrown -- resolves to null instead',
      () async {
        final result = await withStartupTimeout<String>(
          () => throw Exception('platform channel unavailable'),
        );

        expect(result, isNull);
      },
    );

    test(
      'a Future that completes with an error (the real shape of a failed '
      'platform-channel call) is also swallowed -- resolves to null',
      () async {
        final result = await withStartupTimeout<String>(
          () => Future<String>.error(Exception('native call failed')),
        );

        expect(result, isNull);
      },
    );

    test(
      'a successful operation completes normally and its real value is '
      'returned unchanged -- the wrapper adds a bound, nothing else',
      () async {
        final result = await withStartupTimeout(
          () async => 'initial-message-payload',
        );

        expect(result, 'initial-message-payload');
      },
    );

    test(
      'a fast operation is not affected by the timeout at all',
      () async {
        final result = await withStartupTimeout(
          () async {
            await Future<void>.delayed(const Duration(milliseconds: 5));
            return 42;
          },
          timeout: const Duration(seconds: 3),
        );

        expect(result, 42);
      },
    );
  });
}
