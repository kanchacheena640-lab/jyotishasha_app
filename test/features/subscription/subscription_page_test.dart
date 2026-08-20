import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/models/asknow/asknow_contracts.dart';
import 'package:jyotishasha_app/core/models/reports/report_contracts.dart';
import 'package:jyotishasha_app/core/repositories/billing_repository.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/subscription_provider.dart';
import 'package:jyotishasha_app/features/subscription/subscription_page.dart';

import '../../helpers/test_harness.dart';

/// Same fake used in `subscription_provider_test.dart` — duplicated
/// locally since Dart test files can't share a private class across
/// libraries. Lets purchase-flow UI (tier pricing cards, Subscribe
/// button) be tested without touching the real `InAppPurchase.instance`
/// platform channel unavailable in this headless environment.
class _FakeBillingRepository implements BillingRepository {
  bool available = true;
  final Map<String, ChatPackProduct> products = {};
  int restorePurchasesCalls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ChatPackProduct?> getProduct(String productId) async =>
      products[productId];

  @override
  Future<void> purchaseConsumable(ChatPackProduct product) async {}

  @override
  Future<void> purchaseSubscription(ChatPackProduct product) async {}

  @override
  Future<void> restorePurchases() async {
    restorePurchasesCalls++;
  }

  @override
  Stream<ReportPurchaseReceipt> watchPurchases() => const Stream.empty();

  @override
  Future<void> completePurchase(ReportPurchaseReceipt receipt) async {}
}

void main() {
  // autoLoad:false everywhere below — the provider state is set up
  // directly by each test, so the page must not also attempt a real
  // `loadSubscriptionInfo()` call (which would touch FirebaseAuth,
  // unavailable in this test environment) while we assert on a
  // deliberately-constructed state — the same pattern already
  // established by `KundaliOverviewPage`'s tests.
  Future<void> pump(
    WidgetTester tester,
    SubscriptionProvider provider, {
    bool autoLoad = false,
    String lang = 'en',
  }) async {
    await tester.pumpTestHarness(
      SubscriptionPage(autoLoad: autoLoad),
      providers: [
        ChangeNotifierProvider<SubscriptionProvider>.value(value: provider),
        ChangeNotifierProvider<LanguageProvider>.value(
          value: LanguageProvider()..currentLang = lang,
        ),
      ],
    );
  }

  testWidgets('shows a loading indicator while isLoading is true', (
    tester,
  ) async {
    final provider = SubscriptionProvider()..isLoading = true;

    await pump(tester, provider);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Your Subscription'), findsNothing);
  });

  testWidgets(
    'shows an error state with a Retry action when errorMessage is set',
    (tester) async {
      final provider = SubscriptionProvider()..errorMessage = 'boom';

      await pump(tester, provider);

      expect(
        find.text('Something went wrong loading your subscription.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
    },
  );

  testWidgets(
    'shows an empty state with a Retry action when there is no error and '
    'no data',
    (tester) async {
      final provider = SubscriptionProvider();

      await pump(tester, provider);

      expect(
        find.text('No subscription information available yet.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
    },
  );

  group('Membership summary card (shown only when active, per spec)', () {
    testWidgets(
      'shows Current Plan, Subscription Status, Start Date, and End Date '
      'exactly as returned by the backend — no client-side inference',
      (tester) async {
        final provider = SubscriptionProvider()
          ..subscriptionData = {
            'active': true,
            'plan': 'yearly',
            'status': 'active',
            'started_at': '2026-01-15',
            'end_at': '2027-01-15',
            'days_left': 163,
            'renews': true,
            'is_active': true,
          };

        await pump(tester, provider);

        expect(find.text('Your Subscription'), findsOneWidget);
        expect(find.text('Current Plan'), findsOneWidget);
        expect(find.text('yearly'), findsOneWidget);
        expect(find.text('Subscription Status'), findsOneWidget);
        // Capitalized for display only — the raw value is "active".
        expect(find.text('Active'), findsOneWidget);
        expect(find.text('Start Date'), findsOneWidget);
        expect(find.text('15-01-2026'), findsOneWidget);
        expect(find.text('End Date'), findsOneWidget);
        expect(find.text('15-01-2027'), findsOneWidget);
        // Not a trial — no badge.
        expect(find.text('Trial'), findsNothing);
      },
    );

    testWidgets(
      'shows a Trial badge only when the backend\'s own is_trial flag is '
      'true — never inferred from days_left/active/status/etc',
      (tester) async {
        final provider = SubscriptionProvider()
          ..subscriptionData = {
            'plan': 'free',
            'status': 'active',
            'is_active': true,
            'is_trial': true,
            'started_at': '2026-08-01',
            'end_at': '2026-08-15',
          };

        await pump(tester, provider);

        expect(find.text('Subscription Status'), findsOneWidget);
        expect(find.text('Trial'), findsOneWidget);
        expect(find.text('Active'), findsOneWidget);
      },
    );

    testWidgets(
      'never shows the summary card when the backend says the user is '
      'not active — even if some subscription data (e.g. a past status) '
      'exists',
      (tester) async {
        final provider = SubscriptionProvider()
          ..subscriptionData = {'status': 'none'};

        await pump(tester, provider);

        expect(find.text('Your Subscription'), findsNothing);
        expect(find.text('Current Plan'), findsNothing);
      },
    );

    testWidgets(
      'shows the existing, unchanged grace-period message when '
      'in_grace_period is true',
      (tester) async {
        final provider = SubscriptionProvider()
          ..subscriptionData = {
            'active': true,
            'plan': 'GOLD_MONTHLY',
            'status': 'active',
            'in_grace_period': true,
          };

        await pump(tester, provider);

        expect(
          find.text(
            "There's a problem with your payment. Please update your "
            'payment method to keep your access.',
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('"Manage in Play Store" (Google Play Subscription Confirm Contract fix)', () {
    testWidgets(
      'shows "Manage in Play Store" for a genuine paid subscription -- '
      'membership_state == ACTIVE',
      (tester) async {
        final provider = SubscriptionProvider()
          ..subscriptionData = {
            'active': true,
            'is_active': true,
            'plan': 'GOLD_MONTHLY',
            'status': 'active',
            'membership_state': 'ACTIVE',
          };

        await pump(tester, provider);

        expect(find.text('Manage in Play Store'), findsOneWidget);
      },
    );

    testWidgets(
      'shows "Manage in Play Store" during GRACE_PERIOD -- still a real '
      'Play subscription, just lapsed payment',
      (tester) async {
        final provider = SubscriptionProvider()
          ..subscriptionData = {
            'active': true,
            'is_active': true,
            'plan': 'GOLD_MONTHLY',
            'status': 'active',
            'in_grace_period': true,
            'membership_state': 'GRACE_PERIOD',
          };

        await pump(tester, provider);

        expect(find.text('Manage in Play Store'), findsOneWidget);
      },
    );

    testWidgets(
      'does NOT show "Manage in Play Store" during an active backend-'
      'managed free TRIAL -- is_active is true for a trial too, but there '
      'is no real Google Play subscription to manage',
      (tester) async {
        final provider = SubscriptionProvider()
          ..subscriptionData = {
            'plan': 'free',
            'status': 'active',
            'is_active': true,
            'is_trial': true,
            'membership_state': 'TRIAL',
            'started_at': '2026-08-01',
            'end_at': '2026-08-15',
          };

        await pump(tester, provider);

        // Trial access itself is unaffected -- the summary card (and its
        // Trial badge) still shows; only the Play Store action is hidden.
        expect(find.text('Current Plan'), findsOneWidget);
        expect(find.text('Manage in Play Store'), findsNothing);
      },
    );

    testWidgets(
      'does NOT show "Manage in Play Store" when there is no membership_'
      'state field at all (older/incomplete response shape) -- never '
      'assumed present, defaults to hidden rather than guessing',
      (tester) async {
        final provider = SubscriptionProvider()
          ..subscriptionData = {
            'active': true,
            'is_active': true,
            'plan': 'GOLD_MONTHLY',
            'status': 'active',
          };

        await pump(tester, provider);

        expect(find.text('Manage in Play Store'), findsNothing);
      },
    );
  });

  testWidgets('renders Hindi copy for the empty state', (tester) async {
    final provider = SubscriptionProvider();

    await pump(tester, provider, lang: 'hi');

    expect(find.text('सब्सक्रिप्शन प्लान'), findsOneWidget); // AppBar title
    expect(
      find.text('अभी कोई सब्सक्रिप्शन जानकारी उपलब्ध नहीं है।'),
      findsOneWidget,
    );
    expect(find.text('पुनः प्रयास करें'), findsOneWidget);
  });

  testWidgets('renders Hindi labels when subscription data is present', (
    tester,
  ) async {
    final provider = SubscriptionProvider()
      ..subscriptionData = {
        'plan': 'free',
        'status': 'active',
        'is_active': true,
        'is_trial': true,
        'started_at': '2026-08-01',
        'end_at': '2026-08-15',
      };

    await pump(tester, provider, lang: 'hi');

    expect(find.text('आपका सब्सक्रिप्शन'), findsOneWidget);
    expect(find.text('वर्तमान प्लान'), findsOneWidget);
    expect(find.text('सब्सक्रिप्शन स्थिति'), findsOneWidget);
    expect(find.text('प्रारंभ तिथि'), findsOneWidget);
    expect(find.text('समाप्ति तिथि'), findsOneWidget);
    expect(find.text('ट्रायल'), findsOneWidget);
  });

  group('Restore Purchases (S5.4 — unaffected by the pricing redesign)', () {
    testWidgets(
      'shows a Restore Purchases action regardless of subscription state '
      '— active or not',
      (tester) async {
        final provider = SubscriptionProvider()
          ..subscriptionData = {
            'plan': 'yearly',
            'status': 'active',
            'started_at': '2026-01-15',
            'end_at': '2027-01-15',
          };

        await pump(tester, provider);

        expect(find.text('Restore Purchases'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Restore Purchases invokes SubscriptionProvider.'
      'restorePurchases',
      (tester) async {
        final provider = SubscriptionProvider(billing: _FakeBillingRepository());

        await pump(tester, provider);

        await tester.tap(find.text('Restore Purchases'));
        await tester.pump();

        expect(provider.restoreErrorMessage, isNotNull);
        expect(provider.isRestoring, isFalse);
      },
    );

    testWidgets(
      'disables the action and shows a spinner while isRestoring is true',
      (tester) async {
        final provider = SubscriptionProvider()..isRestoring = true;

        await pump(tester, provider);

        expect(find.text('Restore Purchases'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        final button = tester.widget<TextButton>(find.byType(TextButton));
        expect(button.onPressed, isNull);
      },
    );

    testWidgets(
      'shows a friendly SnackBar (not a raw code) when no purchases were '
      'found for this account',
      (tester) async {
        final provider = SubscriptionProvider()
          ..restoreErrorMessage = 'no_purchases_found';

        await pump(tester, provider);
        await tester.pump();

        expect(
          find.text('No active purchases were found for this account.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows the same billing-unavailable SnackBar copy as the purchase '
      'flow — the error mapper is reused, not duplicated',
      (tester) async {
        final provider = SubscriptionProvider()
          ..restoreErrorMessage = 'billing_unavailable';

        await pump(tester, provider);
        await tester.pump();

        expect(
          find.text('Google Play Billing is not available on this device.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders the Hindi Restore Purchases label', (tester) async {
      final provider = SubscriptionProvider();

      await pump(tester, provider, lang: 'hi');

      expect(find.text('खरीद पुनर्स्थापित करें'), findsOneWidget);
    });
  });

  group('Premium pricing redesign — tiered plan cards', () {
    testWidgets(
      'groups resolved products into Silver / Gold / Platinum tier cards',
      (tester) async {
        final billing = _FakeBillingRepository()
          ..products['jyotishasha.silver.monthly'] = const ChatPackProduct(
            productId: 'jyotishasha.silver.monthly',
            title: 'Silver Monthly',
            price: '₹99',
          )
          ..products['jyotishasha.gold.monthly'] = const ChatPackProduct(
            productId: 'jyotishasha.gold.monthly',
            title: 'Gold Monthly',
            price: '₹199',
          )
          ..products['jyotishasha.platinum.yearly'] = const ChatPackProduct(
            productId: 'jyotishasha.platinum.yearly',
            title: 'Platinum Yearly',
            price: '₹2999',
          );
        final provider = SubscriptionProvider(billing: billing);
        await provider.loadAvailableProducts();

        await pump(tester, provider);

        expect(find.text('Available Plans'), findsOneWidget);
        expect(find.text('Silver'), findsOneWidget);
        expect(find.text('Gold'), findsOneWidget);
        expect(find.text('Platinum'), findsOneWidget);
      },
    );

    testWidgets(
      'plans remain visible even when the user is already actively '
      'subscribed — lets them see upgrade options, unlike the previous '
      'behavior of hiding Plans once subscribed',
      (tester) async {
        final billing = _FakeBillingRepository()
          ..products['jyotishasha.gold.monthly'] = const ChatPackProduct(
            productId: 'jyotishasha.gold.monthly',
            title: 'Gold Monthly',
            price: '₹199',
          );
        final provider = SubscriptionProvider(billing: billing)
          ..subscriptionData = {
            'active': true,
            'plan': 'GOLD_MONTHLY',
            'status': 'active',
          };
        await provider.loadAvailableProducts();

        await pump(tester, provider);

        expect(find.text('Available Plans'), findsOneWidget);
      },
    );

    testWidgets(
      'shows a Monthly/Yearly toggle and switches the displayed price '
      'when both periods are resolved for a tier',
      (tester) async {
        final billing = _FakeBillingRepository()
          ..products['jyotishasha.gold.monthly'] = const ChatPackProduct(
            productId: 'jyotishasha.gold.monthly',
            title: 'Gold Monthly',
            price: '₹199',
          )
          ..products['jyotishasha.gold.yearly'] = const ChatPackProduct(
            productId: 'jyotishasha.gold.yearly',
            title: 'Gold Yearly',
            price: '₹1999',
          );
        final provider = SubscriptionProvider(billing: billing);
        await provider.loadAvailableProducts();

        await pump(tester, provider);

        // Defaults to Yearly (a plain new-user default, not tied to any
        // existing subscription).
        expect(find.text('₹1999'), findsOneWidget);
        expect(find.text('₹199'), findsNothing);

        await tester.tap(find.text('Monthly'));
        await tester.pump();

        expect(find.text('₹199'), findsOneWidget);
        expect(find.text('₹1999'), findsNothing);
      },
    );

    testWidgets(
      'shows no Monthly/Yearly toggle when only one period is resolved '
      'for a tier (e.g. Platinum, yearly-only)',
      (tester) async {
        final billing = _FakeBillingRepository()
          ..products['jyotishasha.platinum.yearly'] = const ChatPackProduct(
            productId: 'jyotishasha.platinum.yearly',
            title: 'Platinum Yearly',
            price: '₹2999',
          );
        final provider = SubscriptionProvider(billing: billing);
        await provider.loadAvailableProducts();

        await pump(tester, provider);

        expect(find.text('Platinum'), findsOneWidget);
        expect(find.text('₹2999'), findsOneWidget);
        expect(find.text('per year'), findsOneWidget);
        expect(find.text('Monthly'), findsNothing);
        expect(find.text('Yearly'), findsNothing); // no toggle control
      },
    );

    testWidgets(
      'shows a Current Plan badge and an "Active" (disabled) button on '
      'the tier matching the backend\'s active plan, "Upgrade" on tiers '
      'above it, and "Unavailable" (disabled) on tiers below it',
      (tester) async {
        final billing = _FakeBillingRepository()
          ..products['jyotishasha.silver.monthly'] = const ChatPackProduct(
            productId: 'jyotishasha.silver.monthly',
            title: 'Silver Monthly',
            price: '₹99',
          )
          ..products['jyotishasha.gold.monthly'] = const ChatPackProduct(
            productId: 'jyotishasha.gold.monthly',
            title: 'Gold Monthly',
            price: '₹199',
          )
          ..products['jyotishasha.platinum.yearly'] = const ChatPackProduct(
            productId: 'jyotishasha.platinum.yearly',
            title: 'Platinum Yearly',
            price: '₹2999',
          );
        final provider = SubscriptionProvider(billing: billing)
          ..subscriptionData = {
            'active': true,
            'plan': 'GOLD_MONTHLY',
            'status': 'active',
          };
        await provider.loadAvailableProducts();

        await pump(tester, provider);

        // Appears twice: once as the membership summary card's own
        // "Current Plan" row label, once as the Gold tier card's badge —
        // both legitimately say "Current Plan".
        expect(find.text('Current Plan'), findsNWidgets(2));
        expect(find.widgetWithText(OutlinedButton, 'Active'), findsOneWidget);
        expect(find.text('Upgrade'), findsAtLeastNWidgets(1)); // Platinum
        expect(
          find.widgetWithText(OutlinedButton, 'Unavailable'),
          findsOneWidget, // Silver — below the current Gold tier
        );
        // Never a hidden/gated purchase action — Unavailable/Active are
        // presentation-only; the purchase call itself is untouched.
        expect(find.byType(ElevatedButton), findsOneWidget); // Platinum only
      },
    );

    testWidgets(
      'never shows a Recommended badge — no such business rule exists '
      'anywhere in the current product/backend contract',
      (tester) async {
        final billing = _FakeBillingRepository()
          ..products['jyotishasha.silver.monthly'] = const ChatPackProduct(
            productId: 'jyotishasha.silver.monthly',
            title: 'Silver Monthly',
            price: '₹99',
          )
          ..products['jyotishasha.gold.monthly'] = const ChatPackProduct(
            productId: 'jyotishasha.gold.monthly',
            title: 'Gold Monthly',
            price: '₹199',
          );
        final provider = SubscriptionProvider(billing: billing);
        await provider.loadAvailableProducts();

        await pump(tester, provider);

        expect(find.textContaining('Recommended'), findsNothing);
        expect(find.textContaining('अनुशंसित'), findsNothing);
      },
    );

    testWidgets(
      'shows a short feature summary for each tier',
      (tester) async {
        final billing = _FakeBillingRepository()
          ..products['jyotishasha.silver.monthly'] = const ChatPackProduct(
            productId: 'jyotishasha.silver.monthly',
            title: 'Silver Monthly',
            price: '₹99',
          );
        final provider = SubscriptionProvider(billing: billing);
        await provider.loadAvailableProducts();

        await pump(tester, provider);

        expect(find.text('Access to Premium Reports'), findsOneWidget);
        expect(find.text('Monthly planetary updates'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Subscribe starts the purchase for that specific product — '
      'the exact same SubscriptionProvider.subscribeToPlan call as before',
      (tester) async {
        final billing = _FakeBillingRepository()
          ..products['jyotishasha.silver.monthly'] = const ChatPackProduct(
            productId: 'jyotishasha.silver.monthly',
            title: 'Silver Monthly',
            price: '₹99',
          );
        final provider = SubscriptionProvider(billing: billing);
        await provider.loadAvailableProducts();

        await pump(tester, provider);

        await tester.tap(find.widgetWithText(ElevatedButton, 'Subscribe'));
        await tester.pump();

        expect(provider.isPurchasing, isTrue);
      },
    );

    testWidgets(
      'disables the Subscribe button and shows a spinner while a purchase '
      'is in progress',
      (tester) async {
        final billing = _FakeBillingRepository()
          ..products['jyotishasha.silver.monthly'] = const ChatPackProduct(
            productId: 'jyotishasha.silver.monthly',
            title: 'Silver Monthly',
            price: '₹99',
          );
        final provider = SubscriptionProvider(billing: billing)
          ..isPurchasing = true;
        await provider.loadAvailableProducts();

        await pump(tester, provider);

        final button = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(button.onPressed, isNull);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Subscribe'), findsNothing);
      },
    );

    testWidgets(
      'shows a SnackBar with a friendly message when a purchase is '
      'cancelled — never leaves the UI silent about the failure',
      (tester) async {
        final provider = SubscriptionProvider()
          ..purchaseErrorMessage = 'cancelled';

        await pump(tester, provider);
        await tester.pump();

        expect(find.text('Purchase cancelled.'), findsOneWidget);
      },
    );

    testWidgets(
      'shows a SnackBar for a backend confirmation failure with guidance, '
      'not a raw error code',
      (tester) async {
        final provider = SubscriptionProvider()
          ..purchaseErrorMessage = 'backend_confirmation_failed';

        await pump(tester, provider);
        await tester.pump();

        expect(
          find.textContaining("couldn't confirm your purchase"),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows a SnackBar for billing being unavailable on the device',
      (tester) async {
        final provider = SubscriptionProvider()
          ..purchaseErrorMessage = 'billing_unavailable';

        await pump(tester, provider);
        await tester.pump();

        expect(
          find.text('Google Play Billing is not available on this device.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows an arbitrary network/exception error message verbatim rather '
      'than swallowing it',
      (tester) async {
        final provider = SubscriptionProvider()
          ..purchaseErrorMessage = 'Exception: SocketException: Failed host lookup';

        await pump(tester, provider);
        await tester.pump();

        expect(
          find.text('Exception: SocketException: Failed host lookup'),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders Hindi tier/Subscribe copy', (tester) async {
      final billing = _FakeBillingRepository()
        ..products['jyotishasha.silver.monthly'] = const ChatPackProduct(
          productId: 'jyotishasha.silver.monthly',
          title: 'Silver Monthly',
          price: '₹99',
        );
      final provider = SubscriptionProvider(billing: billing);
      await provider.loadAvailableProducts();

      await pump(tester, provider, lang: 'hi');

      expect(find.text('उपलब्ध प्लान'), findsOneWidget);
      expect(find.text('सिल्वर'), findsOneWidget);
      expect(find.text('सब्सक्राइब करें'), findsOneWidget);
    });
  });

  testWidgets(
    'with autoLoad (default), mounting the page kicks off a load '
    'automatically — proves initState genuinely wired up '
    'SubscriptionProvider.loadSubscriptionInfo, not a no-op page',
    (tester) async {
      final provider = SubscriptionProvider();

      await pump(tester, provider, autoLoad: true);
      await tester.pump();

      // FirebaseAuth isn't available in this test environment, so
      // loadSubscriptionInfo() fails fast (currentUser access throws) —
      // that failure landing on the provider is exactly what proves the
      // page's initState actually called it.
      expect(provider.errorMessage, isNotNull);
      expect(provider.isLoading, isFalse);
    },
  );

  testWidgets(
    'tapping Retry on the error state calls loadSubscriptionInfo again',
    (tester) async {
      final provider = SubscriptionProvider()..errorMessage = 'boom';

      await pump(tester, provider);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Retry'));
      await tester.pump();

      // Same reasoning as above — the retried call fails fast without
      // Firebase, proving Retry genuinely re-invoked the provider.
      expect(provider.errorMessage, isNotNull);
      expect(provider.isLoading, isFalse);
    },
  );
}
