import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/utils/trial_countdown.dart';

/// 15-Day-to-7-Day Trial fix: TrialCountdown never had test coverage
/// before this change. Proves the label/color logic is correct for the
/// current 7-day trial window, and that both are driven entirely by
/// whatever `remainingDays` the caller passes in (i.e. the backend's
/// own count) — never a locally-computed/hardcoded day count.
void main() {
  group('TrialCountdown.label — 7-day wording', () {
    test('7 remaining -> "7 Days Remaining" (English)', () {
      expect(TrialCountdown.label(7, false), '7 Days Remaining');
    });

    test('1 remaining -> singular "1 Day Remaining" (English)', () {
      expect(TrialCountdown.label(1, false), '1 Day Remaining');
    });

    test('0 remaining -> "0 Days Remaining" (English, defensive)', () {
      expect(TrialCountdown.label(0, false), '0 Days Remaining');
    });

    test('7 remaining -> Hindi wording, uninflected', () {
      expect(TrialCountdown.label(7, true), '7 दिन शेष');
    });

    test('never fabricates a day count for an unparseable value', () {
      expect(TrialCountdown.label(null, false), 'null Days Remaining');
    });
  });

  group('TrialCountdown.colorFor — proportional thirds of the 7-day window', () {
    test('>= 5 days remaining -> Primary/Purple (calm)', () {
      expect(TrialCountdown.colorFor(7), AppColors.primary);
      expect(TrialCountdown.colorFor(5), AppColors.primary);
    });

    test('3-4 days remaining -> Amber/Warning', () {
      expect(TrialCountdown.colorFor(4), const Color(0xFF9A5B00));
      expect(TrialCountdown.colorFor(3), const Color(0xFF9A5B00));
    });

    test('1-2 days remaining -> Red/Urgent', () {
      expect(TrialCountdown.colorFor(2), const Color(0xFFDC2626));
      expect(TrialCountdown.colorFor(1), const Color(0xFFDC2626));
    });

    test('0 (should never appear while active) -> Red/Urgent, defensively', () {
      expect(TrialCountdown.colorFor(0), const Color(0xFFDC2626));
    });

    test('an unparseable/missing value never alarms the user -> Primary/Purple', () {
      expect(TrialCountdown.colorFor(null), AppColors.primary);
      expect(TrialCountdown.colorFor('not-a-number'), AppColors.primary);
    });

    test(
      'the old 15-day thresholds (>=11 purple) no longer apply — proves '
      'this is not stale copy-pasted banding for a 15-day window',
      () {
        // Under the old 15-day bands, 7 would have been Amber (6-10);
        // under the correct 7-day bands, 7 is the top of the window and
        // must be calm/Purple.
        expect(TrialCountdown.colorFor(7), isNot(const Color(0xFF9A5B00)));
        expect(TrialCountdown.colorFor(7), AppColors.primary);
      },
    );
  });
}
