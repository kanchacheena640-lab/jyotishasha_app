import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'backend_auth_service.dart';

/// P0 -- Recover authenticated users with incomplete birth profiles.
///
/// Splash and Login previously used two different, backend-blind
/// signals to decide Dashboard vs. birth-detail setup (Splash: none at
/// all; Login: Firestore `profiles/default` doc existence only), which
/// let an authenticated user with an incomplete backend AppUser profile
/// (missing dob/tob/pob/lat/lng) reach Dashboard silently -- causing
/// Premium Report DNA generation to fail with HTTP 422.
///
/// `checkFailed` is a THIRD, distinct outcome from `complete` and
/// `incomplete` -- a network/backend failure must never be treated as
/// "profile incomplete" (that would force a genuinely complete user
/// through destructive re-onboarding on a transient blip) and must
/// never be silently treated as "complete" either (that would defeat
/// the whole point of this check). Callers must handle all three.
enum ProfileCompletenessStatus { complete, incomplete, checkFailed }

class ProfileCompletenessResult {
  const ProfileCompletenessResult(this.status);
  final ProfileCompletenessStatus status;

  bool get isComplete => status == ProfileCompletenessStatus.complete;
  bool get isIncomplete => status == ProfileCompletenessStatus.incomplete;
  bool get checkFailed => status == ProfileCompletenessStatus.checkFailed;
}

class ProfileCompletenessService {
  static const String baseUrl = "https://jyotishasha-backend.onrender.com";

  /// Calls GET /api/profile/completeness for the currently signed-in
  /// Firebase user. Requires a backend JWT (obtained the same way every
  /// other authenticated call in this app does, via
  /// BackendAuthService.getBackendToken), NOT the Firebase ID token
  /// directly -- this endpoint is @jwt_required(), matching the
  /// subscription-info/activate-trial routes it's modeled on.
  static Future<ProfileCompletenessResult> checkCompleteness({
    http.Client? client,
  }) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        // No signed-in user is not this service's concern to classify
        // -- callers only invoke this when a Firebase user IS present.
        return const ProfileCompletenessResult(
          ProfileCompletenessStatus.checkFailed,
        );
      }

      final backendToken = await BackendAuthService.getBackendToken(
        firebaseUser.uid,
        client: client,
      );
      if (backendToken == null) {
        // Token exchange itself failed (network/backend issue) -- a
        // check failure, not an incompleteness signal.
        return const ProfileCompletenessResult(
          ProfileCompletenessStatus.checkFailed,
        );
      }

      final url = Uri.parse("$baseUrl/api/profile/completeness");
      final ownsClient = client == null;
      final effectiveClient = client ?? http.Client();
      final http.Response res;
      try {
        res = await effectiveClient
            .get(
              url,
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $backendToken",
              },
            )
            // Same bound every other release-gate-hardened call in this
            // app uses (BackendAuthService.getBackendToken/registerFirebaseUser,
            // ReportService.sendReportRequest) -- a stalled/never-responding
            // request must not hang Splash/Login forever.
            .timeout(const Duration(seconds: 12));
      } finally {
        if (ownsClient) effectiveClient.close();
      }

      if (res.statusCode != 200) {
        return const ProfileCompletenessResult(
          ProfileCompletenessStatus.checkFailed,
        );
      }

      final data = jsonDecode(res.body);
      if (data is! Map<String, dynamic>) {
        return const ProfileCompletenessResult(
          ProfileCompletenessStatus.checkFailed,
        );
      }

      final complete = data["profile_complete"];
      if (complete == true) {
        return const ProfileCompletenessResult(
          ProfileCompletenessStatus.complete,
        );
      }
      if (complete == false) {
        return const ProfileCompletenessResult(
          ProfileCompletenessStatus.incomplete,
        );
      }

      // Unexpected shape -- treat as a check failure, never guess.
      return const ProfileCompletenessResult(
        ProfileCompletenessStatus.checkFailed,
      );
    } catch (_) {
      return const ProfileCompletenessResult(
        ProfileCompletenessStatus.checkFailed,
      );
    }
  }
}
