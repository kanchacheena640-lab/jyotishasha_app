import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/widgets/create_another_kundali_banner.dart';
import 'package:jyotishasha_app/core/widgets/share_strip_widget.dart';
import 'package:jyotishasha_app/features/manual_kundali/manual_kundali_form_page.dart';

import '../../helpers/test_harness.dart';

/// `ProfileProvider`'s real constructor eagerly builds `ProfileService`,
/// which touches `FirebaseAuth.instance` — unavailable in this widget-test
/// environment. Same fake used by `greeting_header_widget_test.dart`:
/// `Mock`'s `implements` never calls the real constructor.
class _FakeProfileProvider extends Mock
    with ChangeNotifier
    implements ProfileProvider {}

void main() {
  Future<void> pump(WidgetTester tester, {Locale? locale}) async {
    final profileProvider = _FakeProfileProvider();
    when(() => profileProvider.activeProfile).thenReturn(null);

    await tester.pumpTestHarness(
      const Scaffold(body: CreateAnotherKundaliBanner()),
      locale: locale,
      // The navigation target, ManualKundaliFormPage, reads
      // ProfileProvider in its own build() (for the active profile's
      // language) — must be present above MaterialApp, same as
      // production's main.dart, for the pushed route to resolve it.
      providers: [
        ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
      ],
    );
  }

  testWidgets(
    'shows the Title, Subtitle, and "Create Another Kundali" primary '
    'button in English',
    (tester) async {
      await pump(tester);

      expect(find.text('Need Another Kundali?'), findsOneWidget);
      expect(
        find.text(
          'Generate a detailed birth chart for your family, friends or '
          'anyone else in just a few simple steps.',
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ElevatedButton, 'Create Another Kundali'),
        findsOneWidget,
      );
    },
  );

  testWidgets('renders Hindi copy', (tester) async {
    await pump(tester, locale: const Locale('hi'));

    expect(find.text('एक और कुंडली चाहिए?'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'एक और कुंडली बनाएं'),
      findsOneWidget,
    );
  });

  testWidgets(
    'reuses the existing premium-banner design system — same corner '
    'radius (22) and gradient as ShareStripWidget/"Ask Now", not a new '
    'one-off design',
    (tester) async {
      await pump(tester);

      final bannerContainer = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(CreateAnotherKundaliBanner),
              matching: find.byType(Container),
            ),
          )
          .firstWhere((c) => c.decoration is BoxDecoration);
      final bannerDecoration = bannerContainer.decoration as BoxDecoration;
      expect((bannerDecoration.borderRadius as BorderRadius).topLeft.x, 22);

      await tester.pumpTestHarness(
        const Scaffold(body: ShareStripWidget()),
        providers: [
          ChangeNotifierProvider<LanguageProvider>(
            create: (_) => LanguageProvider(),
          ),
        ],
      );
      final shareContainer = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(ShareStripWidget),
              matching: find.byType(Container),
            ),
          )
          .firstWhere((c) => c.decoration is BoxDecoration);
      final shareDecoration = shareContainer.decoration as BoxDecoration;

      expect(bannerDecoration.gradient, shareDecoration.gradient);
    },
  );

  testWidgets(
    'tapping the primary button opens the existing, unmodified '
    'ManualKundaliFormPage — no new form, no new route',
    (tester) async {
      await pump(tester);

      await tester.tap(find.text('Create Another Kundali'));
      await tester.pumpAndSettle();

      expect(find.byType(ManualKundaliFormPage), findsOneWidget);
    },
  );

  testWidgets(
    'tapping anywhere on the banner (not just the button) also opens '
    'ManualKundaliFormPage',
    (tester) async {
      await pump(tester);

      await tester.tap(find.text('Need Another Kundali?'));
      await tester.pumpAndSettle();

      expect(find.byType(ManualKundaliFormPage), findsOneWidget);
    },
  );
}
