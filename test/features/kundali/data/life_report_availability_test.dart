import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/features/kundali/data/identity_report_availability.dart';
import 'package:jyotishasha_app/features/kundali/data/life_report_availability.dart';

void main() {
  group('LifeReportAvailability (F8.5 — centralized, one status each)', () {
    test(
      'Love & Relationship, Career, Marriage, and Foreign Travel are '
      'AVAILABLE — the only categories with a free, instant, personalized '
      'report live on the Next.js site (LIFE_TOOL_IDS)',
      () {
        for (final section in [
          LifeAreaSection.loveRelationship,
          LifeAreaSection.career,
          LifeAreaSection.marriage,
          LifeAreaSection.foreignTravel,
        ]) {
          expect(
            LifeReportAvailability.statusOf(section),
            ReportAvailabilityStatus.available,
          );
        }
      },
    );

    test(
      'Finance & Wealth, Family, Children, Education, Health, Property, '
      'Spirituality, and Legal Matters are COMING_SOON — no free '
      'personalized report exists for these on the Next.js site',
      () {
        for (final section in [
          LifeAreaSection.financeWealth,
          LifeAreaSection.family,
          LifeAreaSection.children,
          LifeAreaSection.education,
          LifeAreaSection.health,
          LifeAreaSection.property,
          LifeAreaSection.spirituality,
          LifeAreaSection.legalMatters,
        ]) {
          expect(
            LifeReportAvailability.statusOf(section),
            ReportAvailabilityStatus.comingSoon,
          );
        }
      },
    );

    test('every LifeAreaSection has exactly one status', () {
      for (final section in LifeAreaSection.values) {
        expect(
          () => LifeReportAvailability.statusOf(section),
          returnsNormally,
        );
      }
    });

    test('LifeAreaSection.values enumerates the required grid order', () {
      expect(LifeAreaSection.values, [
        LifeAreaSection.loveRelationship,
        LifeAreaSection.career,
        LifeAreaSection.financeWealth,
        LifeAreaSection.marriage,
        LifeAreaSection.family,
        LifeAreaSection.children,
        LifeAreaSection.education,
        LifeAreaSection.health,
        LifeAreaSection.property,
        LifeAreaSection.foreignTravel,
        LifeAreaSection.spirituality,
        LifeAreaSection.legalMatters,
      ]);
    });
  });
}
