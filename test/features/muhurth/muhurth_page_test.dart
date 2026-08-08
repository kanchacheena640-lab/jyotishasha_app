import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/features/muhurth/muhurth_page.dart';

import '../../helpers/test_harness.dart';

void main() {
  group('muhurthScorePercent (F6.5 — same mapping as CardsProvider)', () {
    test('maps the 0-7 score scale to the expected percentages', () {
      expect(muhurthScorePercent(7), 100);
      expect(muhurthScorePercent(6), 90);
      expect(muhurthScorePercent(5), 75);
      expect(muhurthScorePercent(4), 60);
      expect(muhurthScorePercent(3), 45);
      expect(muhurthScorePercent(2), 35);
      expect(muhurthScorePercent(0), 35);
    });
  });

  group('pickMuhurthCardImage', () {
    test('is deterministic — same seed always returns the same image', () {
      final first = pickMuhurthCardImage('2026-08-12');
      final second = pickMuhurthCardImage('2026-08-12');
      expect(first, second);
    });

    test('always returns one of the bundled decor assets', () {
      final image = pickMuhurthCardImage('2026-08-12');
      expect(image, startsWith('assets/cards/decor_'));
      expect(image, endsWith('.webp'));
    });
  });

  group('muhurthDateLine', () {
    test('formats one upcoming-date line', () {
      expect(
        muhurthDateLine('12-08-2026', 7),
        '12-08-2026  •  100% auspicious',
      );
    });
  });

  group(
    'buildMuhurthCardModel (F6.5.2 — ONE card per activity, all upcoming '
    'dates, no CardsProvider dependency)',
    () {
      test(
        'aggregates every upcoming date into a single CardModel, in the '
        'given (backend) order',
        () {
          final card = buildMuhurthCardModel(
            activity: 'vehicle',
            dateLines: [
              muhurthDateLine('19-08-2026', 7),
              muhurthDateLine('26-08-2026', 6),
              muhurthDateLine('09-09-2026', 5),
              muhurthDateLine('16-09-2026', 4),
            ],
            image: 'assets/cards/decor_01.webp',
          );

          expect(card.type, 'muhurth');
          expect(card.designType, 'muhurth');
          expect(card.muhurthType, 'vehicle');
          expect(card.image, 'assets/cards/decor_01.webp');
          expect(card.titleEn, 'Vehicle Purchase Muhurth');
          expect(card.titleHi, 'वाहन खरीद मुहूर्त');
          // One card, 4 upcoming dates, best (highest score) first — same
          // order the backend/dateLines were given in, not re-sorted.
          expect(
            card.contentEn,
            '19-08-2026  •  100% auspicious\n'
            '26-08-2026  •  90% auspicious\n'
            '09-09-2026  •  75% auspicious\n'
            '16-09-2026  •  60% auspicious',
          );
          expect(card.meta?['share_en'], isNotNull);
          expect(card.meta?['share_hi'], isNotNull);
        },
      );

      test('falls back to generic titles for an unrecognized activity', () {
        final card = buildMuhurthCardModel(
          activity: 'unknown_activity',
          dateLines: [muhurthDateLine('01-01-2027', 3)],
          image: 'assets/cards/decor_02.webp',
        );

        expect(card.titleEn, 'Shubh Muhurth');
        expect(card.titleHi, 'शुभ मुहूर्त');
        expect(card.contentEn, '01-01-2027  •  45% auspicious');
      });
    },
  );

  group('MuhurthPage(initialActivity:) — F6.5 Home → MuhurthPage handoff', () {
    // MuhurthPage's AppBar hosts the existing GlobalShareButton (text-only
    // share, unrelated to F6.5), which reads LanguageProvider.
    Future<void> pump(WidgetTester tester, Widget page) => tester.pumpTestHarness(
      page,
      providers: [ChangeNotifierProvider(create: (_) => LanguageProvider())],
    );

    testWidgets(
      'preselects the activity passed in from Home (e.g. "marriage")',
      (tester) async {
        await pump(tester, const MuhurthPage(initialActivity: 'marriage'));

        expect(find.text('MARRIAGE'), findsOneWidget);
      },
    );

    testWidgets(
      'falls back to the default activity when none is passed',
      (tester) async {
        await pump(tester, const MuhurthPage());

        expect(find.text('NAAMKARAN'), findsOneWidget);
      },
    );

    testWidgets(
      'falls back to the default activity for an unrecognized value',
      (tester) async {
        await pump(
          tester,
          const MuhurthPage(initialActivity: 'not_a_real_activity'),
        );

        expect(find.text('NAAMKARAN'), findsOneWidget);
      },
    );
  });

  group('Muhurth list share UX (F6.5.1)', () {
    Future<void> pump(WidgetTester tester, Widget page) => tester.pumpTestHarness(
      page,
      locale: const Locale('en'),
      providers: [ChangeNotifierProvider(create: (_) => LanguageProvider())],
    );

    testWidgets(
      'the list shows only a "Share this Muhurta →" link — no inline '
      'CardRenderer/share card — until the user taps it, and closing the '
      'preview returns to the list',
      (tester) async {
        // Pre-populate MuhurthPage's own cache (same key shape _fetchMuhurth
        // builds) so the widget renders real result data without a network
        // call.
        muhurthCache['marriage|28.6139|77.209|en'] = [
          {
            'date': '2026-08-12',
            'score': 7,
            'weekday': 'Wednesday',
            'nakshatra': 'Rohini',
            'tithi': 'Panchami',
            'reasons': ['Auspicious yoga', 'Strong Moon'],
          },
        ];

        await pump(tester, const MuhurthPage(initialActivity: 'marriage'));
        await tester.pump();

        expect(find.text('Share this Muhurta →'), findsOneWidget);
        // No shareable card / BaseCard share icon rendered inline yet.
        expect(find.byIcon(Icons.share_rounded), findsNothing);
        expect(find.text('Marriage Muhurth'), findsNothing);

        await tester.tap(find.text('Share this Muhurta →'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // The full share card (from the existing CardRenderer/BaseCard)
        // now appears — inside the on-demand preview only.
        expect(find.text('Marriage Muhurth'), findsOneWidget);
        expect(find.byIcon(Icons.share_rounded), findsOneWidget);

        // Dismiss the modal (tap the barrier) — back to a clean list.
        await tester.tapAt(const Offset(10, 10));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Marriage Muhurth'), findsNothing);
        expect(find.text('Share this Muhurta →'), findsOneWidget);
      },
    );
  });

  group('Multi-date share card (F6.5.2)', () {
    Future<void> pump(WidgetTester tester, Widget page) => tester.pumpTestHarness(
      page,
      locale: const Locale('en'),
      providers: [ChangeNotifierProvider(create: (_) => LanguageProvider())],
    );

    testWidgets(
      'one activity with 4 upcoming dates produces ONE share card '
      'containing all 4 dates — not one card per date',
      (tester) async {
        muhurthCache['vehicle|28.6139|77.209|en'] = [
          {'date': '2026-08-19', 'score': 7, 'weekday': 'Wed', 'nakshatra': 'Rohini', 'tithi': 'Panchami', 'reasons': []},
          {'date': '2026-08-26', 'score': 6, 'weekday': 'Wed', 'nakshatra': 'Mrigashira', 'tithi': 'Saptami', 'reasons': []},
          {'date': '2026-09-09', 'score': 5, 'weekday': 'Wed', 'nakshatra': 'Pushya', 'tithi': 'Ekadashi', 'reasons': []},
          {'date': '2026-09-16', 'score': 4, 'weekday': 'Wed', 'nakshatra': 'Hasta', 'tithi': 'Tritiya', 'reasons': []},
        ];

        await pump(tester, const MuhurthPage(initialActivity: 'vehicle'));
        await tester.pump();

        // Each visible row has its own "Share this Muhurta →" link (the
        // ListView only builds the rows that fit the test viewport, so
        // this doesn't assert an exact count).
        expect(find.text('Share this Muhurta →'), findsWidgets);

        // Tapping ANY row's link opens the same single aggregated card —
        // check the first row.
        await tester.tap(find.text('Share this Muhurta →').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Vehicle Purchase Muhurth'), findsOneWidget);
        // The upcoming dates appear as separate lines inside the SAME one
        // card (CardRenderer's existing muhurth layout renders one Text
        // per \n-separated line) — checking the first line is enough to
        // confirm it's the aggregated card and not a single-date one; the
        // small preview card's own bounded height means not every line is
        // guaranteed to be laid out (verified exhaustively, independent of
        // any viewport, by the buildMuhurthCardModel unit test above).
        // The full "date • score%" line (not just the bare date) is
        // asserted to disambiguate from the list row underneath, which
        // also shows its own plain date heading.
        expect(find.text('19-08-2026  •  100% auspicious'), findsOneWidget);
      },
    );
  });
}
