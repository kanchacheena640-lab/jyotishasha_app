import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/features/kundali/data/identity_report_availability.dart';

void main() {
  group('IdentityReportAvailability (F8.2 — centralized, one status each)', () {
    test('Ascendant, Moon Sign, and Nakshatra are AVAILABLE', () {
      expect(
        IdentityReportAvailability.statusOf(IdentitySection.ascendant),
        ReportAvailabilityStatus.available,
      );
      expect(
        IdentityReportAvailability.statusOf(IdentitySection.moonSign),
        ReportAvailabilityStatus.available,
      );
      expect(
        IdentityReportAvailability.statusOf(IdentitySection.nakshatra),
        ReportAvailabilityStatus.available,
      );
    });

    test('Mahadasha and Antardasha are COMING_SOON', () {
      expect(
        IdentityReportAvailability.statusOf(IdentitySection.mahadasha),
        ReportAvailabilityStatus.comingSoon,
      );
      expect(
        IdentityReportAvailability.statusOf(IdentitySection.antardasha),
        ReportAvailabilityStatus.comingSoon,
      );
    });

    test('every IdentitySection has exactly one status', () {
      for (final section in IdentitySection.values) {
        // Throws if a section were ever missing from the map.
        expect(
          () => IdentityReportAvailability.statusOf(section),
          returnsNormally,
        );
      }
    });
  });
}
