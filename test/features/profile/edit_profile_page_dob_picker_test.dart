import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/features/profile/edit_profile_page.dart';

import '../../helpers/test_harness.dart';

/// Covers the data-integrity fix in [EditProfilePage]'s `_pickDate()`:
/// previously always initialized the picker to `DateTime.now()`, so
/// confirming without changing anything silently replaced a correct
/// existing DOB with today's date. Fixed to initialize from the
/// existing DOB when present/parseable, else the same neutral
/// historical default `birth_detail_page.dart` uses.
///
/// Only the picker itself is driven here (never `_saveChanges()`,
/// which needs a real `ProfileProvider` backed by Firebase -- out of
/// scope for a picker-integrity bug). The DOB field's controller is
/// `_dobCtrl`, private to this screen's own library -- unlike
/// `birth_detail_page.dart`'s public `dobCtrl`, it can't be reached
/// dynamically from this test file's different library, so these
/// tests instead locate the `TextFormField` by its label and read its
/// `.controller!.text` directly (the controller object itself, once
/// found through the widget tree, has no privacy restriction).
void main() {
  Future<void> pumpEditProfilePage(
    WidgetTester tester, {
    required Map<String, dynamic> profile,
  }) async {
    await tester.pumpTestHarness(EditProfilePage(profile: profile));
    await tester.pumpAndSettle();
  }

  // TextFormField itself doesn't expose its InputDecoration publicly,
  // so the field is located by its unique label text instead (rendered
  // as a real Text descendant of the field, even unfocused).
  Finder dobField() => find.ancestor(
        of: find.text('Date of Birth'),
        matching: find.byType(TextFormField),
      );

  String dobText(WidgetTester tester) =>
      tester.widget<TextFormField>(dobField()).controller!.text;

  Future<void> openDatePickerDialog(WidgetTester tester) async {
    await tester.tap(dobField());
    await tester.pumpAndSettle();
    expect(
      find.byType(DatePickerDialog),
      findsOneWidget,
      reason: 'Material date picker dialog should be open',
    );
  }

  Future<void> tapOk(WidgetTester tester) async {
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'C: existing DOB present -> open picker -> confirm immediately -> '
    'original DOB is preserved, NOT silently replaced with today',
    (tester) async {
      await pumpEditProfilePage(
        tester,
        profile: const {
          'name': 'Test User',
          'dob': '1990-06-15', // as stored by birth_detail_page.dart
          'tob': '08:30',
          'pob': 'Mumbai',
        },
      );

      expect(dobText(tester), '1990-06-15');

      await openDatePickerDialog(tester);

      // The dialog's own initial selection must be the EXISTING DOB,
      // never today -- this is the actual bug fix under test.
      final dialog = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(dialog.initialDate, DateTime(1990, 6, 15));

      await tapOk(tester);

      // Confirming without touching the calendar must preserve the
      // original date (reformatted to this screen's own DD-MM-YYYY
      // write format -- a pre-existing, separate format-consistency
      // concern, not part of this fix).
      expect(dobText(tester), '15-06-1990');

      final today = DateTime.now();
      final todayDdMmYyyy =
          "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";
      expect(
        dobText(tester),
        isNot(todayDdMmYyyy),
        reason: 'the old bug silently overwrote this with DateTime.now()',
      );
    },
  );

  testWidgets(
    'no existing DOB -> picker falls back to the SAME neutral default '
    'birth_detail_page.dart uses, never DateTime.now()',
    (tester) async {
      await pumpEditProfilePage(
        tester,
        profile: const {'name': 'Test User'},
      );

      expect(dobText(tester), isEmpty);

      await openDatePickerDialog(tester);

      final dialog = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(dialog.initialDate, DateTime(2000, 1, 1));
    },
  );

  testWidgets(
    'D: future dates remain blocked (lastDate is today)',
    (tester) async {
      await pumpEditProfilePage(
        tester,
        profile: const {'dob': '1990-06-15'},
      );

      await openDatePickerDialog(tester);

      final dialog = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      final now = DateTime.now();
      expect(dialog.lastDate.year, now.year);
      expect(dialog.lastDate.month, now.month);
      expect(dialog.lastDate.day, now.day);
    },
  );

  testWidgets(
    'E: a genuine recent/newborn existing DOB initializes the picker '
    'from that DOB too -- newborn charts remain fully editable',
    (tester) async {
      final newborn = DateTime.now().subtract(const Duration(days: 5));
      final newbornIso =
          "${newborn.year}-${newborn.month.toString().padLeft(2, '0')}-${newborn.day.toString().padLeft(2, '0')}";

      await pumpEditProfilePage(
        tester,
        profile: {'dob': newbornIso},
      );

      await openDatePickerDialog(tester);

      final dialog = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(dialog.initialDate!.year, newborn.year);
      expect(dialog.initialDate!.month, newborn.month);
      expect(dialog.initialDate!.day, newborn.day);

      await tapOk(tester);
      expect(
        dobText(tester),
        "${newborn.day.toString().padLeft(2, '0')}-${newborn.month.toString().padLeft(2, '0')}-${newborn.year}",
      );
    },
  );
}
