import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/monthly_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/state/yearly_provider.dart';
import 'package:jyotishasha_app/core/widgets/todays_essentials_widget.dart';
import 'package:jyotishasha_app/features/horoscope/horoscope_page.dart';

import '../../helpers/test_harness.dart';

/// `ProfileProvider`'s real constructor touches `FirebaseAuth.instance`,
/// unavailable in this widget-test environment — and `HoroscopePage` (the
/// horoscope card's navigation destination) reads it on init. `Mock`'s
/// `implements` never calls the real constructor.
class _FakeProfileProvider extends Mock
    with ChangeNotifier
    implements ProfileProvider {}

void main() {
  const deityEnglishNames = [
    'Shiva',
    'Hanuman',
    'Ganesha',
    'Vishnu',
    'Lakshmi',
    'Shani',
    'Surya',
  ];
  const deityHindiNames = [
    'शिव',
    'हनुमान',
    'गणेश',
    'विष्णु',
    'लक्ष्मी',
    'शनि',
    'सूर्य',
  ];

  Future<void> pumpWidget(WidgetTester tester, {String lang = 'en'}) async {
    final languageProvider = LanguageProvider();
    languageProvider.currentLang = lang;

    final profileProvider = _FakeProfileProvider();
    when(() => profileProvider.activeProfile).thenReturn(const {
      'name': 'Ravi',
      'moon_sign': 'cancer',
    });

    await tester.pumpTestHarness(
      // Matches production: this widget lives inside a CustomScrollView on
      // the real Home screen.
      const Scaffold(
        body: SingleChildScrollView(child: TodaysEssentialsWidget()),
      ),
      providers: [
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
        ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
        // HoroscopePage (the horoscope card's navigation destination)
        // reads these too.
        ChangeNotifierProvider<DailyProvider>(create: (_) => DailyProvider()),
        ChangeNotifierProvider<MonthlyProvider>(create: (_) => MonthlyProvider()),
        ChangeNotifierProvider<YearlyProvider>(create: (_) => YearlyProvider()),
      ],
    );
  }

  testWidgets(
    'shows the "Today\'s Essentials" heading, "Today\'s Horoscope" with '
    '"Read Now →", and a dynamic "<Deity> Darshan" title with "Open →" — '
    'strictly icon/title/CTA, no subtitle, no Panchang card (F5.4)',
    (tester) async {
      await pumpWidget(tester);

      expect(find.text("Today's Essentials"), findsOneWidget);
      expect(find.text("Today's Horoscope"), findsOneWidget);
      expect(find.text('Read Now →'), findsOneWidget);
      expect(find.text('Open →'), findsOneWidget);
      expect(find.text('☀'), findsOneWidget);
      expect(find.text('🛕'), findsOneWidget);

      // Exactly one "<Deity> Darshan" title is shown, generated from the
      // existing deity mapping (not hardcoded to a single deity).
      final matches = deityEnglishNames.where(
        (name) => find.text('$name Darshan').evaluate().isNotEmpty,
      );
      expect(matches.length, 1);

      // No Panchang card, no old titles/subtitle/preview copy from
      // earlier iterations.
      expect(find.textContaining('Panchang'), findsNothing);
      expect(find.text('Daily Horoscope'), findsNothing);
      expect(find.text("Today's Darshan"), findsNothing);
      expect(find.textContaining('Darshan:'), findsNothing);
      expect(find.textContaining('Seek the blessings'), findsNothing);
      expect(find.byIcon(Icons.temple_hindu_outlined), findsNothing);
    },
  );

  testWidgets('renders Hindi titles and CTAs', (tester) async {
    await pumpWidget(tester, lang: 'hi');

    expect(find.text('आज की ज़रूरी बातें'), findsOneWidget);
    expect(find.text('आज का राशिफल'), findsOneWidget);
    expect(find.text('अभी पढ़ें →'), findsOneWidget);
    expect(find.text('खोलें →'), findsOneWidget);

    final matches = deityHindiNames.where(
      (name) => find.text('$name दर्शन').evaluate().isNotEmpty,
    );
    expect(matches.length, 1);
  });

  testWidgets(
    'tapping the horoscope card navigates to the existing HoroscopePage',
    (tester) async {
      await pumpWidget(tester);

      await tester.tap(find.text("Today's Horoscope"));
      // Not pumpAndSettle: HoroscopePage has its own ongoing async work
      // unrelated to this widget, which would hang pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HoroscopePage), findsOneWidget);
    },
  );
}
