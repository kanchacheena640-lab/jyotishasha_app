import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/features/birth/birth_detail_page.dart';

import '../../helpers/test_harness.dart';

/// Covers the data-integrity fix in
/// [BirthDetailPage]'s `_pickDateCupertino()`: the picker's VISIBLE
/// initial date and the value actually written to `dobCtrl` on "Done"
/// must always be identical -- there must be no hidden `DateTime.now()`
/// default that can diverge from what the wheel shows.
///
/// These tests only drive the DOB picker itself (never
/// `_saveDetails()`, which needs `FirebaseAuth`/`Firestore`/
/// `KundaliProvider` -- unavailable in this widget-test environment and
/// out of scope for a picker-integrity bug), so `BirthDetailPage` is
/// pumped directly with no providers: its `build()` method has no
/// provider dependency, only `_saveDetails()` does.
///
/// `dobCtrl` is a public field on the (private) State class, reachable
/// dynamically via `tester.state()` -- Dart's library-privacy applies
/// to the State class's *name*, not to its public members, so this
/// still compiles and runs from a different library (this test file).
void main() {
  Future<dynamic> pumpBirthDetailPage(WidgetTester tester) async {
    await tester.pumpTestHarness(const BirthDetailPage());
    await tester.pumpAndSettle();
    return tester.state(find.byType(BirthDetailPage));
  }

  Finder dobField(dynamic state) => find.byWidgetPredicate(
        (w) => w is TextFormField && w.controller == state.dobCtrl,
      );

  Future<void> openDobPicker(WidgetTester tester, dynamic state) async {
    await tester.tap(dobField(state));
    await tester.pumpAndSettle();
    expect(
      find.byType(CupertinoDatePicker),
      findsOneWidget,
      reason: 'DOB picker modal should be open',
    );
  }

  Future<void> tapDone(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(CupertinoButton, 'Done'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'A: open DOB picker, do not scroll, tap Done -> submitted DOB equals '
    'the visible neutral default (01-01-2000), NEVER today',
    (tester) async {
      final state = await pumpBirthDetailPage(tester);
      expect(state.dobCtrl.text, isEmpty, reason: 'no DOB picked yet');

      await openDobPicker(tester, state);

      // The picker's own displayed initialDateTime must be the neutral
      // default -- confirms the fix seeded initialDateTime correctly.
      final picker = tester.widget<CupertinoDatePicker>(
        find.byType(CupertinoDatePicker),
      );
      expect(picker.initialDateTime, DateTime(2000, 1, 1));

      await tapDone(tester);

      final today = DateTime.now();
      final todayText =
          "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";

      expect(state.dobCtrl.text, '01-01-2000');
      expect(
        state.dobCtrl.text,
        isNot(todayText),
        reason: 'the old bug silently submitted DateTime.now() here',
      );
    },
  );

  testWidgets(
    'B: scrolling the picker changes the value actually used, not the '
    'default',
    (tester) async {
      final state = await pumpBirthDetailPage(tester);

      await openDobPicker(tester, state);

      // Drag the date wheel to move it away from the neutral default.
      await tester.drag(
        find.byType(CupertinoDatePicker),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      await tapDone(tester);

      expect(
        state.dobCtrl.text,
        isNot('01-01-2000'),
        reason: 'a real scroll must change what gets submitted',
      );
      expect(state.dobCtrl.text, isNotEmpty);
    },
  );

  testWidgets(
    'D: the picker cannot be scrolled past today (future DOB blocked)',
    (tester) async {
      final state = await pumpBirthDetailPage(tester);
      await openDobPicker(tester, state);

      final picker = tester.widget<CupertinoDatePicker>(
        find.byType(CupertinoDatePicker),
      );
      final now = DateTime.now();
      expect(
        picker.maximumDate!.isBefore(now.add(const Duration(minutes: 1))),
        isTrue,
        reason: 'maximumDate must not allow a future DOB',
      );
      expect(
        picker.maximumDate!.year,
        now.year,
        reason: 'maximumDate should be effectively "today"',
      );
    },
  );

  testWidgets(
    'E: re-opening after a genuine recent/newborn DOB was already picked '
    'initializes the picker from that DOB, not the neutral default -- '
    'newborn charts remain fully supported',
    (tester) async {
      final state = await pumpBirthDetailPage(tester);

      // Simulate a newborn DOB already chosen 10 days ago (a plausible
      // real newborn-chart scenario this product must keep supporting).
      final newborn = DateTime.now().subtract(const Duration(days: 10));
      state.dobCtrl.text =
          "${newborn.day.toString().padLeft(2, '0')}-${newborn.month.toString().padLeft(2, '0')}-${newborn.year}";

      await openDobPicker(tester, state);

      final picker = tester.widget<CupertinoDatePicker>(
        find.byType(CupertinoDatePicker),
      );
      expect(picker.initialDateTime.year, newborn.year);
      expect(picker.initialDateTime.month, newborn.month);
      expect(picker.initialDateTime.day, newborn.day);

      // Confirming without scrolling must PRESERVE the newborn DOB
      // (proves no minimum-age rejection exists anywhere in this path).
      await tapDone(tester);
      expect(
        state.dobCtrl.text,
        "${newborn.day.toString().padLeft(2, '0')}-${newborn.month.toString().padLeft(2, '0')}-${newborn.year}",
      );
    },
  );

  testWidgets(
    'DOB is required to submit, but a near-today DOB is never rejected '
    'by validation (no minimum-age rule exists)',
    (tester) async {
      final state = await pumpBirthDetailPage(tester);
      final today = DateTime.now();
      state.dobCtrl.text =
          "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";
      // Every OTHER required field on this Form also needs a value --
      // Form.validate() validates every field at once, and this test
      // only cares whether DOB specifically is ever rejected for being
      // "too recent", not whether the whole form is fully filled.
      state.nameCtrl.text = 'Newborn Test';
      state.tobCtrl.text = '12:00';
      state.pobCtrl.text = 'Mumbai';

      final formState = tester.state<FormState>(find.byType(Form));
      expect(
        formState.validate(),
        isTrue,
        reason: 'a real, actively-chosen near-today DOB must pass validation',
      );
    },
  );
}
