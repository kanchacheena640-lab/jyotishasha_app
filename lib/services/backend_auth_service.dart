import 'dart:convert';
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
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
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
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
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
