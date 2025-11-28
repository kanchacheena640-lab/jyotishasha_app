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

  // ===========================================================
  // PRIVATE: COMMON API CALL
  // ===========================================================
  Future<Map<String, dynamic>?> _callApi(
    String url,
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        errorMessage = "Server Error: ${res.statusCode}";
        return null;
      }
    } catch (e) {
      errorMessage = "Error: $e";
      return null;
    }
  }

  // ===========================================================
  // PUBLIC: DAILY API
  // ===========================================================
  Future<void> fetchDaily({
    required String lagna,
    required double lat,
    required double lon,
    required String lang,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final payload = {"lagna": lagna, "lat": lat, "lon": lon, "language": lang};

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

      final moon = data["moon"] ?? {};
      moonRashi = moon["rashi"];
      moonNakshatra = moon["nakshatra"];
      moonHouse = moon["house"];
      moonDegree = moon["degree"];
      moonMotion = moon["motion"];
    }

    isLoading = false;
    notifyListeners();
  }

  // ===========================================================
  // PUBLIC: TOMORROW API
  // ===========================================================
  Future<void> fetchTomorrow({
    required String lagna,
    required double lat,
    required double lon,
    required String lang,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final payload = {"lagna": lagna, "lat": lat, "lon": lon, "language": lang};

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
    }

    isLoading = false;
    notifyListeners();
  }
}
