import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/firebase_kundali_provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/manual_kundali_provider.dart';
import 'package:jyotishasha_app/core/widgets/in_app_webview.dart';
import 'package:jyotishasha_app/core/widgets/kundali_chart_north_widget.dart';
import 'package:jyotishasha_app/features/kundali/kundali_overview_page.dart';
import 'package:jyotishasha_app/features/kundali/widgets/identity_card.dart';
import 'package:jyotishasha_app/features/kundali/widgets/life_report_card.dart';
import 'package:jyotishasha_app/features/kundali/widgets/yog_dosh_mini_card.dart';
import 'package:jyotishasha_app/features/manual_kundali/manual_kundali_form_page.dart';

import '../../helpers/test_harness.dart';

/// Captures every route pushed via `Navigator.push` so a test can inspect
/// its target *without* letting Flutter actually mount/build it — mounting
/// a real [InAppWebView] with a live http(s) URL throws in this headless
/// test environment (no `webview_flutter` platform implementation is
/// registered — see `in_app_webview_test.dart`). Calling the captured
/// route's `builder` directly just invokes the plain closure
/// `(_) => InAppWebView(url: ...)`, which only *constructs* the widget
/// (no `initState`, no platform channel) — safe to inspect.
class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }
}

void main() {
  // autoLoad:false everywhere below — the provider state is set up
  // directly by each test, so the page must not also attempt a real
  // `loadFromFirebaseProfile()` call (which would touch FirebaseAuth,
  // unavailable in this test environment) while we assert on a
  // deliberately-constructed state. Both FirebaseKundaliProvider and
  // ManualKundaliProvider are always registered — F8.7 made
  // KundaliOverviewPage watch both regardless of `useManualProvider`, so
  // both must be present in the tree for any test to pump successfully.
  Future<void> pump(
    WidgetTester tester,
    FirebaseKundaliProvider provider, {
    bool autoLoad = false,
    bool useManualProvider = false,
    String lang = 'en',
    ManualKundaliProvider? manualProvider,
    List<NavigatorObserver> navigatorObservers = const [],
  }) async {
    await tester.pumpTestHarness(
      KundaliOverviewPage(
        autoLoad: autoLoad,
        useManualProvider: useManualProvider,
      ),
      navigatorObservers: navigatorObservers,
      providers: [
        ChangeNotifierProvider<FirebaseKundaliProvider>.value(value: provider),
        ChangeNotifierProvider<ManualKundaliProvider>.value(
          value: manualProvider ?? ManualKundaliProvider(),
        ),
        ChangeNotifierProvider<LanguageProvider>.value(
          value: LanguageProvider()..currentLang = lang,
        ),
      ],
    );
  }

  testWidgets('shows a loading indicator while isLoading is true', (
    tester,
  ) async {
    final provider = FirebaseKundaliProvider()..isLoading = true;

    await pump(tester, provider);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(KundaliChartNorthWidget), findsNothing);
  });

  testWidgets(
    'shows an error state with a Retry action when errorMessage is set',
    (tester) async {
      final provider = FirebaseKundaliProvider()..errorMessage = 'boom';

      await pump(tester, provider);

      expect(
        find.text('Something went wrong loading your Kundali.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
    },
  );

  testWidgets(
    'shows an empty state with a Retry action when there is no data, no '
    'error, and nothing is loading',
    (tester) async {
      final provider = FirebaseKundaliProvider();

      await pump(tester, provider);

      expect(find.text('No Kundali data available yet.'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
    },
  );

  testWidgets(
    'renders the chart, birth details, Know Yourself, Planetary '
    'Influences, Yog & Dosh, and Life Areas sections in order when '
    'kundaliData is present',
    (tester) async {
      final provider = FirebaseKundaliProvider()
        ..kundaliData = {
          'profile': {
            'name': 'ravi kumar',
            'dob': '1990-08-12',
            'tob': '10:30',
            'pob': 'New Delhi, India',
          },
          'lagna_sign': 'Cancer',
          'lagna_trait': 'You are intuitive and nurturing.',
          'rashi': 'Leo',
          'nakshatra': 'Rohini',
          'moon_traits': {
            'personality': 'You are warm-hearted and expressive.',
          },
          'dasha_summary': {
            'current_block': {
              'mahadasha': 'Saturn',
              'antardasha': 'Mercury',
              'impact_snippet': 'A period of discipline and steady growth.',
            },
          },
          'chart_data': {
            'planets': [
              {'name': 'Sun', 'house': 1, 'sign': 'Leo'},
              {'name': 'Moon', 'house': 4, 'sign': 'Cancer'},
            ],
          },
          'planet_overview': [
            {'planet': 'Sun', 'summary': 'The Sun boosts your confidence.'},
          ],
          'yogas': {
            'gajakesari_yog': {
              'is_active': true,
              'heading': 'Gajakesari Yog',
              'description':
                  'Brings wisdom, respect, and prosperity.\nSecond line.',
            },
            'dhan_yog': {
              'is_active': false,
              'heading': 'Dhan Yog',
              'description': 'Indicates wealth accumulation.',
            },
            'manglik_dosh': {
              'is_active': true,
              'heading': 'Mangal Dosh',
              'description': 'May cause friction in marital harmony.',
            },
            'kaalsarp_dosh': {'is_active': false},
          },
        };

      await pump(tester, provider);

      // Chart — reuses the existing widget with the right data, not a new
      // chart implementation. F8.6 adds a "Birth Chart" title and three
      // at-a-glance badges below it (Ascendant/Moon Sign/Nakshatra), built
      // from the exact same fields the Know Yourself cards below also
      // read — hence each of these three values legitimately appears
      // TWICE on the page now (once as a badge, once as a card value).
      final chart = tester.widget<KundaliChartNorthWidget>(
        find.byType(KundaliChartNorthWidget),
      );
      expect(chart.lagnaSign, 'Cancer');
      expect(chart.planets.length, 2);
      expect(find.text('Birth Chart'), findsOneWidget);
      expect(find.text('♋'), findsOneWidget); // Cancer's zodiac glyph
      expect(find.text('🌙'), findsOneWidget);
      expect(find.text('⭐'), findsOneWidget);

      // Birth Details — F8.6 compact icon grid: 👤 Name, 📅 Date of
      // Birth, 🕒 Birth Time, 📍 Birth Place, each label/value now its
      // own Text (no more "Label: Value" single line).
      expect(find.text('Birth Details'), findsOneWidget);
      expect(find.text('👤'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('ravi kumar'), findsOneWidget);
      expect(find.text('📅'), findsOneWidget);
      expect(find.text('Date of Birth'), findsOneWidget);
      expect(find.text('12-08-1990'), findsOneWidget);
      expect(find.text('🕒'), findsOneWidget);
      expect(find.text('Birth Time'), findsOneWidget);
      expect(find.text('10:30'), findsOneWidget);
      expect(find.text('📍'), findsOneWidget);
      expect(find.text('Birth Place'), findsOneWidget);
      expect(find.text('New Delhi, India'), findsOneWidget);

      // Know Yourself (F8.2, renamed+redesigned F8.6) — 4 cards: real
      // values from kundaliData, no duplicated calculation. Mahadasha +
      // Antardasha are now ONE merged "Current Dasha" card instead of
      // two separate cards, so the impact_snippet summary now appears
      // only once (not twice), and "Saturn"/"Mercury" no longer appear
      // as standalone Know Yourself values — they're combined into one
      // "Saturn → Mercury" string.
      expect(find.text('Know Yourself'), findsOneWidget);
      expect(find.text('Your Ascendant'), findsOneWidget);
      expect(find.text('Cancer'), findsNWidgets(2)); // card value + badge
      expect(find.text('You are intuitive and nurturing.'), findsOneWidget);
      expect(find.text('Your Moon Sign'), findsOneWidget);
      expect(find.text('Leo'), findsNWidgets(2)); // card value + badge
      expect(
        find.text('You are warm-hearted and expressive.'),
        findsOneWidget,
      );
      expect(find.text('Your Nakshatra'), findsOneWidget);
      expect(find.text('Rohini'), findsNWidgets(2)); // card value + badge
      expect(find.text('Current Dasha'), findsOneWidget);
      expect(find.text('Your Mahadasha'), findsNothing);
      expect(find.text('Your Antardasha'), findsNothing);
      expect(find.text('Saturn → Mercury'), findsOneWidget);
      expect(
        find.text('A period of discipline and steady growth.'),
        findsOneWidget, // shown once now, not once-per-old-card
      );

      // Planetary Influences (F8.3, renamed+redesigned F8.6) — all 9
      // cards in the fixed Sun..Ketu order, real house/sign from
      // chart_data.planets, real interpretation from planet_overview
      // where present, neutral placeholder where absent (no new
      // astrology calculated or invented). Position order swapped to
      // Sign • House per F8.6 (was House • Sign).
      expect(find.text('Planetary Influences'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('Leo • 1st House'), findsOneWidget);
      expect(find.text('The Sun boosts your confidence.'), findsOneWidget);
      expect(find.text('Moon'), findsOneWidget);
      expect(find.text('Cancer • 4th House'), findsOneWidget);
      for (final name in ['Mars', 'Jupiter', 'Venus', 'Rahu', 'Ketu']) {
        expect(find.text(name), findsOneWidget);
      }
      // "Saturn"/"Mercury" now appear only here — the Know Yourself
      // Current Dasha card combines both into "Saturn → Mercury" rather
      // than showing either name standalone.
      expect(find.text('Saturn'), findsOneWidget);
      expect(find.text('Mercury'), findsOneWidget);
      expect(
        find.text('Details for this planet will be added soon.'),
        findsNWidgets(8), // the 8 planets absent from planet_overview above
      );

      // Yog & Dosh — F8.5.2, one combined section introduction (Title +
      // subtitle), then "✨ Active Yogas" and "⚠ Active Doshas" premium
      // grids of compact YogDoshMiniCards. Backend filtering/active-entry
      // logic unchanged from F8.4: only the ACTIVE entries render, the
      // inactive ones (dhan_yog, kaalsarp_dosh) must not appear anywhere.
      // No description/effect text anywhere in this section anymore.
      expect(find.text('Yog & Dosh'), findsOneWidget);
      expect(
        find.textContaining('Special planetary combinations'),
        findsOneWidget,
      );
      expect(find.text('✨ Active Yogas'), findsOneWidget);
      expect(find.text('Gajakesari Yog'), findsOneWidget);
      expect(find.text('🐘🌙'), findsOneWidget); // YogDoshMeta icon, reused
      expect(
        find.text('Brings wisdom, respect, and prosperity.'),
        findsNothing, // effect text no longer shown on the compact card
      );
      expect(find.text('Dhan Yog'), findsNothing);

      expect(find.text('⚠ Active Doshas'), findsOneWidget);
      expect(find.text('Mangal Dosh'), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget); // YogDoshMeta icon, reused
      expect(
        find.text('May cause friction in marital harmony.'),
        findsNothing, // effect text no longer shown on the compact card
      );
      expect(find.text('Kaalsarp Dosh'), findsNothing);

      // Life Areas — F8.5, all 12 fixed cards, title + fixed one-line
      // educational intro (verbatim from the task spec, never generated
      // or calculated), no backend field read at all for this section.
      expect(find.text('Life Areas'), findsOneWidget);
      expect(
        find.textContaining("doesn't only describe who you are"),
        findsOneWidget,
      );
      for (final title in const [
        'Love & Relationship',
        'Career',
        'Finance & Wealth',
        'Marriage',
        'Family',
        'Children',
        'Education',
        'Health',
        'Property',
        'Foreign Travel',
        'Spirituality',
        'Legal Matters',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      expect(
        find.text(
          'Discover how your birth chart influences your profession, '
          'growth and career direction.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Explore legal challenges and justice-related indications.'),
        findsOneWidget,
      );

      // "Create Another Kundali" CTA — F8.7, at the very end of the page,
      // only shown for "My Kundali" (useManualProvider defaults false).
      expect(find.text('Need another Kundali?'), findsOneWidget);
      expect(
        find.text(
          'Generate a Kundali for your family, friends or anyone else.',
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ElevatedButton, 'Create Another Kundali'),
        findsOneWidget,
      );

      // Per the F8.2 config: Ascendant/Moon Sign/Nakshatra are AVAILABLE
      // (tappable CTA); the merged Current Dasha card is COMING_SOON
      // (mahadasha's status — same config, now surfaced on one card
      // instead of two). Per the F8.3 config: all 9 planets are
      // AVAILABLE. Per the F8.4 config: both active Yog/Dosh entries are
      // AVAILABLE. Per the F8.5 config: 4 of 12 Life Areas are AVAILABLE
      // (Love & Relationship, Career, Marriage, Foreign Travel), the
      // other 8 are COMING_SOON.
      expect(
        find.text('View Full Free Report →'),
        findsNWidgets(3 + 9 + 2 + 4),
      );
      expect(find.text('Coming Soon'), findsNWidgets(1 + 8));
      // No leftover "Coming soon" placeholder text anywhere.
      expect(find.text('Coming soon'), findsNothing);

      // Section order: Birth Chart → Birth Details → Know Yourself →
      // Planetary Influences → Yog & Dosh (with its Active Yogas/Active
      // Doshas groups nested inside) → Life Areas, verified via
      // on-screen top-to-bottom text order.
      final allTexts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toList();
      final order = [
        'Birth Chart',
        'Birth Details',
        'Know Yourself',
        'Planetary Influences',
        'Yog & Dosh',
        '✨ Active Yogas',
        '⚠ Active Doshas',
        'Life Areas',
        'Need another Kundali?',
      ].map(allTexts.indexOf).toList();
      expect(
        order,
        equals(List<int>.from(order)..sort()),
        reason: 'sections must appear in the required order',
      );
    },
  );

  testWidgets(
    'shows ONE small "No major Yog or Dosh detected." line — and hides '
    'both group headings entirely — when the backend returns none active',
    (tester) async {
      final provider = FirebaseKundaliProvider()
        ..kundaliData = {
          'profile': {'name': 'ravi kumar'},
          'lagna_sign': 'Cancer',
          'rashi': 'Leo',
          'nakshatra': 'Rohini',
          'chart_data': {'planets': []},
          'yogas': {
            'dhan_yog': {'is_active': false},
            'manglik_dosh': {'is_active': false},
          },
        };

      await pump(tester, provider);

      expect(find.text('No major Yog or Dosh detected.'), findsOneWidget);
      expect(find.text('No major Yog detected.'), findsNothing);
      expect(find.text('No major Dosh detected.'), findsNothing);
      expect(find.text('✨ Active Yogas'), findsNothing);
      expect(find.text('⚠ Active Doshas'), findsNothing);
    },
  );

  testWidgets(
    'shows ONE small "No major Yog or Dosh detected." line when the '
    'backend returns no `yogas` map at all',
    (tester) async {
      final provider = FirebaseKundaliProvider()
        ..kundaliData = {
          'profile': {'name': 'ravi kumar'},
          'lagna_sign': 'Cancer',
          'rashi': 'Leo',
          'nakshatra': 'Rohini',
          'chart_data': {'planets': []},
        };

      await pump(tester, provider);

      expect(find.text('No major Yog or Dosh detected.'), findsOneWidget);
      expect(find.text('✨ Active Yogas'), findsNothing);
      expect(find.text('⚠ Active Doshas'), findsNothing);
    },
  );

  testWidgets(
    'hides the Active Doshas group entirely (no heading, no empty text) '
    'when only Yog is active — per-group visibility, not a shared '
    'empty state',
    (tester) async {
      final provider = FirebaseKundaliProvider()
        ..kundaliData = {
          'profile': {'name': 'ravi kumar'},
          'lagna_sign': 'Cancer',
          'rashi': 'Leo',
          'nakshatra': 'Rohini',
          'chart_data': {'planets': []},
          'yogas': {
            'gajakesari_yog': {'is_active': true, 'heading': 'Gajakesari Yog'},
            'manglik_dosh': {'is_active': false},
          },
        };

      await pump(tester, provider);

      expect(find.text('✨ Active Yogas'), findsOneWidget);
      expect(find.text('Gajakesari Yog'), findsOneWidget);
      expect(find.text('⚠ Active Doshas'), findsNothing);
      expect(find.text('No major Yog or Dosh detected.'), findsNothing);
      expect(find.text('No major Dosh detected.'), findsNothing);
    },
  );

  testWidgets(
    'hides the Active Yogas group entirely (no heading, no empty text) '
    'when only Dosh is active',
    (tester) async {
      final provider = FirebaseKundaliProvider()
        ..kundaliData = {
          'profile': {'name': 'ravi kumar'},
          'lagna_sign': 'Cancer',
          'rashi': 'Leo',
          'nakshatra': 'Rohini',
          'chart_data': {'planets': []},
          'yogas': {
            'manglik_dosh': {'is_active': true, 'heading': 'Mangal Dosh'},
            'gajakesari_yog': {'is_active': false},
          },
        };

      await pump(tester, provider);

      expect(find.text('⚠ Active Doshas'), findsOneWidget);
      expect(find.text('Mangal Dosh'), findsOneWidget);
      expect(find.text('✨ Active Yogas'), findsNothing);
      expect(find.text('No major Yog or Dosh detected.'), findsNothing);
      expect(find.text('No major Yog detected.'), findsNothing);
    },
  );

  group('useManualProvider (F8.7 — data-source independence)', () {
    testWidgets(
      'reads ManualKundaliProvider, not FirebaseKundaliProvider, when '
      'useManualProvider is true — shows the generated person\'s name as '
      'the AppBar title, and no "Create Another Kundali" CTA',
      (tester) async {
        final firebaseProvider = FirebaseKundaliProvider()
          ..kundaliData = {
            'profile': {'name': 'the signed-in user'},
            'lagna_sign': 'Aries',
          };
        final manualProvider = ManualKundaliProvider()
          ..kundali = {
            'profile': {'name': 'Priya Sharma'},
            'lagna_sign': 'Scorpio',
            'rashi': 'Pisces',
            'nakshatra': 'Revati',
            'chart_data': {'planets': []},
          };

        await pump(
          tester,
          firebaseProvider,
          useManualProvider: true,
          manualProvider: manualProvider,
        );

        // AppBar shows the manually-generated person's name, not "Kundali"
        // — it also appears once more as the Birth Details "Name" value,
        // so two occurrences total — and not the Firebase user's data at
        // all.
        expect(find.text('Priya Sharma'), findsNWidgets(2));
        expect(find.text('the signed-in user'), findsNothing);
        expect(find.text('Aries'), findsNothing);
        expect(find.text('Scorpio'), findsNWidgets(2)); // badge + card value

        // No "Create Another Kundali" CTA on a manual-mode page.
        expect(find.text('Need another Kundali?'), findsNothing);
        expect(
          find.widgetWithText(ElevatedButton, 'Create Another Kundali'),
          findsNothing,
        );

        // FirebaseKundaliProvider itself was never touched.
        expect(firebaseProvider.kundaliData?['profile']['name'],
            'the signed-in user');
      },
    );

    testWidgets(
      'never calls FirebaseKundaliProvider.loadFromFirebaseProfile when '
      'useManualProvider is true, even with autoLoad — the guard in _load '
      'returns before touching Firebase at all',
      (tester) async {
        final firebaseProvider = FirebaseKundaliProvider();
        final manualProvider = ManualKundaliProvider()
          ..kundali = {
            'profile': {'name': 'Amit'},
            'chart_data': {'planets': []},
          };

        await pump(
          tester,
          firebaseProvider,
          useManualProvider: true,
          autoLoad: true,
          manualProvider: manualProvider,
        );
        await tester.pump();

        // If _load() had ignored the useManualProvider guard, this would
        // have attempted a real Firebase call and set errorMessage (as
        // proven by the autoLoad test above) — it must stay untouched.
        expect(firebaseProvider.errorMessage, isNull);
        expect(firebaseProvider.isLoading, isFalse);
        expect(firebaseProvider.kundaliData, isNull);
      },
    );

    testWidgets(
      'shows the loading/error/empty states from ManualKundaliProvider '
      'when useManualProvider is true, independently of Firebase state',
      (tester) async {
        final firebaseProvider = FirebaseKundaliProvider()
          ..errorMessage = 'firebase side error, must be ignored here';
        final manualProvider = ManualKundaliProvider()..isLoading = true;

        await pump(
          tester,
          firebaseProvider,
          useManualProvider: true,
          manualProvider: manualProvider,
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          find.text('Something went wrong loading your Kundali.'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'falls back to the generic "Kundali" AppBar title when '
      'useManualProvider is true but no profile name is present yet',
      (tester) async {
        final firebaseProvider = FirebaseKundaliProvider();
        final manualProvider = ManualKundaliProvider();

        await pump(
          tester,
          firebaseProvider,
          useManualProvider: true,
          manualProvider: manualProvider,
        );

        expect(find.text('Kundali'), findsOneWidget);
      },
    );
  });

  group('Self | Other toggle (Task 2 — unified Self/Other Kundali UX)', () {
    Map<String, dynamic> selfFixture() => {
      'profile': {'name': 'the signed-in user'},
      'lagna_sign': 'Aries',
      'chart_data': {'planets': []},
    };

    Map<String, dynamic> otherFixture() => {
      'profile': {'name': 'Priya Sharma'},
      'lagna_sign': 'Scorpio',
      'chart_data': {'planets': []},
    };

    testWidgets(
      'default entry (Your Astrology Profile / bottom-nav Astrology tab) '
      'opens in Self mode and shows both toggle segments',
      (tester) async {
        final provider = FirebaseKundaliProvider()..kundaliData = selfFixture();

        await pump(tester, provider);

        expect(find.text('Self'), findsOneWidget);
        expect(find.text('Other'), findsOneWidget);
        // Self content is on screen without ever tapping the toggle.
        expect(find.text('the signed-in user'), findsOneWidget);
        expect(find.byType(ManualKundaliBirthDetailsForm), findsNothing);
      },
    );

    testWidgets(
      'Create Another Kundali / Other-person entry (useManualProvider: '
      'true) opens directly in Other mode and shows the birth-details '
      'form when no Other Kundali exists yet',
      (tester) async {
        final firebaseProvider = FirebaseKundaliProvider();
        final manualProvider = ManualKundaliProvider();

        await pump(
          tester,
          firebaseProvider,
          useManualProvider: true,
          manualProvider: manualProvider,
        );

        expect(find.byType(ManualKundaliBirthDetailsForm), findsOneWidget);
        expect(find.text('Full Name'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Other while viewing Self switches to the birth-details '
      "form and never touches FirebaseKundaliProvider's data",
      (tester) async {
        final firebaseProvider = FirebaseKundaliProvider()
          ..kundaliData = selfFixture();
        final manualProvider = ManualKundaliProvider();

        await pump(tester, firebaseProvider, manualProvider: manualProvider);

        await tester.tap(find.text('Other'));
        await tester.pumpAndSettle();

        expect(find.byType(ManualKundaliBirthDetailsForm), findsOneWidget);
        expect(find.text('the signed-in user'), findsNothing);
        // Self's own data was never touched.
        expect(
          firebaseProvider.kundaliData?['profile']['name'],
          'the signed-in user',
        );
      },
    );

    testWidgets(
      'tapping Self while viewing an existing Other Kundali switches back '
      "and never touches ManualKundaliProvider's data",
      (tester) async {
        final firebaseProvider = FirebaseKundaliProvider()
          ..kundaliData = selfFixture();
        final manualProvider = ManualKundaliProvider()
          ..kundali = otherFixture();

        await pump(
          tester,
          firebaseProvider,
          useManualProvider: true,
          manualProvider: manualProvider,
        );
        expect(find.text('Priya Sharma'), findsWidgets);

        await tester.tap(find.text('Self'));
        await tester.pumpAndSettle();

        expect(find.text('the signed-in user'), findsOneWidget);
        expect(find.text('Priya Sharma'), findsNothing);
        // Other's own data was never touched/reset by switching away.
        expect(manualProvider.kundali?['profile']['name'], 'Priya Sharma');
      },
    );

    testWidgets(
      'switching Self → Other → Self → Other preserves the previously '
      'generated Other Kundali — switching away never resets it',
      (tester) async {
        final firebaseProvider = FirebaseKundaliProvider()
          ..kundaliData = selfFixture();
        final manualProvider = ManualKundaliProvider()
          ..kundali = otherFixture();

        await pump(tester, firebaseProvider, manualProvider: manualProvider);

        await tester.tap(find.text('Other'));
        await tester.pumpAndSettle();
        expect(find.text('Priya Sharma'), findsWidgets);
        expect(find.byType(ManualKundaliBirthDetailsForm), findsNothing);

        await tester.tap(find.text('Self'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Other'));
        await tester.pumpAndSettle();

        // Still the same previously generated Other Kundali — the form
        // did not reappear.
        expect(find.text('Priya Sharma'), findsWidgets);
        expect(find.byType(ManualKundaliBirthDetailsForm), findsNothing);
      },
    );

    testWidgets(
      'a successful Other generation (ManualKundaliProvider populated) '
      'reactively swaps the embedded form out for the shared Kundali '
      'rendering, with no navigation required',
      (tester) async {
        final firebaseProvider = FirebaseKundaliProvider();
        final manualProvider = ManualKundaliProvider();

        await pump(
          tester,
          firebaseProvider,
          useManualProvider: true,
          manualProvider: manualProvider,
        );
        expect(find.byType(ManualKundaliBirthDetailsForm), findsOneWidget);

        // Simulate what a successful generateKundali() call leaves
        // behind — same fixture-injection approach the rest of this
        // suite already uses for FirebaseKundaliProvider.
        manualProvider.kundali = otherFixture();
        manualProvider.notifyListeners();
        await tester.pump();

        expect(find.byType(ManualKundaliBirthDetailsForm), findsNothing);
        expect(find.text('Priya Sharma'), findsWidgets);
      },
    );

    testWidgets(
      'shows a "Create New Kundali" action (not "Create Another '
      'Kundali") when Other mode already has a generated Kundali on '
      'screen',
      (tester) async {
        final firebaseProvider = FirebaseKundaliProvider();
        final manualProvider = ManualKundaliProvider()
          ..kundali = otherFixture();

        await pump(
          tester,
          firebaseProvider,
          useManualProvider: true,
          manualProvider: manualProvider,
        );

        expect(
          find.widgetWithText(OutlinedButton, 'Create New Kundali'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(ElevatedButton, 'Create Another Kundali'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'tapping "Create New Kundali" resets ManualKundaliProvider and '
      'shows the birth-details form again — an explicit action, never '
      'automatic on a mode switch',
      (tester) async {
        final firebaseProvider = FirebaseKundaliProvider();
        final manualProvider = ManualKundaliProvider()
          ..kundali = otherFixture();

        await pump(
          tester,
          firebaseProvider,
          useManualProvider: true,
          manualProvider: manualProvider,
        );

        final createNew = find.widgetWithText(
          OutlinedButton,
          'Create New Kundali',
        );
        await tester.ensureVisible(createNew);
        await tester.tap(createNew);
        await tester.pumpAndSettle();

        expect(manualProvider.kundali, isNull);
        expect(find.byType(ManualKundaliBirthDetailsForm), findsOneWidget);
      },
    );

    testWidgets('the toggle and the embedded form render in Hindi', (
      tester,
    ) async {
      final firebaseProvider = FirebaseKundaliProvider();
      final manualProvider = ManualKundaliProvider();

      await pump(
        tester,
        firebaseProvider,
        useManualProvider: true,
        manualProvider: manualProvider,
        lang: 'hi',
      );

      expect(find.text('स्वयं'), findsOneWidget);
      expect(find.text('अन्य'), findsOneWidget);
      expect(find.text('पूरा नाम'), findsOneWidget);
    });

    testWidgets(
      'the existing "Create Another Kundali" CTA on the Self page still '
      'works — it pushes ManualKundaliFormPage, which (Task 2) now opens '
      'this same unified page already in Other mode',
      (tester) async {
        final observer = _RecordingNavigatorObserver();
        final provider = FirebaseKundaliProvider()..kundaliData = selfFixture();

        await pump(tester, provider, navigatorObservers: [observer]);
        final baseline = observer.pushed.length;

        final cta = find.widgetWithText(ElevatedButton, 'Create Another Kundali');
        await tester.ensureVisible(cta);
        await tester.tap(cta);
        await tester.pumpAndSettle();

        expect(observer.pushed.length, greaterThan(baseline));
        expect(find.byType(ManualKundaliFormPage), findsOneWidget);
      },
    );
  });

  group('Nakshatra extraction (bug fix — was showing "-")', () {
    testWidgets(
      'falls back to parsing the Moon\'s planet_overview summary text '
      'when the backend response has no top-level `nakshatra` field — '
      'the real-world case that was showing "-"',
      (tester) async {
        final provider = FirebaseKundaliProvider()
          ..kundaliData = {
            'profile': {'name': 'ravi kumar'},
            'lagna_sign': 'Cancer',
            'rashi': 'Leo',
            // Deliberately no top-level 'nakshatra' key — matches the
            // real backend response shape that triggered the bug.
            'chart_data': {'planets': []},
            'planet_overview': [
              {
                'planet': 'Moon',
                'summary':
                    'Moon in Leo.\nNakshatra: Chitra (Pada 2)\nOther line.',
              },
            ],
          };

        await pump(tester, provider);

        // Appears twice — once as the chart badge, once as the "Your
        // Nakshatra" card value — exactly like every other resolved
        // value on this page (Ascendant/Moon Sign already do the same).
        expect(find.text('Chitra'), findsNWidgets(2));
      },
    );

    testWidgets(
      'uses the top-level `nakshatra` field directly when the backend '
      'does send it (forward-compatible, no parsing needed)',
      (tester) async {
        final provider = FirebaseKundaliProvider()
          ..kundaliData = {
            'profile': {'name': 'ravi kumar'},
            'lagna_sign': 'Cancer',
            'rashi': 'Leo',
            'nakshatra': 'Rohini',
            'chart_data': {'planets': []},
            'planet_overview': [
              {'planet': 'Moon', 'summary': 'Nakshatra: Chitra (Pada 2)'},
            ],
          };

        await pump(tester, provider);

        // The direct field wins — the summary-text fallback is never
        // consulted when it isn't needed.
        expect(find.text('Rohini'), findsNWidgets(2));
        expect(find.text('Chitra'), findsNothing);
      },
    );

    testWidgets(
      'shows "-" (never fabricates a value) when neither the top-level '
      'field nor the Moon\'s planet_overview summary has it',
      (tester) async {
        final provider = FirebaseKundaliProvider()
          ..kundaliData = {
            'profile': {'name': 'ravi kumar'},
            'lagna_sign': 'Cancer',
            'rashi': 'Leo',
            'chart_data': {'planets': []},
          };

        await pump(tester, provider);

        // The card renders normally (no crash) with the honest fallback
        // value — nothing fabricated in its place.
        expect(find.text('Your Nakshatra'), findsOneWidget);
        expect(find.text('Chitra'), findsNothing);
        expect(find.text('Rohini'), findsNothing);
      },
    );

    testWidgets(
      'applies identically to a manually generated Kundali '
      '(ManualKundaliProvider) — the same backend response shape, same '
      'fix',
      (tester) async {
        final firebaseProvider = FirebaseKundaliProvider();
        final manualProvider = ManualKundaliProvider()
          ..kundali = {
            'profile': {'name': 'Priya Sharma'},
            'lagna_sign': 'Scorpio',
            'rashi': 'Pisces',
            'chart_data': {'planets': []},
            'planet_overview': [
              {
                'planet': 'Moon',
                'summary': 'Nakshatra: Revati (Pada 4)',
              },
            ],
          };

        await pump(
          tester,
          firebaseProvider,
          useManualProvider: true,
          manualProvider: manualProvider,
        );

        expect(find.text('Revati'), findsNWidgets(2));
      },
    );
  });

  testWidgets('renders Hindi copy for the empty state', (tester) async {
    final provider = FirebaseKundaliProvider();

    await pump(tester, provider, lang: 'hi');

    expect(find.text('कुंडली'), findsOneWidget); // AppBar title
    expect(find.text('अभी कोई कुंडली डेटा उपलब्ध नहीं है।'), findsOneWidget);
    expect(find.text('पुनः प्रयास करें'), findsOneWidget);
  });

  testWidgets(
    'tapping Retry on the empty state calls loadFromFirebaseProfile again',
    (tester) async {
      final provider = FirebaseKundaliProvider();

      await pump(tester, provider);
      expect(provider.errorMessage, isNull);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Retry'));
      await tester.pump();

      // FirebaseAuth isn't available in this test environment, so
      // `loadFromFirebaseProfile` fails immediately (synchronously, before
      // its first real await) — that failure being reflected back onto
      // the provider is exactly what proves Retry actually invoked it,
      // rather than being a no-op button.
      expect(provider.errorMessage, isNotNull);
      expect(provider.isLoading, isFalse);
    },
  );

  testWidgets(
    'with autoLoad (default), mounting the page with no data connects to '
    'the provider and kicks off a load automatically',
    (tester) async {
      final provider = FirebaseKundaliProvider();

      await pump(tester, provider, autoLoad: true);

      // Same reasoning as above: the auto-triggered load fails fast in
      // this test environment, but that failure landing on the provider
      // proves the page's initState genuinely wired up and called
      // FirebaseKundaliProvider.loadFromFirebaseProfile — not a new
      // provider, the existing one.
      expect(provider.errorMessage, isNotNull);
    },
  );

  group('Report navigation (F8.8 — connected via ReportDestinations)', () {
    Map<String, dynamic> fixtureData() => {
      'profile': {'name': 'ravi kumar'},
      'lagna_sign': 'Cancer',
      'rashi': 'Leo',
      'nakshatra': 'Rohini',
      'chart_data': {
        'planets': [
          {'name': 'Sun', 'house': 1, 'sign': 'Leo'},
        ],
      },
      'yogas': {
        'gajakesari_yog': {'is_active': true, 'heading': 'Gajakesari Yog'},
        'budh_aditya_yog': {'is_active': true, 'heading': 'Budh Aditya Yog'},
      },
    };

    /// Taps [finder], lets the tap's `onPressed`/`Navigator.push` fire,
    /// then swallows the expected "no webview platform implementation"
    /// exception that mounting a real [InAppWebView] throws in this
    /// headless environment (see `in_app_webview_test.dart`) — that
    /// exception firing at all is itself proof navigation reached a real
    /// widget build attempt, not a no-op.
    Future<void> tapAndSwallowWebViewException(
      WidgetTester tester,
      Finder finder,
    ) async {
      // The page is a long SingleChildScrollView — most cards start
      // below the test viewport, so the target must be scrolled into
      // view before it can receive a tap.
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pump();
      tester.takeException(); // consume/ignore, don't fail the test
    }

    /// The very first entry in [observer.pushed] is the harness's own
    /// initial `home:` route (`KundaliOverviewPage` itself), pushed
    /// before any test action — every assertion below must look only at
    /// routes pushed AFTER that baseline.
    Route<dynamic> lastRealPush(_RecordingNavigatorObserver observer) =>
        observer.pushed.last;

    testWidgets(
      'Ascendant CTA opens InAppWebView pointed at the lagna-finder tool',
      (tester) async {
        final observer = _RecordingNavigatorObserver();
        final provider = FirebaseKundaliProvider()..kundaliData = fixtureData();
        await pump(tester, provider, navigatorObservers: [observer]);
        final baseline = observer.pushed.length;

        await tapAndSwallowWebViewException(
          tester,
          find.text('View Full Free Report →').first,
        );

        expect(observer.pushed.length, greaterThan(baseline));
        final route = lastRealPush(observer) as MaterialPageRoute;
        final widget =
            route.builder(tester.element(find.byType(Scaffold).first))
                as InAppWebView;
        expect(widget.url, 'https://jyotishasha.com/tools/lagna-finder');
      },
    );

    testWidgets(
      'a Planetary Influences CTA (Sun) opens InAppWebView pointed at '
      "the planet's transit page",
      (tester) async {
        final observer = _RecordingNavigatorObserver();
        final provider = FirebaseKundaliProvider()..kundaliData = fixtureData();
        await pump(tester, provider, navigatorObservers: [observer]);
        final baseline = observer.pushed.length;

        // Sun is AVAILABLE per PlanetReportAvailability — its card is the
        // first Planetary Influences "View Full Free Report →" CTA;
        // Ascendant/Moon Sign/Nakshatra (3) come first in Know Yourself.
        await tapAndSwallowWebViewException(
          tester,
          find.text('View Full Free Report →').at(3),
        );

        expect(observer.pushed.length, greaterThan(baseline));
        final route = lastRealPush(observer) as MaterialPageRoute;
        final widget =
            route.builder(tester.element(find.byType(Scaffold).first))
                as InAppWebView;
        expect(widget.url, 'https://jyotishasha.com/sun-transit');
      },
    );

    testWidgets(
      'an Active Yog CTA (Gajakesari Yog) opens InAppWebView pointed at '
      'its /tools/ page',
      (tester) async {
        final observer = _RecordingNavigatorObserver();
        final provider = FirebaseKundaliProvider()..kundaliData = fixtureData();
        await pump(tester, provider, navigatorObservers: [observer]);
        final baseline = observer.pushed.length;

        // Locate the CTA specifically inside the Gajakesari Yog
        // YogDoshMiniCard — not just "any View Full Free Report → on the
        // page", since that text repeats many times.
        final gajakesariCard = find.ancestor(
          of: find.text('Gajakesari Yog'),
          matching: find.byType(YogDoshMiniCard),
        );
        final cta = find.descendant(
          of: gajakesariCard,
          matching: find.text('View Full Free Report →'),
        );
        await tapAndSwallowWebViewException(tester, cta);

        expect(observer.pushed.length, greaterThan(baseline));
        final route = lastRealPush(observer) as MaterialPageRoute;
        final widget =
            route.builder(tester.element(find.byType(Scaffold).first))
                as InAppWebView;
        expect(widget.url, 'https://jyotishasha.com/tools/gajakesari-yog');
      },
    );

    testWidgets(
      'budh_aditya_yog (AVAILABLE per config, but no known Next.js page) '
      'does NOT navigate anywhere when tapped — a safe no-op, not a '
      'guessed URL or a crash',
      (tester) async {
        final observer = _RecordingNavigatorObserver();
        final provider = FirebaseKundaliProvider()..kundaliData = fixtureData();
        await pump(tester, provider, navigatorObservers: [observer]);
        final baseline = observer.pushed.length;

        final budhCard = find.ancestor(
          of: find.text('Budh Aditya Yog'),
          matching: find.byType(YogDoshMiniCard),
        );
        final cta = find.descendant(
          of: budhCard,
          matching: find.text('View Full Free Report →'),
        );

        // Still shown as tappable per the untouched availability config —
        // but tapping it must not push anything, and must not throw.
        await tester.ensureVisible(cta);
        await tester.pumpAndSettle();
        await tester.tap(cta);
        await tester.pumpAndSettle();

        expect(observer.pushed.length, baseline);
        expect(find.byType(InAppWebView), findsNothing);
      },
    );

    testWidgets(
      'a Life Area CTA (Career) opens InAppWebView pointed at its '
      '/tools/ page',
      (tester) async {
        final observer = _RecordingNavigatorObserver();
        final provider = FirebaseKundaliProvider()..kundaliData = fixtureData();
        await pump(tester, provider, navigatorObservers: [observer]);
        final baseline = observer.pushed.length;

        final careerCard = find.ancestor(
          of: find.text('Career'),
          matching: find.byType(LifeReportCard),
        );
        final cta = find.descendant(
          of: careerCard,
          matching: find.text('View Full Free Report →'),
        );
        await tapAndSwallowWebViewException(tester, cta);

        expect(observer.pushed.length, greaterThan(baseline));
        final route = lastRealPush(observer) as MaterialPageRoute;
        final widget =
            route.builder(tester.element(find.byType(Scaffold).first))
                as InAppWebView;
        expect(widget.url, 'https://jyotishasha.com/tools/career-path');
      },
    );

    testWidgets(
      'the Current Dasha card (COMING_SOON) never navigates anywhere — '
      'its "Coming Soon" text has no InkWell at all',
      (tester) async {
        final observer = _RecordingNavigatorObserver();
        final provider = FirebaseKundaliProvider()..kundaliData = fixtureData();
        await pump(tester, provider, navigatorObservers: [observer]);
        final baseline = observer.pushed.length;

        final dashaCard = find.ancestor(
          of: find.text('Current Dasha'),
          matching: find.byType(IdentityCard),
        );
        expect(
          find.descendant(of: dashaCard, matching: find.byType(InkWell)),
          findsNothing,
        );
        expect(observer.pushed.length, baseline);
      },
    );
  });
}
