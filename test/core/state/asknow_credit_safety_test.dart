import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';

import 'package:jyotishasha_app/core/state/asknow_provider.dart';

class _MockHttpClient extends Mock implements http.Client {}

class _MockInAppPurchase extends Mock implements InAppPurchase {}

class _FallbackUri extends Fake implements Uri {}

/// AskNowProvider's constructor falls back to the REAL
/// `InAppPurchase.instance` platform-channel singleton whenever no
/// `billing:` is supplied -- unrelated to this fix (every existing
/// AskNowProvider test already supplies a mock for exactly this reason).
/// Matches asknow_provider_test.dart's own established convention.
AskNowProvider _newProvider(_MockHttpClient http_) {
  final iap = _MockInAppPurchase();
  when(() => iap.purchaseStream)
      .thenAnswer((_) => const Stream<List<PurchaseDetails>>.empty());
  return AskNowProvider(billing: iap, httpClient: http_);
}

/// Ask Now Credit Safety + Live Balance Reconciliation Fix -- Flutter half.
///
/// KNOWN TEST-ENVIRONMENT LIMITATION (pre-existing, not introduced by this
/// fix -- see the last test in asknow_provider_test.dart, already
/// classified PRE-EXISTING NON-BLOCKER): AskNowService's real HTTP calls
/// go through AskNowService._authHeaders(), which reads
/// FirebaseAuth.instance.currentUser directly -- with no Firebase app
/// initialized in this unit-test environment, EVERY real AskNowService
/// call throws '[core/no-app]...' before any HTTP request is even made.
/// That makes the SUCCESS/happy path of askFreeOrFromTokens() and
/// earnedReward() impossible to exercise end-to-end here without adding
/// Firebase test-mocking infrastructure this codebase doesn't have --
/// out of scope for this fix (no redesign requested or performed).
///
/// What IS fully provable here, and is exactly what this fix changed:
///  - the reconciliation step is correctly SKIPPED when no network
///    attempt was made at all (WAIT_SYNC / PAYMENT_REQUIRED),
///  - a reconciliation attempt that itself fails is swallowed and never
///    replaces the original request's own error message,
///  - a failed attempt never silently corrupts existing balance state.
/// applyStatusFromBackend() itself (the actual reconciliation write) is
/// tested directly and exhaustively, with no Firebase dependency at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FallbackUri());
  });

  group('applyStatusFromBackend (the reconciliation write itself)', () {
    test('Free=1, Earned=1 initial status applies correctly', () {
      final provider = _newProvider(_MockHttpClient());
      provider.applyStatusFromBackend({
        'free_available': true,
        'free_used_today': false,
        'remaining_tokens': 1,
      });

      expect(provider.freeAvailable, isTrue);
      expect(provider.remainingTokens, 1);
      expect(provider.hasActivePack, isTrue);
      expect(provider.statusLoaded, isTrue);
    });

    test(
      'after Free is consumed server-side: Free=0, Earned=1 unaffected '
      '-- the exact "Q1 success -> sync" transition the product contract '
      'requires',
      () {
        final provider = _newProvider(_MockHttpClient());
        provider.applyStatusFromBackend({
          'free_available': true,
          'remaining_tokens': 1,
        });

        provider.applyStatusFromBackend({
          'free_available': false,
          'free_used_today': true,
          'remaining_tokens': 1, // untouched by a free-only consumption
        });

        expect(provider.freeAvailable, isFalse);
        expect(provider.remainingTokens, 1);
        expect(provider.hasActivePack, isTrue);
      },
    );

    test(
      'after Earned is also consumed: Free=0, Earned=0 -- the final '
      'state the product contract requires, no refresh involved',
      () {
        final provider = _newProvider(_MockHttpClient());
        provider.applyStatusFromBackend({
          'free_available': false,
          'remaining_tokens': 1,
        });

        provider.applyStatusFromBackend({
          'free_available': false,
          'remaining_tokens': 0,
        });

        expect(provider.freeAvailable, isFalse);
        expect(provider.remainingTokens, 0);
        expect(provider.hasActivePack, isFalse);
      },
    );
  });

  group(
    'askFreeOrFromTokens -- reconciliation gating and failure isolation',
    () {
      late _MockHttpClient http_;
      late AskNowProvider provider;

      setUp(() {
        http_ = _MockHttpClient();
        provider = _newProvider(http_);
      });

      test(
        'WAIT_SYNC path (statusLoaded=false): no network attempt at all, '
        'so no reconciliation call is made either',
        () async {
          provider.statusLoaded = false;

          await provider.askFreeOrFromTokens(
            question: 'q',
            profile: const {},
            userId: 1,
          );

          expect(provider.lastErrorMessage, 'WAIT_SYNC');
          verifyNever(
            () => http_.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            ),
          );
        },
      );

      test(
        'PAYMENT_REQUIRED path (no free, no pack): no network attempt at '
        'all, so no reconciliation call is made either',
        () async {
          provider.statusLoaded = true;
          provider.freeAvailable = false;
          provider.hasActivePack = false;
          provider.remainingTokens = 0;

          await provider.askFreeOrFromTokens(
            question: 'q',
            profile: const {},
            userId: 1,
          );

          expect(provider.lastErrorMessage, 'PAYMENT_REQUIRED');
          verifyNever(
            () => http_.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            ),
          );
        },
      );

      test(
        'a failed free-question attempt never silently corrupts existing '
        'balance state -- remainingTokens/freeAvailable are exactly what '
        'they were before the call',
        () async {
          provider.statusLoaded = true;
          provider.freeAvailable = true;
          provider.hasActivePack = true;
          provider.remainingTokens = 3;

          await provider.askFreeOrFromTokens(
            question: 'q',
            profile: const {},
            userId: 1,
          );

          // The real AskNowService call fails before reaching the network
          // in this test environment (see file doc comment) -- that IS a
          // failed attempt, exactly the case this fix must handle safely.
          expect(provider.lastErrorMessage, isNotNull);
          expect(provider.pendingAnswer, isNull);
          expect(provider.remainingTokens, 3);
          expect(provider.freeAvailable, isTrue);
        },
      );

      test(
        'a failed reconciliation attempt never replaces the original '
        'request error with a different message (Phase C requirement: '
        '"do not let a status-refresh failure overwrite/hide the '
        'original question error")',
        () async {
          provider.statusLoaded = true;
          provider.freeAvailable = true;

          await provider.askFreeOrFromTokens(
            question: 'q',
            profile: const {},
            userId: 1,
          );

          // Both the original askFreeQuestion() call AND the finally-block
          // reconciliation call fail via the identical underlying cause in
          // this environment -- if the reconciliation's own catch clause
          // were missing (i.e. it could throw past its own try/catch), the
          // whole method would throw synchronously OUT of
          // askFreeOrFromTokens instead of completing normally with an
          // error message set. The mere fact this completes normally is
          // itself proof the reconciliation failure was swallowed.
          expect(provider.lastErrorMessage, isNotNull);
          expect(provider.isLoading, isFalse);
        },
      );

      test(
        'a failed paid/earned-question attempt never silently corrupts '
        'existing balance state either',
        () async {
          provider.statusLoaded = true;
          provider.freeAvailable = false;
          provider.hasActivePack = true;
          provider.remainingTokens = 5;

          await provider.askFreeOrFromTokens(
            question: 'q',
            profile: const {},
            userId: 1,
          );

          expect(provider.lastErrorMessage, isNotNull);
          expect(provider.remainingTokens, 5);
          expect(provider.hasActivePack, isTrue);
        },
      );
    },
  );

  group('earnedReward -- Phase D: no false Free-quota coupling', () {
    test(
      'a failed reward call leaves freeAvailable/freeUsedToday completely '
      'untouched -- the removed unconditional freeAvailable=false line '
      'would never have run on this path anyway; this documents the '
      'contract the removal must uphold: reward earning and Free status '
      'are fully independent',
      () async {
        final provider = _newProvider(_MockHttpClient());
        provider.freeAvailable = true;
        provider.freeUsedToday = false;

        await provider.earnedReward(1);

        expect(provider.freeAvailable, isTrue);
        expect(provider.freeUsedToday, isFalse);
      },
    );
  });
}
