// lib/services/asknow_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AskNowService {
  static const String _baseUrl = 'https://jyotishasha-backend.onrender.com';

  // ------------------------------
  // Small helper
  // ------------------------------
  static Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'AskNow API error ${res.statusCode}: ${res.body.toString()}',
      );
    }
  }

  // Build BIRTH block from profile map
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
      "tz": profile["tz"] ?? "+05:30",
    };
  }

  // --------------------------------
  // 1) FREE QUESTION (once per day)
  // --------------------------------
  static Future<Map<String, dynamic>> askFreeQuestion({
    required int userId,
    required String question,
    required Map<String, dynamic> profile,
  }) async {
    final birth = buildBirthFromProfile(profile);

    final payload = {"user_id": userId, "question": question, "birth": birth};

    return _postJson("/api/chat/free", payload);
  }

  // --------------------------------
  // 2) CREATE ₹51 PACK ORDER
  // --------------------------------
  static Future<Map<String, dynamic>> createPackOrder({
    required int userId,
  }) async {
    final payload = {"user_id": userId};
    return _postJson("/api/chat/pack/order", payload);
  }

  // --------------------------------
  // 3) VERIFY PAYMENT (Razorpay)
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
    return _postJson("/asknow/verify", payload);
  }

  // --------------------------------
  // 4) ASK USING PAID PACK (tokens)
  // --------------------------------
  static Future<Map<String, dynamic>> askPaidQuestion({
    required int userId,
    required String question,
    required Map<String, dynamic> profile,
  }) async {
    final birth = buildBirthFromProfile(profile);

    final payload = {"user_id": userId, "question": question, "birth": birth};

    return _postJson("/api/chat/pack", payload);
  }
}
