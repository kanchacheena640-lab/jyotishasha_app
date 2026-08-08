import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/features/kundali/data/identity_report_availability.dart';
import 'package:jyotishasha_app/features/kundali/widgets/identity_card.dart';

import '../../../helpers/test_harness.dart';

void main() {
  testWidgets(
    'renders Title → Value → Summary → tappable "View Full Free Report →" '
    'when AVAILABLE, and calls onViewReport when tapped',
    (tester) async {
      var tapped = false;
      await tester.pumpTestHarness(
        Scaffold(
          body: IdentityCard(
            title: 'Your Ascendant',
            value: 'Cancer',
            summary: 'You are intuitive and nurturing.',
            status: ReportAvailabilityStatus.available,
            isHindi: false,
            onViewReport: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Your Ascendant'), findsOneWidget);
      expect(find.text('Cancer'), findsOneWidget);
      expect(find.text('You are intuitive and nurturing.'), findsOneWidget);
      expect(find.text('View Full Free Report →'), findsOneWidget);
      expect(find.text('Coming Soon'), findsNothing);

      final ctaStyle = tester
          .widget<Text>(find.text('View Full Free Report →'))
          .style;
      expect(ctaStyle?.color, AppColors.primary);

      await tester.tap(find.text('View Full Free Report →'));
      expect(tapped, isTrue);
    },
  );

  testWidgets(
    'renders a grey, non-interactive "Coming Soon" when COMING_SOON — no '
    'InkWell/GestureDetector wraps it',
    (tester) async {
      await tester.pumpTestHarness(
        const Scaffold(
          body: IdentityCard(
            title: 'Your Mahadasha',
            value: 'Saturn',
            summary: 'A period of discipline and steady growth.',
            status: ReportAvailabilityStatus.comingSoon,
            isHindi: false,
          ),
        ),
      );

      expect(find.text('Coming Soon'), findsOneWidget);
      expect(find.text('View Full Free Report →'), findsNothing);
      expect(find.byType(InkWell), findsNothing);

      final style = tester.widget<Text>(find.text('Coming Soon')).style;
      expect(style?.color, const Color(0xFF9CA3AF));
    },
  );

  testWidgets('uses the premium card shell — white, 18dp radius, soft '
      'lavender border, subtle shadow', (tester) async {
    await tester.pumpTestHarness(
      const Scaffold(
        body: IdentityCard(
          title: 'Your Nakshatra',
          value: 'Rohini',
          summary: 'Reveals deeper patterns in your personality.',
          status: ReportAvailabilityStatus.available,
          isHindi: false,
        ),
      ),
    );

    final container = tester
        .widgetList<Container>(find.byType(Container))
        .firstWhere((c) => c.decoration is BoxDecoration);
    final decoration = container.decoration as BoxDecoration;

    expect(decoration.color, Colors.white);
    expect((decoration.borderRadius as BorderRadius).topLeft.x, 18);
    expect(decoration.border, isNotNull);
  });

  testWidgets('renders Hindi copy for both statuses', (tester) async {
    await tester.pumpTestHarness(
      const Scaffold(
        body: Column(
          children: [
            IdentityCard(
              title: 'आपकी राशि',
              value: 'सिंह',
              summary: 'आप गर्मजोशी से भरे हैं।',
              status: ReportAvailabilityStatus.available,
              isHindi: true,
            ),
            IdentityCard(
              title: 'आपकी अंतर्दशा',
              value: 'बुध',
              summary: 'यह एक स्थिर विकास की अवधि है।',
              status: ReportAvailabilityStatus.comingSoon,
              isHindi: true,
            ),
          ],
        ),
      ),
    );

    expect(find.text('पूरी मुफ़्त रिपोर्ट देखें →'), findsOneWidget);
    expect(find.text('जल्द आ रहा है'), findsOneWidget);
  });
}
