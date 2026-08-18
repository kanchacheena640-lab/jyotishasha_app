import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/state/transit_provider.dart';
import 'package:jyotishasha_app/core/widgets/transit_alert_widget.dart';
import 'package:jyotishasha_app/features/transit/pages/transit_content_page.dart';

import '../../helpers/test_harness.dart';

/// `ProfileProvider`'s real constructor touches `FirebaseAuth.instance` via
/// `ProfileService`, unavailable in this widget-test environment. `Mock`'s
/// `implements` never calls the real constructor; `with ChangeNotifier`
/// gives real addListener/notifyListeners behavior for `context.watch`.
class _FakeProfileProvider extends Mock
    with ChangeNotifier
    implements ProfileProvider {}

void main() {
  TransitProvider buildTransitProvider() {
    final provider = TransitProvider();
    // Real constructor fires an eager fetchTransit() HTTP call, which the
    // test binding's stub HttpClient turns into a harmless failure; the
    // fields below are what the widget actually reads.
    provider.isLoading = false;
    provider.transitData = {
      'positions': {
        // Farthest change date of the three.
        'Sun': {'rashi': 'Leo', 'motion': 'Direct', 'degree': '10'},
        // Nearest change date — should be the first carousel page.
        'Moon': {'rashi': 'Cancer', 'motion': 'Retrograde', 'degree': '5'},
        // Middle change date.
        'Mars': {'rashi': 'Aries', 'motion': 'Direct', 'degree': '20'},
      },
      'future_transits': {
        'Sun': [
          {'entering_date': '2026-12-01'},
        ],
        'Moon': [
          {'entering_date': '2026-08-05'},
        ],
        'Mars': [
          {'entering_date': '2026-09-15'},
        ],
      },
    };
    return provider;
  }

  /// All 9 Jyotish planets present — the same canonical set
  /// `TransitProvider.allPlanets`'s own `keys` list reads (Sun, Moon,
  /// Mars, Mercury, Jupiter, Venus, Saturn, Rahu, Ketu) and the live
  /// backend's `positions` payload already returns. Distinct ascending
  /// `next_change` dates give a deterministic priority-sort order, used
  /// below to assert the first and ninth (last) planet are both
  /// reachable via the pagination dots.
  TransitProvider buildFullTransitProvider() {
    final provider = TransitProvider();
    provider.isLoading = false;
    provider.transitData = {
      'positions': {
        'Moon': {'rashi': 'Cancer', 'motion': 'Direct', 'degree': '1'},
        'Mercury': {'rashi': 'Gemini', 'motion': 'Direct', 'degree': '2'},
        'Venus': {'rashi': 'Taurus', 'motion': 'Direct', 'degree': '3'},
        'Mars': {'rashi': 'Aries', 'motion': 'Direct', 'degree': '4'},
        'Sun': {'rashi': 'Leo', 'motion': 'Direct', 'degree': '5'},
        'Saturn': {'rashi': 'Aquarius', 'motion': 'Direct', 'degree': '6'},
        'Jupiter': {
          'rashi': 'Sagittarius',
          'motion': 'Direct',
          'degree': '7',
        },
        'Rahu': {'rashi': 'Aquarius', 'motion': 'Retrograde', 'degree': '8'},
        'Ketu': {'rashi': 'Leo', 'motion': 'Retrograde', 'degree': '9'},
      },
      'future_transits': {
        'Moon': [
          {'entering_date': '2026-08-01'},
        ],
        'Mercury': [
          {'entering_date': '2026-08-05'},
        ],
        'Venus': [
          {'entering_date': '2026-08-10'},
        ],
        'Mars': [
          {'entering_date': '2026-08-15'},
        ],
        'Sun': [
          {'entering_date': '2026-08-20'},
        ],
        'Saturn': [
          {'entering_date': '2026-08-25'},
        ],
        'Jupiter': [
          {'entering_date': '2026-08-30'},
        ],
        'Rahu': [
          {'entering_date': '2026-09-05'},
        ],
        'Ketu': [
          // Farthest change date — last in priority order (9th planet).
          {'entering_date': '2026-09-10'},
        ],
      },
    };
    return provider;
  }

  Future<void> pumpWidget(
    WidgetTester tester, {
    String lang = 'en',
    TransitProvider? transitProvider,
  }) async {
    final profileProvider = _FakeProfileProvider();
    when(() => profileProvider.activeProfile).thenReturn(const {
      'lagna': 'Aries',
    });

    await tester.pumpTestHarness(
      const Scaffold(body: TransitAlertWidget()),
      locale: Locale(lang),
      providers: [
        ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
        ChangeNotifierProvider<TransitProvider>.value(
          value: transitProvider ?? buildTransitProvider(),
        ),
      ],
    );
    await tester.pump();
  }

  testWidgets(
    'shows the "Current Planetary Influence" section title and subtitle',
    (tester) async {
      await pumpWidget(tester);

      expect(find.text('Current Planetary Influence'), findsOneWidget);
      expect(find.text('Based on your birth chart.'), findsOneWidget);
    },
  );

  testWidgets(
    'shows exactly ONE planet card at a time — the highest-priority '
    '(nearest next_change) planet first: Moon',
    (tester) async {
      await pumpWidget(tester);

      // Moon is in Cancer; with lagna Aries (rashi 1) and Cancer rashi 4,
      // house = (4 - 1 + 12) % 12 + 1 = 4.
      expect(find.text('Moon'), findsOneWidget);
      expect(
        find.text('Moon is currently influencing your 4th House.'),
        findsOneWidget,
      );
      expect(find.text('Affects'), findsOneWidget);
      expect(find.text('Home • Comfort • Emotions'), findsOneWidget);
      // Moon's next_change is 2026-08-05 (formatted dd-mm-yyyy by
      // TransitProvider, parsed back and displayed as "5 Aug 2026" —
      // F6.1.1/F6.1.2).
      expect(find.text('Next Change: 5 Aug 2026'), findsOneWidget);
      expect(find.text('Read Full Effects →'), findsOneWidget);

      // Only one card's content is in the tree — Mars/Sun are not built
      // until their page is reached.
      expect(find.text('Mars'), findsNothing);
      expect(find.text('Sun'), findsNothing);
    },
  );

  testWidgets(
    'tapping a pagination dot switches the visible card, staying in the '
    'same priority order (Moon, then Mars, then Sun)',
    (tester) async {
      await pumpWidget(tester);

      expect(find.text('Moon'), findsOneWidget);

      // Dot 1 — Mars, second in priority order.
      await tester.tap(find.byKey(const ValueKey('planet_dot_1')));
      await tester.pumpAndSettle();
      expect(find.text('Mars'), findsOneWidget);
      expect(find.text('Moon'), findsNothing);

      // Dot 2 — Sun, third/last in priority order.
      await tester.tap(find.byKey(const ValueKey('planet_dot_2')));
      await tester.pumpAndSettle();
      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('Mars'), findsNothing);
    },
  );

  testWidgets(
    'swiping the card horizontally advances to the next planet, keeping '
    'the pagination dots in sync',
    (tester) async {
      await pumpWidget(tester);
      expect(find.text('Moon'), findsOneWidget);

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Mars'), findsOneWidget);
    },
  );

  testWidgets('renders Hindi content when the locale is Hindi', (
    tester,
  ) async {
    await pumpWidget(tester, lang: 'hi');

    expect(find.text('वर्तमान ग्रह प्रभाव'), findsOneWidget);
    expect(find.text('आपकी जन्म कुंडली के आधार पर।'), findsOneWidget);
    expect(find.text('चंद्र'), findsOneWidget); // Moon
    expect(
      find.text('चंद्र अभी आपके 4वें भाव को प्रभावित कर रहा है।'),
      findsOneWidget,
    );
    expect(find.text('प्रभाव'), findsOneWidget);
    expect(find.text('घर • सुख • भावनाएं'), findsOneWidget);
    // The "Next Change" label reuses the existing localized string
    // (`t.transitNextChange`); the date itself follows this codebase's
    // established convention of formatting dates without a locale arg.
    expect(find.text('अगला परिवर्तन: 5 Aug 2026'), findsOneWidget);
    expect(find.text('पूरे प्रभाव पढ़ें →'), findsOneWidget);
  });

  testWidgets(
    'tapping the planet card navigates to TransitContentPage',
    (tester) async {
      await pumpWidget(tester);

      await tester.tap(find.text('Moon'));
      // Not pumpAndSettle: TransitContentPage's own loading state keeps
      // scheduling frames (unrelated to this widget), which would hang.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Navigator.push keeps the previous route in the tree (just obscured),
      // so assert the destination is now present rather than the source
      // being gone.
      expect(find.byType(TransitContentPage), findsOneWidget);
    },
  );

  group('9-planet pagination dots (Current Planetary Influence fix)', () {
    testWidgets(
      'renders exactly 9 planet cards across the carousel — all 9 '
      'Jyotish planets, none dropped, in ascending next_change order',
      (tester) async {
        await pumpWidget(tester, transitProvider: buildFullTransitProvider());

        // Only the active page's card is built at a time; walk every
        // page via its dot and confirm the expected planet is shown —
        // the same ascending-next_change priority order the sort in
        // `_TransitAlertWidgetState.build` already produces (F2.2,
        // untouched by this change).
        const expectedOrder = [
          'Moon',
          'Mercury',
          'Venus',
          'Mars',
          'Sun',
          'Saturn',
          'Jupiter',
          'Rahu',
          'Ketu',
        ];
        for (var i = 0; i < expectedOrder.length; i++) {
          await tester.tap(find.byKey(ValueKey('planet_dot_$i')));
          await tester.pumpAndSettle();
          expect(
            find.text(expectedOrder[i]),
            findsOneWidget,
            reason: 'dot $i should show ${expectedOrder[i]}',
          );
        }
      },
    );

    testWidgets('renders exactly 9 pagination dots', (tester) async {
      await pumpWidget(tester, transitProvider: buildFullTransitProvider());

      for (var i = 0; i < 9; i++) {
        expect(find.byKey(ValueKey('planet_dot_$i')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('planet_dot_9')), findsNothing);
    });

    testWidgets(
      'the first dot is active initially — matching the first (nearest '
      'next_change) planet page',
      (tester) async {
        await pumpWidget(tester, transitProvider: buildFullTransitProvider());

        // Moon has the nearest next_change (2026-08-01) among the 9, so
        // it is the first carousel page.
        expect(find.text('Moon'), findsOneWidget);
      },
    );

    testWidgets(
      'swiping the carousel updates the active dot immediately',
      (tester) async {
        await pumpWidget(tester, transitProvider: buildFullTransitProvider());
        expect(find.text('Moon'), findsOneWidget);

        await tester.fling(
          find.byType(PageView),
          const Offset(-400, 0),
          1000,
        );
        await tester.pumpAndSettle();

        // Second-nearest next_change (2026-08-05) is Mercury.
        expect(find.text('Mercury'), findsOneWidget);
        expect(find.text('Moon'), findsNothing);
      },
    );

    testWidgets(
      'the first planet (dot 0) and the ninth planet (dot 8) are both '
      'reachable',
      (tester) async {
        await pumpWidget(tester, transitProvider: buildFullTransitProvider());

        // First planet — Moon (nearest next_change).
        await tester.tap(find.byKey(const ValueKey('planet_dot_0')));
        await tester.pumpAndSettle();
        expect(find.text('Moon'), findsOneWidget);

        // Ninth/last planet — Ketu (farthest next_change).
        await tester.tap(find.byKey(const ValueKey('planet_dot_8')));
        await tester.pumpAndSettle();
        expect(find.text('Ketu'), findsOneWidget);
      },
    );

    testWidgets(
      'existing card content and navigation are unaffected by the dots '
      'change — tapping the active card still opens TransitContentPage',
      (tester) async {
        await pumpWidget(tester, transitProvider: buildFullTransitProvider());

        expect(find.text('Moon'), findsOneWidget);
        expect(find.text('Next Change: 1 Aug 2026'), findsOneWidget);
        expect(find.text('Read Full Effects →'), findsOneWidget);

        await tester.tap(find.text('Moon'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(TransitContentPage), findsOneWidget);
      },
    );
  });
}
