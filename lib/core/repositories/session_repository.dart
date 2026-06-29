import '../models/session/session.dart';

/// Purpose: provides the single application boundary for session state.
///
/// Responsibilities: expose current and changing sessions, authenticate using
/// a named provider, sign out, and resolve the backend authorization token.
///
/// Excluded responsibilities: routing, startup coordination, user/profile
/// persistence, concrete authentication SDKs, and UI state.
///
/// Future implementation owner: ESR-003 session repository implementation.
abstract interface class SessionRepository {
  Stream<Session?> watchSession();

  Future<Session?> getCurrentSession();

  Future<Session> signIn({required String provider});

  Future<void> signOut();

  Future<String?> getBackendToken(String firebaseUid);
}
