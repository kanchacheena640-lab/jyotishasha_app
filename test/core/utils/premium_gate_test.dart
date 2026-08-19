import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/models/asknow/asknow_contracts.dart';
import 'package:jyotishasha_app/core/models/reports/report_contracts.dart';
import 'package:jyotishasha_app/core/repositories/billing_repository.dart';
import 'package:jyotishasha_app/core/state/subscription_provider.dart';
import 'package:jyotishasha_app/core/utils/premium_gate.dart';

class _FakeBillingRepository implements BillingRepository {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ChatPackProduct?> getProduct(String productId) async => null;

  @override
  Future<void> purchaseConsumable(ChatPackProduct product) async {}

  @override
  Future<void> purchaseSubscription(ChatPackProduct product) async {}

  @override
  Future<void> restorePurchases() async {}

  @override
  Stream<ReportPurchaseReceipt> watchPurchases() => const Stream.empty();

  @override
  Future<void> completePurchase(ReportPurchaseReceipt receipt) async {}
}

/// Manual Trial Activation — proves premium sections stay correctly
/// locked BEFORE activation even though `trial_available == true`, and
/// unlock via the pre-existing, unmodified `membership_state` check the
/// instant `membership_state` becomes `TRIAL` after activation. This
/// gate's own logic was never touched by this task -- these tests
/// confirm `trial_available` never leaks into an access decision.
void main() {
  Future<BuildContext> pump(
    WidgetTester tester,
    Map<String, dynamic>? data,
  ) async {
    late BuildContext capturedContext;
    final provider = SubscriptionProvider(billing: _FakeBillingRepository())
      ..subscriptionData = data;

    await tester.pumpWidget(
      ChangeNotifierProvider<SubscriptionProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return capturedContext;
  }

  group('hasActiveSubscription (premium_gate.dart)', () {
    testWidgets(
      'stays locked before activation: trial_available == true but '
      'membership_state == NONE',
      (tester) async {
        final context = await pump(tester, {
          'membership_state': 'NONE',
          'trial_available': true,
        });

        expect(hasActiveSubscription(context), isFalse);
      },
    );

    testWidgets(
      'unlocks the instant membership_state becomes TRIAL, exactly like '
      'before this task -- unaffected by trial_available',
      (tester) async {
        final context = await pump(tester, {
          'membership_state': 'TRIAL',
          'trial_available': false,
        });

        expect(hasActiveSubscription(context), isTrue);
      },
    );

    testWidgets('unlocks for ACTIVE, exactly as before', (tester) async {
      final context = await pump(tester, {
        'membership_state': 'ACTIVE',
        'trial_available': false,
      });

      expect(hasActiveSubscription(context), isTrue);
    });

    testWidgets('unlocks for GRACE_PERIOD, exactly as before', (
      tester,
    ) async {
      final context = await pump(tester, {
        'membership_state': 'GRACE_PERIOD',
        'trial_available': false,
      });

      expect(hasActiveSubscription(context), isTrue);
    });

    testWidgets(
      'stays locked for EXPIRED even if trial_available were somehow '
      'true (defensive -- never a real backend combination)',
      (tester) async {
        final context = await pump(tester, {
          'membership_state': 'EXPIRED',
          'trial_available': true,
        });

        expect(hasActiveSubscription(context), isFalse);
      },
    );

    testWidgets(
      'stays locked before subscriptionData has ever loaded (null)',
      (tester) async {
        final context = await pump(tester, null);

        expect(hasActiveSubscription(context), isFalse);
      },
    );
  });
}
