import '../models/account/account_deletion_contracts.dart';

/// Purpose: owns access to the account-deletion API
/// (`POST /api/auth/delete-account`, backend D1–D3 — Jyotishasha_Backend).
/// The backend is the sole authoritative owner of Firebase Auth/Firestore
/// deletion; this repository never calls `FirebaseAuth.currentUser.delete()`
/// or deletes any Firestore document itself — see
/// `HttpAccountDeletionRepository`'s own docstring.
///
/// Responsibilities: send the deletion request for the caller's own,
/// currently-authenticated account (identity resolved server-side from
/// the backend JWT + a freshly-verified Firebase ID token — no
/// `firebase_uid`/`user_id`/`profile_id` is ever sent).
///
/// Excluded responsibilities: confirmation UX, local session
/// teardown/navigation, retry policy/scheduling — all owned by the
/// caller (`AccountPage`).
abstract interface class AccountDeletionRepository {
  Future<AccountDeletionResult> deleteAccount();
}
