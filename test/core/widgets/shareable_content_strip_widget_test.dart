import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/panchang_provider.dart';
import 'package:jyotishasha_app/core/widgets/shareable_content_strip_widget.dart';
import 'package:jyotishasha_app/features/cards/presentation/cards_page.dart';
import 'package:jyotishasha_app/features/cards/provider/cards_provider.dart';

import '../../helpers/test_harness.dart';

void main() {
  Future<void> pump(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpTestHarness(
      const Scaffold(
        body: SingleChildScrollView(child: ShareableContentStripWidget()),
      ),
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
    'shows the title, subtitle, all four categories, and a View All → card in English',
    (tester) async {
      await pump(tester);

      expect(find.text('Useful Shareable Content'), findsOneWidget);
      expect(
        find.text(
          'Share beautiful astrology content with your family and friends.',
        ),
        findsOneWidget,
      );

      for (final title in [
        'Festival Cards',
        'Daily Panchang',
        'Planetary Updates',
        'Motivational Quotes',
      ]) {
        expect(find.text(title), findsOneWidget);
      }

      expect(find.text('View All →'), findsOneWidget);
    },
  );

  testWidgets('renders Hindi title/subtitle/category text', (tester) async {
    await pump(tester, locale: const Locale('hi'));

    expect(find.text('शेयर करने योग्य उपयोगी सामग्री'), findsOneWidget);
    expect(find.text('त्योहार कार्ड्स'), findsOneWidget);
    expect(find.text('सभी देखें →'), findsOneWidget);
  });

  testWidgets(
    'tapping a category card navigates to the existing, unfiltered CardsPage',
    (tester) async {
      await pump(tester);

      await tester.tap(find.text('Festival Cards'));
      // Not pumpAndSettle: CardsPage has its own ongoing animation/async
      // work unrelated to this widget, which never lets pumpAndSettle
      // finish.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final page = tester.widget<CardsPage>(find.byType(CardsPage));
      expect(page.initialType, isNull); // no filtering yet
    },
  );

  testWidgets(
    'tapping "View All →" also navigates to the existing CardsPage',
    (tester) async {
      await pump(tester);

      await tester.tap(find.text('View All →'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CardsPage), findsOneWidget);
    },
  );
}
