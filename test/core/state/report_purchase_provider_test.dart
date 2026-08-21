import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jyotishasha_app/core/models/profile/birth_details.dart';
import 'package:jyotishasha_app/core/models/reports/report_contracts.dart';
import 'package:jyotishasha_app/core/repositories/report_repository.dart';
import 'package:jyotishasha_app/core/state/report_purchase_provider.dart';

class _MockInAppPurchase extends Mock implements InAppPurchase {}

class _MockProductDetailsResponse extends Mock
    implements ProductDetailsResponse {}

class _MockProductDetails extends Mock implements ProductDetails {}

class _MockPurchaseDetails extends Mock implements PurchaseDetails {}

class _MockPurchaseVerificationData extends Mock
    implements PurchaseVerificationData {}

class _FakeReportRepository implements ReportRepository {
  final List<ReportGenerationRequest> requestCalls = [];
  final List<RelationshipReportRequest> relationshipCalls = [];
  bool nextOutcomeSuccess = true;
  // CANCELED Recovery Dead-End fix: lets tests drive the backend's new
  // structured error_code ("purchase_canceled" / "purchase_pending" /
  // null for an unclassified failure) through the same fake.
  String? nextOutcomeErrorCode;
  Object? nextOutcomeError;

  @override
  Future<List<ReportCatalogItem>> getCatalog({required String language}) =>
      throw UnimplementedError('not used by ReportPurchaseProvider');

  @override
  Future<ReportGenerationOutcome> requestReport(
    ReportGenerationRequest request,
  ) async {
    requestCalls.add(request);
    if (nextOutcomeError != null) throw nextOutcomeError!;
    return ReportGenerationOutcome(
      success: nextOutcomeSuccess,
      errorCode: nextOutcomeSuccess ? null : nextOutcomeErrorCode,
    );
  }

  @override
  Future<ReportGenerationOutcome> requestRelationshipReport(
    RelationshipReportRequest request,
  ) async {
    relationshipCalls.add(request);
    if (nextOutcomeError != null) throw nextOutcomeError!;
    return ReportGenerationOutcome(
      success: nextOutcomeSuccess,
      errorCode: nextOutcomeSuccess ? null : nextOutcomeErrorCode,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(
      PurchaseParam(
        productDetails: _FallbackProductDetails(),
      ),
    );
    registerFallbackValue(_FallbackPurchaseDetails());
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ReportGenerationRequest sampleRequest() => const ReportGenerationRequest(
    name: 'Test User',
    email: 'test@example.com',
    phone: '9999999999',
    product: 'career_report',
    birthDetails: BirthDetails(
      dateOfBirth: '1990-01-01',
      timeOfBirth: '10:00',
      placeOfBirth: 'Delhi',
      latitude: 28.6,
      longitude: 77.2,
    ),
    language: 'en',
  );

  group('ReportPurchaseProvider.purchaseReport (guard logic)', () {
    late _MockInAppPurchase iap;
    late _FakeReportRepository repository;
    late ReportPurchaseProvider provider;
    late StreamController<List<PurchaseDetails>> purchaseController;

    setUp(() {
      iap = _MockInAppPurchase();
      repository = _FakeReportRepository();
      purchaseController = StreamController<List<PurchaseDetails>>.broadcast();

      when(() => iap.purchaseStream).thenAnswer((_) => purchaseController.stream);
      when(() => iap.restorePurchases()).thenAnswer((_) async {});

      provider = ReportPurchaseProvider(repository: repository, billing: iap);
    });

    tearDown(() async {
      provider.dispose();
      await purchaseController.close();
    });

    test('billing unavailable -> sets billing_unavailable, never queries products', () async {
      when(() => iap.isAvailable()).thenAnswer((_) async => false);

      final started = await provider.purchaseReport(request: sampleRequest());

      expect(started, isFalse);
      expect(provider.errorMessage, 'billing_unavailable');
      expect(provider.isProcessing, isFalse);
      verifyNever(() => iap.queryProductDetails(any()));
    });

    test('product not found -> sets product_not_found, never starts a purchase', () async {
      when(() => iap.isAvailable()).thenAnswer((_) async => true);
      final response = _MockProductDetailsResponse();
      when(() => response.error).thenReturn(null);
      when(() => response.productDetails).thenReturn([]);
      when(() => iap.queryProductDetails(any())).thenAnswer((_) async => response);

      final started = await provider.purchaseReport(request: sampleRequest());

      expect(started, isFalse);
      expect(provider.errorMessage, 'product_not_found');
      verifyNever(() => iap.buyConsumable(
            purchaseParam: any(named: 'purchaseParam'),
            autoConsume: any(named: 'autoConsume'),
          ));
    });

    test('a second purchaseReport call is refused while one is already processing', () async {
      when(() => iap.isAvailable()).thenAnswer((_) async => true);
      final details = _MockProductDetails();
      final response = _MockProductDetailsResponse();
      when(() => response.error).thenReturn(null);
      when(() => response.productDetails).thenReturn([details]);
      when(() => iap.queryProductDetails(any())).thenAnswer((_) async => response);
      when(() => iap.buyConsumable(
            purchaseParam: any(named: 'purchaseParam'),
            autoConsume: any(named: 'autoConsume'),
          )).thenAnswer((_) async => true);

      final first = provider.purchaseReport(request: sampleRequest());
      // isProcessing flips true synchronously before the first await
      // yields, matching the same gate SubscriptionProvider/AskNowProvider
      // already use for their own single-purchase-at-a-time buttons.
      final second = await provider.purchaseReport(request: sampleRequest());
      await first;

      expect(second, isFalse);
      verify(() => iap.buyConsumable(
            purchaseParam: any(named: 'purchaseParam'),
            autoConsume: false,
          )).called(1);
    });

    test('a started purchase requests autoConsume: false — Requirement 2', () async {
      when(() => iap.isAvailable()).thenAnswer((_) async => true);
      final details = _MockProductDetails();
      final response = _MockProductDetailsResponse();
      when(() => response.error).thenReturn(null);
      when(() => response.productDetails).thenReturn([details]);
      when(() => iap.queryProductDetails(any())).thenAnswer((_) async => response);
      when(() => iap.buyConsumable(
            purchaseParam: any(named: 'purchaseParam'),
            autoConsume: any(named: 'autoConsume'),
          )).thenAnswer((_) async => true);

      final started = await provider.purchaseReport(request: sampleRequest());

      expect(started, isTrue);
      expect(provider.isProcessing, isTrue);
      final captured = verify(() => iap.buyConsumable(
            purchaseParam: captureAny(named: 'purchaseParam'),
            autoConsume: captureAny(named: 'autoConsume'),
          )).captured;
      expect(captured[1], isFalse); // autoConsume
    });
  });

  group('ReportPurchaseProvider purchase-stream handling', () {
    late _MockInAppPurchase iap;
    late _FakeReportRepository repository;
    late ReportPurchaseProvider provider;
    late StreamController<List<PurchaseDetails>> purchaseController;

    setUp(() async {
      iap = _MockInAppPurchase();
      repository = _FakeReportRepository();
      purchaseController = StreamController<List<PurchaseDetails>>.broadcast();

      when(() => iap.purchaseStream).thenAnswer((_) => purchaseController.stream);
      when(() => iap.restorePurchases()).thenAnswer((_) async {});
      when(() => iap.completePurchase(any())).thenAnswer((_) async {});
      when(() => iap.isAvailable()).thenAnswer((_) async => true);
      final details = _MockProductDetails();
      final response = _MockProductDetailsResponse();
      when(() => response.error).thenReturn(null);
      when(() => response.productDetails).thenReturn([details]);
      when(() => iap.queryProductDetails(any())).thenAnswer((_) async => response);
      when(() => iap.buyConsumable(
            purchaseParam: any(named: 'purchaseParam'),
            autoConsume: any(named: 'autoConsume'),
          )).thenAnswer((_) async => true);

      provider = ReportPurchaseProvider(repository: repository, billing: iap);
      provider.initPurchaseListener();
    });

    tearDown(() async {
      provider.dispose();
      await purchaseController.close();
    });

    _MockPurchaseDetails purchaseFor(String token, {bool pendingComplete = true}) {
      final purchase = _MockPurchaseDetails();
      final verification = _MockPurchaseVerificationData();
      when(() => verification.serverVerificationData).thenReturn(token);
      when(() => purchase.verificationData).thenReturn(verification);
      when(() => purchase.productID).thenReturn('reports51');
      when(() => purchase.purchaseID).thenReturn('GPA.order-$token');
      when(() => purchase.pendingCompletePurchase).thenReturn(pendingComplete);
      when(() => purchase.status).thenReturn(PurchaseStatus.purchased);
      return purchase;
    }

    test(
      '✓ successful purchase: confirms with backend, then (and only then) '
      'acknowledges, and clears the pending record',
      () async {
        repository.nextOutcomeSuccess = true;

        final started = await provider.purchaseReport(request: sampleRequest());
        expect(started, isTrue);

        final purchase = purchaseFor('tok-success');
        purchaseController.add([purchase]);
        await pumpEventQueue();

        expect(repository.requestCalls, hasLength(1));
        expect(repository.requestCalls.first.purchaseToken, 'tok-success');
        verify(() => iap.completePurchase(purchase)).called(1);
        expect(provider.successCount, 1);
        expect(provider.isProcessing, isFalse);
        expect(provider.errorMessage, isNull);

        // Requirement 6 — no duplicate order/report from this single event.
        expect(repository.requestCalls, hasLength(1));
      },
    );

    test(
      '✓ backend failure: does NOT acknowledge, leaves purchase pending, '
      'surfaces report_failed',
      () async {
        repository.nextOutcomeSuccess = false;

        await provider.purchaseReport(request: sampleRequest());
        final purchase = purchaseFor('tok-fail');
        purchaseController.add([purchase]);
        await pumpEventQueue();

        expect(repository.requestCalls, hasLength(1));
        verifyNever(() => iap.completePurchase(any()));
        expect(provider.errorMessage, 'report_failed');
        expect(provider.successCount, 0);
      },
    );

    test(
      '✓ P0 release-gate — network timeout hardening: a report-generation '
      'request that times out (TimeoutException from the underlying HTTP '
      'call, now bounded by ReportService\'s .timeout()) is caught '
      'exactly like any other repository failure — isProcessing resets, '
      'report_failed is surfaced, and critically nothing is acknowledged '
      'or consumed, so the purchase stays recoverable for a retry',
      () async {
        repository.nextOutcomeError = TimeoutException('request timed out');

        await provider.purchaseReport(request: sampleRequest());
        final purchase = purchaseFor('tok-timeout');
        purchaseController.add([purchase]);
        await pumpEventQueue();

        expect(provider.isProcessing, isFalse);
        expect(provider.errorMessage, 'report_failed');
        expect(provider.successCount, 0);
        verifyNever(() => iap.completePurchase(any()));
      },
    );

    test(
      '✓ duplicate callback: the same purchase token arriving twice in one '
      'burst only confirms with the backend once',
      () async {
        repository.nextOutcomeSuccess = true;

        await provider.purchaseReport(request: sampleRequest());
        final purchase = purchaseFor('tok-dup');
        // Same event pushed twice, back to back, before the first
        // confirmation has resolved — simulates an overlapping
        // restorePurchases() delivering the same token the live stream
        // already delivered.
        purchaseController.add([purchase]);
        purchaseController.add([purchase]);
        await pumpEventQueue();

        expect(repository.requestCalls, hasLength(1));
        verify(() => iap.completePurchase(purchase)).called(1);
      },
    );

    test(
      '✓ retry: retryPendingReportPurchase() re-queries Play and the '
      'redelivered purchase is confirmed using the SAME token',
      () async {
        repository.nextOutcomeSuccess = false;
        await provider.purchaseReport(request: sampleRequest());
        final purchase = purchaseFor('tok-retry');
        purchaseController.add([purchase]);
        await pumpEventQueue();
        expect(provider.errorMessage, 'report_failed');

        // Backend now recovers (e.g. transient failure resolved).
        repository.nextOutcomeSuccess = true;
        await provider.retryPendingReportPurchase();
        verify(() => iap.restorePurchases()).called(greaterThanOrEqualTo(1));

        // Simulate Play redelivering the same still-owned, unconsumed
        // purchase in response to restorePurchases() -- tagged `restored`.
        final redelivered = purchaseFor('tok-retry');
        when(() => redelivered.status).thenReturn(PurchaseStatus.restored);
        purchaseController.add([redelivered]);
        await pumpEventQueue();

        expect(provider.successCount, 1);
        expect(repository.requestCalls, hasLength(2)); // 1 failed + 1 retried
        expect(
          repository.requestCalls.every((r) => r.purchaseToken == 'tok-retry'),
          isTrue,
        );
      },
    );

    test(
      '✓ CANCELED (purchase_canceled): clears the pending record, does '
      'NOT acknowledge/consume, and a later redelivery of the same token '
      'finds nothing pending — proves the dead-end is actually cleared',
      () async {
        repository.nextOutcomeSuccess = false;
        repository.nextOutcomeErrorCode = 'purchase_canceled';

        await provider.purchaseReport(request: sampleRequest());
        final purchase = purchaseFor('tok-canceled');
        purchaseController.add([purchase]);
        await pumpEventQueue();

        expect(repository.requestCalls, hasLength(1));
        verifyNever(() => iap.completePurchase(any()));
        expect(provider.errorMessage, 'purchase_canceled');
        expect(provider.successCount, 0);

        // Same still-owned/unconsumed token gets redelivered (e.g. Play's
        // own next-session redelivery). Because the pending record was
        // cleared, the provider has nothing to confirm it with — it must
        // NOT call the backend again with a stale record, and must NOT
        // retroactively show report_failed/Retry for a token already
        // known to be canceled.
        final redelivered = purchaseFor('tok-canceled');
        when(() => redelivered.status).thenReturn(PurchaseStatus.restored);
        purchaseController.add([redelivered]);
        await pumpEventQueue();

        expect(repository.requestCalls, hasLength(1)); // still just 1
        expect(provider.errorMessage, 'unknown_pending_purchase');
        verifyNever(() => iap.completePurchase(any()));
      },
    );

    test(
      '✓ PENDING (purchase_pending): does NOT clear the pending record — '
      'a later retry with the SAME token can still complete the purchase',
      () async {
        repository.nextOutcomeSuccess = false;
        repository.nextOutcomeErrorCode = 'purchase_pending';

        await provider.purchaseReport(request: sampleRequest());
        final purchase = purchaseFor('tok-pending');
        purchaseController.add([purchase]);
        await pumpEventQueue();

        expect(repository.requestCalls, hasLength(1));
        verifyNever(() => iap.completePurchase(any()));
        expect(provider.errorMessage, 'purchase_pending');
        expect(provider.successCount, 0);

        // Google finishes clearing the purchase; retry now succeeds,
        // using the SAME token — proves the pending record survived.
        repository.nextOutcomeSuccess = true;
        await provider.retryPendingReportPurchase();
        final redelivered = purchaseFor('tok-pending');
        when(() => redelivered.status).thenReturn(PurchaseStatus.restored);
        purchaseController.add([redelivered]);
        await pumpEventQueue();

        expect(provider.successCount, 1);
        expect(repository.requestCalls, hasLength(2));
        expect(
          repository.requestCalls.every((r) => r.purchaseToken == 'tok-pending'),
          isTrue,
        );
        verify(() => iap.completePurchase(redelivered)).called(1);
      },
    );

    test(
      '✓ unclassified failure (network/5xx/timeout — no error_code): '
      'behaves exactly like today — report_failed, pending record kept',
      () async {
        repository.nextOutcomeSuccess = false;
        repository.nextOutcomeErrorCode = null;

        await provider.purchaseReport(request: sampleRequest());
        final purchase = purchaseFor('tok-network');
        purchaseController.add([purchase]);
        await pumpEventQueue();

        expect(provider.errorMessage, 'report_failed');
        verifyNever(() => iap.completePurchase(any()));

        // Pending record must survive — same guarantee the pre-existing
        // 'retry' test already exercises for this exact scenario.
        repository.nextOutcomeSuccess = true;
        await provider.retryPendingReportPurchase();
        final redelivered = purchaseFor('tok-network');
        when(() => redelivered.status).thenReturn(PurchaseStatus.restored);
        purchaseController.add([redelivered]);
        await pumpEventQueue();

        expect(provider.successCount, 1);
        expect(repository.requestCalls, hasLength(2));
      },
    );

    test(
      '✓ app restart recovery: a fresh provider instance (simulating a new '
      'app session) recovers a purchase from a persisted pending record '
      'written by a previous instance, without ReportPaymentPage ever '
      'being reopened',
      () async {
        // "Previous session": starts a purchase, then the app "crashes" —
        // no purchase event is ever delivered to this instance, and (as in
        // a real crash) nothing cleanly disposes it either; `tearDown`
        // disposes the original `provider` once, same as every other test.
        await provider.purchaseReport(request: sampleRequest());

        // "New app session": a brand-new provider instance, backed by the
        // same (mocked) SharedPreferences store — nothing re-opens
        // ReportPaymentPage, nothing calls purchaseReport() again.
        final freshIap = _MockInAppPurchase();
        final freshController = StreamController<List<PurchaseDetails>>.broadcast();
        when(() => freshIap.purchaseStream).thenAnswer((_) => freshController.stream);
        when(() => freshIap.restorePurchases()).thenAnswer((_) async {});
        when(() => freshIap.completePurchase(any())).thenAnswer((_) async {});

        final freshRepository = _FakeReportRepository()..nextOutcomeSuccess = true;
        final freshProvider = ReportPurchaseProvider(
          repository: freshRepository,
          billing: freshIap,
        );
        freshProvider.initPurchaseListener(); // exactly what main.dart does at launch

        final restored = purchaseFor('tok-restart');
        when(() => restored.status).thenReturn(PurchaseStatus.restored);
        freshController.add([restored]);
        await pumpEventQueue();

        expect(freshRepository.requestCalls, hasLength(1));
        expect(freshRepository.requestCalls.first.purchaseToken, 'tok-restart');
        expect(freshProvider.successCount, 1);

        freshProvider.dispose();
        await freshController.close();
      },
    );
  });
}

class _FallbackProductDetails extends Fake implements ProductDetails {}

class _FallbackPurchaseDetails extends Fake implements PurchaseDetails {}
