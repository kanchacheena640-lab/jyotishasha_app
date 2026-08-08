import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/core/widgets/shubh_muhurth_preview_widget.dart';

import '../../helpers/test_harness.dart';

void main() {
  final categories = [
    {'event': 'Naamkaran'},
    {'event': 'Marriage'},
    {'event': 'Griha Pravesh'},
    {'event': 'Vehicle'},
    {'event': 'Property'},
    {'event': 'Gold'},
    {'event': 'Travel'},
    {'event': 'Childbirth'},
  ];

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    required void Function(String) onTapType,
    required VoidCallback onSeeMore,
  }) async {
    // Constrained to a realistic phone width (matching the 16dp-padded
    // SliverPadding this widget always sits inside on Home) — the grid's
    // 1:1 aspect-ratio cells would otherwise size themselves against the
    // test viewport's full desktop-like default width and overflow.
    await tester.pumpTestHarness(
      Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 360,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ShubhMuhurthPreviewWidget(
                muhurthList: categories,
                onTapType: onTapType,
                onSeeMore: onSeeMore,
              ),
            ),
          ),
        ),
      ),
      locale: locale,
    );
  }

  testWidgets(
    'shows the centered "Shubh Muhurta" heading and every category label, '
    'in the given order (F6.7 — same data, new presentation)',
    (tester) async {
      await pump(tester, onTapType: (_) {}, onSeeMore: () {});

      expect(find.text('Shubh Muhurta'), findsOneWidget);
      for (final c in categories) {
        expect(find.text(c['event']!), findsOneWidget);
      }
    },
  );

  testWidgets(
    'the old gradient heading, gradient "See More" pill button, and large '
    'icons are gone',
    (tester) async {
      await pump(tester, onTapType: (_) {}, onSeeMore: () {});

      expect(find.byType(ShaderMask), findsNothing);
      expect(find.text('View Full Muhurth Calendar →'), findsNothing);
      expect(find.byIcon(Icons.calendar_month_rounded), findsNothing);

      // New, simple text-link CTA instead.
      expect(find.text('View All Upcoming Muhurth →'), findsOneWidget);
    },
  );

  testWidgets(
    'category cards use the compact white/soft-lavender-border/18dp-radius '
    'style shared with the rest of Home',
    (tester) async {
      await pump(tester, onTapType: (_) {}, onSeeMore: () {});

      final container = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere((c) => c.decoration is BoxDecoration);
      final decoration = container.decoration as BoxDecoration;

      expect((decoration.borderRadius as BorderRadius).topLeft.x, 18);
      expect(decoration.color, Colors.white);
      expect(decoration.border, isNotNull);

      final icon = tester.widget<Icon>(find.byIcon(Icons.favorite_rounded));
      expect(icon.size, 20);
    },
  );

  testWidgets('the grid shows a maximum of 3 cards per row', (tester) async {
    await pump(tester, onTapType: (_) {}, onSeeMore: () {});

    final gridView = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);
  });

  testWidgets(
    'tapping a category card calls onTapType with the matching type slug',
    (tester) async {
      String? tapped;
      await pump(
        tester,
        onTapType: (type) => tapped = type,
        onSeeMore: () {},
      );

      await tester.tap(find.text('Marriage'));
      expect(tapped, 'marriage');

      await tester.tap(find.text('Vehicle'));
      expect(tapped, 'vehicle');
    },
  );

  testWidgets(
    'tapping "View All Upcoming Muhurth →" calls onSeeMore',
    (tester) async {
      var seeMoreCalled = false;
      await pump(
        tester,
        onTapType: (_) {},
        onSeeMore: () => seeMoreCalled = true,
      );

      await tester.tap(find.text('View All Upcoming Muhurth →'));
      expect(seeMoreCalled, isTrue);
    },
  );

  testWidgets('renders Hindi heading and CTA', (tester) async {
    await pump(
      tester,
      locale: const Locale('hi'),
      onTapType: (_) {},
      onSeeMore: () {},
    );

    expect(find.text('शुभ मुहूर्त'), findsOneWidget);
    expect(find.text('सभी आगामी मुहूर्त देखें →'), findsOneWidget);
  });
}
