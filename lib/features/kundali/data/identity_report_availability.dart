// lib/features/kundali/data/identity_report_availability.dart

/// The five Identity cards on [KundaliOverviewPage].
enum IdentitySection { ascendant, moonSign, nakshatra, mahadasha, antardasha }

/// Whether a given [IdentitySection]'s full report can be opened yet.
enum ReportAvailabilityStatus { available, comingSoon }

/// F8.2 — the ONE centralized report-availability configuration.
///
/// Every Identity card reads its status from here — nowhere else in the
/// UI branches on availability. Each [IdentitySection] has exactly one
/// [ReportAvailabilityStatus]; to change what's available, change this
/// map only.
class IdentityReportAvailability {
  const IdentityReportAvailability._();

  static const Map<IdentitySection, ReportAvailabilityStatus> _status = {
    IdentitySection.ascendant: ReportAvailabilityStatus.available,
    IdentitySection.moonSign: ReportAvailabilityStatus.available,
    IdentitySection.nakshatra: ReportAvailabilityStatus.available,
    IdentitySection.mahadasha: ReportAvailabilityStatus.comingSoon,
    IdentitySection.antardasha: ReportAvailabilityStatus.comingSoon,
  };

  static ReportAvailabilityStatus statusOf(IdentitySection section) =>
      _status[section]!;
}
