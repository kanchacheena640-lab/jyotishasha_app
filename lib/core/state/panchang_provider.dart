import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PanchangProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  /// FULL Panchang JSON (selected_date)
  Map<String, dynamic>? fullPanchang;

  /// Cache control
  String? lastFetchDate;
  double savedLat = 26.8467;
  double savedLng = 80.9462;

  /// user's language
  String savedLang = "en";

  /// Reset after 4 AM
  final int cacheResetHour = 4;

  // ------------------------------------------------------------
  // SMART LOAD — Call anywhere (Dashboard, Greeting, etc)
  // ------------------------------------------------------------
  Future<void> loadPanchang({
    double? lat,
    double? lng,
    required String lang, // ⭐ NEW: language required
  }) async {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    // reset cache at 4 AM
    if (_shouldResetCache(now)) {
      fullPanchang = null;
      lastFetchDate = null;
    }

    // STORE LANGUAGE ALWAYS
    savedLang = lang;

    // same location + same date + same language → no API call
    if (lastFetchDate == today &&
        fullPanchang != null &&
        savedLang == lang &&
        (lat == null || lat == savedLat) &&
        (lng == null || lng == savedLng)) {
      return;
    }

    await fetchPanchang(lat: lat ?? savedLat, lng: lng ?? savedLng, lang: lang);
  }

  // ------------------------------------------------------------
  // REAL API CALL
  // ------------------------------------------------------------
  Future<void> fetchPanchang({
    required double lat,
    required double lng,
    required String lang,
  }) async {
    isLoading = true;
    notifyListeners();

    savedLat = lat;
    savedLng = lng;
    savedLang = lang;

    const endpoint = "https://jyotishasha-backend.onrender.com/api/panchang";
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final body = {
      "latitude": lat,
      "longitude": lng,
      "date": today,
      "language": lang, // ⭐ SEND LANGUAGE TO BACKEND
    };

    try {
      final res = await http.post(
        Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        fullPanchang = decoded["selected_date"];
        lastFetchDate = today;
      } else {
        errorMessage = "Server error ${res.statusCode}";
      }
    } catch (e) {
      errorMessage = "Network error: $e";
    }

    isLoading = false;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // Cache reset helper
  // ------------------------------------------------------------
  bool _shouldResetCache(DateTime now) {
    if (lastFetchDate == null) return true;

    final last = DateTime.parse(lastFetchDate!);
    final today = DateTime(now.year, now.month, now.day);

    if (now.isAfter(
          DateTime(today.year, today.month, today.day, cacheResetHour),
        ) &&
        last.isBefore(today)) {
      return true;
    }

    return false;
  }

  // ------------------------------------------------------------
  // SAFE UI GETTERS — Always return string for widgets
  // ------------------------------------------------------------

  String get sunrise => fullPanchang?["sunrise"] ?? "--";
  String get sunset => fullPanchang?["sunset"] ?? "--";

  String get tithiName => fullPanchang?["tithi"]?["name"] ?? "--";
  String get tithiPaksha => fullPanchang?["tithi"]?["paksha"] ?? "--";

  String get nakshatra => fullPanchang?["nakshatra"]?["name"] ?? "--";
  String get nakshatraPada =>
      fullPanchang?["nakshatra"]?["pada"]?.toString() ?? "--";

  String get weekday => fullPanchang?["weekday"] ?? "--";
  String get monthName => fullPanchang?["month_name"] ?? "--";

  String get abhijitStart => fullPanchang?["abhijit_muhurta"]?["start"] ?? "--";
  String get abhijitEnd => fullPanchang?["abhijit_muhurta"]?["end"] ?? "--";

  String get rahukaalStart => fullPanchang?["rahu_kaal"]?["start"] ?? "--";
  String get rahukaalEnd => fullPanchang?["rahu_kaal"]?["end"] ?? "--";

  String get panchakMessage => fullPanchang?["panchak"]?["message"] ?? "--";

  String get yoga => fullPanchang?["yoga"]?["name"] ?? "--";
  String get karan => fullPanchang?["karan"]?["name"] ?? "--";

  bool get hasError => errorMessage != null;
}
