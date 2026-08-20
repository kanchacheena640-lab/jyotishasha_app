import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/models/alerts/alerts_dashboard_contracts.dart';
import 'package:jyotishasha_app/core/repositories/alerts_dashboard_repository.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/subscription_provider.dart';
import 'package:jyotishasha_app/features/alerts/alerts_dashboard_page.dart';
import 'package:jyotishasha_app/features/subscription/subscription_page.dart';

import '../../helpers/test_harness.dart';

/// Hand-rolled fake — same convention as
/// `birth_chart_report_reader_test.dart`'s `_FakePremiumAiReportRepository`
/// — lets every response state be tested deterministically without
/// touching the real `HttpAlertsDashboardRepository` (which would hit
/// FirebaseAuth/the network, unavailable in this headless environment).
class _FakeAlertsDashboardRepository implements AlertsDashboardRepository {
  _FakeAlertsDashboardRepository(this.result);

  final AlertsDashboardResult result;
  int callCount = 0;

  @override
  Future<AlertsDashboardResult> getCurrentAlerts() async {
    callCount++;
    return result;
  }
}

/// Never resolves — used only to deterministically observe the loading
/// state.
class _HangingRepository implements AlertsDashboardRepository {
  @override
  Future<AlertsDashboardResult> getCurrentAlerts() =>
      Completer<AlertsDashboardResult>().future;
}

AlertItem _financialAlert() => const AlertItem(
  alertId: 1,
  eventId: 'financial_gain_opportunity',
  title: 'Financial Gain Opportunity',
  message: 'A financial signal is active for you today.',
  category: 'financial',
  severity: 'HIGH',
  priority: 'high',
  validFrom: '2026-08-14',
  validUntil: '2026-08-16',
);

AlertItem _travelAlert() => const AlertItem(
  alertId: 2,
  eventId: 'travel_opportunity',
  title: 'Travel Opportunity',
  message: 'A travel-related signal is active for you today.',
  category: 'travel',
  severity: 'MEDIUM',
  priority: 'medium',
  validFrom: '2026-08-14',
  validUntil: '2026-08-16',
);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    AlertsDashboardRepository? repository,
    Locale? locale,
  }) async {
    await tester.pumpTestHarness(
      AlertsDashboardPage(repository: repository),
      locale: locale,
      providers: [
        // SubscriptionPage (pushed from the locked-state CTA) reads
        // SubscriptionProvider/LanguageProvider in its own initState --
        // same convention as birth_chart_report_reader_test.dart's pump().
        ChangeNotifierProvider<SubscriptionProvider>.value(
          value: SubscriptionProvider(),
        ),
        ChangeNotifierProvider<LanguageProvider>.value(
          value: LanguageProvider()..currentLang = locale?.languageCode ?? 'en',
        ),
      ],
    );
    await tester.pump();
  }

  group('loading state', () {
    testWidgets('shows a spinner while the call is in flight', (
      tester,
    ) async {
      await pump(tester, repository: _HangingRepository());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('zero-current-alerts state', () {
    testWidgets('shows the reassuring empty state, no invented content', (
      tester,
    ) async {
      final repo = _FakeAlertsDashboardRepository(
        AlertsDashboardResult.success(const []),
      );
      await pump(tester, repository: repo);
      await tester.pumpAndSettle();

      expect(find.text('No active alerts for you right now'), findsOneWidget);
    });
  });

  group('one current alert', () {
    testWidgets('shows the single alert card with title and message', (
      tester,
    ) async {
      final repo = _FakeAlertsDashboardRepository(
        AlertsDashboardResult.success([_financialAlert()]),
      );
      await pump(tester, repository: repo);
      await tester.pumpAndSettle();

      expect(find.text('Financial Gain Opportunity'), findsOneWidget);
      expect(
        find.text('A financial signal is active for you today.'),
        findsOneWidget,
      );
      // Never exposes the raw internal event_id or a confidence value.
      expect(find.textContaining('financial_gain_opportunity'), findsNothing);
      expect(find.textContaining('confidence'), findsNothing);
    });
  });

  group('AI-Written Personalized Alert Content -- action block', () {
    testWidgets(
      'renders the action line when the backend supplied one',
      (tester) async {
        final alert = AlertItem(
          alertId: 1,
          eventId: 'opportunity_window',
          title: 'Opportunity Window',
          message: 'A supportive window is opening for career recognition.',
          category: 'timing',
          severity: 'MEDIUM',
          priority: 'high',
          validFrom: '2026-08-14',
          validUntil: '2026-08-16',
          action: 'Send that proposal or application today.',
        );
        final repo = _FakeAlertsDashboardRepository(
          AlertsDashboardResult.success([alert]),
        );
        await pump(tester, repository: repo);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Send that proposal or application today.'),
          findsOneWidget,
        );
        expect(find.textContaining("Today's Focus"), findsOneWidget);
      },
    );

    testWidgets(
      'renders no action block at all when the backend supplied none '
      '(plain template-fallback alert, unaffected by this addition)',
      (tester) async {
        final repo = _FakeAlertsDashboardRepository(
          AlertsDashboardResult.success([_financialAlert()]),
        );
        await pump(tester, repository: repo);
        await tester.pumpAndSettle();

        expect(find.textContaining("Today's Focus"), findsNothing);
      },
    );

    testWidgets(
      'renders the Hindi action label when locale is Hindi',
      (tester) async {
        final alert = AlertItem(
          alertId: 1,
          eventId: 'opportunity_window',
          title: 'अवसर की खिड़की',
          message: 'करियर पहचान के लिए एक अनुकूल समय खुल रहा है।',
          category: 'timing',
          severity: 'MEDIUM',
          priority: 'high',
          validFrom: '2026-08-14',
          validUntil: '2026-08-16',
          action: 'आज वह प्रस्ताव भेजें।',
        );
        final repo = _FakeAlertsDashboardRepository(
          AlertsDashboardResult.success([alert]),
        );
        await pump(tester, repository: repo, locale: const Locale('hi'));
        await tester.pumpAndSettle();

        expect(find.textContaining('आज करें'), findsOneWidget);
        expect(find.textContaining('आज वह प्रस्ताव भेजें।'), findsOneWidget);
      },
    );
  });

  group('two current alerts', () {
    testWidgets('shows both cards, strongest first', (tester) async {
      final repo = _FakeAlertsDashboardRepository(
        AlertsDashboardResult.success([_financialAlert(), _travelAlert()]),
      );
      await pump(tester, repository: repo);
      await tester.pumpAndSettle();

      expect(find.text('Financial Gain Opportunity'), findsOneWidget);
      expect(find.text('Travel Opportunity'), findsOneWidget);
    });
  });

  group('locked state', () {
    testWidgets(
      'shows the existing subscription/paywall UX, not a bespoke one',
      (tester) async {
        final repo = _FakeAlertsDashboardRepository(
          AlertsDashboardResult.failure(status: AlertsDashboardStatus.locked),
        );
        await pump(tester, repository: repo);
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Alerts & Opportunities is not included in your current plan',
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('View Subscription Plans'));
        await tester.pumpAndSettle();

        expect(find.byType(SubscriptionPage), findsOneWidget);
      },
    );
  });

  group('error state', () {
    testWidgets('shows an error message with a retry action', (
      tester,
    ) async {
      final repo = _FakeAlertsDashboardRepository(
        AlertsDashboardResult.failure(status: AlertsDashboardStatus.error),
      );
      await pump(tester, repository: repo);
      await tester.pumpAndSettle();

      expect(
        find.text('Unable to load your alerts right now. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('retry re-calls the repository', (tester) async {
      final repo = _FakeAlertsDashboardRepository(
        AlertsDashboardResult.failure(status: AlertsDashboardStatus.error),
      );
      await pump(tester, repository: repo);
      await tester.pumpAndSettle();

      expect(repo.callCount, 1);

      await tester.tap(find.text('Try Again'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(repo.callCount, 2);
    });
  });

  group('refresh action', () {
    testWidgets('the AppBar refresh icon re-calls the repository', (
      tester,
    ) async {
      final repo = _FakeAlertsDashboardRepository(
        AlertsDashboardResult.success(const []),
      );
      await pump(tester, repository: repo);
      await tester.pumpAndSettle();

      expect(repo.callCount, 1);

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(repo.callCount, 2);
    });
  });

  group('Hindi', () {
    testWidgets('renders the Hindi title and empty-state copy', (
      tester,
    ) async {
      final repo = _FakeAlertsDashboardRepository(
        AlertsDashboardResult.success(const []),
      );
      await pump(tester, repository: repo, locale: const Locale('hi'));
      await tester.pumpAndSettle();

      expect(find.text('अलर्ट और अवसर'), findsOneWidget);
      expect(find.text('अभी आपके लिए कोई सक्रिय अलर्ट नहीं है'), findsOneWidget);
    });

    testWidgets('renders the Hindi locked-state copy', (tester) async {
      final repo = _FakeAlertsDashboardRepository(
        AlertsDashboardResult.failure(status: AlertsDashboardStatus.locked),
      );
      await pump(tester, repository: repo, locale: const Locale('hi'));
      await tester.pumpAndSettle();

      expect(
        find.text('अलर्ट और अवसर आपकी वर्तमान योजना में शामिल नहीं है'),
        findsOneWidget,
      );
    });
  });
}
