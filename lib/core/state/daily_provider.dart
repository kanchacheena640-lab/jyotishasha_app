import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DailyProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  // -----------------------------
  // DAILY DATA
  // -----------------------------
  String? mainLine;
  String? aspectLine;
  String? remedyLine;
  String? combinedText;

  String? moonRashi;
  String? moonNakshatra;
  int? moonHouse;
  double? moonDegree;
  String? moonMotion;

  // -----------------------------
  // TOMORROW DATA
  // -----------------------------
  String? tMainLine;
  String? tAspectLine;
  String? tRemedyLine;
  String? tCombinedText;

  String? tMoonRashi;
  String? tMoonNakshatra;
  int? tMoonHouse;
  double? tMoonDegree;
  String? tMoonMotion;

  // ⭐ Lucky Fields
  String? luckyColor;
  String? luckyNumber;
  String? luckyDirection;

  // ===========================================================
  // PRIVATE: COMMON API CALL
  // ===========================================================
  Future<Map<String, dynamic>?> _callApi(
    String url,
    Map<String, dynamic> payload,
  ) async {
    try {
      print("🚀 API CALL → $url");
      print("📦 PAYLOAD → $payload");

      final res = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print("🌐 RESPONSE STATUS → ${res.statusCode}");
      print("🌐 RAW RESPONSE → ${res.body}");

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        errorMessage = "Server Error: ${res.statusCode}";
        return null;
      }
    } catch (e) {
      print("❌ API EXCEPTION → $e");
      errorMessage = "Error: $e";
      return null;
    }
  }

  // ===========================================================
  // DAILY API (backend ID compatible)
  // ===========================================================
  Future<void> fetchDaily({
    required String lagna,
    required double lat,
    required double lon,
    required String lang,
    required int? backendUserId,
    required int? backendProfileId,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    // ⭐ FINAL CLEAN PAYLOAD
    final payload = {"lagna": lagna, "lat": lat, "lon": lon, "lang": lang};

    if (backendUserId != null) {
      payload["backend_user_id"] = backendUserId;
    }
    if (backendProfileId != null) {
      payload["backend_profile_id"] = backendProfileId;
    }

    final data = await _callApi(
      "https://jyotishasha-backend.onrender.com/api/personalized/daily",
      payload,
    );

    if (data != null) {
      final result = data["result"] ?? {};

      mainLine = result["main_line"];
      aspectLine = result["aspect_line"];
      remedyLine = result["remedy_line"];
      combinedText = result["combined_text"];

      luckyColor = result["lucky_color"];
      luckyNumber = result["lucky_number"];
      luckyDirection = result["lucky_direction"];

      final moon = data["moon"] ?? {};
      moonRashi = moon["rashi"];
      moonNakshatra = moon["nakshatra"];
      moonHouse = moon["house"];
      moonDegree = moon["degree"];
      moonMotion = moon["motion"];

      print("🎉 DAILY UPDATED (lang = $lang)");
    }

    isLoading = false;
    notifyListeners();
  }

  // ===========================================================
  // TOMORROW API
  // ===========================================================
  Future<void> fetchTomorrow({
    required String lagna,
    required double lat,
    required double lon,
    required String lang,
    required int? backendUserId,
    required int? backendProfileId,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final payload = {"lagna": lagna, "lat": lat, "lon": lon, "lang": lang};

    if (backendUserId != null) {
      payload["backend_user_id"] = backendUserId;
    }
    if (backendProfileId != null) {
      payload["backend_profile_id"] = backendProfileId;
    }

    final data = await _callApi(
      "https://jyotishasha-backend.onrender.com/api/personalized/tomorrow",
      payload,
    );

    if (data != null) {
      final result = data["result"] ?? {};

      tMainLine = result["main_line"];
      tAspectLine = result["aspect_line"];
      tRemedyLine = result["remedy_line"];
      tCombinedText = result["combined_text"];

      final moon = data["moon"] ?? {};
      tMoonRashi = moon["rashi"];
      tMoonNakshatra = moon["nakshatra"];
      tMoonHouse = moon["house"];
      tMoonDegree = moon["degree"];
      tMoonMotion = moon["motion"];

      print("🎉 TOMORROW UPDATED (lang = $lang)");
    }

    isLoading = false;
    notifyListeners();
  }
}
