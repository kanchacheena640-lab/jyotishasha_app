import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DailyProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  // API result fields
  String? aspectLine;
  String? remedyLine;
  String? combinedText;
  String? mainLine;

  // Moon info
  String? moonRashi;
  String? moonNakshatra;
  int? moonHouse;

  String? lagnaReturn;

  Future<void> fetchDaily({
    required String lagna,
    required double lat,
    required double lon,
    required String lang,
    String day = "today",
  }) async {
    isLoading = true;
    errorMessage = null;

    print("\n============================");
    print("🔥 DAILY HOROSCOPE REQUEST START");
    print("============================");

    notifyListeners();

    // 1️⃣ FIX — Capitalize Lagna
    lagna = lagna.isNotEmpty
        ? lagna[0].toUpperCase() + lagna.substring(1).toLowerCase()
        : lagna;

    print("📌 Cleaned Lagna = $lagna");

    final url = Uri.parse(
      "https://jyotishasha-backend.onrender.com/api/personalized/daily",
    );

    final payload = {
      "day": day,
      "lagna": lagna,
      "lat": lat,
      "lon": lon,
      "lang": lang,
    };

    print("📤 SENDING PAYLOAD:");
    print(payload);

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print("📥 RESPONSE STATUS: ${res.statusCode}");

      if (res.statusCode == 200) {
        print("📥 RAW RESPONSE BODY:");
        print(res.body);

        final data = jsonDecode(res.body);

        // -----------------------------
        // RESULT BLOCK
        // -----------------------------
        final result = data["result"] ?? {};
        aspectLine = result["aspect_line"];
        remedyLine = result["remedy_line"];
        combinedText = result["combined_text"];
        mainLine = result["main_line"];

        print("🟣 aspect_line → $aspectLine");
        print("🟢 main_line → $mainLine");
        print("🟡 combined_text → $combinedText");
        print("🔵 remedy_line → $remedyLine");

        // -----------------------------
        // MOON DATA
        // -----------------------------
        final moon = data["moon"] ?? {};
        moonRashi = moon["rashi"];
        moonNakshatra = moon["nakshatra"];
        moonHouse = moon["house"];

        print("🌙 Moon Rashi → $moonRashi");
        print("🌙 Moon Nakshatra → $moonNakshatra");
        print("🌙 Moon House → $moonHouse");

        lagnaReturn = data["lagna"];
        print("♎ Backend Returned Lagna → $lagnaReturn");

        print("✅ DAILY HOROSCOPE LOADED SUCCESSFULLY");
        print("============================\n");

        isLoading = false;
        notifyListeners();
      } else {
        errorMessage = "Server error: ${res.statusCode}";
        print("❌ SERVER ERROR = ${res.statusCode}");
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = "Error: $e";
      print("❌ EXCEPTION OCCURRED = $e");
      isLoading = false;
      notifyListeners();
    }
  }
}
