import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TransitProvider extends ChangeNotifier {
  bool isLoading = false;
  Map<String, dynamic>? transitData;
  Map<String, dynamic>? contentData;
  String? errorMessage;
  String savedLang = "en";

  final Map<String, int> rashiToNumber = {
    "Aries": 1,
    "Taurus": 2,
    "Gemini": 3,
    "Cancer": 4,
    "Leo": 5,
    "Virgo": 6,
    "Libra": 7,
    "Scorpio": 8,
    "Sagittarius": 9,
    "Capricorn": 10,
    "Aquarius": 11,
    "Pisces": 12,
  };

  TransitProvider() {
    fetchTransit();
  }

  /// PLANET LIST BUILDER
  List<Map<String, dynamic>> get allPlanets {
    if (transitData == null) return [];

    final positions = transitData?["positions"];
    final future = transitData?["future_transits"];

    if (positions == null) return [];

    List<Map<String, dynamic>> planetList = [];

    final keys = [
      "Sun",
      "Moon",
      "Mars",
      "Mercury",
      "Jupiter",
      "Venus",
      "Saturn",
      "Rahu",
      "Ketu",
    ];

    for (var key in keys) {
      var data = positions[key];

      if (data != null) {
        String rashiName = data["rashi"] ?? "Aries";

        String nextDate = "--";

        if (future != null &&
            future[key] != null &&
            future[key] is List &&
            future[key].isNotEmpty) {
          nextDate = future[key][0]["entering_date"]?.toString() ?? "--";
        }

        planetList.add({
          "name": key,
          "rashi": rashiName,
          "rashi_number": rashiToNumber[rashiName] ?? 1,
          "degree": data["degree"]?.toString() ?? "0",
          "motion": data["motion"] ?? "Direct",
          "next_change": nextDate,
        });
      }
    }

    return planetList;
  }

  /// FEATURED PLANET (used by TransitContentPage)
  Map<String, dynamic>? get featuredPlanet {
    if (allPlanets.isEmpty) return null;
    return allPlanets.firstWhere(
      (p) => p["name"] == "Sun",
      orElse: () => allPlanets.first,
    );
  }

  /// API 1 → CURRENT PLANETS
  Future<void> fetchTransit() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await http
          .get(
            Uri.parse(
              "https://jyotishasha-backend.onrender.com/api/transit/current",
            ),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        transitData = jsonDecode(res.body);
      } else {
        errorMessage = "Server Error: ${res.statusCode}";
      }
    } catch (e) {
      errorMessage = "Connection Error: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// API 2 → PERSONALIZED TRANSIT CONTENT
  Future<void> fetchTransitContent({
    required String ascendant,
    required String planet,
    required int lagnaRashi,
    required int planetRashi,
    required String lang,
  }) async {
    isLoading = true;
    contentData = null;
    errorMessage = null;
    savedLang = lang;
    notifyListeners();

    try {
      int house = (planetRashi - lagnaRashi + 12) % 12 + 1;

      final url =
          Uri.parse(
            "https://jyotishasha-backend.onrender.com/api/transit",
          ).replace(
            queryParameters: {
              "ascendant": ascendant,
              "planet": planet,
              "house": house.toString(),
              "lang": lang,
            },
          );

      final res = await http.get(url).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        contentData = jsonDecode(res.body);
      } else {
        errorMessage = "Content API Error: ${res.statusCode}";
      }
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  /// CONTENT HELPER
  String get summaryText =>
      contentData?["summary"] ??
      "Select a planet to see your personalized impact.";
}
