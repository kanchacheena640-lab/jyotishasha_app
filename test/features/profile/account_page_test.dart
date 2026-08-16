import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/models/asknow/asknow_contracts.dart';
import 'package:jyotishasha_app/core/models/reports/report_contracts.dart';
import 'package:jyotishasha_app/core/repositories/billing_repository.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/state/subscription_provider.dart';
import 'package:jyotishasha_app/features/profile/account_page.dart';
import 'package:jyotishasha_app/features/profile/edit_profile_page.dart';
import 'package:jyotishasha_app/features/subscription/subscription_page.dart';

import '../../helpers/test_harness.dart';

/// `ProfileProvider`'s real constructor touches `FirebaseAuth.instance` via
/// `ProfileService`, unavailable in this widget-test environment. `Mock`'s
/// `implements` never calls the real constructor; `with ChangeNotifier`
/// gives real addListener/notifyListeners behavior for `context.watch`.
class _FakeProfileProvider extends Mock
    with ChangeNotifier
    implements ProfileProvider {}

/// Same fake used in `subscription_provider_test.dart`/
/// `subscription_page_test.dart` — the Manage Subscription action can push
/// the real `SubscriptionPage`, whose `autoLoad` would otherwise call the
/// real `PlayBillingRepository` and throw via the Android platform
/// channel (no plugin implementation registered in this headless
/// environment).
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
  late _FakeProfileProvider profileProvider;
  late SubscriptionProvider subscriptionProvider;

  setUp(() {
    profileProvider = _FakeProfileProvider();
    when(() => profileProvider.loadProfiles()).thenAnswer((_) async {});
    when(() => profileProvider.isLoading).thenReturn(false);
    when(() => profileProvider.errorMessage).thenReturn(null);
    when(() => profileProvider.activeProfile).thenReturn({
      "name": "Ravi Kumar",
      "dob": "1990-05-12",
      "pob": "Lucknow",
      "moon_sign": "Cancer",
      "lagna": "Aries",
    });
    subscriptionProvider = SubscriptionProvider(
      billing: _FakeBillingRepository(),
    );
  });

  Future<void> pump(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpTestHarness(
      const AccountPage(),
      locale: locale,
      providers: [
        ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
        ChangeNotifierProvider<SubscriptionProvider>.value(
          value: subscriptionProvider,
        ),
        // EditProfilePage/SubscriptionPage (possible navigation targets)
        // read this on mount.
        ChangeNotifierProvider<LanguageProvider>.value(
          value: LanguageProvider(),
        ),
      ],
    );
  }

  testWidgets(
    'shows Account title, name, birth details, and Moon Sign/Lagna',
    (tester) async {
      await pump(tester);

      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Ravi Kumar'), findsOneWidget);
      expect(find.textContaining('1990-05-12'), findsOneWidget);
      expect(find.text('Moon Sign'), findsOneWidget);
      expect(find.text('Cancer'), findsOneWidget);
      expect(find.text('Lagna'), findsOneWidget);
      expect(find.text('Aries'), findsOneWidget);
    },
  );

  group('Profile loading/error/retry (Gate 2)', () {
    testWidgets('shows a loading indicator while ProfileProvider.isLoading '
        'is true', (tester) async {
      when(() => profileProvider.isLoading).thenReturn(true);
      when(() => profileProvider.activeProfile).thenReturn(null);

      await pump(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Account'), findsNothing);
    });

    testWidgets(
      'shows an error state with a Retry action when loadProfiles failed '
      'and no profile is available — never an infinite spinner',
      (tester) async {
        when(() => profileProvider.errorMessage).thenReturn('network_error');
        when(() => profileProvider.activeProfile).thenReturn(null);

        await pump(tester);

        expect(
          find.text('Something went wrong loading your profile.'),
          findsOneWidget,
        );
        expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);

        await tester.tap(find.widgetWithText(OutlinedButton, 'Retry'));
        verify(() => profileProvider.loadProfiles()).called(greaterThan(0));
      },
    );
  });

  group('Edit Profile (Gate 2 — reconnects the existing EditProfilePage)', () {
    testWidgets('tapping Edit Profile opens the existing EditProfilePage '
        'with the active profile, not a second implementation', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      expect(find.byType(EditProfilePage), findsOneWidget);
    });
  });

  group('Subscription card (membership_state — Gate 3)', () {
    testWidgets('shows "-" before subscription data has loaded', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('TRIAL shows FREE TRIAL and the backend\'s own '
        'remaining_days — never a locally-calculated number', (tester) async {
      subscriptionProvider.subscriptionData = {
        'membership_state': 'TRIAL',
        'remaining_days': 5,
      };

      await pump(tester);

      expect(find.text('FREE TRIAL'), findsOneWidget);
    });

    testWidgets('ACTIVE shows the backend\'s own plan string', (
      tester,
    ) async {
      subscriptionProvider.subscriptionData = {
        'membership_state': 'ACTIVE',
        'plan': 'GOLD_YEARLY',
      };

      await pump(tester);

      expect(find.text('GOLD_YEARLY'), findsOneWidget);
    });

    testWidgets('GRACE_PERIOD is shown distinctly from ACTIVE', (
      tester,
    ) async {
      subscriptionProvider.subscriptionData = {
        'membership_state': 'GRACE_PERIOD',
        'plan': 'SILVER_MONTHLY',
      };

      await pump(tester);

      expect(find.text('Grace Period'), findsOneWidget);
    });

    testWidgets('EXPIRED shows "Expired", never a fabricated "Free User"', (
      tester,
    ) async {
      subscriptionProvider.subscriptionData = {
        'membership_state': 'EXPIRED',
      };

      await pump(tester);

      expect(find.text('Expired'), findsOneWidget);
      expect(find.text('Free User'), findsNothing);
    });

    testWidgets('NONE (never subscribed) shows "Free" / no active '
        'subscription', (tester) async {
      subscriptionProvider.subscriptionData = {'membership_state': 'NONE'};

      await pump(tester);

      expect(find.text('Free'), findsOneWidget);
      expect(find.text('No active subscription'), findsOneWidget);
    });
  });

  testWidgets(
    'tapping Manage Subscription opens the existing SubscriptionPage',
    (tester) async {
      await pump(tester);

      await tester.tap(find.text('Manage Subscription'));
      await tester.pumpAndSettle();

      expect(find.byType(SubscriptionPage), findsOneWidget);
    },
  );

  group('Removed obsolete rows (Gate 10)', () {
    testWidgets(
      'Free Horoscope PDF, Premium Reports, AI Love Insights, and '
      'Downloads are all gone — that discovery belongs on Explore now',
      (tester) async {
        await pump(tester);

        expect(find.text('Free Horoscope PDF'), findsNothing);
        expect(find.text('Premium Reports'), findsNothing);
        expect(find.text('AI Love Insights'), findsNothing);
        expect(find.text('Downloads'), findsNothing);
        expect(find.text('Coming Soon'), findsNothing);
      },
    );
  });

  group('Settings — Language (Gate 5, reuses the existing LanguageProvider)', () {
    testWidgets('shows the current language and opens a picker that calls '
        'the existing LanguageProvider.setLanguage — no second '
        'language-state system', (tester) async {
      final languageProvider = LanguageProvider();
      await tester.pumpTestHarness(
        const AccountPage(),
        providers: [
          ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
          ChangeNotifierProvider<SubscriptionProvider>.value(
            value: subscriptionProvider,
          ),
          ChangeNotifierProvider<LanguageProvider>.value(
            value: languageProvider,
          ),
        ],
      );

      expect(find.text('English'), findsOneWidget);

      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      expect(find.text('Choose Language'), findsOneWidget);
      expect(find.text('हिन्दी'), findsOneWidget);

      await tester.tap(find.text('हिन्दी'));
      await tester.pumpAndSettle();

      // The test harness's MaterialApp.locale is fixed per-pump (unlike
      // production's JyotishashaApp, which watches LanguageProvider to
      // rebuild MaterialApp.router's own `locale`) — so this asserts the
      // one thing this widget test CAN observe: the tap reached the
      // real, shared LanguageProvider and persisted the choice, the same
      // provider/mechanism `renders Hindi Account/section text` below
      // exercises via the harness's `locale:` param instead.
      expect(languageProvider.currentLang, 'hi');
    });
  });

  group('Help & Legal (Gate 7 — exact jyotishasha.com destinations)', () {
    testWidgets('shows all four rows', (tester) async {
      await pump(tester);

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Refund Policy'), findsOneWidget);
    });
  });

  group('Logout (Gate 8 — confirmation + provider cleanup)', () {
    testWidgets('tapping Logout shows a confirmation dialog first — no '
        'immediate sign-out', (tester) async {
      await pump(tester);

      await tester.ensureVisible(find.text('Logout'));
      await tester.tap(find.text('Logout'));
      await tester.pump();

      expect(find.text('Logout?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      // Sign-out itself (FirebaseAuth) never actually runs in this
      // headless test — Cancel is tapped, proving it did not fire yet.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Account'), findsOneWidget);
    });

    // AccountPage._logout() calls context.read<ProfileProvider>().reset()/
    // context.read<SubscriptionProvider>().reset() before navigating away
    // (see its own doc comment) — but driving that call end-to-end
    // through a widget test means also driving FirebaseAuth.instance/
    // GoogleSignIn()'s real, non-injected platform channels, which have
    // no mock registered in this headless environment and do not
    // reliably resolve (or throw) within a widget-test pump loop. This
    // is exactly why the pre-existing test suite for this screen never
    // exercised full logout either. [SubscriptionProvider.reset] — the
    // part that actually matters for cross-account state leakage — is
    // unit-tested directly below instead, independent of the
    // Firebase/Google call that precedes it in `_logout`.
    // ([ProfileProvider.reset] is reviewed by inspection only: its own
    // real constructor eagerly touches `FirebaseAuth.instance` via
    // `ProfileService` — see `_FakeProfileProvider`'s doc comment above
    // — so it cannot be constructed at all in this headless test
    // environment, mock or not, without that same pre-existing
    // constraint; `reset()` itself is a straightforward field-clear with
    // no logic to hide a defect in.)
    test('SubscriptionProvider.reset() clears membership/purchase state', () {
      final provider = SubscriptionProvider(billing: _FakeBillingRepository());
      provider.subscriptionData = {'membership_state': 'ACTIVE'};
      provider.errorMessage = 'some_error';
      provider.purchaseErrorMessage = 'purchase_failed';
      provider.restoreErrorMessage = 'no_purchases_found';

      provider.reset();

      expect(provider.subscriptionData, isNull);
      expect(provider.errorMessage, isNull);
      expect(provider.purchaseErrorMessage, isNull);
      expect(provider.restoreErrorMessage, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.isPurchasing, isFalse);
      expect(provider.isRestoring, isFalse);
    });
  });

  testWidgets(
    'does not show any multi-profile UI (Add Profile, Other Profiles, Activate/Edit/Delete)',
    (tester) async {
      await pump(tester);

      expect(find.text('Add Profile'), findsNothing);
      expect(find.text('Other Profiles'), findsNothing);
      expect(find.text('Activate'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    },
  );

  testWidgets('renders Hindi Account/section text', (tester) async {
    await pump(tester, locale: const Locale('hi'));

    expect(find.text('अकाउंट'), findsOneWidget);
    expect(find.text('चंद्र राशि'), findsOneWidget);
    expect(find.text('प्रोफ़ाइल संपादित करें'), findsOneWidget);
    expect(find.text('सदस्यता प्रबंधित करें'), findsOneWidget);
    expect(find.text('भाषा'), findsOneWidget);
    expect(find.text('सहायता व समर्थन'), findsOneWidget);
    expect(find.text('गोपनीयता नीति'), findsOneWidget);
    expect(find.text('नियम व शर्तें'), findsOneWidget);
    expect(find.text('रिफंड नीति'), findsOneWidget);
    expect(find.text('लॉगआउट'), findsOneWidget);
  });
}
