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

  Future<void> pumpWidget(WidgetTester tester, {String lang = 'en'}) async {
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
          value: buildTransitProvider(),
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
    'tapping a planet chip switches the visible card, staying in the same '
    'priority order (Moon, then Mars, then Sun)',
    (tester) async {
      await pumpWidget(tester);

      expect(find.text('Moon'), findsOneWidget);

      // Mars chip (♂) — second in priority order.
      await tester.tap(find.text('♂'));
      await tester.pumpAndSettle();
      expect(find.text('Mars'), findsOneWidget);
      expect(find.text('Moon'), findsNothing);

      // Sun chip (☉) — third/last in priority order.
      await tester.tap(find.text('☉'));
      await tester.pumpAndSettle();
      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('Mars'), findsNothing);
    },
  );

  testWidgets(
    'swiping the card horizontally advances to the next planet, keeping '
    'the chip row in sync',
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
}
