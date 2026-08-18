import 'package:flutter_test/flutter_test.dart';

import '../helpers/source_characterization.dart';

void main() {
  group('purchase and commerce characterization', () {
    test('backend status controls AskNow entitlement state', () {
      final source = readProjectSource('lib/core/state/asknow_provider.dart');

      expectMarkersInOrder(source, const [
        'freeAvailable = status["free_available"] == true;',
        'freeUsedToday = status["free_used_today"] == true;',
        'int.tryParse(status["remaining_tokens"]?.toString() ?? "0") ?? 0;',
        'hasActivePack = remainingTokens > 0;',
        'statusLoaded = true;',
        'notifyListeners();',
      ]);
    });

    test('AskNow purchase status matrix remains fixed', () {
      final source = readProjectSource('lib/core/state/asknow_provider.dart');

      expectMarkersInOrder(source, const [
        'case PurchaseStatus.pending:',
        'isLoading = true;',
        'case PurchaseStatus.purchased:',
        'case PurchaseStatus.restored:',
        '_verifyAndActivate(purchase);',
        'case PurchaseStatus.canceled:',
        'lastErrorMessage = "Payment cancelled";',
        'case PurchaseStatus.error:',
      ]);
    });

    // Release-gate fix (P0) closed the one real defect this
    // characterization test used to lock in: `autoConsume: true` let Play
    // consume a pack purchase before `/api/chatpack/verify` ever ran, so
    // a network/backend failure meant the customer paid and got nothing,
    // with no recovery path. AskNow now mirrors the same
    // verify-then-consume shape ReportPurchaseProvider's own section
    // below already characterizes for Paid Reports — this test now locks
    // in THAT architecture, not the unsafe one it replaced.
    test('AskNow lookup, verification payload, and completion stay fixed', () {
      final source = readProjectSource('lib/core/state/asknow_provider.dart');

      expect(source, contains('_iap.queryProductDetails({productId})'));
      expect(source, contains('lastErrorMessage = "Product not found"'));
      // Requirement (P0 fix) — consumption only ever happens explicitly,
      // after backend confirmation succeeds, never automatically.
      expect(
        source,
        contains('await _iap.buyConsumable(purchaseParam: param, autoConsume: false);'),
      );
      expect(
        source,
        contains('if (_confirmingTokens.contains(token)) return;'),
      );
      expectMarkersInOrder(source, const [
        '"user_id": _pendingUserId,',
        '"product_id": purchase.productID,',
        '"purchase_token": token,',
        'if (purchase.pendingCompletePurchase) {',
        'await _iap.completePurchase(purchase);',
        'await _consume(purchase);',
        'remainingTokens = 8;',
        'hasActivePack = true;',
      ]);
    });

    // Report Purchase Lifecycle Architecture (Bucket A) moved report
    // purchases off ReportPaymentPage's own page-scoped listener and
    // into a dedicated, app-global ReportPurchaseProvider -- the same
    // shape AskNow's characterization above already locks in for its
    // own domain. These two tests now characterize THAT architecture,
    // not the page-owned one it replaced.
    test('report purchases stay guarded, product-specific, and deferred-consume', () {
      final source = readProjectSource(
        'lib/core/state/report_purchase_provider.dart',
      );

      expect(source, contains('static const String _productId = "reports51"'));
      expect(source, contains('if (isProcessing) return false;'));
      expect(source, contains('if (p.productID != _productId) continue;'));
      expect(
        source,
        contains('if (_confirmingTokens.contains(token)) return;'),
      );
      // Requirement 2 -- the actual fix this architecture exists for.
      expect(
        source,
        contains('await _iap.buyConsumable(purchaseParam: param, autoConsume: false);'),
      );
      expect(source, contains('if (purchase.pendingCompletePurchase)'));
      expect(
        source,
        contains(
          'final token = purchase.verificationData.serverVerificationData;',
        ),
      );
      // Requirement 4 -- consume/acknowledge only ever follow success.
      expectMarkersInOrder(source, const [
        'if (!ok) {',
        'return;',
        '}',
        'if (purchase.pendingCompletePurchase) {',
        'await _iap.completePurchase(purchase);',
        '}',
        'await _consume(purchase);',
      ]);
    });

    test('report purchase recovery stays app-global and persisted', () {
      final providerSource = readProjectSource(
        'lib/core/state/report_purchase_provider.dart',
      );
      final mainSource = readProjectSource('lib/main.dart');
      final pageSource = readProjectSource(
        'lib/features/reports/pages/report_payment_page.dart',
      );

      // Requirement 5 -- recoverable without reopening ReportPaymentPage:
      // registered lazy:false, same shape as Subscription/AskNow above.
      expectMarkersInOrder(mainSource, const [
        'final p = ReportPurchaseProvider();',
        'p.initPurchaseListener();',
      ]);
      expect(
        providerSource,
        contains('unawaited(_iap.restorePurchases());'),
      );
      // The pending request survives process death via local persistence,
      // not in-memory widget state.
      expect(
        providerSource,
        contains('await prefs.setString(_pendingRequestPrefsKey, jsonEncode(blob));'),
      );

      // The page itself no longer owns any purchase-stream subscription.
      expect(pageSource, isNot(contains('_purchaseSub')));
      expect(
        pageSource,
        contains('widget.selectedReport["id"] == "relationship_future_report"'),
      );
      expect(pageSource, contains('product: "relationship_future_report"'));
      expect(pageSource, contains('userId: _backendUserId'));
    });

    test('startup billing probe remains availability-only', () {
      final source = normalizeWhitespace(
        readProjectSource('lib/services/play_billing_stub.dart'),
      );
      expect(
        source,
        contains(
          'static Future<void> init() async { await _iap.isAvailable(); }',
        ),
      );
    });
  });
}
