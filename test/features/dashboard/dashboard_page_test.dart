import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/identity/current_user_identity_port.dart';
import 'package:jyotishasha_app/core/models/asknow/asknow_contracts.dart';
import 'package:jyotishasha_app/core/models/reports/report_contracts.dart';
import 'package:jyotishasha_app/core/repositories/billing_repository.dart';
import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/firebase_kundali_provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/notification_provider.dart';
import 'package:jyotishasha_app/core/state/panchang_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/state/subscription_provider.dart';
import 'package:jyotishasha_app/core/state/transit_provider.dart';
import 'package:jyotishasha_app/features/asknow/asknow_chat_page.dart';
import 'package:jyotishasha_app/features/dashboard/dashboard_page.dart';

import '../../helpers/test_harness.dart';

/// Task 4A — `DashboardHomeSection`'s own `_loadUnreadCount` needs a
/// signed-in Firebase user before it will do anything; this headless
/// test environment has no real Firebase, so DashboardPage now accepts
/// an injectable [CurrentUserIdentityPort] (forwarded straight through
/// to DashboardHomeSection) purely for this — a fake that resolves
/// immediately means the widget under test never has to actually wait
/// on the poll loop at all. Production never supplies this constructor
/// argument.
class _FakeCurrentUserIdentityPort implements CurrentUserIdentityPort {
  const _FakeCurrentUserIdentityPort();

  @override
  String? get currentFirebaseUid => 'test-uid';
}

/// `ProfileProvider`'s real constructor eagerly touches `FirebaseAuth`,
/// unavailable in this widget-test environment — same fake used across
/// `account_page_test.dart`/`greeting_header_widget_test.dart`.
class _FakeProfileProvider extends Mock
    with ChangeNotifier
    implements ProfileProvider {}

/// Same fake used across `explore_page_test.dart`/`account_page_test.dart`
/// — anything that could reach the real `PlayBillingRepository` would
/// otherwise throw via the Android platform channel in this headless
/// environment.
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

/// Captures every route pushed via `Navigator.push` — same pattern
/// already used in `kundali_overview_page_test.dart`/
/// `greeting_header_widget_test.dart`.
class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }
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
      "moon_sign": "Cancer",
      "lagna": "Aries",
      "nakshatra": "Rohini",
    });
    subscriptionProvider = SubscriptionProvider(
      billing: _FakeBillingRepository(),
    );
  });

  Future<void> pump(
    WidgetTester tester, {
    List<NavigatorObserver> navigatorObservers = const [],
    Locale? locale,
    String lang = 'en',
  }) async {
    await tester.pumpTestHarness(
      DashboardPage(identityPort: const _FakeCurrentUserIdentityPort()),
      locale: locale,
      navigatorObservers: navigatorObservers,
      providers: [
        ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
        ChangeNotifierProvider<SubscriptionProvider>.value(
          value: subscriptionProvider,
        ),
        ChangeNotifierProvider<LanguageProvider>.value(
          value: LanguageProvider()..currentLang = lang,
        ),
        ChangeNotifierProvider<DailyProvider>.value(value: DailyProvider()),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
        ChangeNotifierProvider<TransitProvider>(
          create: (_) => TransitProvider(),
        ),
        ChangeNotifierProvider<PanchangProvider>(
          create: (_) => PanchangProvider(),
        ),
        ChangeNotifierProvider<FirebaseKundaliProvider>(
          create: (_) => FirebaseKundaliProvider(),
        ),
      ],
    );
    // Flushes GreetingHeaderWidget's 2s-delayed unread-count fetch (now a
    // real, cancellable Timer — Task 4A) so no timer is left pending at
    // test teardown. DashboardHomeSection's own unread-count poll
    // resolves immediately via the fake identity port above, so this no
    // longer risks the pre-existing crash that previously blocked this
    // entire test file.
    await tester.pump(const Duration(seconds: 3));
  }

  group('Bottom navigation bar (Task 4 — Astrology replaced by Ask Now)', () {
    testWidgets(
      'shows Ask Now (not Astrology) at the second position, with the '
      'existing localized EN label and chat icon',
      (tester) async {
        await pump(tester);

        final nav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );

        expect(nav.items.length, 5);
        expect(nav.items[1].label, 'Ask Now');
        expect(nav.items[1].icon, isA<Icon>());
        expect((nav.items[1].icon as Icon).icon, Icons.chat_bubble_outline);
        expect((nav.items[1].activeIcon as Icon).icon, Icons.chat);

        // Astrology's old label/icon are gone from the bar entirely.
        expect(find.text('Astrology'), findsNothing);
        expect(
          nav.items.any(
            (i) => i.icon is Icon && (i.icon as Icon).icon == Icons.star_border,
          ),
          isFalse,
        );
      },
    );

    testWidgets('shows the Hindi Ask Now label', (tester) async {
      await pump(tester, locale: const Locale('hi'), lang: 'hi');

      final nav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(nav.items[1].label, 'पूछें');
    });

    testWidgets(
      'tapping Ask Now pushes AskNowChatPage and does NOT change the '
      'currently-selected dashboard tab',
      (tester) async {
        final observer = _RecordingNavigatorObserver();
        await pump(tester, navigatorObservers: [observer]);
        final baseline = observer.pushed.length;

        // Deliberately no `tester.pump()` after the tap: Navigator.push
        // (called synchronously from the button's onTap, itself invoked
        // synchronously by tester.tap()) already notifies
        // NavigatorObserver.didPush before any frame runs, so the pushed
        // route is fully inspectable here. Never letting Flutter actually
        // build/mount the real AskNowChatPage avoids its own real
        // Firebase/billing/ad-loading initState work (deliberately
        // off-limits — Ask Now's commercial logic is not part of this
        // task), exactly like this suite's existing
        // InAppWebView-avoidance pattern in kundali_overview_page_test.dart
        // and greeting_header_widget_test.dart's own CTA-push test.
        await tester.tap(find.text('Ask Now'));

        expect(observer.pushed.length, greaterThan(baseline));
        final route = observer.pushed.last as MaterialPageRoute;
        expect(
          route.builder(tester.element(find.byType(Scaffold).first)),
          isA<AskNowChatPage>(),
        );

        // The bottom nav itself still reports Home (index 0) selected —
        // tapping Ask Now never called _switchTab.
        final nav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(nav.currentIndex, 0);
      },
    );

    testWidgets(
      'closing Ask Now (popping the pushed route) never touches the '
      'underlying dashboard tab selection either',
      (tester) async {
        final observer = _RecordingNavigatorObserver();
        await pump(tester, navigatorObservers: [observer]);
        final baseline = observer.pushed.length;

        // Same no-pump-after-push rationale as the test above — the
        // route is pushed (and immediately popped) at the Navigator/
        // route-stack level without ever building the real
        // AskNowChatPage, which is exactly the layer _onBottomNavTap's
        // own contract (push, never touch _currentIndex) operates at.
        await tester.tap(find.text('Ask Now'));
        expect(observer.pushed.length, greaterThan(baseline));

        final navigatorState = tester.state<NavigatorState>(
          find.byType(Navigator).first,
        );
        navigatorState.pop();
        await tester.pump();

        final nav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(nav.currentIndex, 0);
      },
    );

    testWidgets('Home works — remains selected on initial load (index 0)', (
      tester,
    ) async {
      await pump(tester);

      final nav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(nav.currentIndex, 0);
    });

    testWidgets('Reports works — tapping it switches to index 2', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.byIcon(Icons.description_outlined));
      await tester.pumpAndSettle();

      final nav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(nav.currentIndex, 2);
    });

    testWidgets('Explore works — tapping it switches to index 3', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.byIcon(Icons.explore_outlined));
      await tester.pumpAndSettle();

      final nav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(nav.currentIndex, 3);
    });

    testWidgets('Account works — tapping it switches to index 4', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      final nav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(nav.currentIndex, 4);
    });
  });
}
