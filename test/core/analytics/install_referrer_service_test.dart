import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jyotishasha_app/core/analytics/install_referrer_service.dart';

/// Task 5 focused tests for InstallReferrerService.
///
/// LOCAL/UNIT ONLY -- no real Play Install Referrer platform channel is
/// ever touched (debugFetcherOverride replaces it in every test);
/// SharedPreferences uses the package's own official in-memory test
/// mock (SharedPreferences.setMockInitialValues), the exact same
/// convention already established elsewhere in this repo (see e.g.
/// test/core/state/asknow_provider_test.dart).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    InstallReferrerService.debugResetFetcherOverride();
  });

  tearDown(() {
    InstallReferrerService.debugResetFetcherOverride();
  });

  group('parseAllowlisted (pure parsing)', () {
    test(
      'A: accepts a valid controlled campaign referrer string',
      () {
        final result = InstallReferrerService.parseAllowlisted(
          'utm_source=newsletter&utm_medium=email&utm_campaign=launch',
        );
        expect(result['utm_source'], 'newsletter');
        expect(result['utm_medium'], 'email');
        expect(result['utm_campaign'], 'launch');
        expect(result['cta_location'], isNull);
      },
    );

    test(
      'B: a malformed referrer string is safely ignored, never throws',
      () {
        expect(
          () => InstallReferrerService.parseAllowlisted('%%%not a valid query string%%%'),
          returnsNormally,
        );
        final result = InstallReferrerService.parseAllowlisted('###&&&===');
        expect(result.values.every((v) => v == null), isTrue);
      },
    );

    test('B2: an empty referrer string yields an all-null result, never throws', () {
      final result = InstallReferrerService.parseAllowlisted('');
      expect(result.values.every((v) => v == null), isTrue);
    });

    test(
      'C: unknown keys are ignored -- only the allowlisted keys are ever read',
      () {
        final result = InstallReferrerService.parseAllowlisted(
          'utm_source=newsletter&some_unknown_key=xyz&another_bogus=1',
        );
        expect(result['utm_source'], 'newsletter');
        expect(result.containsKey('some_unknown_key'), isFalse);
        expect(result.containsKey('another_bogus'), isFalse);
      },
    );

    test(
      'D: PII-like/unapproved keys are never persisted/exposed in the result',
      () {
        final result = InstallReferrerService.parseAllowlisted(
          'email=someone%40example.com&phone=9876543210&utm_source=newsletter',
        );
        expect(result['utm_source'], 'newsletter');
        expect(result.containsKey('email'), isFalse);
        expect(result.containsKey('phone'), isFalse);
        // The full result map has EXACTLY the 4 allowlisted keys, never
        // any additional key the raw string happened to contain.
        expect(result.keys.toSet(), {'utm_source', 'utm_medium', 'utm_campaign', 'cta_location'});
      },
    );

    test('D2: an oversized value is dropped entirely, not truncated', () {
      final oversized = 'x' * 300;
      final result = InstallReferrerService.parseAllowlisted('utm_source=$oversized');
      expect(result['utm_source'], isNull);
    });
  });

  group('captureOnce', () {
    test(
      'E: a never-completing fetcher cannot block startup -- bounded by '
      'the (test-overridden, short) timeout and completes normally',
      () async {
        final neverCompletes = Completer<String?>();
        InstallReferrerService.debugFetcherOverride = () => neverCompletes.future;

        await expectLater(
          InstallReferrerService.captureOnce(timeout: const Duration(milliseconds: 50)),
          completes,
        );
      },
    );

    test(
      'F: once/consumed semantics -- a second call does not re-invoke the '
      'fetcher and does not overwrite already-captured attribution',
      () async {
        var callCount = 0;
        InstallReferrerService.debugFetcherOverride = () async {
          callCount++;
          return 'utm_source=first_call&utm_medium=email&utm_campaign=launch';
        };

        await InstallReferrerService.captureOnce();
        expect(callCount, 1);
        expect(await InstallReferrerService.debugIsProcessed(), isTrue);

        // Second call -- even with a DIFFERENT fetcher result available,
        // the once-guard must prevent it from ever being read.
        InstallReferrerService.debugFetcherOverride = () async {
          callCount++;
          return 'utm_source=second_call_should_never_be_read';
        };
        await InstallReferrerService.captureOnce();

        expect(callCount, 1, reason: 'fetcher must not be invoked a second time');
        final captured = await InstallReferrerService.readCapturedAttribution();
        expect(captured['utm_source'], 'first_call', reason: 'first captured value must not be overwritten');
      },
    );

    test(
      'G: no install evidence (fetch failure/timeout) -> no attribution '
      'is persisted and the processed marker is NOT set (so a later '
      'genuine attempt can still succeed)',
      () async {
        InstallReferrerService.debugFetcherOverride = () async {
          throw Exception('Play Services unavailable');
        };

        await InstallReferrerService.captureOnce();

        expect(await InstallReferrerService.debugIsProcessed(), isFalse);
        final captured = await InstallReferrerService.readCapturedAttribution();
        expect(captured.values.every((v) => v == null), isTrue);
      },
    );

    test(
      'G2: an organic install (referrer read succeeds but is empty) IS '
      'real evidence -- marked processed, all attribution fields absent',
      () async {
        InstallReferrerService.debugFetcherOverride = () async => '';

        await InstallReferrerService.captureOnce();

        expect(await InstallReferrerService.debugIsProcessed(), isTrue);
        final captured = await InstallReferrerService.readCapturedAttribution();
        expect(captured.values.every((v) => v == null), isTrue);
      },
    );

    test(
      'never throws even when the fetcher throws synchronously',
      () async {
        InstallReferrerService.debugFetcherOverride = () => throw StateError('boom');
        await expectLater(InstallReferrerService.captureOnce(), completes);
      },
    );

    test(
      'captured fields round-trip correctly through readCapturedAttribution',
      () async {
        InstallReferrerService.debugFetcherOverride = () async =>
            'utm_source=daily_panchang&utm_medium=primary_cta&utm_campaign=hero&cta_location=daily_panchang_primary_cta';

        await InstallReferrerService.captureOnce();
        final captured = await InstallReferrerService.readCapturedAttribution();

        expect(captured['utm_source'], 'daily_panchang');
        expect(captured['utm_medium'], 'primary_cta');
        expect(captured['utm_campaign'], 'hero');
        expect(captured['cta_location'], 'daily_panchang_primary_cta');
      },
    );
  });
}
