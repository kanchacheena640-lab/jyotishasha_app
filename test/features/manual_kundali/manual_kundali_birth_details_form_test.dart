import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/manual_kundali_provider.dart';
import 'package:jyotishasha_app/features/manual_kundali/manual_kundali_form_page.dart';

import '../../helpers/test_harness.dart';

/// Covers [ManualKundaliBirthDetailsForm] — the existing Other-person
/// birth-details form, extracted (Task 2) so it can be embedded inside
/// [KundaliOverviewPage] as well as shown standalone. Field-level
/// autocomplete/geocoding (`LocationService`) makes real HTTP calls with
/// no test seam, so these tests exercise everything up to that boundary:
/// rendering, EN/HI copy, and Form-level validation — the same boundary
/// `kundali_overview_page_test.dart` already treats
/// `FirebaseKundaliProvider`/`ManualKundaliProvider` results as
/// pre-fetched fixtures rather than driving a real network call.
void main() {
  Future<void> pump(WidgetTester tester, {bool isHindi = false}) async {
    await tester.pumpTestHarness(
      Scaffold(
        body: SingleChildScrollView(
          child: ManualKundaliBirthDetailsForm(isHindi: isHindi),
        ),
      ),
      providers: [
        ChangeNotifierProvider<ManualKundaliProvider>(
          create: (_) => ManualKundaliProvider(),
        ),
        ChangeNotifierProvider<LanguageProvider>.value(
          value: LanguageProvider()..currentLang = isHindi ? 'hi' : 'en',
        ),
      ],
    );
  }

  testWidgets('renders all four fields and the submit button in English', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Enter Their Birth Details'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Date of Birth (DD-MM-YYYY)'), findsOneWidget);
    expect(find.text('Time of Birth (HH:MM)'), findsOneWidget);
    expect(find.text('Place of Birth'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Generate Kundali'),
      findsOneWidget,
    );
  });

  testWidgets('renders all four fields and the submit button in Hindi', (
    tester,
  ) async {
    await pump(tester, isHindi: true);

    expect(find.text('उनका जन्म विवरण दर्ज करें'), findsOneWidget);
    expect(find.text('पूरा नाम'), findsOneWidget);
    expect(find.text('जन्म तिथि (DD-MM-YYYY)'), findsOneWidget);
    expect(find.text('जन्म समय (HH:MM)'), findsOneWidget);
    expect(find.text('जन्म स्थान'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'कुंडली बनाएं'),
      findsOneWidget,
    );
  });

  testWidgets(
    'tapping Generate Kundali with every field empty shows "Required '
    'field" validation on all four fields, in English',
    (tester) async {
      await pump(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Generate Kundali'));
      await tester.pump();

      expect(find.text('Required field'), findsNWidgets(4));
    },
  );

  testWidgets(
    'tapping the submit button with every field empty shows the Hindi '
    'validation message on all four fields',
    (tester) async {
      await pump(tester, isHindi: true);

      await tester.tap(find.widgetWithText(ElevatedButton, 'कुंडली बनाएं'));
      await tester.pump();

      expect(find.text('आवश्यक फ़ील्ड'), findsNWidgets(4));
    },
  );

  testWidgets(
    'shows the app-language note pointing at Account → Language, not the '
    'old per-profile language footer',
    (tester) async {
      await pump(tester);

      expect(
        find.textContaining('The Kundali language follows your app language'),
        findsOneWidget,
      );
    },
  );
}
