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
import 'package:jyotishasha_app/features/reports/pages/report_catalog_page.dart';
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
/// `subscription_page_test.dart` — the Premium Reports gate can push the
/// real `SubscriptionPage`, whose `autoLoad` would otherwise call the
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
        // ReportCatalogPage (a possible navigation target from the
        // Premium Reports gate) reads this on mount.
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

  group('Subscription card (S5.3 — live SubscriptionProvider, no more '
      'hardcoded "Free User")', () {
    testWidgets(
      'shows "-" (never a fabricated "Free User") before subscription '
      'data has loaded',
      (tester) async {
        await pump(tester);

        expect(find.text('Free User'), findsNothing);
        expect(find.text('-'), findsOneWidget);
      },
    );

    testWidgets(
      'shows the backend\'s own plan and status once loaded — never '
      'inferred',
      (tester) async {
        subscriptionProvider.subscriptionData = {
          'active': true,
          'plan': 'yearly',
          'status': 'active',
        };

        await pump(tester);

        expect(find.text('yearly • Active'), findsOneWidget);
      },
    );

    testWidgets(
      'shows just the capitalized status when the backend has no plan '
      'yet (e.g. a never-subscribed user)',
      (tester) async {
        subscriptionProvider.subscriptionData = {'status': 'none'};

        await pump(tester);

        expect(find.text('None'), findsOneWidget);
      },
    );
  });

  group('Premium Reports gate (S5.3)', () {
    testWidgets(
      'opens the existing SubscriptionPage (not a new dialog) when '
      'tapped without an active subscription',
      (tester) async {
        subscriptionProvider.subscriptionData = {'status': 'expired'};

        await pump(tester);

        await tester.tap(find.text('Premium Reports'));
        await tester.pumpAndSettle();

        expect(find.byType(SubscriptionPage), findsOneWidget);
        expect(find.byType(ReportCatalogPage), findsNothing);
      },
    );

    testWidgets(
      'opens the existing ReportCatalogPage (reused, not duplicated) when '
      'tapped with an active subscription',
      (tester) async {
        subscriptionProvider.subscriptionData = {
          'active': true,
          'status': 'active',
        };

        await pump(tester);

        await tester.tap(find.text('Premium Reports'));
        await tester.pumpAndSettle();

        expect(find.byType(ReportCatalogPage), findsOneWidget);
        expect(find.byType(SubscriptionPage), findsNothing);
      },
    );

    testWidgets(
      'no longer shows a "Coming Soon" snackbar for Premium Reports',
      (tester) async {
        subscriptionProvider.subscriptionData = {'status': 'none'};

        await pump(tester);

        await tester.tap(find.text('Premium Reports'));
        await tester.pump();

        expect(find.text('Coming Soon'), findsNothing);
      },
    );
  });

  testWidgets(
    'shows the services/general action rows including Logout',
    (tester) async {
      await pump(tester);

      for (final label in [
        'Free Horoscope PDF',
        'Premium Reports',
        'Downloads',
        'Settings',
        'Help & Support',
        'Logout',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    },
  );

  testWidgets(
    'does not show any multi-profile UI (Add Profile, Other Profiles, Activate/Edit/Delete)',
    (tester) async {
      await pump(tester);

      expect(find.text('Add Profile'), findsNothing);
      expect(find.text('Other Profiles'), findsNothing);
      expect(find.text('Activate'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    },
  );

  testWidgets('renders Hindi Account/Services text', (tester) async {
    await pump(tester, locale: const Locale('hi'));

    expect(find.text('अकाउंट'), findsOneWidget);
    expect(find.text('चंद्र राशि'), findsOneWidget);
    expect(find.text('लॉगआउट'), findsOneWidget);
  });
}
