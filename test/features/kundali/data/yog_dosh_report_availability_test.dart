import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/features/kundali/data/identity_report_availability.dart';
import 'package:jyotishasha_app/features/kundali/data/yog_dosh_report_availability.dart';

void main() {
  group('YogDoshReportAvailability (F8.4 — centralized, one status each)', () {
    test('all seventeen known Yog/Dosh sections are AVAILABLE', () {
      for (final section in YogDoshSection.values) {
        expect(
          YogDoshReportAvailability.statusOf(section),
          ReportAvailabilityStatus.available,
        );
      }
    });

    test('every YogDoshSection has exactly one status', () {
      for (final section in YogDoshSection.values) {
        expect(
          () => YogDoshReportAvailability.statusOf(section),
          returnsNormally,
        );
      }
    });

    test('statusForId resolves known backend ids to the same status as '
        'their YogDoshSection', () {
      expect(
        YogDoshReportAvailability.statusForId('manglik_dosh'),
        ReportAvailabilityStatus.available,
      );
      expect(
        YogDoshReportAvailability.statusForId('gajakesari_yog'),
        ReportAvailabilityStatus.available,
      );
      expect(
        YogDoshReportAvailability.statusForId('sadhesati'),
        ReportAvailabilityStatus.available,
      );
    });

    test('statusForId defaults to COMING_SOON for an id outside the known '
        'catalog — a safe fallback, not a guess', () {
      expect(
        YogDoshReportAvailability.statusForId('some_future_yog'),
        ReportAvailabilityStatus.comingSoon,
      );
    });
  });
}
