import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class BackendAuthService {
  static const String baseUrl = "https://jyotishasha-backend.onrender.com";

  // 🔥 REGISTER / LINK USER
  static Future<int?> registerFirebaseUser({
    required String firebaseUid,
    String? email,
    String? phone,
    String? name,
    http.Client? client,
  }) async {
    final url = Uri.parse("$baseUrl/api/auth/register");

    try {
      // Bucket A compatibility fix: the backend now requires a verified
      // Firebase ID token (Authorization: Bearer <id_token>) instead of
      // trusting firebase_uid from the body. The ID token is obtained from
      // the currently signed-in Firebase user, right here, so no caller of
      // this method needs to change.
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return null;

      // Test-injection seam (Release-gate fix, P0): `client` is optional
      // and defaults to today's exact behavior (a fresh client per call,
      // same as the top-level `http.post` helper already did) -- no
      // existing caller passes it, so production behavior is unchanged.
      final ownsClient = client == null;
      final effectiveClient = client ?? http.Client();
      final http.Response res;
      try {
        res = await effectiveClient
            .post(
              url,
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $idToken",
              },
              body: jsonEncode({
                "firebase_uid": firebaseUid,
                "email": email,
                "phone": phone,
                "name": name,
              }),
            )
            // Release-gate fix (P0): a stalled/never-responding request
            // (Render cold start, dropped connection) previously hung this
            // await forever. TimeoutException flows into the existing
            // catch below exactly like any other failure -- same `null`
            // return, same contract.
            .timeout(const Duration(seconds: 12));
      } finally {
        if (ownsClient) effectiveClient.close();
      }

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["success"] == true) {
        return data["user_id"];
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // 🔥 NEW: GET BACKEND JWT TOKEN (IMPORTANT)
  static Future<String?> getBackendToken(
    String firebaseUid, {
    http.Client? client,
  }) async {
    final url = Uri.parse("$baseUrl/api/auth/token");

    try {
      // Same compatibility fix as registerFirebaseUser() above: attach the
      // verified Firebase ID token as a Bearer header. Signature and every
      // existing caller of getBackendToken(firebaseUid) are unchanged.
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return null;

      // Test-injection seam -- see registerFirebaseUser's identical
      // comment above.
      final ownsClient = client == null;
      final effectiveClient = client ?? http.Client();
      final http.Response res;
      try {
        res = await effectiveClient
            .post(
              url,
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $idToken",
              },
              body: jsonEncode({"firebase_uid": firebaseUid}),
            )
            // Release-gate fix (P0): see registerFirebaseUser's identical
            // comment above -- this token exchange gates purchase
            // confirmation across Subscription/AskNow/Report flows, so an
            // unbounded hang here previously left every caller's
            // isLoading/isPurchasing flag stuck forever.
            .timeout(const Duration(seconds: 12));
      } finally {
        if (ownsClient) effectiveClient.close();
      }

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return data["token"];
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
