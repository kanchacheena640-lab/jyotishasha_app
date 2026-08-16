// lib/core/models/premium_reports/premium_ai_report_contracts.dart

/// S5.X — typed contract for `GET /api/premium-report`.
///
/// Segment constants mirror the backend's actual, currently *registered*
/// generators exactly (`modules/ai_report_engine/generator_registry.py::
/// _register_default_generators` in the backend repo registers all five —
/// `LoveGenerator`/`CareerGenerator`/`FinanceGenerator`/`HealthGenerator`/
/// `FamilyGenerator`, each supporting report types `DNA`/`CURRENT_PHASE`/
/// `DAILY_INSIGHT`). `ALERTS` is deliberately NOT one of these constants:
/// per that same backend file's own docstring, "Alerts" is not a
/// ReportGenerator segment at all — `modules/alerts/` is a separate,
/// independent, rule-based system with its own registry
/// (`modules/alerts/event_registry.py`), consumed by the existing
/// notification pipeline, not by this entitlement-gated report engine.
/// Adding it here would 400 against a segment the backend's
/// `AI_REPORT_SEGMENTS` tuple (`modules/models_ai_reports.py`) does not
/// recognize.
class PremiumAiReportSegments {
  const PremiumAiReportSegments._();

  static const String love = 'LOVE';
  static const String career = 'CAREER';
  static const String finance = 'FINANCE';
  static const String health = 'HEALTH';
  static const String family = 'FAMILY';
}

class PremiumAiReportTypes {
  const PremiumAiReportTypes._();

  static const String dna = 'DNA';
  static const String currentPhase = 'CURRENT_PHASE';
  static const String dailyInsight = 'DAILY_INSIGHT';

  /// Its own distinct `report_type` — a separate `GET /api/premium-report`
  /// call, exactly like [dna]/[currentPhase]/[dailyInsight] each already
  /// are. Previously `BirthChartReportReader` had no call for this at
  /// all: it tried to recover "Current Timing" content by pattern-matching
  /// a `## Current Timing` heading inside the unrelated [currentPhase]
  /// response instead of requesting it. See that file's audit trail for
  /// the fix.
  static const String currentTiming = 'CURRENT_TIMING';
}

/// Result of a `GET /api/premium-report` call — success carries the
/// backend's own `content` text verbatim; failure carries the backend's
/// own `error`/`message` verbatim (this client never invents or
/// rewords backend error copy, matching `SubscriptionProvider`'s same
/// "backend is the source of truth" convention).
class PremiumAiReportResult {
  const PremiumAiReportResult._({
    this.content,
    this.errorCode,
    this.errorMessage,
  });

  factory PremiumAiReportResult.success(String content) =>
      PremiumAiReportResult._(content: content);

  factory PremiumAiReportResult.failure({
    required String errorCode,
    String? errorMessage,
  }) =>
      PremiumAiReportResult._(errorCode: errorCode, errorMessage: errorMessage);

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
