import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jyotishasha_app/services/backend_auth_service.dart';

class NotificationService {
  static const baseUrl = "https://jyotishasha-backend.onrender.com";

  // ===============================
  // 🔔 UNREAD COUNT
  // ===============================
  static Future<int> getUnreadCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ USER NULL");
      return 0;
    }

    try {
      final firebaseUid = user.uid;
      print("🔥 FIREBASE UID: $firebaseUid");

      final token = await BackendAuthService.getBackendToken(firebaseUid);
      print("🔥 TOKEN: $token");

      if (token == null) {
        print("❌ TOKEN NULL");
        return 0;
      }

      final res = await http.get(
        Uri.parse("$baseUrl/api/user-notifications/unread-count"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("🔥 STATUS: ${res.statusCode}");
      print("🔥 RESPONSE: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data["unread_count"] ?? 0;
      }

      return 0;
    } catch (e) {
      print("❌ Unread count error: $e");
      return 0;
    }
  }

  // ===============================
  // 📄 GET NOTIFICATIONS LIST
  // ===============================
  static Future<List> getNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final firebaseUid = user.uid;
      final token = await BackendAuthService.getBackendToken(firebaseUid);
      print("FIREBASE UID: $firebaseUid");
      print("TOKEN: $token");

      if (token == null) return [];

      final res = await http.get(
        Uri.parse("$baseUrl/api/user-notifications"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // 🔥 SAFE PARSE (important)
        if (data is List) {
          return data;
        } else if (data["notifications"] != null) {
          return data["notifications"];
        }
      }

      return [];
    } catch (e) {
      print("❌ Get notifications error: $e");
      return [];
    }
  }

  // ===============================
  // ✅ MARK AS READ
  // ===============================
  static Future<void> markAsRead(int notificationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final firebaseUid = user.uid;
      final token = await BackendAuthService.getBackendToken(firebaseUid);

      if (token == null) return;

      await http.post(
        Uri.parse("$baseUrl/api/user-notifications/mark-read"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"notification_id": notificationId}),
      );
    } catch (e) {
      print("❌ Mark as read error: $e");
    }
  }
}
