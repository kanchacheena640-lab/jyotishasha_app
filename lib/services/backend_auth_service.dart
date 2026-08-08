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

      final res = await http.post(
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
      );

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
  static Future<String?> getBackendToken(String firebaseUid) async {
    final url = Uri.parse("$baseUrl/api/auth/token");

    try {
      // Same compatibility fix as registerFirebaseUser() above: attach the
      // verified Firebase ID token as a Bearer header. Signature and every
      // existing caller of getBackendToken(firebaseUid) are unchanged.
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return null;

      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $idToken",
        },
        body: jsonEncode({"firebase_uid": firebaseUid}),
      );

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
