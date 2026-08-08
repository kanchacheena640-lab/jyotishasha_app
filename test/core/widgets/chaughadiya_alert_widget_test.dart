import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/panchang_provider.dart';
import 'package:jyotishasha_app/core/widgets/chaughadiya_alert_widget.dart';
import 'package:jyotishasha_app/features/panchang/panchang_page.dart';

import '../../helpers/test_harness.dart';

void main() {
  // A single chaughadiya slot with identical start/end ("00:00"-"00:00")
  // always matches `PanchangProvider.getCurrentChaughadiya()`'s "wraps
  // around midnight" branch (`currentMinutes >= start || currentMinutes <
  // end`, true for any `currentMinutes >= 0`), regardless of the real
  // clock time the test happens to run at. Present in both day and night
  // lists so the test doesn't also need to control sunrise/sunset timing.
  Map<String, dynamic> buildFullPanchang() {
    const slot = {
      "start": "00:00",
      "end": "00:00",
      "name": "अमृत",
      "name_en": "Amrit",
      "nature": "shubh",
    };
    return {
      "sunrise": "06:00",
      "sunset": "18:00",
      "tithi": {"name": "Panchami"},
      "chaughadiya": {
        "day": [slot],
        "night": [slot],
      },
    };
  }

  Future<PanchangProvider> pumpWidget(
    WidgetTester tester, {
    String lang = 'en',
    bool loading = false,
  }) async {
    // Real constructor starts a 1-minute clock Timer.periodic; each test
    // explicitly disposes this provider before finishing (`.value`
    // providers don't own/dispose the object they're given, and a
    // pending timer fails the test at teardown otherwise).
    final panchangProvider = PanchangProvider();

    panchangProvider.isLoading = loading;
    if (!loading) {
      panchangProvider.fullPanchang = buildFullPanchang();
    }

    final languageProvider = LanguageProvider();
    languageProvider.currentLang = lang;

    await tester.pumpTestHarness(
      const Scaffold(body: ChaughadiyaAlertWidget()),
      providers: [
        ChangeNotifierProvider<PanchangProvider>.value(value: panchangProvider),
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
      ],
    );
    await tester.pump();
    return panchangProvider;
  }

  testWidgets(
    'shows the "Current Timing" heading, the ticker content, and the '
    'footer link in English — no inline "ALERT" badge',
    (tester) async {
      final provider = await pumpWidget(tester);

      expect(find.text('Current Timing'), findsOneWidget);
      expect(find.textContaining('AMRIT'), findsWidgets);
      expect(find.textContaining('Panchami'), findsWidgets);
      expect(
        find.text('View Full Panchang & Chaughadiya →'),
        findsOneWidget,
      );

      // The old inline "ALERT" badge is gone, replaced by the heading.
      expect(find.text('ALERT'), findsNothing);

      provider.dispose();
    },
  );

  testWidgets('renders Hindi heading and footer link when the locale is Hindi', (
    tester,
  ) async {
    final provider = await pumpWidget(tester, lang: 'hi');

    expect(find.text('अभी का समय'), findsOneWidget);
    expect(find.text('पूरा पंचांग व चौघड़िया देखें →'), findsOneWidget);

    provider.dispose();
  });

  testWidgets(
    'shows a compact loading placeholder while Panchang is still loading',
    (tester) async {
      final provider = await pumpWidget(tester, loading: true);

      expect(find.text('Current Timing'), findsOneWidget);
      expect(find.text('Calculating Panchang...'), findsOneWidget);
      // Footer link still present even while the ticker itself is loading.
      expect(
        find.text('View Full Panchang & Chaughadiya →'),
        findsOneWidget,
      );

      provider.dispose();
    },
  );

  testWidgets(
    'tapping the footer link navigates to the existing PanchangPage',
    (tester) async {
      final provider = await pumpWidget(tester);

      await tester.tap(find.text('View Full Panchang & Chaughadiya →'));
      // Not pumpAndSettle: PanchangPage has its own ongoing async/location
      // work unrelated to this widget, which would hang pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PanchangPage), findsOneWidget);

      provider.dispose();
    },
  );
}
