import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:jyotishasha_app/services/backend_auth_service.dart';

import '../../models/account/account_deletion_contracts.dart';
import '../account_deletion_repository.dart';

/// D4 client for `POST /api/auth/delete-account` (backend D1–D3, locked).
///
/// OWNERSHIP (unchanged from the backend's own D0.1/D3 lock): the backend
/// is the sole authoritative owner of Firebase Auth/Firestore deletion.
/// This class NEVER calls `FirebaseAuth.currentUser.delete()` and never
/// touches Firestore — it only ever (a) reads a fresh Firebase ID token
/// to prove identity, and (b) sends one HTTP POST. Deleting the actual
/// Firebase user and Firestore documents happens exclusively server-side
/// (see `modules/auth/firebase_cleanup_service.py` in the backend repo).
///
/// AUTH: reuses the exact same two mechanisms every other authenticated
/// call in this app already uses — no second auth architecture:
///   - the backend JWT via [BackendAuthService.getBackendToken] (the same
///     helper [SubscriptionProvider]/[HttpAlertsDashboardRepository]/
///     [HttpPremiumAiReportRepository] already call), sent as
///     `Authorization: Bearer <jwt>`;
///   - a FRESH Firebase ID token (`user.getIdToken(true)` — force
///     refresh, per the backend's own "fresh proof" requirement, not a
///     cached token) sent as `X-Firebase-ID-Token: <token>`, the same
///     header name the backend route expects.
///
/// No request body is ever sent — this method never has an opportunity
/// to transmit `firebase_uid`/`user_id`/`profile_id`, by construction,
/// not merely by omission.
///
/// The two Firebase-touching lookups are injectable
/// ([fetchFreshFirebaseIdToken]/[fetchBackendToken]) purely so tests can
/// simulate "no signed-in user" / "token refresh failed" / "backend
/// token missing" with a plain closure — this codebase has no existing
/// FirebaseAuth/User mocking pattern to reuse, so a raw seam at this
/// level avoids inventing one. Production callers never need to pass
/// these; both default to the real Firebase/backend calls.
final class HttpAccountDeletionRepository implements AccountDeletionRepository {
  HttpAccountDeletionRepository({
    http.Client? client,
    Future<String?> Function()? fetchFreshFirebaseIdToken,
    Future<String?> Function()? fetchBackendToken,
  }) : _client = client ?? http.Client(),
       _fetchFreshFirebaseIdToken =
           fetchFreshFirebaseIdToken ?? _defaultFetchFreshFirebaseIdToken,
       _fetchBackendToken = fetchBackendToken ?? _defaultFetchBackendToken;

  static const String _baseUrl = 'https://jyotishasha-backend.onrender.com';

  final http.Client _client;
  final Future<String?> Function() _fetchFreshFirebaseIdToken;
  final Future<String?> Function() _fetchBackendToken;

  static Future<String?> _defaultFetchFreshFirebaseIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken(true); // force refresh -- Gate 4
  }

  static Future<String?> _defaultFetchBackendToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return BackendAuthService.getBackendToken(user.uid);
  }

  @override
  Future<AccountDeletionResult> deleteAccount() async {
    String? firebaseToken;
    try {
      firebaseToken = await _fetchFreshFirebaseIdToken();
    } catch (_) {
      firebaseToken = null;
    }
    if (firebaseToken == null || firebaseToken.isEmpty) {
      return AccountDeletionResult.failure(
        status: AccountDeletionStatus.authFailed,
        message: 'firebase_identity_unavailable',
      );
    }

    String? backendToken;
    try {
      backendToken = await _fetchBackendToken();
    } catch (_) {
      backendToken = null;
    }
    if (backendToken == null || backendToken.isEmpty) {
      return AccountDeletionResult.failure(
        status: AccountDeletionStatus.authFailed,
        message: 'backend_token_missing',
      );
    }

    final uri = Uri.parse('$_baseUrl/api/auth/delete-account');

    http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $backendToken',
          'X-Firebase-ID-Token': firebaseToken,
        },
      );
    } catch (e) {
      return AccountDeletionResult.failure(
        status: AccountDeletionStatus.networkError,
        message: e.toString(),
      );
    }

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {
      body = null;
    }

    switch (response.statusCode) {
      case 200:
        if (body == null || body['success'] != true) {
          return AccountDeletionResult.failure(
            status: AccountDeletionStatus.malformedResponse,
            message: 'unexpected_response_shape',
          );
        }
        final cleanupStatus =
            body['firebase_cleanup_status']?.toString() ?? 'pending';
        final alreadyDeleted = body['already_deleted'] == true;
        final hardDeleted =
            (body['hard_deleted_profile_count'] as num?)?.toInt() ?? 0;
        final anonymized =
            (body['anonymized_profile_count'] as num?)?.toInt() ?? 0;

        if (cleanupStatus == 'complete') {
          return AccountDeletionResult.success(
            alreadyDeleted: alreadyDeleted,
            hardDeletedProfileCount: hardDeleted,
            anonymizedProfileCount: anonymized,
            firebaseCleanupStatus: cleanupStatus,
          );
        }
        return AccountDeletionResult.pendingCleanup(
          alreadyDeleted: alreadyDeleted,
          hardDeletedProfileCount: hardDeleted,
          anonymizedProfileCount: anonymized,
          firebaseCleanupStatus: cleanupStatus,
        );

      case 401:
        return AccountDeletionResult.failure(
          status: AccountDeletionStatus.unauthorized,
          message: body?['message']?.toString(),
        );

      case 403:
        return AccountDeletionResult.failure(
          status: AccountDeletionStatus.forbidden,
          message: body?['message']?.toString(),
        );

      case 500:
        return AccountDeletionResult.failure(
          status: AccountDeletionStatus.serverError,
          message: body?['message']?.toString(),
        );

      default:
        return AccountDeletionResult.failure(
          status: AccountDeletionStatus.serverError,
          message: 'unexpected_status_${response.statusCode}',
        );
    }
  }
}
