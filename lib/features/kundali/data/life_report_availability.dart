// lib/features/kundali/data/life_report_availability.dart

import 'package:jyotishasha_app/features/kundali/data/identity_report_availability.dart'
    show ReportAvailabilityStatus;

/// The twelve Life Area cards on [KundaliOverviewPage], in the exact
/// order specified for the grid.
enum LifeAreaSection {
  loveRelationship,
  career,
  financeWealth,
  marriage,
  family,
  children,
  education,
  health,
  property,
  foreignTravel,
  spirituality,
  legalMatters,
}

/// F8.5 — the ONE centralized report-availability configuration for the
/// Life Areas section, following exactly the same architecture as
/// [IdentityReportAvailability] (F8.2), `PlanetReportAvailability`
/// (F8.3), and `YogDoshReportAvailability` (F8.4). Every Life Area card
/// reads its status from here — nowhere else in the UI branches on
/// availability.
///
/// Availability was determined ONLY by inspecting the live Next.js
/// report inventory (`jyotishasha-frontend`), not guessed:
///
/// `app/[locale]/tools/[toolId]/ToolDynamicPage.tsx` defines
/// `LIFE_TOOL_IDS = ['career-path', 'marriage-path', 'foreign-travel',
/// 'government-job', 'business-path', 'love-life']` — these are the
/// only life-area reports that are free, instant, and personalized
/// (they call `fetchFullKundali` + `fetchLifeTool` with the user's real
/// birth data and render an actual result in-page). Of this app's 12
/// categories, that covers Love & Relationship (`love-life`), Career
/// (`career-path`), Marriage (`marriage-path`), and Foreign Travel
/// (`foreign-travel`) — marked AVAILABLE below.
///
/// Every other category was checked and found to be either (a) gated
/// behind a paid checkout flow only (`app/data/reportsData.ts` —
/// `financial_report`, `children_parenting_report`, `property_report`,
/// `legal_disputes_report`, `mood_mental_health_report`, etc.) or (b) a
/// static, non-personalized SEO page, several explicitly commented out
/// as not-yet-built in `lib/authority-engine/registry.ts`
/// (`health-astrology`, `property-astrology`, `education-astrology`,
/// `foreign-settlement-astrology`), or (c) not found on the site at all
/// (Family, Spirituality). None of that is a free report, so none of it
/// satisfies "View Full Free Report →" — all eight remain COMING_SOON.
class LifeReportAvailability {
  const LifeReportAvailability._();

  static const Map<LifeAreaSection, ReportAvailabilityStatus> _status = {
    LifeAreaSection.loveRelationship: ReportAvailabilityStatus.available,
    LifeAreaSection.career: ReportAvailabilityStatus.available,
    LifeAreaSection.financeWealth: ReportAvailabilityStatus.comingSoon,
    LifeAreaSection.marriage: ReportAvailabilityStatus.available,
    LifeAreaSection.family: ReportAvailabilityStatus.comingSoon,
    LifeAreaSection.children: ReportAvailabilityStatus.comingSoon,
    LifeAreaSection.education: ReportAvailabilityStatus.comingSoon,
    LifeAreaSection.health: ReportAvailabilityStatus.comingSoon,
    LifeAreaSection.property: ReportAvailabilityStatus.comingSoon,
    LifeAreaSection.foreignTravel: ReportAvailabilityStatus.available,
    LifeAreaSection.spirituality: ReportAvailabilityStatus.comingSoon,
    LifeAreaSection.legalMatters: ReportAvailabilityStatus.comingSoon,
  };

  static ReportAvailabilityStatus statusOf(LifeAreaSection section) =>
      _status[section]!;
}
