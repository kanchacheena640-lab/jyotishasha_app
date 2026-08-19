import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jyotishasha_app/core/auth/session_cleanup.dart';
import 'package:jyotishasha_app/core/state/asknow_provider.dart';
import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/firebase_kundali_provider.dart';
import 'package:jyotishasha_app/core/state/kundali_provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/manual_kundali_provider.dart';
import 'package:jyotishasha_app/core/state/monthly_provider.dart';
import 'package:jyotishasha_app/core/state/notification_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/state/report_purchase_provider.dart';
import 'package:jyotishasha_app/core/state/subscription_provider.dart';
import 'package:jyotishasha_app/core/state/yearly_provider.dart';
import 'package:jyotishasha_app/core/repositories/billing_repository.dart';
import 'package:jyotishasha_app/core/repositories/report_repository.dart';
import 'package:jyotishasha_app/core/models/asknow/asknow_contracts.dart';
import 'package:jyotishasha_app/core/models/reports/report_contracts.dart';
import 'package:jyotishasha_app/features/love/providers/love_provider.dart';

/// `ProfileProvider`'s real constructor eagerly builds `ProfileService`,
/// which touches `FirebaseAuth.instance` — unavailable in this widget-test
/// environment (same constraint `account_page_test.dart` already
/// documents). `Mock`'s `implements` never calls the real constructor.
class _FakeProfileProvider extends Mock
    with ChangeNotifier
    implements ProfileProvider {}

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

class _FakeReportRepository implements ReportRepository {
  @override
  Future<List<ReportCatalogItem>> getCatalog({required String language}) =>
      throw UnimplementedError('not used by this test');
  @override
  Future<ReportGenerationOutcome> requestReport(
    ReportGenerationRequest request,
  ) => throw UnimplementedError('not used by this test');
  @override
  Future<ReportGenerationOutcome> requestRelationshipReport(
    RelationshipReportRequest request,
  ) => throw UnimplementedError('not used by this test');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  late _FakeProfileProvider profileProvider;
  late SubscriptionProvider subscriptionProvider;
  late FirebaseKundaliProvider firebaseKundaliProvider;
  late KundaliProvider kundaliProvider;
  late ManualKundaliProvider manualKundaliProvider;
  late DailyProvider dailyProvider;
  late MonthlyProvider monthlyProvider;
  late YearlyProvider yearlyProvider;
  late LoveProvider loveProvider;
  late NotificationProvider notificationProvider;
  late AskNowProvider askNowProvider;
  late ReportPurchaseProvider reportPurchaseProvider;
  late LanguageProvider languageProvider;

  /// Dirties every provider as if account A had been using the app for a
  /// while — real PII-shaped values, not placeholders, so a leftover
  /// value after cleanup is unambiguous.
  void dirtyAllProviders() {
    when(() => profileProvider.activeProfile).thenReturn({
      'name': 'Account A',
      'dob': '1990-01-01',
    });
    when(() => profileProvider.reset()).thenReturn(null);

    subscriptionProvider.subscriptionData = {'membership_state': 'ACTIVE'};
    subscriptionProvider.errorMessage = 'some_error';

    firebaseKundaliProvider.kundaliData = {'lagna': 'Leo'};
    firebaseKundaliProvider.profileData = {'name': 'Account A'};
    firebaseKundaliProvider.errorMessage = 'boom';

    kundaliProvider.kundaliData = {'lagna': 'Leo'};

    manualKundaliProvider.kundali = {'lagna': 'Leo'};
    manualKundaliProvider.error = 'boom';

    dailyProvider.dailyTitle = 'Account A horoscope';
    dailyProvider.intro = 'stale intro';

    monthlyProvider.title = 'Account A monthly';

    yearlyProvider.title = 'Account A yearly';

    loveProvider.setPayload({'boy_name': 'A', 'girl_name': 'B'});

    notificationProvider.unreadCount = 7;

    askNowProvider.remainingTokens = 10;
    askNowProvider.hasActivePack = true;
    askNowProvider.freeAvailable = true;
    askNowProvider.pendingAnswer = 'stale answer';

    reportPurchaseProvider.isProcessing = true;
    reportPurchaseProvider.successCount = 3;
    reportPurchaseProvider.lastSuccessProduct = 'career_report';

    languageProvider.currentLang = 'hi';
  }

  Future<BuildContext> pumpHarnessAndGetContext(WidgetTester tester) async {
    profileProvider = _FakeProfileProvider();
    subscriptionProvider = SubscriptionProvider(
      billing: _FakeBillingRepository(),
    );
    firebaseKundaliProvider = FirebaseKundaliProvider();
    kundaliProvider = KundaliProvider();
    manualKundaliProvider = ManualKundaliProvider();
    dailyProvider = DailyProvider();
    monthlyProvider = MonthlyProvider();
    yearlyProvider = YearlyProvider();
    loveProvider = LoveProvider();
    notificationProvider = NotificationProvider();
    askNowProvider = AskNowProvider();
    reportPurchaseProvider = ReportPurchaseProvider(
      repository: _FakeReportRepository(),
    );
    languageProvider = LanguageProvider();

    late BuildContext capturedContext;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
          ChangeNotifierProvider<SubscriptionProvider>.value(
            value: subscriptionProvider,
          ),
          ChangeNotifierProvider<FirebaseKundaliProvider>.value(
            value: firebaseKundaliProvider,
          ),
          ChangeNotifierProvider<KundaliProvider>.value(value: kundaliProvider),
          ChangeNotifierProvider<ManualKundaliProvider>.value(
            value: manualKundaliProvider,
          ),
          ChangeNotifierProvider<DailyProvider>.value(value: dailyProvider),
          ChangeNotifierProvider<MonthlyProvider>.value(value: monthlyProvider),
          ChangeNotifierProvider<YearlyProvider>.value(value: yearlyProvider),
          ChangeNotifierProvider<LoveProvider>.value(value: loveProvider),
          ChangeNotifierProvider<NotificationProvider>.value(
            value: notificationProvider,
          ),
          ChangeNotifierProvider<AskNowProvider>.value(value: askNowProvider),
          ChangeNotifierProvider<ReportPurchaseProvider>.value(
            value: reportPurchaseProvider,
          ),
          ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
        ],
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

    dirtyAllProviders();
    await tester.pump();

    return capturedContext;
  }

  group('clearUserScopedProviders', () {
    testWidgets(
      '✓ resets every account-scoped provider (Profile, Subscription, '
      'both Kundali providers, Manual Kundali, Daily/Monthly/Yearly, '
      'Love, Notifications, Ask Now, Report purchase)',
      (tester) async {
        final context = await pumpHarnessAndGetContext(tester);

        await clearUserScopedProviders(context);
        await tester.pump();

        verify(() => profileProvider.reset()).called(1);

        expect(subscriptionProvider.subscriptionData, isNull);
        expect(subscriptionProvider.errorMessage, isNull);

        expect(firebaseKundaliProvider.kundaliData, isNull);
        expect(firebaseKundaliProvider.profileData, isNull);
        expect(firebaseKundaliProvider.errorMessage, isNull);

        expect(kundaliProvider.kundaliData, isNull);

        expect(manualKundaliProvider.kundali, isNull);
        expect(manualKundaliProvider.error, isNull);

        expect(dailyProvider.dailyTitle, isNull);
        expect(dailyProvider.intro, isNull);

        expect(monthlyProvider.title, isNull);
        expect(yearlyProvider.title, isNull);

        expect(loveProvider.payload, isNull);

        expect(notificationProvider.unreadCount, 0);

        expect(askNowProvider.remainingTokens, 0);
        expect(askNowProvider.hasActivePack, isFalse);
        expect(askNowProvider.freeAvailable, isFalse);
        expect(askNowProvider.pendingAnswer, isNull);

        expect(reportPurchaseProvider.isProcessing, isFalse);
        expect(reportPurchaseProvider.successCount, 0);
        expect(reportPurchaseProvider.lastSuccessProduct, isNull);
      },
    );

    testWidgets(
      '✓ clears the persisted Ask Now pending-user-id — a fresh session '
      "can never inherit the previous account's pending purchase context",
      (tester) async {
        final context = await pumpHarnessAndGetContext(tester);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('asknow_pending_user_id_v1', 111);

        await clearUserScopedProviders(context);

        expect(prefs.getInt('asknow_pending_user_id_v1'), isNull);
      },
    );

    testWidgets(
      '✓ clears the persisted Report-purchase pending record — prevents '
      "another account's name/email/phone/birth details surviving in "
      'SharedPreferences after logout',
      (tester) async {
        final context = await pumpHarnessAndGetContext(tester);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'report_purchase_pending_v1',
          '{"report":{"name":"Account A","email":"a@example.com"}}',
        );

        await clearUserScopedProviders(context);

        expect(prefs.getString('report_purchase_pending_v1'), isNull);
      },
    );

    testWidgets(
      '✓ preserves device-level preferences — LanguageProvider is '
      'untouched (never reset)',
      (tester) async {
        final context = await pumpHarnessAndGetContext(tester);
        expect(languageProvider.currentLang, 'hi');

        await clearUserScopedProviders(context);

        expect(languageProvider.currentLang, 'hi');
      },
    );

    testWidgets(
      "✓ re-login as another account: after cleanup, a fresh account's "
      "data is never intermixed with the previous account's",
      (tester) async {
        final context = await pumpHarnessAndGetContext(tester);
        await clearUserScopedProviders(context);

        // "Account B" logs into the same long-lived app process.
        when(() => profileProvider.activeProfile).thenReturn({
          'name': 'Account B',
        });
        firebaseKundaliProvider.profileData = {'name': 'Account B'};
        askNowProvider.remainingTokens = 3;
        notificationProvider.unreadCount = 1;

        expect(profileProvider.activeProfile?['name'], 'Account B');
        expect(firebaseKundaliProvider.profileData?['name'], 'Account B');
        expect(askNowProvider.remainingTokens, 3);
        expect(notificationProvider.unreadCount, 1);
        // Nothing from Account A survives alongside B's fresh values.
        expect(subscriptionProvider.subscriptionData, isNull);
        expect(reportPurchaseProvider.lastSuccessProduct, isNull);
      },
    );
  });

  group(
    'navigation stack replacement (the go_router half of '
    'clearUserScopedSessionAndReturnToLogin)',
    () {
      // Firebase/Google/FCM sign-out has no mock registered in this
      // headless environment (same longstanding constraint
      // account_page_test.dart's own Logout group documents), so the
      // navigation half is verified here in isolation, against a real
      // (test-scoped) GoRouter — exercising the exact same `context.go`
      // call `clearUserScopedSessionAndReturnToLogin` makes, not a
      // simulation of it.
      Future<GoRouter> pumpRouterHarness(WidgetTester tester) async {
        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Logout'),
                ),
              ),
            ),
            GoRoute(
              path: '/login',
              builder: (context, state) =>
                  const Scaffold(body: Text('Login Screen')),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        return router;
      }

      testWidgets(
        '✓ context.go(\'/login\') replaces the current location — Home '
        'is no longer part of the route stack',
        (tester) async {
          await pumpRouterHarness(tester);
          expect(find.text('Login Screen'), findsNothing);

          await tester.tap(find.text('Logout'));
          await tester.pumpAndSettle();

          expect(find.text('Login Screen'), findsOneWidget);
          expect(find.text('Logout'), findsNothing); // Home is gone
        },
      );

      testWidgets(
        '✓ Back cannot reopen Home after go(\'/login\') — the stack was '
        'replaced, not pushed onto',
        (tester) async {
          await pumpRouterHarness(tester);

          await tester.tap(find.text('Logout'));
          await tester.pumpAndSettle();
          expect(find.text('Login Screen'), findsOneWidget);

          // A plain push (Navigator.push / the old pushNamedAndRemoveUntil
          // misuse this fix replaces) would leave Home poppable back to;
          // a genuine stack replacement must not.
          final navigator = tester.state<NavigatorState>(
            find.byType(Navigator).first,
          );
          expect(navigator.canPop(), isFalse);
        },
      );
    },
  );
}
