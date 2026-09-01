import 'package:jyotishasha_app/core/identity/current_user_identity_port.dart';
import 'package:jyotishasha_app/services/activity_event_client.dart';

/// Phase 5B -- a defensive fallback identity port whose
/// `currentFirebaseUid` is always null, used ONLY when constructing the
/// real default `ActivityEventClient()` itself fails synchronously.
///
/// This can only happen if `FirebaseCurrentUserIdentityPort`'s own
/// constructor -- which eagerly reads `FirebaseAuth.instance` -- runs
/// before Firebase has finished initializing. In production this never
/// happens (`main()` always `await`s `Firebase.initializeApp()` before
/// `runApp()`, so every widget that could fire a producer call already
/// has a ready Firebase app); it is a real, observed condition in a
/// headless widget-test environment, where no Firebase app exists at all.
class _NullIdentityPort implements CurrentUserIdentityPort {
  const _NullIdentityPort();
  @override
  String? get currentFirebaseUid => null;
}

/// Constructs a real, production-default [ActivityEventClient], but NEVER
/// throws even if that construction itself fails -- falls back to a
/// client that will always safely no-op (no signed-in user, per
/// [ActivityEventClient.record]'s own "no Firebase user -> dropped"
/// contract) instead of letting a construction-time exception escape into
/// product code.
///
/// [ActivityEventClient.record] already guarantees it never throws once
/// constructed; this closes the one gap that guarantee didn't cover --
/// construction itself. Every Phase 5B producer (`ActivityEvents`,
/// `SessionStartProducer`, `NotificationOpenedProducer`) uses this at
/// their one shared "lazily build the real default client" seam instead
/// of calling `ActivityEventClient()` directly.
ActivityEventClient safeDefaultActivityEventClient() {
  try {
    return ActivityEventClient();
  } catch (_) {
    return ActivityEventClient(identityPort: const _NullIdentityPort());
  }
}
