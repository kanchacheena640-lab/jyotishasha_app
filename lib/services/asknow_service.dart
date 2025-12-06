// lib/services/asknow_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AskNowService {
  static const String _baseUrl = 'https://jyotishasha-backend.onrender.com';

  // ------------------------------
  // Small helper (ONLY for chat answers)
  // ------------------------------
  static Future<Map<String, dynamic>> _postJsonCleanAnswer(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('AskNow API error ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;

    // Cleaned answer for chat endpoints only
    final clean = <String, dynamic>{
      "success": decoded["success"] ?? true,
      "answer": decoded["answer"] ?? "",
      "remaining_tokens":
          decoded["remaining_tokens"] ??
          decoded["remaining"] ??
          decoded["remaining_questions"] ??
          decoded["tokens_left"],
      "message": decoded["message"],
    };

    return clean;
  }

  // Build BIRTH block
  static Map<String, dynamic> buildBirthFromProfile(
    Map<String, dynamic> profile,
  ) {
    return {
      "name": profile["name"] ?? "User",
      "dob": profile["dob"] ?? "",
      "tob": profile["tob"] ?? "",
      "pob":
          profile["pob"] ?? profile["place_name"] ?? profile["placeName"] ?? "",
      "lat": profile["lat"] ?? profile["latitude"] ?? 0.0,
      "lng": profile["lng"] ?? profile["longitude"] ?? 0.0,
      "timezone": profile["timezone"] ?? profile["tz"] ?? "+05:30",
    };
  }

  // --------------------------------
  // 1) FREE QUESTION  (CLEANED ANSWER)
  // --------------------------------
  static Future<Map<String, dynamic>> askFreeQuestion({
    required int userId,
    required String question,
    required Map<String, dynamic> profile,
  }) async {
    final birth = buildBirthFromProfile(profile);

    final payload = {"user_id": userId, "question": question, "birth": birth};

    // ✅ Free chat bhi ab paid jaisa cleaned JSON hi dega
    return _postJsonCleanAnswer("/api/chat/free", payload);
  }

  // --------------------------------
  // 2) CREATE PACK ORDER  (KEEP FULL ORDER JSON)
  // --------------------------------
  static Future<Map<String, dynamic>> createPackOrder({
    required int userId,
  }) async {
    final payload = {"user_id": userId};

    final uri = Uri.parse("$_baseUrl/api/chat/pack/order");

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Pack order API error ${res.statusCode}: ${res.body}");
    }

    // yahan nested "order" waala JSON chahiye as-is
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return decoded; // { success, order: {...} }
  }

  // --------------------------------
  // 3) VERIFY PAYMENT  (KEEP FULL RESULT JSON)
  // --------------------------------
  static Future<Map<String, dynamic>> verifyPayment({
    required int userId,
    required String orderId,
    required String paymentId,
  }) async {
    final payload = {
      "user_id": userId,
      "order_id": orderId,
      "payment_id": paymentId,
    };

    final uri = Uri.parse("$_baseUrl/asknow/verify");

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Verify API error ${res.statusCode}: ${res.body}");
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return decoded; // { success, result: { success, total_tokens, ... } }
  }

  // --------------------------------
  // 4) ASK FROM PAID PACK (CLEANED ANSWER)
  // --------------------------------
  static Future<Map<String, dynamic>> askPaidQuestion({
    required int userId,
    required String question,
    required Map<String, dynamic> profile,
  }) async {
    final birth = buildBirthFromProfile(profile);

    final payload = {"user_id": userId, "question": question, "birth": birth};

    return _postJsonCleanAnswer("/api/chat/pack", payload);
  }

  // ------------------------------------------------------
  // NEW: Get free + tokens status from backend
  // ------------------------------------------------------
  static Future<Map<String, dynamic>> fetchChatStatus(int userId) async {
    final uri = Uri.parse("$_baseUrl/api/chat/status");

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId}),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception("Status API error ${res.statusCode}: ${res.body}");
    }
  }

  // ⭐ ADD: Reward question API call
  static Future<Map<String, dynamic>> addRewardQuestion(int userId) async {
    try {
      final res = await http.post(
        Uri.parse("$_baseUrl/api/chat/reward"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId}),
      );

      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {"success": false, "message": "Reward API error: $e"};
    }
  }
}
