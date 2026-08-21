import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jyotishasha_app/core/state/asknow_provider.dart';

class _MockInAppPurchase extends Mock implements InAppPurchase {}

class _MockProductDetailsResponse extends Mock
    implements ProductDetailsResponse {}

class _MockProductDetails extends Mock implements ProductDetails {}

class _MockPurchaseDetails extends Mock implements PurchaseDetails {}

class _MockPurchaseVerificationData extends Mock
    implements PurchaseVerificationData {}

class _MockHttpClient extends Mock implements http.Client {}

class _FallbackProductDetails extends Fake implements ProductDetails {}

class _FallbackPurchaseDetails extends Fake implements PurchaseDetails {}

class _FallbackUri extends Fake implements Uri {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(PurchaseParam(productDetails: _FallbackProductDetails()));
    registerFallbackValue(_FallbackPurchaseDetails());
    registerFallbackValue(_FallbackUri());
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  _MockPurchaseDetails purchaseFor(
    String token, {
    PurchaseStatus status = PurchaseStatus.purchased,
    bool pendingComplete = true,
  }) {
    final purchase = _MockPurchaseDetails();
    final verification = _MockPurchaseVerificationData();
    when(() => verification.serverVerificationData).thenReturn(token);
    when(() => purchase.verificationData).thenReturn(verification);
    when(() => purchase.productID).thenReturn('asknow10q');
    when(() => purchase.pendingCompletePurchase).thenReturn(pendingComplete);
    when(() => purchase.status).thenReturn(status);
    when(() => purchase.error).thenReturn(null);
    return purchase;
  }

  group('AskNowProvider product switch (asknow10q, ₹100, 10 questions)', () {
    test(
      'packProductId is asknow10q — the ONE source of truth every caller '
      'reads, never asknow8q',
      () {
        expect(AskNowProvider.packProductId, 'asknow10q');
      },
    );

    test(
      'queryPackProduct returns the resolved ProductDetails for the pack '
      'product id',
      () async {
        final iap = _MockInAppPurchase();
        final details = _MockProductDetails();
        final response = _MockProductDetailsResponse();
        when(() => response.productDetails).thenReturn([details]);
        when(
          () => iap.queryProductDetails({AskNowProvider.packProductId}),
        ).thenAnswer((_) async => response);
        final provider = AskNowProvider(billing: iap);

        final result = await provider.queryPackProduct(
          AskNowProvider.packProductId,
        );

        expect(result, same(details));
      },
    );

    test(
      'queryPackProduct returns null (never throws) when the product is '
      'unresolvable — callers fall back to static copy',
      () async {
        final iap = _MockInAppPurchase();
        final response = _MockProductDetailsResponse();
        when(() => response.productDetails).thenReturn([]);
        when(() => iap.queryProductDetails(any())).thenAnswer((_) async => response);
        final provider = AskNowProvider(billing: iap);

        final result = await provider.queryPackProduct('asknow10q');

        expect(result, isNull);
      },
    );
  });

  group('AskNowProvider.startGooglePlayPackPurchase (P0 guard logic)', () {
    late _MockInAppPurchase iap;
    late _MockHttpClient http_;
    late AskNowProvider provider;
    late StreamController<List<PurchaseDetails>> purchaseController;

    setUp(() {
      iap = _MockInAppPurchase();
      http_ = _MockHttpClient();
      purchaseController = StreamController<List<PurchaseDetails>>.broadcast();
      when(() => iap.purchaseStream).thenAnswer((_) => purchaseController.stream);
      when(() => iap.restorePurchases()).thenAnswer((_) async {});
      provider = AskNowProvider(billing: iap, httpClient: http_);
    });

    tearDown(() async {
      provider.dispose();
      await purchaseController.close();
    });

    test('product not found -> sets error, never starts a purchase', () async {
      final response = _MockProductDetailsResponse();
      when(() => response.productDetails).thenReturn([]);
      when(() => iap.queryProductDetails(any())).thenAnswer((_) async => response);

      await provider.startGooglePlayPackPurchase(userId: 1, productId: 'asknow10q');

      expect(provider.lastErrorMessage, 'Product not found');
      verifyNever(
        () => iap.buyConsumable(
          purchaseParam: any(named: 'purchaseParam'),
          autoConsume: any(named: 'autoConsume'),
        ),
      );
    });

    test(
      '✓ P0 fix — a started purchase requests autoConsume: false, never '
      'true (the exact defect this release gate exists to close)',
      () async {
        final details = _MockProductDetails();
        final response = _MockProductDetailsResponse();
        when(() => response.productDetails).thenReturn([details]);
        when(() => iap.queryProductDetails(any())).thenAnswer((_) async => response);
        when(
          () => iap.buyConsumable(
            purchaseParam: any(named: 'purchaseParam'),
            autoConsume: any(named: 'autoConsume'),
          ),
        ).thenAnswer((_) async => true);

        await provider.startGooglePlayPackPurchase(userId: 1, productId: 'asknow10q');

        final captured = verify(
          () => iap.buyConsumable(
            purchaseParam: captureAny(named: 'purchaseParam'),
            autoConsume: captureAny(named: 'autoConsume'),
          ),
        ).captured;
        expect(captured[1], isFalse); // autoConsume
      },
    );
  });

  group('AskNowProvider purchase-stream handling', () {
    late _MockInAppPurchase iap;
    late _MockHttpClient http_;
    late AskNowProvider provider;
    late StreamController<List<PurchaseDetails>> purchaseController;

    setUp(() async {
      iap = _MockInAppPurchase();
      http_ = _MockHttpClient();
      purchaseController = StreamController<List<PurchaseDetails>>.broadcast();

      when(() => iap.purchaseStream).thenAnswer((_) => purchaseController.stream);
      when(() => iap.restorePurchases()).thenAnswer((_) async {});
      when(() => iap.completePurchase(any())).thenAnswer((_) async {});

      final details = _MockProductDetails();
      final response = _MockProductDetailsResponse();
      when(() => response.productDetails).thenReturn([details]);
      when(() => iap.queryProductDetails(any())).thenAnswer((_) async => response);
      when(
        () => iap.buyConsumable(
          purchaseParam: any(named: 'purchaseParam'),
          autoConsume: any(named: 'autoConsume'),
        ),
      ).thenAnswer((_) async => true);

      provider = AskNowProvider(billing: iap, httpClient: http_);
      provider.initBilling();
    });

    tearDown(() async {
      provider.dispose();
      await purchaseController.close();
    });

    test(
      '✓ successful verification: credits 10 tokens (asknow10q pack), '
      'acknowledges, consumes, clears pending state, no error',
      () async {
        when(
          () => http_.post(any(), headers: any(named: 'headers'), body: any(named: 'body')),
        ).thenAnswer((_) async => http.Response('{"ok":true}', 200));

        await provider.startGooglePlayPackPurchase(userId: 42, productId: 'asknow10q');
        purchaseController.add([purchaseFor('tok-success')]);
        await pumpEventQueue();

        expect(provider.remainingTokens, 10);
        expect(provider.hasActivePack, isTrue);
        expect(provider.statusLoaded, isTrue);
        expect(provider.lastErrorMessage, isNull);
        verify(() => iap.completePurchase(any())).called(1);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('asknow_pending_user_id_v1'), isNull);
      },
    );

    test(
      '✓ backend verification failure (non-2xx): does NOT acknowledge or '
      'consume, tokens NOT credited, pending record kept for retry',
      () async {
        when(
          () => http_.post(any(), headers: any(named: 'headers'), body: any(named: 'body')),
        ).thenAnswer((_) async => http.Response('server error', 500));

        await provider.startGooglePlayPackPurchase(userId: 42, productId: 'asknow10q');
        purchaseController.add([purchaseFor('tok-fail')]);
        await pumpEventQueue();

        expect(provider.remainingTokens, 0);
        expect(provider.hasActivePack, isFalse);
        expect(provider.lastErrorMessage, 'Verification failed');
        verifyNever(() => iap.completePurchase(any()));

        // Pending record survives — this is what makes the purchase
        // recoverable instead of silently lost.
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('asknow_pending_user_id_v1'), 42);
      },
    );

    test(
      '✓ network-loss after successful payment: an exception thrown by the '
      'HTTP call is caught — no crash out of the purchaseStream listener, '
      'nothing consumed, tokens NOT credited',
      () async {
        when(
          () => http_.post(any(), headers: any(named: 'headers'), body: any(named: 'body')),
        ).thenThrow(Exception('Connection reset by peer'));

        await provider.startGooglePlayPackPurchase(userId: 42, productId: 'asknow10q');
        // Adding to the stream must not throw synchronously and must not
        // leave an unhandled Future error.
        expect(
          () => purchaseController.add([purchaseFor('tok-network-loss')]),
          returnsNormally,
        );
        await pumpEventQueue();

        expect(provider.remainingTokens, 0);
        expect(provider.lastErrorMessage, 'Verification failed');
        verifyNever(() => iap.completePurchase(any()));
      },
    );

    test(
      '✓ duplicate callback: the same purchase token arriving twice in one '
      'burst only calls the backend once — no double credit',
      () async {
        when(
          () => http_.post(any(), headers: any(named: 'headers'), body: any(named: 'body')),
        ).thenAnswer((_) async => http.Response('{"ok":true}', 200));

        await provider.startGooglePlayPackPurchase(userId: 42, productId: 'asknow10q');
        final purchase = purchaseFor('tok-dup');
        // Same event pushed twice, back to back, before the first
        // confirmation has resolved — simulates an overlapping
        // restorePurchases() delivering the same token the live stream
        // already delivered.
        purchaseController.add([purchase]);
        purchaseController.add([purchase]);
        await pumpEventQueue();

        verify(
          () => http_.post(any(), headers: any(named: 'headers'), body: any(named: 'body')),
        ).called(1);
        expect(provider.remainingTokens, 10); // credited exactly once
      },
    );

    test('pending purchase status sets isLoading, no HTTP call', () async {
      purchaseController.add([purchaseFor('tok-pending', status: PurchaseStatus.pending)]);
      await pumpEventQueue();

      expect(provider.isLoading, isTrue);
      verifyNever(
        () => http_.post(any(), headers: any(named: 'headers'), body: any(named: 'body')),
      );
    });

    test('cancelled purchase sets "Payment cancelled", no HTTP call', () async {
      purchaseController.add([purchaseFor('tok-cancel', status: PurchaseStatus.canceled)]);
      await pumpEventQueue();

      expect(provider.isLoading, isFalse);
      expect(provider.lastErrorMessage, 'Payment cancelled');
      verifyNever(
        () => http_.post(any(), headers: any(named: 'headers'), body: any(named: 'body')),
      );
    });

    test('errored purchase surfaces the plugin error message, no HTTP call', () async {
      final purchase = purchaseFor('tok-error', status: PurchaseStatus.error);
      when(() => purchase.error).thenReturn(
        IAPError(source: 'test', code: 'boom', message: 'Something broke'),
      );
      purchaseController.add([purchase]);
      await pumpEventQueue();

      expect(provider.isLoading, isFalse);
      expect(provider.lastErrorMessage, 'Something broke');
      verifyNever(
        () => http_.post(any(), headers: any(named: 'headers'), body: any(named: 'body')),
      );
    });

    test(
      '✓ retryPendingAskNowPurchase() re-queries Play; the redelivered '
      'purchase is verified using the SAME token',
      () async {
        when(
          () => http_.post(any(), headers: any(named: 'headers'), body: any(named: 'body')),
        ).thenAnswer((_) async => http.Response('server error', 500));
        await provider.startGooglePlayPackPurchase(userId: 42, productId: 'asknow10q');
        purchaseController.add([purchaseFor('tok-retry')]);
        await pumpEventQueue();
        expect(provider.lastErrorMessage, 'Verification failed');

        // Backend recovers.
        when(
          () => http_.post(any(), headers: any(named: 'headers'), body: any(named: 'body')),
        ).thenAnswer((_) async => http.Response('{"ok":true}', 200));

        await provider.retryPendingAskNowPurchase();
        verify(() => iap.restorePurchases()).called(greaterThanOrEqualTo(1));

        purchaseController.add(
          [purchaseFor('tok-retry', status: PurchaseStatus.restored)],
        );
        await pumpEventQueue();

        expect(provider.remainingTokens, 10);
        expect(provider.lastErrorMessage, isNull);
      },
    );

    test(
      '✓ app restart recovery: a fresh provider instance recovers the '
      'pending user id from persisted storage and credits tokens exactly '
      'once — the exact scenario the original defect could never recover '
      'from',
      () async {
        // "Previous session": starts a purchase; the app then "crashes"
        // before any purchase event is delivered to this instance.
        await provider.startGooglePlayPackPurchase(userId: 99, productId: 'asknow10q');

        // "New app session": a brand-new provider instance, backed by the
        // same (mocked) SharedPreferences store — nothing re-opens the
        // pack sheet, nothing calls startGooglePlayPackPurchase() again.
        final freshIap = _MockInAppPurchase();
        final freshHttp = _MockHttpClient();
        final freshController = StreamController<List<PurchaseDetails>>.broadcast();
        when(() => freshIap.purchaseStream).thenAnswer((_) => freshController.stream);
        when(() => freshIap.restorePurchases()).thenAnswer((_) async {});
        when(() => freshIap.completePurchase(any())).thenAnswer((_) async {});
        when(
          () => freshHttp.post(any(), headers: any(named: 'headers'), body: any(named: 'body')),
        ).thenAnswer((_) async => http.Response('{"ok":true}', 200));

        final freshProvider = AskNowProvider(billing: freshIap, httpClient: freshHttp);
        freshProvider.initBilling(); // exactly what main.dart does at launch

        freshController.add(
          [purchaseFor('tok-restart', status: PurchaseStatus.restored)],
        );
        await pumpEventQueue();

        expect(freshProvider.remainingTokens, 10);
        expect(freshProvider.hasActivePack, isTrue);
        verify(() => freshIap.completePurchase(any())).called(1);
        final captured = verify(
          () => freshHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: captureAny(named: 'body'),
          ),
        ).captured;
        expect((captured.single as String), contains('"user_id":99'));

        freshProvider.dispose();
        await freshController.close();
      },
    );
  });

  group(
    'AskNowProvider (P0 release-gate — network timeout hardening)',
    () {
      late _MockInAppPurchase iap;
      late _MockHttpClient http_;
      late AskNowProvider provider;
      late StreamController<List<PurchaseDetails>> purchaseController;

      setUp(() {
        iap = _MockInAppPurchase();
        http_ = _MockHttpClient();
        purchaseController = StreamController<List<PurchaseDetails>>.broadcast();
        when(() => iap.purchaseStream).thenAnswer((_) => purchaseController.stream);
        when(() => iap.restorePurchases()).thenAnswer((_) async {});

        final details = _MockProductDetails();
        final response = _MockProductDetailsResponse();
        when(() => response.productDetails).thenReturn([details]);
        when(() => iap.queryProductDetails(any())).thenAnswer((_) async => response);
        when(
          () => iap.buyConsumable(
            purchaseParam: any(named: 'purchaseParam'),
            autoConsume: any(named: 'autoConsume'),
          ),
        ).thenAnswer((_) async => true);

        provider = AskNowProvider(billing: iap, httpClient: http_);
        provider.initBilling();
      });

      tearDown(() async {
        provider.dispose();
        await purchaseController.close();
      });

      test(
        'a chat-pack verify request that times out is caught exactly like '
        'the existing generic-network-failure case: isLoading resets, '
        'nothing is acknowledged/consumed, tokens are NOT credited',
        () async {
          when(
            () => http_.post(any(), headers: any(named: 'headers'), body: any(named: 'body')),
          ).thenThrow(TimeoutException('request timed out'));
          when(() => iap.completePurchase(any())).thenAnswer((_) async {});

          await provider.startGooglePlayPackPurchase(userId: 42, productId: 'asknow10q');
          purchaseController.add([purchaseFor('tok-timeout')]);
          await pumpEventQueue();

          expect(provider.isLoading, isFalse);
          expect(provider.lastErrorMessage, 'Verification failed');
          expect(provider.remainingTokens, 0);
          expect(provider.hasActivePack, isFalse);
          verifyNever(() => iap.completePurchase(any()));

          // Requirement 7 — the pending record survives a timeout exactly
          // like it survives any other network failure, so a retry can
          // still find and re-verify this same purchase.
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getInt('asknow_pending_user_id_v1'), 42);
        },
      );

      test(
        'askFreeOrFromTokens: a free-question request that times out exits '
        'isLoading and surfaces an error, exactly as any other network '
        'failure already does — no new code path, no stuck spinner',
        () async {
          provider.statusLoaded = true;
          provider.freeAvailable = true;
          when(
            () => http_.post(any(), headers: any(named: 'headers'), body: any(named: 'body')),
          ).thenThrow(TimeoutException('request timed out'));

          await provider.askFreeOrFromTokens(
            question: 'What does my chart say?',
            profile: const {},
            userId: 7,
          );

          expect(provider.isLoading, isFalse);
          expect(provider.lastErrorMessage, isNotNull);
          expect(provider.pendingAnswer, isNull);
        },
      );

      test(
        'askFreeOrFromTokens: a paid-pack question that times out also '
        'exits isLoading and surfaces an error, without crediting/'
        'debiting tokens differently than any other failure would',
        () async {
          provider.statusLoaded = true;
          provider.freeAvailable = false;
          provider.hasActivePack = true;
          provider.remainingTokens = 3;
          when(
            () => http_.post(any(), headers: any(named: 'headers'), body: any(named: 'body')),
          ).thenThrow(TimeoutException('request timed out'));

          await provider.askFreeOrFromTokens(
            question: 'What does my chart say?',
            profile: const {},
            userId: 7,
          );

          expect(provider.isLoading, isFalse);
          expect(provider.lastErrorMessage, isNotNull);
          // Untouched by a failed attempt — the backend never confirmed
          // consumption, so the local count must not silently drop.
          expect(provider.remainingTokens, 3);
        },
      );

      test(
        '✓ successful requests behave exactly as before this fix: '
        'askFreeOrFromTokens still resolves the real answer and resets '
        'isLoading on a normal 2xx response',
        () async {
          provider.statusLoaded = true;
          provider.freeAvailable = true;
          when(
            () => http_.post(any(), headers: any(named: 'headers'), body: any(named: 'body')),
          ).thenAnswer(
            (invocation) async {
              final uri = invocation.positionalArguments[0] as Uri;
              if (uri.path.contains('/status')) {
                return http.Response(
                  '{"free_available":true,"free_used_today":false,"has_active_pack":false,"remaining_tokens":0}',
                  200,
                );
              }
              return http.Response(
                '{"success":true,"answer":"Your career looks strong this month.","remaining_tokens":0}',
                200,
              );
            },
          );

          await provider.askFreeOrFromTokens(
            question: 'What does my chart say?',
            profile: const {},
            userId: 7,
          );

          expect(provider.isLoading, isFalse);
          expect(provider.lastErrorMessage, isNull);
          expect(provider.pendingAnswer, 'Your career looks strong this month.');
        },
      );
    },
  );
}
