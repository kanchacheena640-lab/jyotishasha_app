import '../models/alerts/alerts_dashboard_contracts.dart';

/// Purpose: owns access to the entitlement-gated Alerts & Opportunities
/// subscription API (`GET /api/alerts/current`) — distinct from any
/// Premium AI Report repository; Alerts is a separate, independent,
/// rule-based system (backend: `modules/alerts/`), not an AI-generated
/// report.
///
/// Responsibilities: fetch the caller's own profile's currently-selected
/// alerts (identity resolved server-side from the auth token — no
/// `profile_id` is ever sent).
///
/// Excluded responsibilities: alert detection/selection (the backend's
/// existing Alerts Engine remains the sole authority), entitlement
/// computation, billing, navigation, presentation state.
abstract interface class AlertsDashboardRepository {
  Future<AlertsDashboardResult> getCurrentAlerts();
}
