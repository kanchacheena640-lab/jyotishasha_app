import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/models/premium_reports/premium_ai_report_contracts.dart';
import 'package:jyotishasha_app/core/repositories/premium_ai_report_repository.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/subscription_provider.dart';
import 'package:jyotishasha_app/features/premium_report/birth_chart_report_reader.dart';
import 'package:jyotishasha_app/features/premium_report/premium_report_type.dart';
import 'package:jyotishasha_app/features/subscription/subscription_page.dart';

import '../../helpers/test_harness.dart';

/// Hand-rolled fake — lets the real-content branch (Love only) be tested
/// deterministically without touching the real `HttpPremiumAiReportRepository`
/// (which would hit FirebaseAuth/the network, unavailable in this
/// headless environment).
class _FakePremiumAiReportRepository implements PremiumAiReportRepository {
  final Map<String, PremiumAiReportResult> results = {};
  final List<String> calls = [];

  @override
  Future<PremiumAiReportResult> getReport({
    required String segment,
    required String reportType,
    required String language,
  }) async {
    calls.add(reportType);
    return results[reportType] ??
        PremiumAiReportResult.failure(errorCode: 'not_configured');
  }
}

/// Never resolves — used only to deterministically observe the loading
/// state, without racing against the real (near-instant) Future
/// completion timing of [_FakePremiumAiReportRepository].
class _HangingRepository implements PremiumAiReportRepository {
  @override
  Future<PremiumAiReportResult> getReport({
    required String segment,
    required String reportType,
    required String language,
  }) => Completer<PremiumAiReportResult>().future;
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    PremiumReportType type, {
    PremiumAiReportRepository? repository,
    Locale? locale,
  }) async {
    await tester.pumpTestHarness(
      BirthChartReportReader(type: type, repository: repository),
      locale: locale,
      providers: [
        ChangeNotifierProvider<SubscriptionProvider>.value(
          value: SubscriptionProvider(),
        ),
        ChangeNotifierProvider<LanguageProvider>.value(
          value: LanguageProvider()..currentLang = locale?.languageCode ?? 'en',
        ),
      ],
    );
  }

  group('Reports with no backend generator (Career/Finance/Health/Family) '
      '— existing static content only, no network call', () {
    testWidgets(
      'shows the header, the free DNA section (existing About text), '
      'Current Phase/Current Timing (existing static content), a '
      '"Next Change" not-available notice, and the subscription CTA',
      (tester) async {
        await pump(tester, PremiumReportType.career);

        expect(find.text('Career Report'), findsOneWidget);
        expect(find.text('Premium Report'), findsOneWidget);

        expect(find.text('Your Career DNA'), findsOneWidget);
        expect(find.text('Birth Chart Based'), findsOneWidget);
        expect(
          find.textContaining('Career Report explores'),
          findsOneWidget,
        ); // existing PremiumReportContent.about text, reused verbatim

        expect(find.text('Current Career Phase'), findsOneWidget);
        expect(find.text('Current Phase'), findsOneWidget);
        expect(find.text('Current Timing'), findsOneWidget);
        expect(find.text('Next Change'), findsOneWidget);
        expect(find.text("This section isn't available yet."), findsOneWidget);

        expect(
          find.widgetWithText(OutlinedButton, 'View Subscription Plans'),
          findsOneWidget,
        );

        // No fabricated marketing copy, no prices.
        expect(find.textContaining('₹'), findsNothing);
      },
    );

    testWidgets(
      'shows a "Read Full {X} DNA →" toggle that expands the SAME section '
      'in place — never a navigation',
      (tester) async {
        await pump(tester, PremiumReportType.finance);

        expect(find.text('Read Full Finance DNA →'), findsOneWidget);
        expect(find.text('Show Less ↑'), findsNothing);

        await tester.tap(find.text('Read Full Finance DNA →'));
        await tester.pump();

        expect(find.text('Show Less ↑'), findsOneWidget);
        expect(find.text('Read Full Finance DNA →'), findsNothing);
        // Still on the same screen — no navigation happened.
        expect(find.byType(BirthChartReportReader), findsOneWidget);
      },
    );

    testWidgets('renders Hindi headings for Health', (tester) async {
      await pump(
        tester,
        PremiumReportType.health,
        locale: const Locale('hi'),
      );

      expect(find.text('स्वास्थ्य रिपोर्ट'), findsOneWidget);
      expect(find.text('आपकी स्वास्थ्य DNA'), findsOneWidget);
      expect(find.text('जन्म कुंडली आधारित'), findsOneWidget);
      expect(find.text('वर्तमान स्वास्थ्य चरण'), findsOneWidget);
      expect(find.text('अगला बदलाव'), findsOneWidget);
      expect(find.text('यह सेक्शन अभी उपलब्ध नहीं है।'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'सदस्यता प्लान देखें'),
        findsOneWidget,
      );
    });

    testWidgets(
      'tapping the subscription CTA opens the existing SubscriptionPage',
      (tester) async {
        await pump(tester, PremiumReportType.family);

        await tester.ensureVisible(find.text('View Subscription Plans'));
        await tester.tap(find.text('View Subscription Plans'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(SubscriptionPage), findsOneWidget);
      },
    );
  });

  group('Love — the only segment with a real backend generator', () {
    testWidgets(
      'shows a loading indicator for the free DNA section and the '
      'Current Phase sub-section while the real backend call is in '
      'flight',
      (tester) async {
        await pump(tester, PremiumReportType.love, repository: _HangingRepository());
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
      },
    );

    testWidgets(
      'shows the real backend DNA content on success — not the static '
      'placeholder text',
      (tester) async {
        final repository = _FakePremiumAiReportRepository()
          ..results[PremiumAiReportTypes.dna] = PremiumAiReportResult.success(
            'Your real, backend-generated Love DNA content appears here.',
          )
          ..results[PremiumAiReportTypes.currentPhase] =
              PremiumAiReportResult.success('Your real current phase reading.');

        await pump(tester, PremiumReportType.love, repository: repository);
        await tester.pump();

        expect(
          find.text('Your real, backend-generated Love DNA content appears here.'),
          findsOneWidget,
        );
        expect(find.text('Your real current phase reading.'), findsOneWidget);
        expect(find.textContaining('Love Report explores'), findsNothing);

        expect(repository.calls, containsAll([
          PremiumAiReportTypes.dna,
          PremiumAiReportTypes.currentPhase,
        ]));
      },
    );

    testWidgets(
      'collapses the real DNA content to 5 lines by default and expands '
      'it in place when "Read Full Love DNA →" is tapped',
      (tester) async {
        final repository = _FakePremiumAiReportRepository()
          ..results[PremiumAiReportTypes.dna] =
              PremiumAiReportResult.success('A long real Love DNA reading.')
          ..results[PremiumAiReportTypes.currentPhase] =
              PremiumAiReportResult.success('Phase reading.');

        await pump(tester, PremiumReportType.love, repository: repository);
        await tester.pump();

        final collapsedText = tester.widget<Text>(
          find.text('A long real Love DNA reading.'),
        );
        expect(collapsedText.maxLines, 5);
        expect(find.text('Read Full Love DNA →'), findsOneWidget);

        await tester.tap(find.text('Read Full Love DNA →'));
        await tester.pump();

        final expandedText = tester.widget<Text>(
          find.text('A long real Love DNA reading.'),
        );
        expect(expandedText.maxLines, isNull);
        expect(find.text('Show Less ↑'), findsOneWidget);

        await tester.tap(find.text('Show Less ↑'));
        await tester.pump();

        expect(find.text('Read Full Love DNA →'), findsOneWidget);
      },
    );

    testWidgets(
      'shows an entitlement notice (not raw content, no expand toggle) '
      'when the backend denies access',
      (tester) async {
        final repository = _FakePremiumAiReportRepository()
          ..results[PremiumAiReportTypes.dna] =
              PremiumAiReportResult.failure(errorCode: 'trial_expired')
          ..results[PremiumAiReportTypes.currentPhase] =
              PremiumAiReportResult.failure(errorCode: 'trial_expired');

        await pump(tester, PremiumReportType.love, repository: repository);
        await tester.pump();

        expect(
          find.textContaining('A subscription is required'),
          findsWidgets,
        );
        expect(find.text('Read Full Love DNA →'), findsNothing);
      },
    );

    testWidgets(
      'shows the backend\'s own error message with a Retry action for a '
      'non-entitlement error, and Retry re-invokes the repository',
      (tester) async {
        final repository = _FakePremiumAiReportRepository()
          ..results[PremiumAiReportTypes.dna] = PremiumAiReportResult.failure(
            errorCode: 'network_error',
            errorMessage: 'Connection failed.',
          )
          ..results[PremiumAiReportTypes.currentPhase] =
              PremiumAiReportResult.success('Phase reading.');

        await pump(tester, PremiumReportType.love, repository: repository);
        await tester.pump();

        expect(find.text('Connection failed.'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        final callsBefore = repository.calls.length;
        await tester.tap(find.text('Retry'));
        await tester.pump();

        expect(repository.calls.length, greaterThan(callsBefore));
      },
    );

    testWidgets(
      '"Current Timing" and "Next Change" stay on existing static '
      'content for Love too — no backend report type maps to them',
      (tester) async {
        final repository = _FakePremiumAiReportRepository()
          ..results[PremiumAiReportTypes.dna] =
              PremiumAiReportResult.success('DNA.')
          ..results[PremiumAiReportTypes.currentPhase] =
              PremiumAiReportResult.success('Phase.');

        await pump(tester, PremiumReportType.love, repository: repository);
        await tester.pump();

        expect(find.text('Current Timing'), findsOneWidget);
        expect(find.text('Next Change'), findsOneWidget);
        expect(find.text("This section isn't available yet."), findsOneWidget);
      },
    );
  });
}
