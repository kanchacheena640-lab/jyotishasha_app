// D4 Gate 7 -- HttpAccountDeletionRepository, in isolation.
//
// NO REAL FIREBASE OR NETWORK CALL IS EVER MADE. HTTP is faked via
// package:http/testing.dart's MockClient (part of the `http` package
// this app already depends on -- no new test dependency). Firebase
// token/backend-token retrieval is faked via the repository's own
// injectable closures -- this codebase has no existing
// FirebaseAuth/User mocking pattern, so that seam avoids inventing one.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:jyotishasha_app/core/models/account/account_deletion_contracts.dart';
import 'package:jyotishasha_app/core/repositories/implementations/http_account_deletion_repository.dart';

void main() {
  const backendToken = 'fake-backend-jwt';
  const firebaseToken = 'fake-fresh-firebase-id-token';

  HttpAccountDeletionRepository buildRepo({
    required MockClientHandler handler,
    Future<String?> Function()? fetchFreshFirebaseIdToken,
    Future<String?> Function()? fetchBackendToken,
  }) {
    return HttpAccountDeletionRepository(
      client: MockClient(handler),
      fetchFreshFirebaseIdToken:
          fetchFreshFirebaseIdToken ?? () async => firebaseToken,
      fetchBackendToken: fetchBackendToken ?? () async => backendToken,
    );
  }

  group('request shape (Gate 2 — fresh token / backend JWT / no identity in body)', () {
    test('sends a fresh Firebase ID token as X-Firebase-ID-Token', () async {
      http.Request? captured;
      final repo = buildRepo(
        handler: (req) async {
          captured = req;
          return http.Response(
            jsonEncode({
              'success': true,
              'already_deleted': false,
              'hard_deleted_profile_count': 1,
              'anonymized_profile_count': 0,
              'firebase_cleanup_status': 'complete',
            }),
            200,
          );
        },
      );

      await repo.deleteAccount();

      expect(captured, isNotNull);
      expect(captured!.headers['X-Firebase-ID-Token'], firebaseToken);
    });

    test('sends the backend JWT as Authorization: Bearer <jwt>', () async {
      http.Request? captured;
      final repo = buildRepo(
        handler: (req) async {
          captured = req;
          return http.Response(
            jsonEncode({
              'success': true,
              'already_deleted': false,
              'hard_deleted_profile_count': 1,
              'anonymized_profile_count': 0,
              'firebase_cleanup_status': 'complete',
            }),
            200,
          );
        },
      );

      await repo.deleteAccount();

      expect(captured!.headers['Authorization'], 'Bearer $backendToken');
    });

    test(
      'never sends firebase_uid/user_id/profile_id — no request body at '
      'all, and no query parameters',
      () async {
        http.Request? captured;
        final repo = buildRepo(
          handler: (req) async {
            captured = req;
            return http.Response(
              jsonEncode({
                'success': true,
                'already_deleted': false,
                'hard_deleted_profile_count': 1,
                'anonymized_profile_count': 0,
                'firebase_cleanup_status': 'complete',
              }),
              200,
            );
          },
        );

        await repo.deleteAccount();

        expect(captured!.body, isEmpty);
        expect(captured!.url.queryParameters, isEmpty);
        expect(captured!.url.path, '/api/auth/delete-account');
      },
    );
  });

  group('response parsing (Gate 5)', () {
    test('full success -> status.success, isFullSuccess true', () async {
      final repo = buildRepo(
        handler: (_) async => http.Response(
          jsonEncode({
            'success': true,
            'already_deleted': false,
            'hard_deleted_profile_count': 2,
            'anonymized_profile_count': 0,
            'firebase_cleanup_status': 'complete',
          }),
          200,
        ),
      );

      final result = await repo.deleteAccount();

      expect(result.status, AccountDeletionStatus.success);
      expect(result.isFullSuccess, isTrue);
      expect(result.hardDeletedProfileCount, 2);
    });

    test(
      'success=true but firebase_cleanup_status=pending -> pendingCleanup, '
      'NOT full success',
      () async {
        final repo = buildRepo(
          handler: (_) async => http.Response(
            jsonEncode({
              'success': true,
              'already_deleted': false,
              'hard_deleted_profile_count': 0,
              'anonymized_profile_count': 1,
              'firebase_cleanup_status': 'pending',
            }),
            200,
          ),
        );

        final result = await repo.deleteAccount();

        expect(result.status, AccountDeletionStatus.pendingCleanup);
        expect(result.isFullSuccess, isFalse);
        expect(result.isPendingCleanup, isTrue);
      },
    );

    test('401 -> unauthorized', () async {
      final repo = buildRepo(
        handler: (_) async => http.Response(
          jsonEncode({'error': 'reauthentication_required', 'message': 'nope'}),
          401,
        ),
      );

      final result = await repo.deleteAccount();

      expect(result.status, AccountDeletionStatus.unauthorized);
    });

    test('403 -> forbidden', () async {
      final repo = buildRepo(
        handler: (_) async => http.Response(
          jsonEncode({'error': 'identity_mismatch', 'message': 'nope'}),
          403,
        ),
      );

      final result = await repo.deleteAccount();

      expect(result.status, AccountDeletionStatus.forbidden);
    });

    test('500 -> serverError', () async {
      final repo = buildRepo(
        handler: (_) async => http.Response(
          jsonEncode({'error': 'deletion_failed', 'message': 'nope'}),
          500,
        ),
      );

      final result = await repo.deleteAccount();

      expect(result.status, AccountDeletionStatus.serverError);
    });

    test('network failure (client throws) -> networkError', () async {
      final repo = buildRepo(
        handler: (_) async => throw Exception('simulated socket error'),
      );

      final result = await repo.deleteAccount();

      expect(result.status, AccountDeletionStatus.networkError);
    });

    test('malformed response (invalid JSON body) -> malformedResponse', () async {
      final repo = buildRepo(
        handler: (_) async => http.Response('not-json{{{', 200),
      );

      final result = await repo.deleteAccount();

      expect(result.status, AccountDeletionStatus.malformedResponse);
    });

    test(
      'malformed response (200 but missing success field) -> malformedResponse',
      () async {
        final repo = buildRepo(
          handler: (_) async =>
              http.Response(jsonEncode({'unexpected': 'shape'}), 200),
        );

        final result = await repo.deleteAccount();

        expect(result.status, AccountDeletionStatus.malformedResponse);
      },
    );
  });

  group('pre-flight auth failures (Gate 4) — request must never be sent', () {
    test('no signed-in Firebase user -> authFailed, HTTP never called', () async {
      var called = false;
      final repo = buildRepo(
        handler: (_) async {
          called = true;
          return http.Response('{}', 200);
        },
        fetchFreshFirebaseIdToken: () async => null,
      );

      final result = await repo.deleteAccount();

      expect(result.status, AccountDeletionStatus.authFailed);
      expect(called, isFalse);
    });

    test('Firebase token refresh failure -> authFailed, HTTP never called', () async {
      var called = false;
      final repo = buildRepo(
        handler: (_) async {
          called = true;
          return http.Response('{}', 200);
        },
        fetchFreshFirebaseIdToken: () async =>
            throw Exception('simulated refresh failure'),
      );

      final result = await repo.deleteAccount();

      expect(result.status, AccountDeletionStatus.authFailed);
      expect(called, isFalse);
    });

    test('backend token missing -> authFailed, HTTP never called', () async {
      var called = false;
      final repo = buildRepo(
        handler: (_) async {
          called = true;
          return http.Response('{}', 200);
        },
        fetchBackendToken: () async => null,
      );

      final result = await repo.deleteAccount();

      expect(result.status, AccountDeletionStatus.authFailed);
      expect(called, isFalse);
    });
  });
}
