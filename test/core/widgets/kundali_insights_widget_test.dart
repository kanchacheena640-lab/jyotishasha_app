import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/core/widgets/kundali_insights_widget.dart';

import '../../helpers/test_harness.dart';

void main() {
  testWidgets(
    'shows the title, subtitle, and all six card titles in English',
    (tester) async {
      await tester.pumpTestHarness(
        // Matches production: this widget lives inside a CustomScrollView
        // on the real Home screen, so it never has to fit an unscrollable
        // fixed-height viewport on its own.
        const Scaffold(
          body: SingleChildScrollView(child: KundaliInsightsWidget()),
        ),
      );

      expect(find.text('From Your Kundali'), findsOneWidget);
      expect(
        find.text(
          'Discover what your birth chart says about the important areas of your life.',
        ),
        findsOneWidget,
      );

      for (final title in [
        'Raj Yoga',
        'Dosha',
        'Strengths',
        'Weaknesses',
        'Career',
        'Marriage',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
    },
  );

  testWidgets('renders a 2-column, 3-row grid of exactly six cards', (
    tester,
  ) async {
    await tester.pumpTestHarness(
      const Scaffold(
        body: SingleChildScrollView(child: KundaliInsightsWidget()),
      ),
    );

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

    expect(delegate.crossAxisCount, 2);
    expect(find.byType(InkWell), findsNWidgets(6));
  });

  testWidgets(
    'renders Hindi titles/subtitle when the locale is Hindi',
    (tester) async {
      await tester.pumpTestHarness(
        // Matches production: this widget lives inside a CustomScrollView
        // on the real Home screen, so it never has to fit an unscrollable
        // fixed-height viewport on its own.
        const Scaffold(
          body: SingleChildScrollView(child: KundaliInsightsWidget()),
        ),
        locale: const Locale('hi'),
      );

      expect(find.text('आपकी कुंडली से'), findsOneWidget);
      expect(find.text('राज योग'), findsOneWidget);
      expect(find.text('विवाह'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping a card shows a "Coming Soon" message and does not navigate',
    (tester) async {
      await tester.pumpTestHarness(
        // Matches production: this widget lives inside a CustomScrollView
        // on the real Home screen, so it never has to fit an unscrollable
        // fixed-height viewport on its own.
        const Scaffold(
          body: SingleChildScrollView(child: KundaliInsightsWidget()),
        ),
      );

      // First-row card, guaranteed visible without scrolling.
      await tester.tap(find.text('Raj Yoga'));
      await tester.pump();

      expect(find.text('Coming Soon'), findsOneWidget);
      // Still on the same screen — no new route was pushed.
      expect(find.byType(KundaliInsightsWidget), findsOneWidget);
    },
  );
}
