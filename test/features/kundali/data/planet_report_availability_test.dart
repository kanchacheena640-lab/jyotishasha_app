import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/features/kundali/data/identity_report_availability.dart';
import 'package:jyotishasha_app/features/kundali/data/planet_report_availability.dart';

void main() {
  group('PlanetReportAvailability (F8.3 — centralized, one status each)', () {
    test('all nine planets are AVAILABLE', () {
      for (final section in PlanetSection.values) {
        expect(
          PlanetReportAvailability.statusOf(section),
          ReportAvailabilityStatus.available,
        );
      }
    });

    test('every PlanetSection has exactly one status', () {
      for (final section in PlanetSection.values) {
        // Throws if a section were ever missing from the map.
        expect(
          () => PlanetReportAvailability.statusOf(section),
          returnsNormally,
        );
      }
    });

    test('PlanetSection.values enumerates the required display order', () {
      expect(PlanetSection.values, [
        PlanetSection.sun,
        PlanetSection.moon,
        PlanetSection.mars,
        PlanetSection.mercury,
        PlanetSection.jupiter,
        PlanetSection.venus,
        PlanetSection.saturn,
        PlanetSection.rahu,
        PlanetSection.ketu,
      ]);
    });
  });
}
