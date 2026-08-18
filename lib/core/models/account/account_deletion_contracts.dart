// lib/core/models/account/account_deletion_contracts.dart

/// Typed contract for `POST /api/auth/delete-account` — the backend
/// endpoint locked by D1–D3 (Jyotishasha_Backend). A client branches on
/// [AccountDeletionResult.status], never on the raw HTTP code directly,
/// matching this app's existing repository conventions (e.g.
/// `AlertsDashboardResult`).
///
/// This screen never sends `firebase_uid`/`user_id`/`profile_id` as a
/// deletion target — the backend derives the target exclusively from the
/// authenticated JWT + a freshly-verified Firebase ID token (see
/// `HttpAccountDeletionRepository`). Nothing in this contract carries an
/// identity field at all, by design.
enum AccountDeletionStatus {
  /// `success == true` AND `firebase_cleanup_status == "complete"` — the
  /// full A–E deletion sequence (D3) has finished. Safe to sign the user
  /// out locally and return to the login screen.
  success,

  /// `success == true` but `firebase_cleanup_status != "complete"`
  /// (currently only `"pending"`). The backend's DB-side deletion
  /// already committed — this is NOT a failure — but Firebase-side
  /// cleanup has not yet been confirmed. Must NOT be presented as
  /// ordinary full success, and the retry path (re-issuing this same
  /// request) must remain available — see D3's own retry design.
  pendingCleanup,

  /// HTTP 401 — the backend rejected the JWT and/or the fresh Firebase
  /// proof. Local state must be left untouched; the user may retry or
  /// sign in again.
  unauthorized,

  /// HTTP 403 — the freshly-verified Firebase identity did not match
  /// the authenticated account. Local state must be left untouched.
  forbidden,

  /// HTTP 500, or any other unexpected status code. Nothing on the
  /// backend is assumed to have changed.
  serverError,

  /// The request itself could not be completed (no connectivity, DNS,
  /// timeout, etc.). Nothing is assumed to have changed.
  networkError,

  /// A 200 response was received but its body did not match the locked
  /// contract (missing/invalid `success`, unparsable JSON, ...).
  /// Treated as a safe failure, never as success.
  malformedResponse,

  /// The request was never sent at all: no signed-in Firebase user, a
  /// fresh Firebase ID token could not be obtained, or no backend JWT
  /// was available. Distinct from every status above because the
  /// backend was never actually contacted.
  authFailed,
}

class AccountDeletionResult {
  const AccountDeletionResult._({
    required this.status,
    this.alreadyDeleted = false,
    this.hardDeletedProfileCount = 0,
    this.anonymizedProfileCount = 0,
    this.firebaseCleanupStatus,
    this.message,
  });

  factory AccountDeletionResult.success({
    required bool alreadyDeleted,
    required int hardDeletedProfileCount,
    required int anonymizedProfileCount,
    required String firebaseCleanupStatus,
  }) => AccountDeletionResult._(
    status: AccountDeletionStatus.success,
    alreadyDeleted: alreadyDeleted,
    hardDeletedProfileCount: hardDeletedProfileCount,
    anonymizedProfileCount: anonymizedProfileCount,
    firebaseCleanupStatus: firebaseCleanupStatus,
  );

  factory AccountDeletionResult.pendingCleanup({
    required bool alreadyDeleted,
    required int hardDeletedProfileCount,
    required int anonymizedProfileCount,
    required String firebaseCleanupStatus,
  }) => AccountDeletionResult._(
    status: AccountDeletionStatus.pendingCleanup,
    alreadyDeleted: alreadyDeleted,
    hardDeletedProfileCount: hardDeletedProfileCount,
    anonymizedProfileCount: anonymizedProfileCount,
    firebaseCleanupStatus: firebaseCleanupStatus,
  );

  factory AccountDeletionResult.failure({
    required AccountDeletionStatus status,
    String? message,
  }) => AccountDeletionResult._(status: status, message: message);

  final AccountDeletionStatus status;

  /// Only meaningful on [success]/[pendingCleanup] — the backend's own
  /// `already_deleted` (a safe, idempotent replay of a prior call).
  final bool alreadyDeleted;
  final int hardDeletedProfileCount;
  final int anonymizedProfileCount;

  /// The backend's own raw `firebase_cleanup_status` string
  /// (`"complete"` / `"pending"`), preserved verbatim for diagnostics —
  /// the UI itself only ever branches on [status] above.
  final String? firebaseCleanupStatus;

  /// The backend's own `message` field when present, or a short internal
  /// reason code for client-only failures (never shown to the user
  /// verbatim without localized wrapping).
  final String? message;

  bool get isFullSuccess => status == AccountDeletionStatus.success;
  bool get isPendingCleanup => status == AccountDeletionStatus.pendingCleanup;
}
