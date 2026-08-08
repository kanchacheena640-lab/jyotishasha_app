/// Purpose: owns the Welcome Gift "claimed" flag lifecycle for the
/// onboarding flow (5 personalized premium reports + 15 days premium
/// membership, offered once per user).
///
/// Responsibilities: report whether the current user has already claimed
/// the Welcome Gift, and record a claim.
///
/// Excluded responsibilities: report generation, subscription activation,
/// entitlement computation, backend networking, presentation state.
///
/// Current implementation ([LocalWelcomeGiftRepository]) is local-only by
/// design for this task — see its doc comment for how a future
/// backend-backed implementation slots in behind this same interface.
abstract interface class WelcomeGiftRepository {
  Future<bool> isClaimed();

  Future<void> markClaimed();
}
