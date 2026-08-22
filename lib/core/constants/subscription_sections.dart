// lib/core/constants/subscription_sections.dart

/// Canonical subscription-section identifiers.
///
/// Mirrors the backend's `modules/entitlement/subscription_sections.py::
/// SUBSCRIPTION_SECTIONS` exactly (confirmed directly against the
/// backend's deployed `main` branch, not guessed/invented): every
/// [PremiumAiReportSegments] value, plus `"ALERTS"`, in the backend's own
/// declared order (`AI_REPORT_SEGMENTS + (ALERTS_SECTION,)`).
///
/// Deliberately a SEPARATE constants class from [PremiumAiReportSegments]
/// — not a re-export/alias of it — matching the backend's own explicit
/// decoupling: `subscription_sections.py`'s docstring documents that
/// these are two independent value domains (subscription entitlement/
/// selection vs. what the AI Report Engine can generate) that happen to
/// share five string values today, and must never be silently coupled
/// so a future change to one can't leak into the other.
///
/// Used only where a plan's segment ACCESS is `ACCESS_SELECTED` on the
/// backend (`Silver Monthly`/`Silver Yearly` — see
/// `modules/entitlement/plan_access_policy.py::PLAN_SEGMENT_ACCESS`).
/// Gold/Platinum are `ACCESS_ALL` and never send `selected_segment` at
/// all — this class is not consulted for those plans' purchase flow.
class SubscriptionSections {
  const SubscriptionSections._();

  static const String love = 'LOVE';
  static const String career = 'CAREER';
  static const String finance = 'FINANCE';
  static const String health = 'HEALTH';
  static const String family = 'FAMILY';
  static const String alerts = 'ALERTS';

  /// Fixed display order — matches the backend's own tuple order
  /// exactly, so the on-screen list order is never an arbitrary/
  /// independent choice.
  static const List<String> all = [love, career, finance, health, family, alerts];

  /// The six user-facing section labels shown in the Silver
  /// section-selection UI. Falls back to the raw canonical value for
  /// any value outside [all] — defensive only; every caller in this app
  /// only ever iterates [all], so this branch is not expected to be
  /// reached in practice.
  static String label(String section, bool isHindi) => switch (section) {
    love => isHindi ? 'प्रेम और रिश्ते' : 'Love & Relationship',
    career => isHindi ? 'करियर और शिक्षा' : 'Career & Education',
    finance => isHindi ? 'वित्त और धन' : 'Finance & Wealth',
    health => isHindi ? 'स्वास्थ्य और कल्याण' : 'Health & Wellness',
    family => isHindi ? 'परिवार और सामाजिक जीवन' : 'Family & Social Life',
    alerts => isHindi ? 'अलर्ट और अवसर' : 'Alerts & Opportunities',
    _ => section,
  };
}
