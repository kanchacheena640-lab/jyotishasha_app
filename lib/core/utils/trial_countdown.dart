// lib/core/utils/trial_countdown.dart
//
// Presentation-only helpers for the TRIAL membership countdown — shared
// between SubscriptionPage's Trial card and Explore's Membership Strip
// so both stay visually consistent (per spec). Reads only the backend's
// own `remaining_days`; never calculates, infers, or decrements a day
// count locally. Entitlement itself is unaffected — this file has no
// bearing on `hasActiveSubscription`/`premium_gate.dart`.

import 'package:flutter/material.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';

class TrialCountdown {
  const TrialCountdown._();

  static const Color _amberWarning = Color(0xFF9A5B00);
  static const Color _redUrgent = Color(0xFFDC2626);

  /// `>= 11` days: Primary/Purple. `6–10`: Amber/Warning. `1–5`:
  /// Red/Urgent. `0` should never appear while a trial is active per
  /// spec, but is treated as urgent (red) defensively rather than
  /// guessing. An unparseable/missing value falls back to Primary/Purple
  /// — never alarms the user over a display-only formatting gap.
  static Color colorFor(dynamic remainingDays) {
    final days = _asInt(remainingDays);
    if (days == null || days >= 11) return AppColors.primary;
    if (days >= 6) return _amberWarning;
    return _redUrgent;
  }

  /// "1 Day Remaining" / "15 Days Remaining" — proper English
  /// singular/plural; Hindi "दिन" doesn't inflect for count, so it's
  /// unchanged either way. Always the backend's own count, verbatim.
  static String label(dynamic remainingDays, bool isHindi) {
    final days = _asInt(remainingDays);
    if (days == null) {
      // Unparseable — show the backend's raw value rather than
      // fabricating a number.
      return isHindi
          ? '$remainingDays दिन शेष'
          : '$remainingDays Days Remaining';
    }
    if (isHindi) return '$days दिन शेष';
    return days == 1 ? '1 Day Remaining' : '$days Days Remaining';
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
