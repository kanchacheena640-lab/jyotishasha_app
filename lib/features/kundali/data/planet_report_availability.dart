// lib/features/kundali/data/planet_report_availability.dart

import 'package:jyotishasha_app/features/kundali/data/identity_report_availability.dart'
    show ReportAvailabilityStatus;

/// The nine Planet cards on [KundaliOverviewPage], always in this fixed
/// display order (Sun → Moon → Mars → Mercury → Jupiter → Venus → Saturn →
/// Rahu → Ketu) — never dependent on backend list ordering.
enum PlanetSection {
  sun,
  moon,
  mars,
  mercury,
  jupiter,
  venus,
  saturn,
  rahu,
  ketu,
}

/// F8.3 — the ONE centralized report-availability configuration for the
/// Planet section, following exactly the same architecture as
/// [IdentityReportAvailability] (F8.2). Every planet card reads its status
/// from here — nowhere else in the UI branches on availability. Each
/// [PlanetSection] has exactly one [ReportAvailabilityStatus]; to change
/// what's available, change this map only.
class PlanetReportAvailability {
  const PlanetReportAvailability._();

  static const Map<PlanetSection, ReportAvailabilityStatus> _status = {
    PlanetSection.sun: ReportAvailabilityStatus.available,
    PlanetSection.moon: ReportAvailabilityStatus.available,
    PlanetSection.mars: ReportAvailabilityStatus.available,
    PlanetSection.mercury: ReportAvailabilityStatus.available,
    PlanetSection.jupiter: ReportAvailabilityStatus.available,
    PlanetSection.venus: ReportAvailabilityStatus.available,
    PlanetSection.saturn: ReportAvailabilityStatus.available,
    PlanetSection.rahu: ReportAvailabilityStatus.available,
    PlanetSection.ketu: ReportAvailabilityStatus.available,
  };

  static ReportAvailabilityStatus statusOf(PlanetSection section) =>
      _status[section]!;
}
