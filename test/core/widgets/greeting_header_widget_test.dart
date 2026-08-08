import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/notification_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/state/welcome_gift_provider.dart';
import 'package:jyotishasha_app/core/widgets/greeting_header_widget.dart';

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
    bool welcomeGiftClaimed = false,
  }) async {
    // GreetingHeaderWidget's initState calls WelcomeGiftProvider.loadStatus,
    // which reads the real (SharedPreferences-backed)
    // LocalWelcomeGiftRepository — mock the plugin channel so that
    // resolves deterministically instead of throwing in this headless
    // environment.
    SharedPreferences.setMockInitialValues(
      welcomeGiftClaimed ? {'welcome_gift_claimed': true} : {},
    );

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
        ChangeNotifierProvider<WelcomeGiftProvider>(
          create: (_) => WelcomeGiftProvider(),
        ),
      ],
    );
    // The widget's initState schedules a 2s-delayed unread-count fetch;
    // advance past it so no timer is left pending at test teardown. This
    // also flushes WelcomeGiftProvider.loadStatus's async SharedPreferences
    // read, scheduled in the same initState.
    await tester.pump(const Duration(seconds: 3));
  }

  testWidgets(
    'shows "Hi {Name}", "♋ {Zodiac}" and the Welcome Gift card in English, '
    'derived from the active profile',
    (tester) async {
      await pumpHeader(
        tester,
        lang: 'en',
        profile: const {'name': 'Ravi', 'moon_sign': 'cancer'},
      );

      expect(find.text('Hi Ravi'), findsOneWidget);
      expect(find.text('♋ Cancer'), findsOneWidget);
      expect(find.text('🎁 Welcome Gift'), findsOneWidget);
      expect(
        find.text('Unlock 5 Personalized Premium Reports\n(Birth Chart Based)'),
        findsOneWidget,
      );
      expect(find.text('+ 15 Days Premium Membership'), findsOneWidget);
      expect(find.text('Claim Free Access →'), findsOneWidget);

      // The old "Your Astrology Profile" CTA this card replaced is gone.
      expect(find.text('Your Astrology Profile'), findsNothing);
      expect(find.text('View →'), findsNothing);

      // No card: subtitle removed, and the row has no
      // border/background/shadow container (F4.1.9).
      expect(find.text('Know yourself better'), findsNothing);
    },
  );

  testWidgets(
    'never shows the Welcome Gift card once it has already been claimed',
    (tester) async {
      await pumpHeader(
        tester,
        lang: 'en',
        profile: const {'name': 'Ravi', 'moon_sign': 'cancer'},
        welcomeGiftClaimed: true,
      );

      expect(find.text('🎁 Welcome Gift'), findsNothing);
      expect(find.textContaining('Claim Free Access'), findsNothing);
    },
  );

  testWidgets(
    'tapping the Welcome Gift card opens the new, standalone WelcomeGiftPage',
    (tester) async {
      await pumpHeader(
        tester,
        lang: 'en',
        profile: const {'name': 'Ravi', 'moon_sign': 'cancer'},
      );

      await tester.tap(find.text('🎁 Welcome Gift'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Love Report'), findsOneWidget);
      expect(
        find.text('Unlock your personalized astrology experience.'),
        findsOneWidget,
      );
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
      expect(find.text('🎁 वेलकम गिफ्ट'), findsOneWidget);
      expect(find.text('फ्री एक्सेस पाएं →'), findsOneWidget);
    },
  );

  testWidgets(
    'still renders a sensible greeting when there is no active profile yet',
    (tester) async {
      await pumpHeader(tester, lang: 'en', profile: null);

      expect(find.text('Hi Guest'), findsOneWidget);
      expect(find.text('♌ Leo'), findsOneWidget);
    },
  );

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
          ChangeNotifierProvider<WelcomeGiftProvider>(
            create: (_) => WelcomeGiftProvider(),
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
