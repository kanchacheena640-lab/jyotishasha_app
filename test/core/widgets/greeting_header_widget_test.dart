import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/notification_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/widgets/greeting_header_widget.dart';
import 'package:jyotishasha_app/features/dashboard/dashboard_tab_switcher.dart';

import '../../helpers/test_harness.dart';

/// `ProfileProvider`'s real constructor eagerly builds `ProfileService`,
/// which touches `FirebaseAuth.instance` — unavailable in this widget-test
/// environment. `Mock`'s `implements` never calls the real constructor, so
/// this sidesteps that entirely; `with ChangeNotifier` gives real
/// addListener/notifyListeners behavior so `context.watch` works normally.
class _FakeProfileProvider extends Mock
    with ChangeNotifier
    implements ProfileProvider {}

void main() {
  Future<void> pumpHeader(
    WidgetTester tester, {
    required String lang,
    required Map<String, dynamic>? profile,
    void Function(int index)? onSwitchTab,
  }) async {
    final profileProvider = _FakeProfileProvider();
    when(() => profileProvider.activeProfile).thenReturn(profile);

    final dailyProvider = DailyProvider()
      ..intro = 'Sample horoscope preview text for today.'
      ..isLoading = false;

    final languageProvider = LanguageProvider();
    languageProvider.currentLang = lang;

    await tester.pumpTestHarness(
      const Scaffold(body: GreetingHeaderWidget()),
      providers: [
        ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
        ChangeNotifierProvider<DailyProvider>.value(value: dailyProvider),
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
        // The Astrology Profile CTA's onTap reads DashboardTabSwitcher —
        // present app-wide in production (registered once in
        // dashboard_page.dart); every test needs it in the tree even if
        // it never taps the CTA, since Provider.of/context.read requires
        // an ancestor to exist regardless of whether it is ever invoked.
        Provider<DashboardTabSwitcher>.value(
          value: DashboardTabSwitcher(onSwitchTab ?? (_) {}),
        ),
      ],
    );
    // The widget's initState schedules a 2s-delayed unread-count fetch;
    // advance past it so no timer is left pending at test teardown.
    await tester.pump(const Duration(seconds: 3));
  }

  testWidgets(
    'shows "Hi {Name}", "♋ {Zodiac}" and the Astrology Profile CTA in '
    'English, derived from the active profile, with no gift-related UI',
    (tester) async {
      await pumpHeader(
        tester,
        lang: 'en',
        profile: const {'name': 'Ravi', 'moon_sign': 'cancer'},
      );

      expect(find.text('Hi Ravi'), findsOneWidget);
      expect(find.text('♋ Cancer'), findsOneWidget);

      // Finalized "Your Astrology Profile   View →" CTA row.
      expect(find.text('Your Astrology Profile'), findsOneWidget);
      expect(find.text('View →'), findsOneWidget);

      // The Greeting Header contains no gift-related UI of any kind —
      // neither the old large Welcome Gift card nor the small Gift badge
      // that temporarily replaced it.
      expect(find.textContaining('Gift'), findsNothing);
      expect(find.textContaining('गिफ्ट'), findsNothing);
      expect(
        find.text('Unlock 5 Personalized Premium Reports\n(Birth Chart Based)'),
        findsNothing,
      );
      expect(find.text('+ 15 Days Premium Membership'), findsNothing);
      expect(find.text('Claim Free Access →'), findsNothing);
    },
  );

  testWidgets(
    'only shows the first name, even when the profile has a full multi-part name',
    (tester) async {
      await pumpHeader(
        tester,
        lang: 'en',
        profile: const {
          'name': 'Ravi Kumar Sharma',
          'moon_sign': 'cancer',
        },
      );

      expect(find.text('Hi Ravi'), findsOneWidget);
      expect(find.textContaining('Kumar'), findsNothing);
      expect(find.textContaining('Sharma'), findsNothing);
    },
  );

  testWidgets(
    'shows the Hindi greeting with the Hindi zodiac name',
    (tester) async {
      await pumpHeader(
        tester,
        lang: 'hi',
        profile: const {'name': 'Ravi', 'moon_sign': 'cancer'},
      );

      // The person's name is never transliterated — only the surrounding
      // greeting/zodiac text is localized, matching the app's existing
      // convention (e.g. the previous "नमस्कार Ravi" behavior).
      expect(find.text('नमस्ते, Ravi'), findsOneWidget);
      expect(find.text('♋ कर्क'), findsOneWidget);
      expect(find.text('आपकी ज्योतिष प्रोफाइल'), findsOneWidget);
      expect(find.text('देखें →'), findsOneWidget);
    },
  );

  testWidgets(
    'still renders a sensible greeting when there is no active profile yet '
    '— and (Task 3) never invents a Leo fallback for the missing sign',
    (tester) async {
      await pumpHeader(tester, lang: 'en', profile: null);

      expect(find.text('Hi Guest'), findsOneWidget);
      expect(find.text('✨ Moon sign not available yet'), findsOneWidget);
      expect(find.text('♌ Leo'), findsNothing);
      expect(find.textContaining('Leo'), findsNothing);
    },
  );

  group('Astrology fields (Task 3 — Lagna/Nakshatra + Leo-fallback fix)', () {
    testWidgets(
      'a valid Moon Sign still renders exactly as before',
      (tester) async {
        await pumpHeader(
          tester,
          lang: 'en',
          profile: const {'name': 'Ravi', 'moon_sign': 'cancer'},
        );

        expect(find.text('♋ Cancer'), findsOneWidget);
      },
    );

    testWidgets(
      'a missing moon_sign (profile present, field absent) shows the '
      'neutral state, never a fabricated Leo',
      (tester) async {
        await pumpHeader(
          tester,
          lang: 'en',
          profile: const {'name': 'Ravi'},
        );

        expect(find.text('✨ Moon sign not available yet'), findsOneWidget);
        expect(find.textContaining('Leo'), findsNothing);
      },
    );

    testWidgets(
      'an empty-string moon_sign is treated the same as missing — no '
      'fabricated Leo',
      (tester) async {
        await pumpHeader(
          tester,
          lang: 'en',
          profile: const {'name': 'Ravi', 'moon_sign': ''},
        );

        expect(find.text('✨ Moon sign not available yet'), findsOneWidget);
        expect(find.textContaining('Leo'), findsNothing);
      },
    );

    testWidgets(
      'shows Lagna and Nakshatra badges (from ProfileProvider.'
      'activeProfile, no new fetch) when both are available',
      (tester) async {
        await pumpHeader(
          tester,
          lang: 'en',
          profile: const {
            'name': 'Ravi',
            'moon_sign': 'cancer',
            'lagna': 'Aries',
            'nakshatra': 'Rohini',
          },
        );

        expect(find.text('Lagna: Aries'), findsOneWidget);
        expect(find.text('Nakshatra: Rohini'), findsOneWidget);
      },
    );

    testWidgets(
      'a missing Lagna shows "-" (never fabricated) while Nakshatra still '
      'renders correctly',
      (tester) async {
        await pumpHeader(
          tester,
          lang: 'en',
          profile: const {
            'name': 'Ravi',
            'moon_sign': 'cancer',
            'nakshatra': 'Rohini',
          },
        );

        expect(find.text('Lagna: -'), findsOneWidget);
        expect(find.text('Nakshatra: Rohini'), findsOneWidget);
      },
    );

    testWidgets(
      'a missing Nakshatra shows "-" (never fabricated) while Lagna still '
      'renders correctly',
      (tester) async {
        await pumpHeader(
          tester,
          lang: 'en',
          profile: const {
            'name': 'Ravi',
            'moon_sign': 'cancer',
            'lagna': 'Aries',
          },
        );

        expect(find.text('Lagna: Aries'), findsOneWidget);
        expect(find.text('Nakshatra: -'), findsOneWidget);
      },
    );

    testWidgets(
      'omits the badge row entirely when neither Lagna nor Nakshatra is '
      'available, rather than showing two empty "-" chips',
      (tester) async {
        await pumpHeader(
          tester,
          lang: 'en',
          profile: const {'name': 'Ravi', 'moon_sign': 'cancer'},
        );

        expect(find.textContaining('Lagna'), findsNothing);
        expect(find.textContaining('Nakshatra'), findsNothing);
      },
    );

    testWidgets(
      'Lagna/Nakshatra badges render with Hindi labels',
      (tester) async {
        await pumpHeader(
          tester,
          lang: 'hi',
          profile: const {
            'name': 'Ravi',
            'moon_sign': 'cancer',
            'lagna': 'Aries',
            'nakshatra': 'Rohini',
          },
        );

        expect(find.text('लग्न: Aries'), findsOneWidget);
        expect(find.text('नक्षत्र: Rohini'), findsOneWidget);
      },
    );

    testWidgets(
      'a null activeProfile also shows the neutral state, never a '
      'fabricated Leo, and no badges',
      (tester) async {
        await pumpHeader(tester, lang: 'en', profile: null);

        expect(find.text('✨ Moon sign not available yet'), findsOneWidget);
        expect(find.textContaining('Lagna'), findsNothing);
        expect(find.textContaining('Nakshatra'), findsNothing);
      },
    );
  });

  group('Astrology Profile CTA navigation (Task 3 — unchanged onTap)', () {
    testWidgets(
      'tapping the CTA calls DashboardTabSwitcher.switchTo('
      'astrologyTabIndex) — the exact same call the redesign must not '
      'change',
      (tester) async {
        final calls = <int>[];

        await pumpHeader(
          tester,
          lang: 'en',
          profile: const {'name': 'Ravi', 'moon_sign': 'cancer'},
          onSwitchTab: calls.add,
        );

        await tester.tap(find.text('Your Astrology Profile'));
        await tester.pump();

        expect(calls, [DashboardTabSwitcher.astrologyTabIndex]);
      },
    );
  });

  testWidgets(
    'shows a single active-language chip (not a segmented EN/HI toggle), and '
    'renders nothing below the greeting block — GreetingHeaderWidget is now '
    'a pure header (F4.1.3)',
    (tester) async {
      await pumpHeader(
        tester,
        lang: 'en',
        profile: const {'name': 'Ravi', 'moon_sign': 'cancer'},
      );

      // Single chip shows only the active language.
      expect(find.text('EN'), findsOneWidget);
      expect(find.text('HI'), findsNothing);

      // No secondary content: Quick Actions (Mantra & Darshan) was removed
      // entirely, and the Horoscope card is unreferenced (kept intact for
      // reuse elsewhere, but not rendered here).
      expect(find.text('Mantra & Darshan'), findsNothing);
      expect(find.text("TODAY'S HOROSCOPE"), findsNothing);
      expect(
        find.text('Sample horoscope preview text for today.'),
        findsNothing,
      );
      expect(find.text('Read More →'), findsNothing);

      expect(find.text('Panchang'), findsNothing);
      expect(find.text('Divine Wishes'), findsNothing);

      // No zodiac icon/badge at all (F4.1.6 "Minimal Premium Header").
      expect(find.byType(Image), findsNothing);
    },
  );

  testWidgets(
    'the language chip and notification bell share the same visual height '
    '(F4.1.7)',
    (tester) async {
      await pumpHeader(
        tester,
        lang: 'en',
        profile: const {'name': 'Ravi', 'moon_sign': 'cancer'},
      );

      final chipHeight = tester
          .getSize(
            find
                .ancestor(
                  of: find.text('EN'),
                  matching: find.byType(Container),
                )
                .first,
          )
          .height;
      final bellHeight = tester
          .getSize(
            find
                .ancestor(
                  of: find.byIcon(Icons.notifications_none_rounded),
                  matching: find.byType(Container),
                )
                .first,
          )
          .height;

      expect(chipHeight, bellHeight);
    },
  );

  testWidgets(
    'tapping the single language chip switches to the other language '
    'via the existing localization mechanism',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      final languageProvider = LanguageProvider();
      languageProvider.currentLang = 'en';

      final profileProvider = _FakeProfileProvider();
      when(() => profileProvider.activeProfile).thenReturn(const {
        'name': 'Ravi',
        'moon_sign': 'cancer',
      });

      final dailyProvider = DailyProvider()
        ..intro = 'Sample horoscope preview text for today.'
        ..isLoading = false;

      await tester.pumpTestHarness(
        const Scaffold(body: GreetingHeaderWidget()),
        providers: [
          ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
          ChangeNotifierProvider<DailyProvider>.value(value: dailyProvider),
          ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
          ChangeNotifierProvider<NotificationProvider>(
            create: (_) => NotificationProvider(),
          ),
        ],
      );
      // Advance past the 2s-delayed unread-count fetch scheduled in
      // initState, so no timer is left pending at test teardown.
      await tester.pump(const Duration(seconds: 3));

      // Chip currently shows "EN" (the active language); tapping it should
      // switch to Hindi.
      await tester.tap(find.text('EN'));
      await tester.pump();

      expect(languageProvider.currentLang, 'hi');
    },
  );
}
