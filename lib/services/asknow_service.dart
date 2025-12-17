import 'dart:convert';
import 'package:http/http.dart' as http;

class AskNowService {
  static const String _baseUrl = 'https://jyotishasha-backend.onrender.com';

  // =====================================================
  // 🔹 INTERNAL: POST JSON + CLEAN CHAT ANSWER (FINAL)
  // =====================================================
  static Future<Map<String, dynamic>> _postJsonCleanAnswer(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$_baseUrl$path');

    final res = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('AskNow API error ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;

    // -------- CLEAN ANSWER EXTRACTION (LOCKED LOGIC) --------
    String cleanAnswer = "";

    final dynamic rawAnswer = decoded["answer"];

    if (rawAnswer is Map<String, dynamic>) {
      cleanAnswer = rawAnswer["answer"]?.toString().trim() ?? "";
    } else if (rawAnswer is String) {
      cleanAnswer = rawAnswer.trim();
    }

    // ✅ first try backend message
    if (cleanAnswer.isEmpty) {
      cleanAnswer = (decoded["message"] ?? "").toString().trim();
    }

    // ✅ final fallback only
    if (cleanAnswer.isEmpty) {
      cleanAnswer = "Your answer is being prepared. Please try again.";
    }

    // -------- REMAINING TOKENS NORMALIZATION --------
    final int remainingTokens =
        int.tryParse(
          (decoded["remaining_tokens"] ??
                  decoded["remaining"] ??
                  decoded["remaining_questions"] ??
                  decoded["tokens_left"] ??
                  0)
              .toString(),
        ) ??
        0;

    return {
      "success": decoded["success"] ?? true,
      "answer": cleanAnswer,
      "remaining_tokens": remainingTokens,
      "message": decoded["message"],
    };
  }

  // =====================================================
  // 🔹 BUILD BIRTH BLOCK (SINGLE SOURCE)
  // =====================================================
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

  // =====================================================
  // 🔹 FREE QUESTION  (SMARTCHAT)
  // =====================================================
  static Future<Map<String, dynamic>> askFreeQuestion({
    required int userId,
    required String question,
    required Map<String, dynamic> profile,
  }) {
    return _postJsonCleanAnswer("/api/smartchat", {
      "question": question,
      "birth": buildBirthFromProfile(profile),
    });
  }

  // =====================================================
  // 🔹 PAID QUESTION (CHAT PACK)
  // =====================================================
  static Future<Map<String, dynamic>> askPaidQuestion({
    required int userId,
    required String question,
    required Map<String, dynamic> profile,
  }) {
    return _postJsonCleanAnswer("/api/chat/pack", {
      "user_id": userId,
      "question": question,
      "birth": buildBirthFromProfile(profile),
    });
  }

  // =====================================================
  // 🔹 CHAT STATUS (FREE + TOKENS)
  // =====================================================
  static Future<Map<String, dynamic>> fetchChatStatus(int userId) async {
    final res = await http.post(
      Uri.parse("$_baseUrl/api/chat/status"),
      headers: const {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Status API error ${res.statusCode}: ${res.body}");
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // =====================================================
  // 🔹 REWARD QUESTION (ADS) — NORMALIZED
  // =====================================================
  static Future<Map<String, dynamic>> addRewardQuestion(int userId) async {
    final res = await http.post(
      Uri.parse("$_baseUrl/api/chat/reward"),
      headers: const {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Reward API error ${res.statusCode}: ${res.body}");
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;

    final int totalTokens =
        int.tryParse(
          (decoded["total_tokens"] ??
                  decoded["remaining_tokens"] ??
                  decoded["remaining"] ??
                  0)
              .toString(),
        ) ??
        0;

    return {
      "success": decoded["success"] ?? true,
      "added_tokens": 1, // 🔒 reward = +1 usable question
      "total_tokens": totalTokens,
    };
  }
}
