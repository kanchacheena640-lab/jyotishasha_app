import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/panchang_provider.dart';
import 'package:jyotishasha_app/core/widgets/share_strip_widget.dart';
import 'package:jyotishasha_app/core/widgets/trending_questions_widget.dart';
import 'package:jyotishasha_app/features/cards/presentation/cards_page.dart';
import 'package:jyotishasha_app/features/cards/provider/cards_provider.dart';

import '../../helpers/test_harness.dart';

void main() {
  Future<void> pump(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpTestHarness(
      const Scaffold(body: ShareStripWidget()),
      locale: locale,
      // CardsPage (the navigation target) reads CardsProvider and
      // PanchangProvider, both provided at the app root in production
      // main.dart.
      providers: [
        ChangeNotifierProvider(create: (_) => CardsProvider()),
        ChangeNotifierProvider(create: (_) => PanchangProvider()),
      ],
    );
  }

  testWidgets(
    'shows the faded background share icon, the single dominant text line, '
    '"Share Now →" CTA, and icon-only platform row in English (F5.7)',
    (tester) async {
      await pump(tester);

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(
        find.text('Someone find this helpful.'),
        findsOneWidget,
      );
      expect(find.text('Share Now →'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
      expect(find.byIcon(Icons.facebook), findsOneWidget);

      // No text labels next to the platform icons, and old copy from
      // earlier iterations is gone.
      expect(find.text('WhatsApp'), findsNothing);
      expect(find.text('Instagram'), findsNothing);
      expect(find.text('Facebook'), findsNothing);
      expect(find.text('Share astrology updates'), findsNothing);
      expect(find.text("Share today's guidance"), findsNothing);
      expect(find.text('Someone you love may need it today.'), findsNothing);
      expect(find.text('View →'), findsNothing);
    },
  );

  testWidgets('renders Hindi copy', (tester) async {
    await pump(tester, locale: const Locale('hi'));

    expect(
      find.text('किसी के लिए यह मददगार है।'),
      findsOneWidget,
    );
    expect(find.text('अभी शेयर करें →'), findsOneWidget);
  });

  testWidgets(
    'the three platform icons are all the same 18dp size (F5.6 — "no icon '
    'should feel larger than another")',
    (tester) async {
      await pump(tester);

      for (final icon in [
        Icons.chat_bubble_rounded,
        Icons.camera_alt_rounded,
        Icons.facebook,
      ]) {
        final widget = tester.widget<Icon>(find.byIcon(icon));
        expect(widget.size, 18);
      }
    },
  );

  testWidgets(
    "the banner is 90dp tall (F5.7.1) and matches Ask Now's corner radius "
    '(22) and gradient (sister components)',
    (tester) async {
      await pump(tester);

      final size = tester.getSize(find.byType(ShareStripWidget));
      expect(size.height, 90);

      final shareContainer = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(ShareStripWidget),
              matching: find.byType(Container),
            ),
          )
          .firstWhere((c) => c.decoration is BoxDecoration);
      final shareDecoration = shareContainer.decoration as BoxDecoration;
      expect((shareDecoration.borderRadius as BorderRadius).topLeft.x, 22);

      // Re-pump the same tester with the Ask Now banner and compare its
      // gradient to the Share banner's captured above — they must be
      // identical.
      await tester.pumpTestHarness(
        const Scaffold(body: TrendingQuestionsWidget()),
        providers: [
          ChangeNotifierProvider<LanguageProvider>(
            create: (_) => LanguageProvider(),
          ),
        ],
      );
      final askNowContainer = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(TrendingQuestionsWidget),
              matching: find.byType(Container),
            ),
          )
          .firstWhere((c) => c.decoration is BoxDecoration);
      final askNowDecoration = askNowContainer.decoration as BoxDecoration;

      expect(shareDecoration.gradient, askNowDecoration.gradient);
    },
  );

  testWidgets(
    'tapping anywhere on the strip navigates to the existing, unfiltered '
    'CardsPage',
    (tester) async {
      await pump(tester);

      await tester.tap(find.text('Share Now →'));
      // Not pumpAndSettle: CardsPage has its own ongoing animation/async
      // work unrelated to this widget, which would hang pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final page = tester.widget<CardsPage>(find.byType(CardsPage));
      expect(page.initialType, isNull);
    },
  );
}
