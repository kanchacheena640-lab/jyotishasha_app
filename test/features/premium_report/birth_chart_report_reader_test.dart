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

/// Hand-rolled fake — lets the real-content path (now every segment: Love,
/// Career, Finance, Health, Family) be tested deterministically without
/// touching the real `HttpPremiumAiReportRepository` (which would hit
/// FirebaseAuth/the network, unavailable in this headless environment).
class _FakePremiumAiReportRepository implements PremiumAiReportRepository {
  final Map<String, PremiumAiReportResult> results = {};
  final List<String> calls = [];
  final List<String> segmentCalls = [];

  @override
  Future<PremiumAiReportResult> getReport({
    required String segment,
    required String reportType,
    required String language,
  }) async {
    calls.add(reportType);
    segmentCalls.add(segment);
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
    // Defaults to no active entitlement — the realistic default for a
    // user who just tapped a report card, and the scenario the premium
    // gate exists for. Individual tests opt into `unlocked: true` to
    // cover the entitled (ACTIVE) path, or pass `membershipState`
    // directly to exercise TRIAL/GRACE_PERIOD/etc.
    bool unlocked = false,
    String? membershipState,
  }) async {
    final state = membershipState ?? (unlocked ? 'ACTIVE' : null);
    await tester.pumpTestHarness(
      BirthChartReportReader(type: type, repository: repository),
      locale: locale,
      providers: [
        ChangeNotifierProvider<SubscriptionProvider>.value(
          value: SubscriptionProvider()
            ..subscriptionData = state != null
                ? {'membership_state': state}
                : null,
        ),
        ChangeNotifierProvider<LanguageProvider>.value(
          value: LanguageProvider()..currentLang = locale?.languageCode ?? 'en',
        ),
      ],
    );
  }

  group('The report always opens — free DNA section is never gated', () {
    testWidgets(
      'shows the header, the free DNA section (real backend content, not '
      'the static About text) and the subscription CTA regardless of '
      'entitlement',
      (tester) async {
        final repository = _FakePremiumAiReportRepository()
          ..results[PremiumAiReportTypes.dna] = PremiumAiReportResult.success(
            'Your real, backend-generated Career DNA content appears here.',
          );

        await pump(tester, PremiumReportType.career, repository: repository);
        await tester.pump();

        expect(find.text('Career Report'), findsOneWidget);
        expect(find.text('Premium Report'), findsOneWidget);

        expect(find.text('Your Career DNA'), findsOneWidget);
        expect(find.text('Birth Chart Based'), findsOneWidget);
        expect(
          find.text(
            'Your real, backend-generated Career DNA content appears here.',
          ),
          findsOneWidget,
        );
        // The old static About fallback is gone now that DNA is real —
        // same as Love's own equivalent assertion.
        expect(find.textContaining('Career Report explores'), findsNothing);

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
      'in place — never a navigation — and is unaffected by entitlement',
      (tester) async {
        final repository = _FakePremiumAiReportRepository()
          ..results[PremiumAiReportTypes.dna] = PremiumAiReportResult.success(
            'A long real Finance DNA reading.',
          );

        await pump(tester, PremiumReportType.finance, repository: repository);
        await tester.pump();

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
        repository: _FakePremiumAiReportRepository(),
      );
      await tester.pump();

      expect(find.text('स्वास्थ्य रिपोर्ट'), findsOneWidget);
      expect(find.text('आपकी स्वास्थ्य DNA'), findsOneWidget);
      expect(find.text('जन्म कुंडली आधारित'), findsOneWidget);
      expect(find.text('वर्तमान स्वास्थ्य चरण'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'सदस्यता प्लान देखें'),
        findsOneWidget,
      );
    });

    testWidgets(
      'tapping the subscription CTA opens the existing SubscriptionPage',
      (tester) async {
        await pump(
          tester,
          PremiumReportType.family,
          repository: _FakePremiumAiReportRepository(),
        );
        await tester.pump();

        await tester.ensureVisible(find.text('View Subscription Plans'));
        await tester.tap(find.text('View Subscription Plans'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(SubscriptionPage), findsOneWidget);
      },
    );
  });

  group(
    'Each type requests its own backend segment — not a hardcoded LOVE',
    () {
      for (final entry in {
        PremiumReportType.love: 'LOVE',
        PremiumReportType.career: 'CAREER',
        PremiumReportType.finance: 'FINANCE',
        PremiumReportType.health: 'HEALTH',
        PremiumReportType.family: 'FAMILY',
      }.entries) {
        testWidgets(
          '${entry.value}: both DNA and Current Phase calls carry segment '
          '"${entry.value}"',
          (tester) async {
            final repository = _FakePremiumAiReportRepository();

            await pump(tester, entry.key, repository: repository);
            await tester.pump();

            expect(repository.segmentCalls, isNotEmpty);
            expect(
              repository.segmentCalls.every((s) => s == entry.value),
              isTrue,
              reason:
                  'expected every getReport() call for ${entry.key} to use '
                  'segment "${entry.value}", got ${repository.segmentCalls}',
            );
          },
        );
      }
    },
  );

  group(
    'Premium gate — exactly two premium sections: Current Phase (collapsed) '
    'and Current Timing (always expanded); Watch Out For / Remedy / Next '
    'Phase Change are never independent cards',
    () {
      testWidgets(
        'LOCKED by default (no active entitlement): both premium sections '
        'show an unlock prompt instead of their content, while the free '
        'DNA section stays fully visible',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.dna] = PremiumAiReportResult.success(
              'Your real, backend-generated Career DNA content appears here.',
            );

          await pump(tester, PremiumReportType.career, repository: repository);
          await tester.pump();

          // Outer segment-flavored section labels are always visible —
          // only the card content underneath is replaced by the lock
          // prompt.
          expect(find.text('Current Career Phase'), findsOneWidget);
          expect(find.text('Current Career Timing'), findsOneWidget);

          // Exactly two gated cards now (down from four/five) — Current
          // Phase and Current Timing are the only two premium sections.
          expect(find.text('Current Phase'), findsOneWidget);
          expect(find.text('Current Timing'), findsOneWidget);
          expect(
            find.text('Unlock with Premium Membership →'),
            findsNWidgets(2),
          );
          expect(find.byIcon(Icons.lock_rounded), findsNWidgets(2));

          // Watch Out For / Remedy / Next Phase Change / Quick Tip never
          // appear as their own cards — locked or not, they only exist
          // inside the expanded Current Phase report and Current Timing
          // card, both of which are fully hidden behind the lock here.
          expect(find.text('Watch Out For'), findsNothing);
          expect(find.text('Remedy For This Phase'), findsNothing);
          expect(find.text('Next Phase Change'), findsNothing);
          expect(find.text('Quick Tip'), findsNothing);
          expect(find.textContaining('static preview'), findsNothing);
          expect(find.text('Birth Chart Foundation — Current'), findsNothing);

          // The free section is completely unaffected by the gate — real
          // backend content, not the static About fallback.
          expect(find.text('Your Career DNA'), findsOneWidget);
          expect(
            find.text(
              'Your real, backend-generated Career DNA content appears here.',
            ),
            findsOneWidget,
          );
          expect(find.textContaining('Career Report explores'), findsNothing);
        },
      );

      testWidgets(
        'UNLOCKED, legacy plain-text CURRENT_PHASE response (no headings): '
        'Current Phase shows that raw content as its collapsed excerpt; '
        'Current Timing and Quick Tip fall back to their pre-existing '
        'static copy; the three sub-sections stay hidden until expanded',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.dna] = PremiumAiReportResult.success(
              'Career DNA.',
            )
            ..results[PremiumAiReportTypes.currentPhase] =
                PremiumAiReportResult.success(
                  'Your real current Career phase reading.',
                );

          await pump(
            tester,
            PremiumReportType.career,
            unlocked: true,
            repository: repository,
          );
          await tester.pump();

          expect(find.text('Unlock with Premium Membership →'), findsNothing);
          expect(find.byIcon(Icons.lock_rounded), findsNothing);

          expect(
            find.text('Your real current Career phase reading.'),
            findsOneWidget,
          );
          expect(find.text('Read Full Current Phase Report →'), findsOneWidget);
          expect(find.textContaining('static preview'), findsNothing);

          // Current Timing is always expanded — no toggle, immediately
          // visible, falling back to the exact static copy this screen
          // has always shown for it.
          expect(find.text('Birth Chart Foundation — Current'), findsOneWidget);
          expect(find.text('Quick Tip'), findsOneWidget);
          expect(
            find.text("Remedy details aren't available yet."),
            findsOneWidget,
          );

          // Collapsed — the three supporting sub-sections aren't visible
          // yet.
          expect(find.text('Watch Out For'), findsNothing);
          expect(find.text('Remedy For This Phase'), findsNothing);
          expect(find.text('Next Phase Change'), findsNothing);
        },
      );

      testWidgets(
        'expanding Current Phase reveals the continuous report — Watch Out '
        'For / Remedy For This Phase / Next Phase Change appear in order, '
        'each with its own placeholder (legacy no-heading response)',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.currentPhase] =
                PremiumAiReportResult.success(
                  'Your real current Career phase reading.',
                );

          await pump(
            tester,
            PremiumReportType.career,
            unlocked: true,
            repository: repository,
          );
          await tester.pump();

          await tester.tap(find.text('Read Full Current Phase Report →'));
          await tester.pump();

          expect(find.text('Show Less ↑'), findsOneWidget);
          expect(find.text('Read Full Current Phase Report →'), findsNothing);

          expect(find.text('Watch Out For'), findsOneWidget);
          expect(
            find.text('No specific watch-outs available yet.'),
            findsOneWidget,
          );
          expect(find.text('Remedy For This Phase'), findsOneWidget);
          expect(find.text('Next Phase Change'), findsOneWidget);
          expect(
            find.text("This section isn't available yet."),
            findsOneWidget,
          );

          // "Remedy details aren't available yet." now appears twice —
          // once as the expanded Remedy For This Phase sub-section, once
          // as Quick Tip under Current Timing (same reused value, by
          // design).
          expect(
            find.text("Remedy details aren't available yet."),
            findsNWidgets(2),
          );

          // Collapsing goes back to the excerpt-only view. The expanded
          // report pushes the toggle below the fold in this viewport, so
          // scroll it into view first (same pattern already used for the
          // subscription CTA above).
          await tester.ensureVisible(find.text('Show Less ↑'));
          await tester.tap(find.text('Show Less ↑'));
          await tester.pump();
          expect(find.text('Watch Out For'), findsNothing);
          expect(find.text('Read Full Current Phase Report →'), findsOneWidget);
        },
      );

      testWidgets('renders the locked prompt in Hindi', (tester) async {
        await pump(
          tester,
          PremiumReportType.health,
          locale: const Locale('hi'),
          repository: _FakePremiumAiReportRepository(),
        );
        await tester.pump();

        expect(
          find.text('प्रीमियम मेंबरशिप के साथ अनलॉक करें →'),
          findsNWidgets(2),
        );
      });

      testWidgets('tapping a locked premium section opens the existing '
          'SubscriptionPage via the existing requirePremium gate — no new '
          'purchase UI', (tester) async {
        await pump(
          tester,
          PremiumReportType.career,
          repository: _FakePremiumAiReportRepository(),
        );
        await tester.pump();

        await tester.tap(find.text('Current Phase').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(SubscriptionPage), findsOneWidget);
      });

      testWidgets(
        'TRIAL unlocks both premium sections exactly like ACTIVE — a trial '
        'user sees the same content a paid user would',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.dna] = PremiumAiReportResult.success(
              'Career DNA.',
            )
            ..results[PremiumAiReportTypes.currentPhase] =
                PremiumAiReportResult.success(
                  'Your real current Career phase reading.',
                );

          await pump(
            tester,
            PremiumReportType.career,
            membershipState: 'TRIAL',
            repository: repository,
          );
          await tester.pump();

          expect(find.text('Unlock with Premium Membership →'), findsNothing);
          expect(find.byIcon(Icons.lock_rounded), findsNothing);

          expect(
            find.text('Your real current Career phase reading.'),
            findsOneWidget,
          );
          expect(find.text('Birth Chart Foundation — Current'), findsOneWidget);
        },
      );
    },
  );

  // Love — reference-implementation-specific assertions. Unaffected by
  // extending Career/Finance/Health/Family above: every test in this
  // group already used a fake/hanging repository (never the real
  // HttpPremiumAiReportRepository), and none of them is modified here.
  group(
    'Love — reference implementation (DNA, Current Phase, error paths)',
    () {
      testWidgets('shows a loading indicator for the free DNA section, Current '
          'Phase and Current Timing — three independent cards now read the '
          'same in-flight call (already entitled)', (tester) async {
        await pump(
          tester,
          PremiumReportType.love,
          repository: _HangingRepository(),
          unlocked: true,
        );
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNWidgets(3));
      });

      testWidgets(
        'shows the real backend DNA content on success — not the static '
        'placeholder text (already entitled)',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.dna] = PremiumAiReportResult.success(
              'Your real, backend-generated Love DNA content appears here.',
            )
            ..results[PremiumAiReportTypes.currentPhase] =
                PremiumAiReportResult.success(
                  'Your real current phase reading.',
                );

          await pump(
            tester,
            PremiumReportType.love,
            repository: repository,
            unlocked: true,
          );
          await tester.pump();

          expect(
            find.text(
              'Your real, backend-generated Love DNA content appears here.',
            ),
            findsOneWidget,
          );
          expect(find.text('Your real current phase reading.'), findsOneWidget);
          expect(find.textContaining('Love Report explores'), findsNothing);

          expect(
            repository.calls,
            containsAll([
              PremiumAiReportTypes.dna,
              PremiumAiReportTypes.currentPhase,
            ]),
          );
        },
      );

      testWidgets(
        'collapses the real DNA content to 5 lines by default and expands '
        'it in place when "Read Full Love DNA →" is tapped — unaffected by '
        'entitlement (DNA is always free)',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.dna] = PremiumAiReportResult.success(
              'A long real Love DNA reading.',
            )
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
          // Current Phase's own toggle uses the same generic "Show Less
          // ↑" wording but stays independently collapsed here (its own
          // `_phaseExpanded` state) — exactly one match, from DNA.
          expect(find.text('Show Less ↑'), findsOneWidget);

          await tester.tap(find.text('Show Less ↑'));
          await tester.pump();

          expect(find.text('Read Full Love DNA →'), findsOneWidget);
        },
      );

      testWidgets(
        'Your Love DNA always renders the real backend response directly, '
        'with no special-casing and no fallback — the backend now serves '
        'DNA without any entitlement check, so the temporary '
        'entitlement-denied-to-fallback workaround has been removed',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.dna] = PremiumAiReportResult.success(
              'Your real, backend-generated Love DNA content appears here.',
            )
            ..results[PremiumAiReportTypes.currentPhase] =
                PremiumAiReportResult.success(
                  'Your real current phase reading.',
                );

          await pump(
            tester,
            PremiumReportType.love,
            repository: repository,
            unlocked: true,
          );
          await tester.pump();

          // Real backend content, not the static About fallback.
          expect(
            find.text(
              'Your real, backend-generated Love DNA content appears here.',
            ),
            findsOneWidget,
          );
          expect(find.textContaining('Love Report explores'), findsNothing);
        },
      );

      testWidgets(
        'if the backend were to still return an entitlement-denied DNA '
        'result, it is shown as-is (no fallback reintroduced) — proving '
        'the removed workaround is genuinely gone, per spec',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.dna] = PremiumAiReportResult.failure(
              errorCode: 'trial_expired',
            );

          await pump(
            tester,
            PremiumReportType.love,
            repository: repository,
            unlocked: true,
          );
          await tester.pump();

          expect(
            find.textContaining('A subscription is required'),
            findsOneWidget,
          );
          // No fallback About text and no expand toggle — the result is
          // passed straight through, not redirected.
          expect(find.textContaining('Love Report explores'), findsNothing);
          expect(find.text('Read Full Love DNA →'), findsNothing);
        },
      );

      testWidgets(
        'shows the backend\'s own error message with a Retry action for a '
        'non-entitlement error, and Retry re-invokes the repository '
        '(already entitled)',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.dna] = PremiumAiReportResult.failure(
              errorCode: 'network_error',
              errorMessage: 'Connection failed.',
            )
            ..results[PremiumAiReportTypes.currentPhase] =
                PremiumAiReportResult.success('Phase reading.');

          await pump(
            tester,
            PremiumReportType.love,
            repository: repository,
            unlocked: true,
          );
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
        'Current Timing and Quick Tip fall back to their own placeholder '
        'copy for Love too when entitled and the response has no headings '
        '— Watch Out For / Remedy / Next Phase Change stay hidden until '
        'Current Phase is expanded',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.dna] = PremiumAiReportResult.success(
              'DNA.',
            )
            ..results[PremiumAiReportTypes.currentPhase] =
                PremiumAiReportResult.success('Phase.');

          await pump(
            tester,
            PremiumReportType.love,
            repository: repository,
            unlocked: true,
          );
          await tester.pump();

          expect(find.text('Current Timing'), findsOneWidget);
          expect(find.text('Quick Tip'), findsOneWidget);
          expect(find.text('Birth Chart Foundation — Current'), findsOneWidget);
          expect(
            find.text("Remedy details aren't available yet."),
            findsOneWidget,
          );
          expect(find.text('Watch Out For'), findsNothing);
          expect(find.text('Next Phase Change'), findsNothing);
        },
      );

      testWidgets(
        'Current Phase and Current Timing are both LOCKED for Love too '
        'when not entitled, even though the free DNA section still '
        'renders its real backend content',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.dna] = PremiumAiReportResult.success(
              'Your real, backend-generated Love DNA content appears here.',
            )
            ..results[PremiumAiReportTypes.currentPhase] =
                PremiumAiReportResult.success(
                  'Your real current phase reading.',
                );

          await pump(tester, PremiumReportType.love, repository: repository);
          await tester.pump();

          // Free section: real content, ungated.
          expect(
            find.text(
              'Your real, backend-generated Love DNA content appears here.',
            ),
            findsOneWidget,
          );

          // Premium: locked, even though the backend would have granted it.
          expect(find.text('Your real current phase reading.'), findsNothing);
          expect(
            find.text('Unlock with Premium Membership →'),
            findsNWidgets(2),
          );
        },
      );
    },
  );

  group('Current Phase / Current Timing sourced from the five-heading '
      'CURRENT_PHASE markdown (Current Phase / Next Phase Change / Watch '
      'Out For / Remedy For This Phase / Current Timing) — presentation '
      'layer only; the backend response format itself is untouched', () {
    // Mirrors the live backend's actual CURRENT_PHASE response shape.
    const markdownBody =
        '## Current Phase\n'
        'You are in a growth phase.\n\n'
        '## Next Phase Change\n'
        'A shift is expected in the next 6 weeks.\n\n'
        '## Watch Out For\n'
        'Avoid impulsive financial decisions this month.\n\n'
        '## Remedy For This Phase\n'
        'Wear a citrine on Thursdays.\n\n'
        '## Current Timing\n'
        'Jupiter transits your 10th house until October.';

    for (final entry in {
      PremiumReportType.love: 'Love',
      PremiumReportType.career: 'Career',
      PremiumReportType.finance: 'Finance',
      PremiumReportType.health: 'Health',
      PremiumReportType.family: 'Family',
    }.entries) {
      testWidgets('${entry.value}: collapsed view shows only the Current Phase '
          'excerpt and the always-expanded Current Timing + Quick Tip — '
          'Watch Out For / Remedy / Next Phase Change stay hidden until '
          'expanded, with no raw "##" markers ever leaking', (tester) async {
        final repository = _FakePremiumAiReportRepository()
          ..results[PremiumAiReportTypes.currentPhase] =
              PremiumAiReportResult.success(markdownBody);

        await pump(tester, entry.key, unlocked: true, repository: repository);
        await tester.pump();

        // Current Phase — collapsed excerpt only.
        expect(find.text('You are in a growth phase.'), findsOneWidget);
        expect(find.text('Read Full Current Phase Report →'), findsOneWidget);

        // Current Timing — always visible immediately, no toggle.
        expect(
          find.text('Jupiter transits your 10th house until October.'),
          findsOneWidget,
        );
        expect(find.text('Quick Tip'), findsOneWidget);
        // Quick Tip reuses Remedy's text — visible once here, even
        // though Current Phase itself is still collapsed.
        expect(find.text('Wear a citrine on Thursdays.'), findsOneWidget);

        // Not yet shown as independent cards while collapsed.
        expect(find.text('Watch Out For'), findsNothing);
        expect(find.text('Remedy For This Phase'), findsNothing);
        expect(find.text('Next Phase Change'), findsNothing);
        expect(
          find.text('Avoid impulsive financial decisions this month.'),
          findsNothing,
        );
        expect(
          find.text('A shift is expected in the next 6 weeks.'),
          findsNothing,
        );

        // Only ONE Current Phase card exists (one
        // `auto_awesome_rounded` icon) — not four independent cards.
        expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);

        expect(find.textContaining('##'), findsNothing);
        expect(find.text(markdownBody), findsNothing);
      });

      testWidgets(
        '${entry.value}: expanding Current Phase reveals ONE continuous '
        'report with Watch Out For / Remedy For This Phase / Next Phase '
        'Change in order — Remedy text also still shows once more as '
        'Quick Tip (the same reused value, by design)',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.currentPhase] =
                PremiumAiReportResult.success(markdownBody);

          await pump(tester, entry.key, unlocked: true, repository: repository);
          await tester.pump();

          await tester.tap(find.text('Read Full Current Phase Report →'));
          await tester.pump();

          expect(find.text('Show Less ↑'), findsOneWidget);
          expect(find.text('Watch Out For'), findsOneWidget);
          expect(
            find.text('Avoid impulsive financial decisions this month.'),
            findsOneWidget,
          );
          expect(find.text('Remedy For This Phase'), findsOneWidget);
          expect(find.text('Next Phase Change'), findsOneWidget);
          expect(
            find.text('A shift is expected in the next 6 weeks.'),
            findsOneWidget,
          );

          // Remedy's text now appears twice — once inside the expanded
          // report, once as the always-visible Quick Tip.
          expect(find.text('Wear a citrine on Thursdays.'), findsNWidgets(2));

          // Still exactly one Current Phase card — expanding adds
          // content in place, it does not spawn new cards.
          expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);

          expect(find.textContaining('##'), findsNothing);
        },
      );
    }

    testWidgets(
      'still renders the pre-existing look for a legacy cached report '
      'with NO "## " headings at all: Current Phase shows raw content as '
      'its excerpt, expanding shows the three sub-sections with their '
      'placeholder copy, and Current Timing falls back to its old '
      'static text',
      (tester) async {
        final repository = _FakePremiumAiReportRepository()
          ..results[PremiumAiReportTypes.currentPhase] =
              PremiumAiReportResult.success(
                'Plain, non-markdown phase reading with no headings.',
              );

        await pump(
          tester,
          PremiumReportType.career,
          unlocked: true,
          repository: repository,
        );
        await tester.pump();

        expect(
          find.text('Plain, non-markdown phase reading with no headings.'),
          findsOneWidget,
        );
        expect(find.text('Birth Chart Foundation — Current'), findsOneWidget);
        expect(
          find.text("Remedy details aren't available yet."),
          findsOneWidget,
        );

        await tester.tap(find.text('Read Full Current Phase Report →'));
        await tester.pump();

        expect(find.text('Watch Out For'), findsOneWidget);
        expect(
          find.text('No specific watch-outs available yet.'),
          findsOneWidget,
        );
        expect(find.text('Next Phase Change'), findsOneWidget);
        expect(find.text("This section isn't available yet."), findsOneWidget);
        // Remedy's fallback now appears twice — expanded report +
        // Quick Tip — same as the real-content case above.
        expect(
          find.text("Remedy details aren't available yet."),
          findsNWidgets(2),
        );
      },
    );

    testWidgets('a response with only a subset of the five headings (an older '
        'server version, or a heading the backend temporarily omits) '
        'resolves each sub-section independently — matched headings show '
        'real content, missing ones fall back, nothing is dropped '
        'wholesale', (tester) async {
      const partialMarkdown =
          '## Current Phase\n'
          'You are in a growth phase.\n\n'
          '## Remedy For This Phase\n'
          'Wear a citrine on Thursdays.';

      final repository = _FakePremiumAiReportRepository()
        ..results[PremiumAiReportTypes.currentPhase] =
            PremiumAiReportResult.success(partialMarkdown);

      await pump(
        tester,
        PremiumReportType.family,
        unlocked: true,
        repository: repository,
      );
      await tester.pump();

      // Matched heading — real content, visible in the excerpt.
      expect(find.text('You are in a growth phase.'), findsOneWidget);

      // Matched Remedy — visible immediately as Quick Tip, even
      // before expanding.
      expect(find.text('Wear a citrine on Thursdays.'), findsOneWidget);

      await tester.tap(find.text('Read Full Current Phase Report →'));
      await tester.pump();

      // Matched heading shows real content inside the expanded
      // report too — now twice total (expanded + Quick Tip).
      expect(find.text('Wear a citrine on Thursdays.'), findsNWidgets(2));

      // Unmatched heading — falls back to its own copy, not to the
      // raw markdown and not to "Current Phase"'s content.
      expect(
        find.text('No specific watch-outs available yet.'),
        findsOneWidget,
      );
      expect(find.text("This section isn't available yet."), findsOneWidget);
      expect(find.text('Birth Chart Foundation — Current'), findsOneWidget);

      expect(find.textContaining('##'), findsNothing);
    });

    testWidgets('renders Hindi labels for both premium sections and their '
        'sub-sections', (tester) async {
      final repository = _FakePremiumAiReportRepository()
        ..results[PremiumAiReportTypes.currentPhase] =
            PremiumAiReportResult.success(markdownBody);

      await pump(
        tester,
        PremiumReportType.health,
        unlocked: true,
        locale: const Locale('hi'),
        repository: repository,
      );
      await tester.pump();

      expect(find.text('वर्तमान चरण'), findsOneWidget);
      expect(find.text('वर्तमान समय'), findsOneWidget);
      expect(find.text('त्वरित सुझाव'), findsOneWidget);

      await tester.tap(find.text('पूरी वर्तमान चरण रिपोर्ट पढ़ें →'));
      await tester.pump();

      expect(find.text('किन बातों का ध्यान रखें'), findsOneWidget);
      expect(find.text('इस चरण के लिए उपाय'), findsOneWidget);
      expect(find.text('अगला चरण परिवर्तन'), findsOneWidget);
      expect(find.text('कम दिखाएं ↑'), findsOneWidget);
    });
  });
}
