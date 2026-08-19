import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/models/asknow/asknow_contracts.dart';
import 'package:jyotishasha_app/core/models/reports/report_contracts.dart';
import 'package:jyotishasha_app/core/repositories/billing_repository.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/subscription_provider.dart';
import 'package:jyotishasha_app/features/alerts/alerts_dashboard_page.dart';
import 'package:jyotishasha_app/features/explore/explore_page.dart';
import 'package:jyotishasha_app/features/premium_report/birth_chart_report_reader.dart';
import 'package:jyotishasha_app/features/subscription/subscription_page.dart';

import '../../helpers/test_harness.dart';

/// Same fake used across `subscription_provider_test.dart`/
/// `subscription_page_test.dart`/`account_page_test.dart` — the
/// membership strip can push the real `SubscriptionPage`, whose
/// `autoLoad` would otherwise call the real `PlayBillingRepository` and
/// throw via the Android platform channel (no plugin implementation
/// registered in this headless environment).
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

void main() {
  Future<SubscriptionProvider> pump(
    WidgetTester tester, {
    Map<String, dynamic>? data,
    bool isLoading = false,
    Locale? locale,
  }) async {
    final provider = SubscriptionProvider(billing: _FakeBillingRepository())
      ..subscriptionData = data
      ..isLoading = isLoading;

    await tester.pumpTestHarness(
      const ExplorePage(),
      locale: locale,
      providers: [
        ChangeNotifierProvider<SubscriptionProvider>.value(value: provider),
        // SubscriptionPage (pushed when the strip is tapped) reads
        // LanguageProvider for its bilingual copy.
        ChangeNotifierProvider<LanguageProvider>.value(
          value: LanguageProvider()..currentLang = locale?.languageCode ?? 'en',
        ),
      ],
    );
    // Flushes the strip's initState microtask guard — a no-op here since
    // data/isLoading are already pre-set, matching the deterministic
    // pattern already established for SubscriptionProvider-backed tests.
    await tester.pump();
    return provider;
  }

  group('Membership strip (real SubscriptionProvider state)', () {
    testWidgets(
      'shows "Premium Trial Active" and the remaining-days countdown '
      '(Manual Trial Activation) when active and is_trial is true',
      (tester) async {
        await pump(
          tester,
          data: {
            'active': true, 'is_trial': true, 'plan': 'GOLD_MONTHLY',
            'remaining_days': 5,
          },
        );

        expect(find.text('Premium Trial Active'), findsOneWidget);
        expect(find.text('5 Days Remaining'), findsOneWidget);
      },
    );

    testWidgets('shows the formatted plan name for an active Gold Monthly '
        'subscription', (tester) async {
      await pump(
        tester,
        data: {'active': true, 'is_trial': false, 'plan': 'GOLD_MONTHLY'},
      );

      expect(find.text('Gold Monthly'), findsOneWidget);
    });

    testWidgets('shows the formatted plan name for an active Gold Yearly '
        'subscription', (tester) async {
      await pump(tester, data: {'active': true, 'plan': 'GOLD_YEARLY'});

      expect(find.text('Gold Yearly'), findsOneWidget);
    });

    testWidgets(
      'shows the formatted plan name for a plan with no period suffix '
      '(Silver)',
      (tester) async {
        await pump(tester, data: {'active': true, 'plan': 'SILVER'});

        expect(find.text('Silver'), findsOneWidget);
      },
    );

    testWidgets('shows "Expired" when not active and status is expired', (
      tester,
    ) async {
      await pump(tester, data: {'active': false, 'status': 'expired'});

      expect(find.text('Expired'), findsOneWidget);
    });

    testWidgets(
      'shows "Grace Period" — and it takes precedence even when active '
      'and is_trial are also true',
      (tester) async {
        await pump(
          tester,
          data: {
            'active': true,
            'is_trial': true,
            'in_grace_period': true,
            'plan': 'GOLD_MONTHLY',
          },
        );

        expect(find.text('Grace Period'), findsOneWidget);
        expect(find.text('Premium Trial Active'), findsNothing);
      },
    );

    testWidgets(
      'shows "No Subscription" when not active and there is no plan',
      (tester) async {
        await pump(tester, data: {'active': false, 'status': 'none'});

        expect(find.text('No Subscription'), findsOneWidget);
      },
    );

    testWidgets('shows a loading indicator instead of a state chip while '
        'isLoading is true and no data has arrived yet', (tester) async {
      await pump(tester, isLoading: true);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No Subscription'), findsNothing);
    });

    testWidgets(
      'falls back to "View Membership" — never "No Subscription" — when '
      'status genuinely cannot be determined yet (no data, not loading)',
      (tester) async {
        // No `data` supplied: the strip's own initState guard fires a
        // real loadSubscriptionInfo() call, which fails fast in this
        // headless environment (no FirebaseAuth app) without ever
        // reaching the network — subscriptionData stays null throughout.
        await pump(tester);
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('View Membership'), findsOneWidget);
        // Never asserts a subscription state it doesn't actually know.
        expect(find.text('No Subscription'), findsNothing);
        expect(find.text('Expired'), findsNothing);
      },
    );

    testWidgets('renders the Hindi label for Premium Trial Active', (
      tester,
    ) async {
      await pump(
        tester,
        data: {
          'active': true, 'is_trial': true, 'plan': 'GOLD_MONTHLY',
          'remaining_days': 5,
        },
        locale: const Locale('hi'),
      );

      expect(find.text('सदस्यता'), findsOneWidget);
      expect(find.text('प्रीमियम ट्रायल सक्रिय'), findsOneWidget);
      expect(find.text('5 दिन शेष'), findsOneWidget);
    });

    testWidgets(
      'the old static strip copy is gone — no "Premium Membership", no '
      '"7 Days Remaining" anywhere',
      (tester) async {
        await pump(tester, data: {'active': true, 'plan': 'GOLD_YEARLY'});

        expect(find.text('Premium Membership'), findsNothing);
        expect(find.text('7 Days Remaining'), findsNothing);
      },
    );

    testWidgets(
      'tapping the strip opens the existing SubscriptionPage — same '
      'destination regardless of active/expired/no-subscription state',
      (tester) async {
        await pump(tester, data: {'active': false, 'status': 'expired'});

        await tester.tap(find.text('Expired'));
        await tester.pump();
        // Explicit finite pumps rather than pumpAndSettle — the pushed
        // SubscriptionPage's own autoLoad kicks off a real (fast-failing,
        // no FirebaseAuth in this environment) loadSubscriptionInfo()
        // call on the same shared provider, which pumpAndSettle's
        // animation-driven settling can hang on.
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(SubscriptionPage), findsOneWidget);
      },
    );
  });

  group('Trial activation card (Manual Trial Activation)', () {
    testWidgets(
      'shows the activation card when trial_available is true and '
      'membership_state is NONE',
      (tester) async {
        await pump(
          tester,
          data: {
            'active': false, 'is_trial': false, 'status': 'none',
            'membership_state': 'NONE', 'trial_available': true,
          },
        );

        expect(find.text('Your 7-Day Premium Gift is Ready'), findsOneWidget);
        expect(
          find.text('Unlock all premium sections free for 7 days.'),
          findsOneWidget,
        );
        expect(find.text('Activate Free Access'), findsOneWidget);
      },
    );

    testWidgets(
      'hides the activation card when trial_available is false '
      '(previously used/expired, or paid subscriber never eligible)',
      (tester) async {
        await pump(
          tester,
          data: {
            'active': false, 'status': 'none',
            'membership_state': 'EXPIRED', 'trial_available': false,
          },
        );

        expect(find.text('Your 7-Day Premium Gift is Ready'), findsNothing);
        expect(find.text('Activate Free Access'), findsNothing);
      },
    );

    testWidgets(
      'hides the activation card while membership_state is already TRIAL, '
      'even if trial_available were somehow still true (defensive — '
      'matches the spec\'s explicit double condition)',
      (tester) async {
        await pump(
          tester,
          data: {
            'active': true, 'is_trial': true,
            'membership_state': 'TRIAL', 'trial_available': true,
            'remaining_days': 5,
          },
        );

        expect(find.text('Your 7-Day Premium Gift is Ready'), findsNothing);
      },
    );

    testWidgets(
      'hides the activation card for an ACTIVE paid subscriber',
      (tester) async {
        await pump(
          tester,
          data: {
            'active': true, 'plan': 'GOLD_YEARLY',
            'membership_state': 'ACTIVE', 'trial_available': false,
          },
        );

        expect(find.text('Your 7-Day Premium Gift is Ready'), findsNothing);
      },
    );

    testWidgets(
      'hides the activation card before subscriptionData has ever loaded '
      '(no flash of the card while trialAvailable defaults to false)',
      (tester) async {
        await pump(tester, data: null);

        expect(find.text('Your 7-Day Premium Gift is Ready'), findsNothing);
      },
    );

    testWidgets(
      'tapping "Activate Free Access" calls activateTrial() exactly once, '
      'and the button is disabled/shows a spinner while it is in flight',
      (tester) async {
        final provider = await pump(
          tester,
          data: {
            'active': false, 'status': 'none',
            'membership_state': 'NONE', 'trial_available': true,
          },
        );

        // Manually drives isActivatingTrial to simulate an in-flight
        // call without a real network dependency (SubscriptionProvider
        // has no injectable HTTP client — same limitation
        // subscription_provider_test.dart's own tests already work
        // around for loadSubscriptionInfo()/_confirmWithBackend()).
        provider.isActivatingTrial = true;
        provider.notifyListeners();
        await tester.pump();

        expect(find.text('Activate Free Access'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        final button = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(button.onPressed, isNull); // disabled -> no double tap
      },
    );

    testWidgets(
      'shows a user-friendly error message when activation fails',
      (tester) async {
        final provider = await pump(
          tester,
          data: {
            'active': false, 'status': 'none',
            'membership_state': 'NONE', 'trial_available': true,
          },
        );

        provider.activateTrialErrorMessage = 'trial_already_used';
        provider.notifyListeners();
        await tester.pump();

        expect(
          find.text("You've already used your free trial."),
          findsOneWidget,
        );
      },
    );
  });

  group('Report cards (unrelated to the membership strip — unchanged)', () {
    testWidgets(
      'shows the title and all six report cards (with "Current Planetary '
      'Condition" and "Premium Report · Birth Chart Based" under each) '
      'in English',
      (tester) async {
        await pump(tester, data: {'active': false, 'status': 'none'});

        expect(find.text('Explore'), findsOneWidget);

        for (final title in [
          'Love',
          'Career',
          'Finance',
          'Health',
          'Family',
          'Alerts',
        ]) {
          expect(find.text(title), findsOneWidget);
        }

        expect(find.text('Current Planetary Condition'), findsNWidgets(6));
        expect(
          find.text('Premium Report · Birth Chart Based'),
          findsNWidgets(6),
        );

        // No prices or purchase/upgrade wording on this screen.
        expect(find.textContaining('₹'), findsNothing);
        expect(find.byIcon(Icons.lock_outline), findsNothing);
        expect(find.textContaining('Subscribe'), findsNothing);
        expect(find.textContaining('Upgrade'), findsNothing);
      },
    );

    testWidgets('renders Hindi category/condition text', (tester) async {
      await pump(
        tester,
        data: {'active': false, 'status': 'none'},
        locale: const Locale('hi'),
      );

      expect(find.text('एक्सप्लोर'), findsOneWidget);
      expect(find.text('प्रेम'), findsOneWidget);
      expect(find.text('वर्तमान ग्रह स्थिति'), findsNWidgets(6));
      expect(
        find.text('प्रीमियम रिपोर्ट · जन्म कुंडली आधारित'),
        findsNWidgets(6),
      );
    });

    testWidgets('the membership strip and all six cards give visual tap '
        'feedback (7 InkWells total)', (tester) async {
      await pump(tester, data: {'active': false, 'status': 'none'});

      expect(find.byType(InkWell), findsNWidgets(7));
    });

    testWidgets(
      'tapping a Premium Report card (e.g. Career) opens '
      'BirthChartReportReader directly — no intermediate landing page',
      (tester) async {
        await pump(tester, data: {'active': false, 'status': 'none'});

        // Career (not Love) deliberately — Love's reader makes a real
        // backend call on mount (see birth_chart_report_reader_test.dart
        // for that, with an injected fake repository); Career has no
        // backend generator, so its reader never touches the network,
        // keeping this navigation-only assertion simple and safe.
        await tester.tap(find.text('Career'));
        await tester.pumpAndSettle();

        expect(find.byType(BirthChartReportReader), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Alerts (not one of the 5 Premium Reports) opens '
      'AlertsDashboardPage directly — no intermediate landing page, no '
      'no-op placeholder',
      (tester) async {
        await pump(tester, data: {'active': false, 'status': 'none'});

        // AlertsDashboardPage makes a real backend call on mount (see
        // alerts_dashboard_page_test.dart for state assertions, with an
        // injected fake repository) — this navigation-only test can't
        // inject one through ExplorePage's real tap path, so it relies
        // on HttpAlertsDashboardRepository's own null-token handling (no
        // Firebase app in this headless environment -> treated as "not
        // signed in" -> a failure result, not a crash), same convention
        // as the Career-card navigation test above.
        await tester.ensureVisible(find.text('Alerts'));
        await tester.tap(find.text('Alerts'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertsDashboardPage), findsOneWidget);
      },
    );
  });
}
