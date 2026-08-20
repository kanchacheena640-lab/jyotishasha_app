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
  final List<String> calls = [];

  @override
  Future<PremiumAiReportResult> getReport({
    required String segment,
    required String reportType,
    required String language,
  }) {
    calls.add(reportType);
    return Completer<PremiumAiReportResult>().future;
  }
}

/// Controllable, per-report_type delayed resolution — lets a test
/// observe "still loading" deterministically, then resolve exactly the
/// call it wants, when it wants. Used for double-tap-protection tests,
/// where [_FakePremiumAiReportRepository]'s near-instant resolution
/// would race the assertion and [_HangingRepository] can never resolve
/// at all.
class _DelayedRepository implements PremiumAiReportRepository {
  final List<String> calls = [];
  final Map<String, Completer<PremiumAiReportResult>> _pending = {};

  @override
  Future<PremiumAiReportResult> getReport({
    required String segment,
    required String reportType,
    required String language,
  }) {
    calls.add(reportType);
    final completer = Completer<PremiumAiReportResult>();
    _pending[reportType] = completer;
    return completer.future;
  }

  void resolve(String reportType, PremiumAiReportResult result) {
    _pending[reportType]!.complete(result);
  }
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

  // Progressive/On-Demand Generation fix — CURRENT_PHASE/CURRENT_TIMING no
  // longer auto-load on screen open, so any test that needs their real
  // content must explicitly tap that section's own on-demand CTA first.
  // Matched by the CTA's own fixed suffix ("Phase →"/"Timing →") rather
  // than the full, category-specific string ("See Current Love Phase →"),
  // so these helpers work unchanged for every PremiumReportType tested
  // below — never colliding with "Read Full Current Phase Report →"
  // (ends in "Report →", not "Phase →") or any section label (no arrow
  // at all).
  Future<void> tapPhaseCta(WidgetTester tester) async {
    await tester.tap(find.textContaining('Phase →').first);
    await tester.pump();
  }

  Future<void> tapTimingCta(WidgetTester tester) async {
    await tester.tap(find.textContaining('Timing →').first);
    await tester.pump();
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
          expect(
            find.text("Current timing details aren't available yet."),
            findsNothing,
          );

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
        'UNLOCKED, plain-text CURRENT_PHASE and CURRENT_TIMING responses '
        '(no headings on either): Current Phase shows its own raw content '
        'as its collapsed excerpt, Current Timing shows its own raw '
        'content too (its own call, not borrowed from Current Phase), '
        'and Quick Tip falls back to its own static copy — the three '
        'Current Phase sub-sections stay hidden until expanded',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.dna] = PremiumAiReportResult.success(
              'Career DNA.',
            )
            ..results[PremiumAiReportTypes.currentPhase] =
                PremiumAiReportResult.success(
                  'Your real current Career phase reading.',
                )
            ..results[PremiumAiReportTypes.currentTiming] =
                PremiumAiReportResult.success(
                  'Your real current Career timing reading.',
                );

          await pump(
            tester,
            PremiumReportType.career,
            unlocked: true,
            repository: repository,
          );
          await tester.pump();
          await tapPhaseCta(tester);
          await tapTimingCta(tester);

          expect(find.text('Unlock with Premium Membership →'), findsNothing);
          expect(find.byIcon(Icons.lock_rounded), findsNothing);

          expect(
            find.text('Your real current Career phase reading.'),
            findsOneWidget,
          );
          expect(find.text('Read Full Current Phase Report →'), findsOneWidget);
          expect(find.textContaining('static preview'), findsNothing);

          // Current Timing is always expanded — no toggle, immediately
          // visible, showing its OWN call's real content, not Current
          // Phase's and not the old static placeholder.
          expect(
            find.text('Your real current Career timing reading.'),
            findsOneWidget,
          );
          expect(
            find.text("Current timing details aren't available yet."),
            findsNothing,
          );
          expect(find.text('Quick Tip'), findsOneWidget);
          expect(find.text('No quick tip available yet.'), findsOneWidget);
          // Not Current Phase's Remedy fallback — Quick Tip no longer
          // borrows from the unrelated CURRENT_PHASE call.
          expect(
            find.text("Remedy details aren't available yet."),
            findsNothing,
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
          await tapPhaseCta(tester);

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

          // "Remedy details aren't available yet." appears exactly once —
          // the expanded Remedy For This Phase sub-section. Quick Tip (no
          // `CURRENT_TIMING` result configured in this test, so it renders
          // its own generic error state) no longer echoes Current Phase's
          // Remedy text.
          expect(
            find.text("Remedy details aren't available yet."),
            findsOneWidget,
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
                )
            ..results[PremiumAiReportTypes.currentTiming] =
                PremiumAiReportResult.success(
                  'Your real current Career timing reading.',
                );

          await pump(
            tester,
            PremiumReportType.career,
            membershipState: 'TRIAL',
            repository: repository,
          );
          await tester.pump();
          await tapPhaseCta(tester);
          await tapTimingCta(tester);

          expect(find.text('Unlock with Premium Membership →'), findsNothing);
          expect(find.byIcon(Icons.lock_rounded), findsNothing);

          expect(
            find.text('Your real current Career phase reading.'),
            findsOneWidget,
          );
          expect(
            find.text('Your real current Career timing reading.'),
            findsOneWidget,
          );
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
      testWidgets(
        'Progressive/On-Demand Generation — screen open shows a loading '
        'indicator ONLY for the free DNA section; Current Phase and '
        'Current Timing show their own CTA cards, not spinners, and never '
        'call the backend at all until tapped (already entitled)',
        (tester) async {
          final repository = _HangingRepository();

          await pump(
            tester,
            PremiumReportType.love,
            repository: repository,
            unlocked: true,
          );
          await tester.pump();

          // Exactly one spinner — DNA's own, since it's still the only
          // section that auto-loads.
          expect(find.byType(CircularProgressIndicator), findsOneWidget);

          expect(find.text('See Current Love Phase →'), findsOneWidget);
          expect(find.text('Check Current Love Timing →'), findsOneWidget);

          // Zero calls for CURRENT_PHASE/CURRENT_TIMING — only DNA's own
          // (hanging, so it never resolves, but the request itself was
          // still made and recorded).
          expect(repository.calls, ['DNA']);
        },
      );

      testWidgets(
        'tapping Current Phase\'s own CTA shows ITS OWN loading state '
        '("Analyzing current phase...") — never Current Timing\'s',
        (tester) async {
          await pump(
            tester,
            PremiumReportType.love,
            repository: _HangingRepository(),
            unlocked: true,
          );
          await tester.pump();

          await tester.tap(find.text('See Current Love Phase →'));
          await tester.pump();

          expect(find.text('Analyzing current phase...'), findsOneWidget);
          expect(find.text('Analyzing current timing...'), findsNothing);
          // Current Timing's own CTA is unaffected — still its own
          // separate on-demand state, not touched by Phase's own tap.
          expect(find.text('Check Current Love Timing →'), findsOneWidget);
        },
      );

      testWidgets(
        'tapping Current Timing\'s own CTA shows ONLY its own loading '
        'state ("Analyzing current timing...") — Current Phase never '
        'flashes a competing loading indicator for Timing\'s own silent '
        'dependency step',
        (tester) async {
          await pump(
            tester,
            PremiumReportType.love,
            repository: _HangingRepository(),
            unlocked: true,
          );
          await tester.pump();

          await tester.tap(find.text('Check Current Love Timing →'));
          await tester.pump();

          expect(find.text('Analyzing current timing...'), findsOneWidget);
          expect(find.text('Analyzing current phase...'), findsNothing);
          // Current Phase's own card is untouched — still its own CTA,
          // not a loading state, even though a CURRENT_PHASE fetch is
          // silently in flight underneath as Timing's own dependency.
          expect(find.text('See Current Love Phase →'), findsOneWidget);
        },
      );

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
          await tapPhaseCta(tester);

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
        'shows a fixed, generic error message (never the backend\'s own '
        'raw errorMessage — Progressive/On-Demand Generation fix, see '
        '_aiBody\'s own doc comment) with a Retry action for a '
        'non-entitlement error, and Retry re-invokes the repository '
        '(already entitled)',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.dna] = PremiumAiReportResult.failure(
              errorCode: 'network_error',
              errorMessage: 'Connection failed.',
            )
            ..results[PremiumAiReportTypes.currentPhase] =
                PremiumAiReportResult.success('Phase reading.')
            ..results[PremiumAiReportTypes.currentTiming] =
                PremiumAiReportResult.success('Timing reading.');

          await pump(
            tester,
            PremiumReportType.love,
            repository: repository,
            unlocked: true,
          );
          await tester.pump();

          // Never the backend's own raw message...
          expect(find.text('Connection failed.'), findsNothing);
          // ...only the one fixed, generic, safe string.
          expect(
            find.text('Something went wrong loading this content.'),
            findsOneWidget,
          );
          expect(find.text('Retry'), findsOneWidget);

          final callsBefore = repository.calls.length;
          await tester.tap(find.text('Retry'));
          await tester.pump();

          expect(repository.calls.length, greaterThan(callsBefore));
        },
      );

      testWidgets(
        'Current Timing shows its own CURRENT_TIMING content and Quick Tip '
        'falls back to its own placeholder copy for Love too when entitled '
        'and the CURRENT_TIMING response has no headings — Watch Out For / '
        'Remedy / Next Phase Change stay hidden until Current Phase is '
        'expanded',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.dna] = PremiumAiReportResult.success(
              'DNA.',
            )
            ..results[PremiumAiReportTypes.currentPhase] =
                PremiumAiReportResult.success('Phase.')
            ..results[PremiumAiReportTypes.currentTiming] =
                PremiumAiReportResult.success('Timing.');

          await pump(
            tester,
            PremiumReportType.love,
            repository: repository,
            unlocked: true,
          );
          await tester.pump();
          await tapTimingCta(tester);

          expect(find.text('Current Timing'), findsOneWidget);
          expect(find.text('Timing.'), findsOneWidget);
          expect(find.text('Quick Tip'), findsOneWidget);
          expect(find.text('No quick tip available yet.'), findsOneWidget);
          // Not Current Phase's own content or its Remedy fallback —
          // Current Timing/Quick Tip are sourced from their own
          // CURRENT_TIMING call, never CURRENT_PHASE's.
          expect(
            find.text("Remedy details aren't available yet."),
            findsNothing,
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

  group(
    'Current Phase (CURRENT_PHASE, four headings: Current Phase / Next '
    'Phase Change / Watch Out For / Remedy For This Phase -- the legacy '
    'unused 5th "Current Timing" section has been removed from the '
    'backend prompt) and Current Timing (its own, independent '
    'CURRENT_TIMING call -- real contract: plain text, no Markdown, a '
    '"Quick Tip:" plain-text label) — presentation layer only; the '
    'backend response formats themselves are untouched',
    () {
      // Mirrors the live backend's actual CURRENT_PHASE response shape —
      // no "Current Timing" heading in here; that content has its own
      // call (see [timingPlainTextBody]).
      const phaseMarkdownBody =
          '## Current Phase\n'
          'You are in a growth phase.\n\n'
          '## Next Phase Change\n'
          'A shift is expected in the next 6 weeks.\n\n'
          '## Watch Out For\n'
          'Avoid impulsive financial decisions this month.\n\n'
          '## Remedy For This Phase\n'
          'Wear a citrine on Thursdays.';

      // Mirrors the live backend's own, separate CURRENT_TIMING
      // response's REAL, verified contract (current_*_timing_v1.txt,
      // all 5 segments): plain text, NO Markdown headings at all -- a
      // 2-3 sentence situation, a blank line, then the literal label
      // "Quick Tip:", then one sentence.
      const timingPlainTextBody =
          'Jupiter transits your 10th house until October.\n\n'
          'Quick Tip:\n'
          'Light a diya at sunset.';

      for (final entry in {
        PremiumReportType.love: 'Love',
        PremiumReportType.career: 'Career',
        PremiumReportType.finance: 'Finance',
        PremiumReportType.health: 'Health',
        PremiumReportType.family: 'Family',
      }.entries) {
        testWidgets(
          '${entry.value}: collapsed view shows only the Current Phase '
          'excerpt and the always-expanded Current Timing + its OWN Quick '
          'Tip — Watch Out For / Remedy / Next Phase Change stay hidden '
          'until expanded, with no raw "##" markers ever leaking',
          (tester) async {
            final repository = _FakePremiumAiReportRepository()
              ..results[PremiumAiReportTypes.currentPhase] =
                  PremiumAiReportResult.success(phaseMarkdownBody)
              ..results[PremiumAiReportTypes.currentTiming] =
                  PremiumAiReportResult.success(timingPlainTextBody);

            await pump(
              tester,
              entry.key,
              unlocked: true,
              repository: repository,
            );
            await tester.pump();
            await tapPhaseCta(tester);
            await tapTimingCta(tester);

            // Current Phase — collapsed excerpt only.
            expect(find.text('You are in a growth phase.'), findsOneWidget);
            expect(
              find.text('Read Full Current Phase Report →'),
              findsOneWidget,
            );

            // Current Timing — always visible immediately, no toggle,
            // sourced from its OWN call.
            expect(
              find.text('Jupiter transits your 10th house until October.'),
              findsOneWidget,
            );
            expect(find.text('Quick Tip'), findsOneWidget);
            expect(find.text('Light a diya at sunset.'), findsOneWidget);
            // Never Current Phase's Remedy text — Quick Tip no longer
            // borrows from the unrelated CURRENT_PHASE call.
            expect(find.text('Wear a citrine on Thursdays.'), findsNothing);

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

            // Exactly one Current Phase card and one Current Timing
            // card.
            expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
            expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);

            expect(find.textContaining('##'), findsNothing);
            expect(find.text(phaseMarkdownBody), findsNothing);
            expect(find.text(timingPlainTextBody), findsNothing);
          },
        );

        testWidgets(
          '${entry.value}: expanding Current Phase reveals ONE continuous '
          'report with Watch Out For / Remedy For This Phase / Next Phase '
          'Change in order — Current Timing and its Quick Tip are '
          'completely unaffected by that toggle, since they come from a '
          'separate call',
          (tester) async {
            final repository = _FakePremiumAiReportRepository()
              ..results[PremiumAiReportTypes.currentPhase] =
                  PremiumAiReportResult.success(phaseMarkdownBody)
              ..results[PremiumAiReportTypes.currentTiming] =
                  PremiumAiReportResult.success(timingPlainTextBody);

            await pump(
              tester,
              entry.key,
              unlocked: true,
              repository: repository,
            );
            await tester.pump();
            await tapPhaseCta(tester);
            await tapTimingCta(tester);

            await tester.tap(find.text('Read Full Current Phase Report →'));
            await tester.pump();

            expect(find.text('Show Less ↑'), findsOneWidget);
            expect(find.text('Watch Out For'), findsOneWidget);
            expect(
              find.text('Avoid impulsive financial decisions this month.'),
              findsOneWidget,
            );
            expect(find.text('Remedy For This Phase'), findsOneWidget);
            // Exactly once now — only inside the expanded report, never
            // echoed as Quick Tip.
            expect(find.text('Wear a citrine on Thursdays.'), findsOneWidget);
            expect(find.text('Next Phase Change'), findsOneWidget);
            expect(
              find.text('A shift is expected in the next 6 weeks.'),
              findsOneWidget,
            );

            // Current Timing/Quick Tip still show their own, unaffected
            // content.
            expect(
              find.text('Jupiter transits your 10th house until October.'),
              findsOneWidget,
            );
            expect(find.text('Light a diya at sunset.'), findsOneWidget);

            expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
            expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);

            expect(find.textContaining('##'), findsNothing);
          },
        );
      }

      testWidgets(
        'a legacy cached CURRENT_PHASE report with NO "## " headings at '
        'all still renders the pre-existing look (raw content as the '
        'excerpt, three sub-sections falling back to placeholder copy '
        'once expanded) — completely independent of Current Timing, '
        'which still shows its own real content from its own '
        'CURRENT_TIMING call',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.currentPhase] =
                PremiumAiReportResult.success(
                  'Plain, non-markdown phase reading with no headings.',
                )
            ..results[PremiumAiReportTypes.currentTiming] =
                PremiumAiReportResult.success(timingPlainTextBody);

          await pump(
            tester,
            PremiumReportType.career,
            unlocked: true,
            repository: repository,
          );
          await tester.pump();
          await tapPhaseCta(tester);
          await tapTimingCta(tester);

          expect(
            find.text('Plain, non-markdown phase reading with no headings.'),
            findsOneWidget,
          );

          // Current Timing unaffected by Current Phase's missing
          // headings — its own call, its own successful parse.
          expect(
            find.text('Jupiter transits your 10th house until October.'),
            findsOneWidget,
          );
          expect(find.text('Light a diya at sunset.'), findsOneWidget);

          await tester.tap(find.text('Read Full Current Phase Report →'));
          await tester.pump();

          expect(find.text('Watch Out For'), findsOneWidget);
          expect(
            find.text('No specific watch-outs available yet.'),
            findsOneWidget,
          );
          expect(find.text('Remedy For This Phase'), findsOneWidget);
          expect(
            find.text("Remedy details aren't available yet."),
            findsOneWidget,
          );
          expect(find.text('Next Phase Change'), findsOneWidget);
          expect(
            find.text("This section isn't available yet."),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'a CURRENT_TIMING response with NO "## " headings falls back to '
        'showing its whole content as Current Timing plus a placeholder '
        'Quick Tip — independent of a fully-headed CURRENT_PHASE',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.currentPhase] =
                PremiumAiReportResult.success(phaseMarkdownBody)
            ..results[PremiumAiReportTypes.currentTiming] =
                PremiumAiReportResult.success(
                  'Plain, non-markdown timing reading with no headings.',
                );

          await pump(
            tester,
            PremiumReportType.finance,
            unlocked: true,
            repository: repository,
          );
          await tester.pump();
          await tapTimingCta(tester); // silently ensures Phase too

          expect(
            find.text(
              'Plain, non-markdown timing reading with no headings.',
            ),
            findsOneWidget,
          );
          expect(find.text('Quick Tip'), findsOneWidget);
          expect(find.text('No quick tip available yet.'), findsOneWidget);

          // Current Phase unaffected.
          expect(find.text('You are in a growth phase.'), findsOneWidget);
        },
      );

      testWidgets(
        'a CURRENT_PHASE response with only a subset of its four headings '
        '(an older server version, or a heading the backend temporarily '
        'omits) resolves each sub-section independently — matched '
        'headings show real content, missing ones fall back, nothing is '
        'dropped wholesale',
        (tester) async {
          const partialMarkdown =
              '## Current Phase\n'
              'You are in a growth phase.\n\n'
              '## Remedy For This Phase\n'
              'Wear a citrine on Thursdays.';

          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.currentPhase] =
                PremiumAiReportResult.success(partialMarkdown)
            ..results[PremiumAiReportTypes.currentTiming] =
                PremiumAiReportResult.success(timingPlainTextBody);

          await pump(
            tester,
            PremiumReportType.family,
            unlocked: true,
            repository: repository,
          );
          await tester.pump();
          await tapPhaseCta(tester);
          await tapTimingCta(tester);

          // Matched heading — real content, visible in the excerpt.
          expect(find.text('You are in a growth phase.'), findsOneWidget);

          await tester.tap(find.text('Read Full Current Phase Report →'));
          await tester.pump();

          // Matched Remedy — real content, exactly once, inside the
          // expanded report.
          expect(find.text('Wear a citrine on Thursdays.'), findsOneWidget);

          // Unmatched heading — falls back to its own copy, not to the
          // raw markdown and not to "Current Phase"'s content.
          expect(
            find.text('No specific watch-outs available yet.'),
            findsOneWidget,
          );
          expect(
            find.text("This section isn't available yet."),
            findsOneWidget,
          );

          // Current Timing/Quick Tip unaffected — own call, fully
          // headed.
          expect(
            find.text('Jupiter transits your 10th house until October.'),
            findsOneWidget,
          );
          expect(find.text('Light a diya at sunset.'), findsOneWidget);

          expect(find.textContaining('##'), findsNothing);
        },
      );

      testWidgets(
        'renders Hindi labels for both premium sections and their '
        'sub-sections',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.currentPhase] =
                PremiumAiReportResult.success(phaseMarkdownBody)
            ..results[PremiumAiReportTypes.currentTiming] =
                PremiumAiReportResult.success(timingPlainTextBody);

          await pump(
            tester,
            PremiumReportType.health,
            unlocked: true,
            locale: const Locale('hi'),
            repository: repository,
          );
          await tester.pump();
          // Hindi CTA copy — category-specific ("वर्तमान स्वास्थ्य चरण देखें
          // →"/"वर्तमान स्वास्थ्य समय जांचें →" for Health), so tapPhaseCta/
          // tapTimingCta's English-only "Phase →"/"Timing →" match doesn't
          // apply here.
          await tester.tap(find.text('वर्तमान स्वास्थ्य चरण देखें →'));
          await tester.pump();
          await tester.tap(find.text('वर्तमान स्वास्थ्य समय जांचें →'));
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
        },
      );
    },
  );

  group(
    'CURRENT_TIMING plain-text parsing — the real, verified contract '
    '(current_*_timing_v1.txt, all 5 segments): "<situation>\\n\\nQuick '
    'Tip:\\n<tip>", no Markdown at all',
    () {
      // Every test in this group configures ONLY the CURRENT_TIMING fake
      // result, since these tests are purely about that call's own
      // content-parsing contract. Progressive/On-Demand Generation fix:
      // CURRENT_TIMING now always ensures CURRENT_PHASE is READY first
      // (see BirthChartReportReader._onTapCurrentTiming), so CURRENT_PHASE
      // must be configured to succeed too, or the dependency step itself
      // would fail and none of these fixtures would ever be reached at
      // all — this is the same real contract Flutter now enforces, not a
      // workaround. Its own content is irrelevant here and never
      // asserted on.
      const unusedPhaseContext = 'Phase context (unused by these Timing-focused assertions).';

      testWidgets(
        'the literal "Quick Tip:" label never remains visible inside the '
        'situation paragraph',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.currentPhase] =
                PremiumAiReportResult.success(unusedPhaseContext)
            ..results[PremiumAiReportTypes.currentTiming] =
                PremiumAiReportResult.success(
                  'A message from someone you care about may arrive.\n\n'
                  'Quick Tip:\n'
                  'Read the message twice before replying.',
                );

          await pump(
            tester,
            PremiumReportType.love,
            unlocked: true,
            repository: repository,
          );
          await tester.pump();
          await tapTimingCta(tester);

          expect(
            find.text(
              'A message from someone you care about may arrive.',
            ),
            findsOneWidget,
          );
          expect(
            find.text('Read the message twice before replying.'),
            findsOneWidget,
          );
          // The label itself never appears as its own visible text run —
          // only the "Quick Tip" section heading (a fixed UI label, not
          // backend content) does.
          expect(find.textContaining('Quick Tip:'), findsNothing);
        },
      );

      testWidgets(
        'tolerates real-world capitalization/spacing variations of the '
        '"Quick Tip:" delimiter safely',
        (tester) async {
          for (final variant in [
            'Quick tip:',
            'QUICK TIP:',
            'Quick Tip :',
            'Quick   Tip:',
          ]) {
            final repository = _FakePremiumAiReportRepository()
              ..results[PremiumAiReportTypes.currentPhase] =
                  PremiumAiReportResult.success(unusedPhaseContext)
              ..results[PremiumAiReportTypes.currentTiming] =
                  PremiumAiReportResult.success(
                    'A situation sentence.\n\n$variant\nA tip sentence.',
                  );

            // Force a full unmount between iterations — Flutter's own
            // widget-diffing would otherwise reuse the SAME
            // BirthChartReportReader State (same widget type/no Key)
            // across every pumpWidget() call in this loop, leaking
            // _timingResult from one variant into the next and making
            // this loop over-report success (a pre-existing test-
            // isolation gap, made visible now that On-Demand generation
            // means a stale, already-populated result skips the CTA
            // tapTimingCta needs to find).
            await tester.pumpWidget(const SizedBox.shrink());

            await pump(
              tester,
              PremiumReportType.love,
              unlocked: true,
              repository: repository,
            );
            await tester.pump();
            await tapTimingCta(tester);

            expect(
              find.text('A situation sentence.'),
              findsOneWidget,
              reason: 'delimiter variant: "$variant"',
            );
            expect(
              find.text('A tip sentence.'),
              findsOneWidget,
              reason: 'delimiter variant: "$variant"',
            );
          }
        },
      );

      testWidgets(
        'a genuinely empty CURRENT_TIMING content falls back gracefully — '
        'no crash, placeholder copy for both the situation and the tip',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.currentPhase] =
                PremiumAiReportResult.success(unusedPhaseContext)
            ..results[PremiumAiReportTypes.currentTiming] =
                PremiumAiReportResult.success('');

          await pump(
            tester,
            PremiumReportType.love,
            unlocked: true,
            repository: repository,
          );
          await tester.pump();
          await tapTimingCta(tester);

          expect(
            find.text("Current timing details aren't available yet."),
            findsOneWidget,
          );
          expect(find.text('No quick tip available yet.'), findsOneWidget);
        },
      );

      testWidgets(
        'a whitespace-only CURRENT_TIMING content falls back gracefully — '
        'no crash',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.currentPhase] =
                PremiumAiReportResult.success(unusedPhaseContext)
            ..results[PremiumAiReportTypes.currentTiming] =
                PremiumAiReportResult.success('   \n\n   ');

          await pump(
            tester,
            PremiumReportType.love,
            unlocked: true,
            repository: repository,
          );
          await tester.pump();
          await tapTimingCta(tester);

          expect(
            find.text("Current timing details aren't available yet."),
            findsOneWidget,
          );
          expect(find.text('No quick tip available yet.'), findsOneWidget);
        },
      );

      testWidgets(
        'a malformed CURRENT_TIMING content (Quick Tip: with nothing '
        'after it) falls back to the placeholder tip rather than '
        'rendering an empty tip',
        (tester) async {
          final repository = _FakePremiumAiReportRepository()
            ..results[PremiumAiReportTypes.currentPhase] =
                PremiumAiReportResult.success(unusedPhaseContext)
            ..results[PremiumAiReportTypes.currentTiming] =
                PremiumAiReportResult.success(
                  'A situation sentence.\n\nQuick Tip:',
                );

          await pump(
            tester,
            PremiumReportType.love,
            unlocked: true,
            repository: repository,
          );
          await tester.pump();
          await tapTimingCta(tester);

          expect(find.text('A situation sentence.'), findsOneWidget);
          expect(find.text('No quick tip available yet.'), findsOneWidget);
        },
      );
    },
  );

  group('Progressive/On-Demand Generation — dependency handling, leak '
      'prevention, caching, double-tap protection', () {
    testWidgets(
      'tapping Current Timing when Current Phase was never tapped '
      'silently ensures Phase is READY first, then generates Timing — '
      'both end up populated from ONE user action, and Phase\'s own '
      'card updates too even though the user never tapped it directly',
      (tester) async {
        final repository = _FakePremiumAiReportRepository()
          ..results[PremiumAiReportTypes.currentPhase] =
              PremiumAiReportResult.success('Real phase content.')
          ..results[PremiumAiReportTypes.currentTiming] =
              PremiumAiReportResult.success('Real timing content.');

        await pump(
          tester,
          PremiumReportType.love,
          unlocked: true,
          repository: repository,
        );
        await tester.pump();

        // Never tapped Phase's own CTA.
        expect(find.text('See Current Love Phase →'), findsOneWidget);

        await tapTimingCta(tester);

        // Timing's own content is now visible.
        expect(find.text('Real timing content.'), findsOneWidget);
        // Phase's dependency was silently ensured too — its card
        // updated to show real content, without the user ever tapping
        // it directly.
        expect(find.text('Real phase content.'), findsOneWidget);
        expect(find.text('See Current Love Phase →'), findsNothing);

        // Both backend calls actually happened, Phase strictly before
        // Timing.
        expect(
          repository.calls,
          containsAll([
            PremiumAiReportTypes.currentPhase,
            PremiumAiReportTypes.currentTiming,
          ]),
        );
        expect(
          repository.calls.indexOf(PremiumAiReportTypes.currentPhase) <
              repository.calls.indexOf(PremiumAiReportTypes.currentTiming),
          isTrue,
        );
      },
    );

    testWidgets(
      'a raw backend dependency-check error — the exact production leak '
      '("...must be generated before it can be used... no READY cached '
      'report found.") — NEVER reaches the UI: Phase failing blocks '
      'Timing from even attempting its own call, and only a generic, '
      'safe message is shown',
      (tester) async {
        final repository = _FakePremiumAiReportRepository()
          ..results[PremiumAiReportTypes.dna] = PremiumAiReportResult.success(
            'DNA content (unrelated to this test).',
          )
          ..results[PremiumAiReportTypes.currentPhase] =
              PremiumAiReportResult.failure(
                errorCode: 'report_validation_failed',
                errorMessage:
                    'LOVE CURRENT_PHASE must be generated before it can '
                    'be used as input here... no READY cached report '
                    'found.',
              );
        // currentTiming deliberately NOT configured in this fixture —
        // proves it is never actually requested.

        await pump(
          tester,
          PremiumReportType.love,
          unlocked: true,
          repository: repository,
        );
        await tester.pump();

        await tapTimingCta(tester);

        // The raw backend message never appears anywhere on screen, in
        // whole or in part.
        expect(find.textContaining('must be generated before'), findsNothing);
        expect(find.textContaining('READY cached report'), findsNothing);
        expect(find.textContaining('LOVE CURRENT_PHASE'), findsNothing);
        expect(find.textContaining('no READY'), findsNothing);

        // Only the one fixed, generic failure message — shown twice
        // (Phase's own failed card, and Timing's synthetic
        // "dependency_unavailable" failure), never the raw backend text.
        expect(
          find.text('Something went wrong loading this content.'),
          findsNWidgets(2),
        );

        // CURRENT_TIMING itself was never even requested — Phase's
        // failure short-circuits before wasting a call already known
        // to fail the same dependency check.
        expect(
          repository.calls.contains(PremiumAiReportTypes.currentTiming),
          isFalse,
        );
        expect(
          repository.calls.where((c) => c == PremiumAiReportTypes.currentPhase).length,
          1,
        );
      },
    );

    testWidgets(
      'Current Phase, once READY, is reused (never re-fetched) when '
      'Current Timing needs it as a dependency — exactly one '
      'CURRENT_PHASE call total across both actions',
      (tester) async {
        final repository = _FakePremiumAiReportRepository()
          ..results[PremiumAiReportTypes.currentPhase] =
              PremiumAiReportResult.success('Real phase content.')
          ..results[PremiumAiReportTypes.currentTiming] =
              PremiumAiReportResult.success('Real timing content.');

        await pump(
          tester,
          PremiumReportType.love,
          unlocked: true,
          repository: repository,
        );
        await tester.pump();

        await tapPhaseCta(tester); // Phase becomes READY on its own first.
        expect(
          repository.calls
              .where((c) => c == PremiumAiReportTypes.currentPhase)
              .length,
          1,
        );

        await tapTimingCta(tester); // must reuse the already-READY Phase.

        expect(
          repository.calls
              .where((c) => c == PremiumAiReportTypes.currentPhase)
              .length,
          1, // still exactly one — never re-fetched
        );
        expect(find.text('Real timing content.'), findsOneWidget);
      },
    );

    testWidgets(
      'two taps on Current Phase\'s CTA landing before any rebuild start '
      'exactly one request — proves the internal loading guard itself '
      'prevents a duplicate generation, not merely the UI replacing the '
      'CTA after the first tap is processed',
      (tester) async {
        final repository = _DelayedRepository();

        await pump(
          tester,
          PremiumReportType.love,
          unlocked: true,
          repository: repository,
        );
        await tester.pump();

        final cta = find.text('See Current Love Phase →');
        await tester.tap(cta);
        // Deliberately NO pump() between the two taps — both land while
        // the widget tree still shows the CTA, exactly the fast-double-
        // tap race a UI-only defense (disabling/replacing the button)
        // would not by itself survive.
        await tester.tap(cta, warnIfMissed: false);
        await tester.pump();

        expect(
          repository.calls
              .where((c) => c == PremiumAiReportTypes.currentPhase)
              .length,
          1,
        );

        repository.resolve(
          PremiumAiReportTypes.currentPhase,
          PremiumAiReportResult.success('Phase content.'),
        );
        await tester.pump();

        expect(find.text('Phase content.'), findsOneWidget);
        expect(
          repository.calls
              .where((c) => c == PremiumAiReportTypes.currentPhase)
              .length,
          1, // still exactly one after resolving
        );
      },
    );

    testWidgets(
      'READY cached Current Phase content is reused, never regenerated, '
      'across a subscription-state rebuild (e.g. SubscriptionProvider '
      'notifying listeners for an unrelated reason) — no extra call',
      (tester) async {
        final repository = _FakePremiumAiReportRepository()
          ..results[PremiumAiReportTypes.currentPhase] =
              PremiumAiReportResult.success('Real phase content.');

        await pump(
          tester,
          PremiumReportType.love,
          unlocked: true,
          repository: repository,
        );
        await tester.pump();
        await tapPhaseCta(tester);

        expect(
          repository.calls
              .where((c) => c == PremiumAiReportTypes.currentPhase)
              .length,
          1,
        );

        // A few more, unrelated rebuilds of the same widget tree.
        await tester.pump();
        await tester.pump();

        expect(find.text('Real phase content.'), findsOneWidget);
        expect(
          repository.calls
              .where((c) => c == PremiumAiReportTypes.currentPhase)
              .length,
          1, // unchanged — no unnecessary regeneration
        );
      },
    );
  });
}
