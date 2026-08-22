import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final List<String> purchaseSubscriptionCalls = [];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ChatPackProduct?> getProduct(String productId) async =>
      products[productId];

  @override
  Future<void> purchaseConsumable(ChatPackProduct product) async {}

  @override
  Future<void> purchaseSubscription(ChatPackProduct product) async {
    purchaseSubscriptionCalls.add(product.productId ?? '');
  }

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
  // Needed now that the Silver section-selection fix's subscribeToPlan
  // persists the chosen segment via SharedPreferences before starting
  // billing — same mock every other provider's tests already set up
  // for their own SharedPreferences-touching code paths.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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
      '✓ Silver Monthly: states ONE chosen section plus the monthly-only '
      'transit allowance (no "each month"/recurring wording), and the '
      'confirmed Venus/Mars/Mercury clarification',
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

        expect(find.text('Choose 1 Premium Section'), findsOneWidget);
        expect(find.text('1 Short Planet Transit Report'), findsOneWidget);
        expect(find.text('Venus, Mars or Mercury'), findsOneWidget);
        expect(
          find.text('1 Short Planet Transit Report each month'),
          findsNothing,
        );
        // Never claims full/unlimited access for Silver.
        expect(find.textContaining('All 6'), findsNothing);
        expect(find.textContaining('Everything'), findsNothing);
      },
    );

    testWidgets(
      '✓ Silver Yearly: states ONE chosen section plus the recurring '
      '"each month" transit allowance -- yearly wording must never show '
      'the Monthly-only phrasing',
      (tester) async {
        final billing = _FakeBillingRepository()
          ..products['jyotishasha.silver.yearly'] = const ChatPackProduct(
            productId: 'jyotishasha.silver.yearly',
            title: 'Silver Yearly',
            price: '₹990',
          );
        final provider = SubscriptionProvider(billing: billing);
        await provider.loadAvailableProducts();

        await pump(tester, provider);

        expect(find.text('Choose 1 Premium Section'), findsOneWidget);
        expect(
          find.text('1 Short Planet Transit Report each month'),
          findsOneWidget,
        );
        expect(find.text('Venus, Mars or Mercury'), findsOneWidget);
        // The Monthly-only phrasing (no "each month") must not appear.
        expect(find.text('1 Short Planet Transit Report'), findsNothing);
      },
    );

    testWidgets(
      '✓ Gold Monthly: states ALL 6 sections, up to 2 short-planet '
      'transit reports for the month, and one big-planet report ONLY '
      'when applicable -- never names which planets qualify as "big" '
      '(no authoritative definition exists)',
      (tester) async {
        final billing = _FakeBillingRepository()
          ..products['jyotishasha.gold.monthly'] = const ChatPackProduct(
            productId: 'jyotishasha.gold.monthly',
            title: 'Gold Monthly',
            price: '₹199',
          );
        final provider = SubscriptionProvider(billing: billing);
        await provider.loadAvailableProducts();

        await pump(tester, provider);

        expect(find.text('All 6 Premium Sections'), findsOneWidget);
        expect(
          find.text('Up to 2 Short Planet Transit Reports'),
          findsOneWidget,
        );
        expect(
          find.text('1 Big Planet Transit Report when applicable'),
          findsOneWidget,
        );
        expect(find.textContaining('each month'), findsNothing);
        expect(find.textContaining('subscription year'), findsNothing);
        // Never implies Gold is limited to one section, and never
        // repeats the now-removed, unverifiable "Priority report
        // updates" / "AI Love Insights included" claims.
        expect(find.textContaining('Choose 1'), findsNothing);
        expect(find.textContaining('Priority'), findsNothing);
        expect(find.textContaining('Love Insights'), findsNothing);
      },
    );

    testWidgets(
      '✓ Gold Yearly: same ALL-6-sections + transit entitlement as '
      'Gold Monthly, but with the recurring "each month"/"subscription '
      'year" wording -- Monthly-only phrasing must never show',
      (tester) async {
        final billing = _FakeBillingRepository()
          ..products['jyotishasha.gold.yearly'] = const ChatPackProduct(
            productId: 'jyotishasha.gold.yearly',
            title: 'Gold Yearly',
            price: '₹1999',
          );
        final provider = SubscriptionProvider(billing: billing);
        await provider.loadAvailableProducts();

        await pump(tester, provider);

        expect(find.text('All 6 Premium Sections'), findsOneWidget);
        expect(
          find.text('Up to 2 Short Planet Transit Reports each month'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Big Planet Transit Reports when applicable during your subscription year',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Up to 2 Short Planet Transit Reports'),
          findsNothing,
        );
        expect(
          find.text('1 Big Planet Transit Report when applicable'),
          findsNothing,
        );
      },
    );

    testWidgets(
      '✓ Platinum Yearly: ALL 6 sections, ALL applicable transit reports '
      'for the year, full-year access -- identical entitlement to Gold '
      '(verified: PLAN_SEGMENT_ACCESS has no Platinum-exclusive benefit), '
      'and never claims a "best value"/"savings" framing this app\'s '
      'real Play Console pricing does not support (Platinum Yearly '
      'prices higher per month than Gold Yearly for the same access)',
      (tester) async {
        final billing = _FakeBillingRepository()
          ..products['jyotishasha.platinum.yearly'] = const ChatPackProduct(
            productId: 'jyotishasha.platinum.yearly',
            title: 'Platinum Yearly',
            price: '₹3999',
          );
        final provider = SubscriptionProvider(billing: billing);
        await provider.loadAvailableProducts();

        await pump(tester, provider);

        expect(find.text('All 6 Premium Sections'), findsOneWidget);
        expect(find.text('All Applicable Transit Reports'), findsOneWidget);
        expect(find.text('Full-year premium access'), findsOneWidget);
        expect(find.textContaining('Best value'), findsNothing);
        expect(find.textContaining('Save'), findsNothing);
      },
    );

    testWidgets(
      '✓ Monthly/Yearly transit wording never crosses over: toggling '
      'the SAME Silver card between Monthly and Yearly swaps the '
      'copy cleanly -- proves the period-aware features() plumbing '
      '(the smallest presentation-layer fix this task\'s audit called '
      'for), not just two independently-stubbed products',
      (tester) async {
        final billing = _FakeBillingRepository()
          ..products['jyotishasha.silver.monthly'] = const ChatPackProduct(
            productId: 'jyotishasha.silver.monthly',
            title: 'Silver Monthly',
            price: '₹99',
          )
          ..products['jyotishasha.silver.yearly'] = const ChatPackProduct(
            productId: 'jyotishasha.silver.yearly',
            title: 'Silver Yearly',
            price: '₹990',
          );
        final provider = SubscriptionProvider(billing: billing);
        await provider.loadAvailableProducts();

        await pump(tester, provider);

        // Defaults to Yearly (existing, unchanged convention).
        expect(
          find.text('1 Short Planet Transit Report each month'),
          findsOneWidget,
        );
        expect(find.text('1 Short Planet Transit Report'), findsNothing);

        await tester.tap(find.text('Monthly'));
        await tester.pump();

        expect(find.text('1 Short Planet Transit Report'), findsOneWidget);
        expect(
          find.text('1 Short Planet Transit Report each month'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'tapping Subscribe starts the purchase for that specific product — '
      'the exact same SubscriptionProvider.subscribeToPlan call as before',
      (tester) async {
        // Gold, not Silver -- this test is specifically about the
        // direct/unmediated Subscribe tap, which the Silver
        // section-selection fix intentionally changes (see the
        // dedicated "Silver plan section-selection fix" group below for
        // that new behavior). Gold's tap is untouched by this fix.
        final billing = _FakeBillingRepository()
          ..products['jyotishasha.gold.monthly'] = const ChatPackProduct(
            productId: 'jyotishasha.gold.monthly',
            title: 'Gold Monthly',
            price: '₹199',
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

    testWidgets(
      '✓ entitlement-accurate copy (Hindi): Silver/Gold/Platinum feature '
      'bullets carry the same corrected, period-aware meaning in Hindi '
      'as in English -- Silver Monthly = one chosen section + monthly-'
      'only transit line, Gold/Platinum = all six sections',
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
            price: '₹3999',
          );
        final provider = SubscriptionProvider(billing: billing);
        await provider.loadAvailableProducts();

        await pump(tester, provider, lang: 'hi');

        expect(find.text('1 प्रीमियम सेक्शन चुनें'), findsOneWidget);
        expect(find.text('1 शॉर्ट प्लैनेट ट्रांजिट रिपोर्ट'), findsOneWidget);
        expect(find.text('शुक्र, मंगल या बुध'), findsOneWidget);
        expect(find.text('सभी 6 प्रीमियम सेक्शन'), findsNWidgets(2)); // Gold + Platinum
        expect(
          find.text('अधिकतम 2 शॉर्ट प्लैनेट ट्रांजिट रिपोर्ट'),
          findsOneWidget,
        );
        expect(
          find.text('लागू होने पर 1 बिग प्लैनेट ट्रांजिट रिपोर्ट'),
          findsOneWidget,
        );
        expect(find.text('सभी लागू ट्रांजिट रिपोर्ट'), findsOneWidget);
        expect(find.text('पूरे साल का प्रीमियम एक्सेस'), findsOneWidget);
      },
    );

    testWidgets(
      '✓ Hindi: Silver Yearly shows the recurring "हर महीने" '
      '(each month) transit wording, never the Monthly-only phrasing',
      (tester) async {
        final billing = _FakeBillingRepository()
          ..products['jyotishasha.silver.yearly'] = const ChatPackProduct(
            productId: 'jyotishasha.silver.yearly',
            title: 'Silver Yearly',
            price: '₹990',
          );
        final provider = SubscriptionProvider(billing: billing);
        await provider.loadAvailableProducts();

        await pump(tester, provider, lang: 'hi');

        expect(
          find.text('हर महीने 1 शॉर्ट प्लैनेट ट्रांजिट रिपोर्ट'),
          findsOneWidget,
        );
        expect(find.text('1 शॉर्ट प्लैनेट ट्रांजिट रिपोर्ट'), findsNothing);
      },
    );

    testWidgets(
      '✓ Hindi: Gold Yearly shows the recurring "हर महीने" short-planet '
      'wording and the subscription-year big-planet wording -- exact '
      'strings per the final business copy, never the Monthly-only '
      'phrasing',
      (tester) async {
        final billing = _FakeBillingRepository()
          ..products['jyotishasha.gold.yearly'] = const ChatPackProduct(
            productId: 'jyotishasha.gold.yearly',
            title: 'Gold Yearly',
            price: '₹1999',
          );
        final provider = SubscriptionProvider(billing: billing);
        await provider.loadAvailableProducts();

        await pump(tester, provider, lang: 'hi');

        expect(
          find.text('हर महीने अधिकतम 2 शॉर्ट प्लैनेट ट्रांजिट रिपोर्ट'),
          findsOneWidget,
        );
        expect(
          find.text('सदस्यता वर्ष के दौरान लागू होने पर बिग प्लैनेट ट्रांजिट रिपोर्ट'),
          findsOneWidget,
        );
        expect(
          find.text('अधिकतम 2 शॉर्ट प्लैनेट ट्रांजिट रिपोर्ट'),
          findsNothing,
        );
        expect(
          find.text('लागू होने पर 1 बिग प्लैनेट ट्रांजिट रिपोर्ट'),
          findsNothing,
        );
      },
    );
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

  group('Silver plan section-selection fix', () {
    _FakeBillingRepository silverBilling() => _FakeBillingRepository()
      ..products['jyotishasha.silver.monthly'] = const ChatPackProduct(
        productId: 'jyotishasha.silver.monthly',
        title: 'Silver Monthly',
        price: '₹99',
      );

    _FakeBillingRepository goldBilling() => _FakeBillingRepository()
      ..products['jyotishasha.gold.monthly'] = const ChatPackProduct(
        productId: 'jyotishasha.gold.monthly',
        title: 'Gold Monthly',
        price: '₹199',
      );

    testWidgets(
      'English: tapping Subscribe on the Silver card opens the '
      'section-selection sheet with all six sections, none pre-selected '
      '-- billing has not started yet',
      (tester) async {
        final billing = silverBilling();
        final provider = SubscriptionProvider(billing: billing);
        await provider.loadAvailableProducts();

        await pump(tester, provider, lang: 'en');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Subscribe'));
        await tester.pumpAndSettle();

        expect(find.text('Choose your one section'), findsOneWidget);
        expect(find.text('Love & Relationship'), findsOneWidget);
        expect(find.text('Career & Education'), findsOneWidget);
        expect(find.text('Finance & Wealth'), findsOneWidget);
        expect(find.text('Health & Wellness'), findsOneWidget);
        expect(find.text('Family & Social Life'), findsOneWidget);
        expect(find.text('Alerts & Opportunities'), findsOneWidget);
        // Billing must not have started merely by opening the sheet.
        expect(billing.purchaseSubscriptionCalls, isEmpty);
      },
    );

    testWidgets(
      'Hindi: the same section-selection sheet renders the Hindi labels '
      'for all six sections',
      (tester) async {
        final billing = silverBilling();
        final provider = SubscriptionProvider(billing: billing);
        await provider.loadAvailableProducts();

        await pump(tester, provider, lang: 'hi');
        await tester.tap(find.widgetWithText(ElevatedButton, 'सब्सक्राइब करें'));
        await tester.pumpAndSettle();

        expect(find.text('एक सेक्शन चुनें'), findsOneWidget);
        expect(find.text('प्रेम और रिश्ते'), findsOneWidget);
        expect(find.text('करियर और शिक्षा'), findsOneWidget);
        expect(find.text('वित्त और धन'), findsOneWidget);
        expect(find.text('स्वास्थ्य और कल्याण'), findsOneWidget);
        expect(find.text('परिवार और सामाजिक जीवन'), findsOneWidget);
        expect(find.text('अलर्ट और अवसर'), findsOneWidget);
      },
    );

    testWidgets(
      '✓ tapping one section in the sheet closes it and starts Google '
      'Play Billing for the Silver product with exactly that section',
      (tester) async {
        final billing = silverBilling();
        final provider = SubscriptionProvider(billing: billing);
        await provider.loadAvailableProducts();

        await pump(tester, provider, lang: 'en');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Subscribe'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Career & Education'));
        // Not pumpAndSettle(): subscribeToPlan leaves isPurchasing true
        // (by design -- "the stream listener resolves it next"), which
        // renders an indeterminate CircularProgressIndicator that would
        // never let pumpAndSettle() finish. A bounded pump sequence lets
        // the sheet's close animation finish and the fake billing
        // repository's (immediately-resolving) async chain run, exactly
        // like the pre-existing "tapping Subscribe starts the purchase"
        // test above does with its own single pump().
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        expect(find.text('Choose your one section'), findsNothing);
        expect(billing.purchaseSubscriptionCalls, [
          'jyotishasha.silver.monthly',
        ]);
      },
    );

    testWidgets(
      'dismissing the sheet without choosing a section never starts '
      'billing -- no default/automatic selection is ever substituted',
      (tester) async {
        final billing = silverBilling();
        final provider = SubscriptionProvider(billing: billing);
        await provider.loadAvailableProducts();

        await pump(tester, provider, lang: 'en');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Subscribe'));
        await tester.pumpAndSettle();

        // Tap the barrier behind the sheet (top-left corner is outside
        // the sheet's own content area) to dismiss without choosing.
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(find.text('Choose your one section'), findsNothing);
        expect(billing.purchaseSubscriptionCalls, isEmpty);
        expect(provider.purchaseErrorMessage, isNull);
        expect(provider.isPurchasing, isFalse);
      },
    );

    testWidgets(
      '✓ Gold: tapping Subscribe never shows the section-selection '
      'sheet -- Google Play Billing starts immediately, exactly as '
      'before this fix',
      (tester) async {
        final billing = goldBilling();
        final provider = SubscriptionProvider(billing: billing);
        await provider.loadAvailableProducts();

        await pump(tester, provider, lang: 'en');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Subscribe'));
        // Not pumpAndSettle() -- same indeterminate-spinner reasoning as
        // the Silver section-tap test above (Gold starts billing
        // immediately here, with the exact same isPurchasing-stays-true
        // shape).
        await tester.pump();

        expect(find.text('Choose your one section'), findsNothing);
        expect(billing.purchaseSubscriptionCalls, [
          'jyotishasha.gold.monthly',
        ]);
      },
    );
  });
}
