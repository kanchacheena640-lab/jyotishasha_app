import '../models/premium_reports/premium_ai_report_contracts.dart';

/// Purpose: owns access to the entitlement-gated AI Premium Report
/// engine (`GET /api/premium-report`) — distinct from [ReportRepository],
/// which owns the pre-existing, unrelated one-off IAP report catalog
/// (`reports51`-style purchases). This repository never touches billing
/// — entitlement is a server-side decision this call surfaces, not one
/// this client computes.
///
/// Responsibilities: fetch a segment/report-type's AI-generated content
/// for the caller's own profile (identity resolved server-side from the
/// auth token — no `profile_id` is ever sent).
///
/// Excluded responsibilities: entitlement computation, billing,
/// navigation, presentation state.
abstract interface class PremiumAiReportRepository {
  Future<PremiumAiReportResult> getReport({
    required String segment,
    required String reportType,
    required String language,
  });
}
