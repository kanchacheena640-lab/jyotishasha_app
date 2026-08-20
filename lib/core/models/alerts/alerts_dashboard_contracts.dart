// lib/core/models/alerts/alerts_dashboard_contracts.dart

/// Typed contract for `GET /api/alerts/current` — the "Alerts &
/// Opportunities" premium subscription section's own, independent API
/// (backend: `routes/routes_alerts_dashboard.py`). Deliberately separate
/// from [PremiumAiReportResult]/`PremiumAiReportSegments` — Alerts is not
/// an AI-generated report and has no `segment`/`report_type` of its own;
/// see that file's own docstring for why `ALERTS` is intentionally absent
/// from `PremiumAiReportSegments`.
///
/// One [AlertItem] per currently-selected alert (normally 1, at most 2 —
/// the backend's own hardened Alerts Engine selection, never
/// re-decided here). Only ever the minimal fields the backend actually
/// returns: no confidence, no detection-internal state, no birth data.
class AlertItem {
  const AlertItem({
    required this.alertId,
    required this.eventId,
    required this.title,
    required this.message,
    required this.category,
    required this.severity,
    required this.priority,
    required this.validFrom,
    required this.validUntil,
    this.action,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) => AlertItem(
    alertId: json['alert_id'] as int?,
    eventId: json['event_id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    message: json['message']?.toString() ?? '',
    category: json['category']?.toString() ?? '',
    severity: json['severity']?.toString(),
    priority: json['priority']?.toString(),
    validFrom: json['valid_from']?.toString(),
    validUntil: json['valid_until']?.toString(),
    // AI-Written Personalized Alert Content addition -- present only
    // when the backend actually generated one for this alert (a
    // genuine new/reactivated occurrence); a plain generic template
    // fallback alert has none. Never defaulted to an empty string —
    // `null` means "no action for this alert", not "not loaded yet".
    action: json['action']?.toString(),
  );

  final int? alertId;
  final String eventId;
  final String title;
  final String message;
  final String category;
  final String? severity;
  final String? priority;
  final String? validFrom;
  final String? validUntil;
  final String? action;
}

/// The distinct outcomes `GET /api/alerts/current` can produce — a client
/// branches on [status], never on HTTP code directly, matching this app's
/// existing repository conventions (e.g. [PremiumAiReportResult]).
enum AlertsDashboardStatus {
  success,
  locked,
  noProfile,
  forbidden,
  authFailed,
  networkError,
  error,
}

class AlertsDashboardResult {
  const AlertsDashboardResult._({
    required this.status,
    this.alerts = const [],
    this.message,
  });

  factory AlertsDashboardResult.success(List<AlertItem> alerts) =>
      AlertsDashboardResult._(status: AlertsDashboardStatus.success, alerts: alerts);

  factory AlertsDashboardResult.failure({
    required AlertsDashboardStatus status,
    String? message,
  }) => AlertsDashboardResult._(status: status, message: message);

  final AlertsDashboardStatus status;

  /// Only ever populated on [AlertsDashboardStatus.success] — 0, 1, or 2
  /// items. The backend never returns raw detected candidates; this is
  /// always the already-selected, final set.
  final List<AlertItem> alerts;

  /// The backend's own `message` field, if any -- this client never
  /// invents or rewords backend error copy.
  final String? message;

  bool get isSuccess => status == AlertsDashboardStatus.success;

  /// The one outcome a subscription upsell should react to -- Alerts &
  /// Opportunities was not this profile's entitled/selected section.
  bool get isLocked => status == AlertsDashboardStatus.locked;
}
