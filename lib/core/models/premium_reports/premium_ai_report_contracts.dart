// lib/core/models/premium_reports/premium_ai_report_contracts.dart

/// S5.X — typed contract for `GET /api/premium-report`.
///
/// Segment/report-type constants mirror the backend's actual, currently
/// *registered* generators exactly (`modules/ai_report_engine/
/// generator_registry.py::_register_default_generators` in the backend
/// repo only registers `"LOVE"`; `modules/love/love_generator.py`
/// supports report types `DNA`/`CURRENT_PHASE`/`DAILY_INSIGHT`). Other
/// segments (`CAREER`/`FINANCE`/`HEALTH`/`FAMILY`/`ALERTS`) are valid
/// entitlement segments but have no generator yet — calling them 400s
/// regardless of subscription, so this client deliberately does not
/// expose them until the backend registers a generator for each.
class PremiumAiReportSegments {
  const PremiumAiReportSegments._();

  static const String love = 'LOVE';
}

class PremiumAiReportTypes {
  const PremiumAiReportTypes._();

  static const String dna = 'DNA';
  static const String currentPhase = 'CURRENT_PHASE';
  static const String dailyInsight = 'DAILY_INSIGHT';
}

/// Result of a `GET /api/premium-report` call — success carries the
/// backend's own `content` text verbatim; failure carries the backend's
/// own `error`/`message` verbatim (this client never invents or
/// rewords backend error copy, matching `SubscriptionProvider`'s same
/// "backend is the source of truth" convention).
class PremiumAiReportResult {
  const PremiumAiReportResult._({this.content, this.errorCode, this.errorMessage});

  factory PremiumAiReportResult.success(String content) =>
      PremiumAiReportResult._(content: content);

  factory PremiumAiReportResult.failure({
    required String errorCode,
    String? errorMessage,
  }) => PremiumAiReportResult._(errorCode: errorCode, errorMessage: errorMessage);

  /// Non-null exactly when the call succeeded.
  final String? content;

  /// The backend's own `error` field (e.g. `"trial_expired"`,
  /// `"subscription_required"`, `"unknown_segment"`, ...). Non-null
  /// exactly when the call failed.
  final String? errorCode;

  /// The backend's own `message` field, if any.
  final String? errorMessage;

  bool get isSuccess => errorCode == null;

  /// The two entitlement-gating outcomes — the ones a subscription
  /// upsell should react to, as opposed to a generic error.
  bool get isEntitlementDenied =>
      errorCode == 'trial_expired' || errorCode == 'subscription_required';
}
