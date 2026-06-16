import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PanchangProvider extends ChangeNotifier {
  Timer? _clockTimer;

  bool isLoading = false;
  String? errorMessage;

  Map<String, dynamic>? fullPanchang; // ← purana naam
  Map<String, dynamic>? nextPanchang;

  String? lastFetchDate;
  String? lastLang;

  double savedLat = 26.8467;
  double savedLng = 80.9462;

  final int cacheResetHour = 4;

  PanchangProvider() {
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      notifyListeners();
    });
  }

  // =============================================================
  // LOAD
  // =============================================================
  Future<void> loadPanchang({
    double? lat,
    double? lng,
    required String lang,
  }) async {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    if (_shouldResetCache(now)) {
      fullPanchang = null;
      nextPanchang = null;
      lastFetchDate = null;
      lastLang = null;
    }

    if (lastFetchDate == today &&
        lastLang == lang &&
        fullPanchang != null &&
        (lat == null || (lat - savedLat).abs() < 0.0001) &&
        (lng == null || (lng - savedLng).abs() < 0.0001)) {
      return;
    }

    await fetchPanchang(lat: lat ?? savedLat, lng: lng ?? savedLng, lang: lang);
  }

  // =============================================================
  // FETCH
  // =============================================================
  Future<void> fetchPanchang({
    required double lat,
    required double lng,
    required String lang,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    savedLat = lat;
    savedLng = lng;

    const String endpoint =
        "https://jyotishasha-backend.onrender.com/api/panchang";

    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final body = {
      "latitude": lat,
      "longitude": lng,
      "date": today,
      "language": lang,
    };

    try {
      final res = await http.post(
        Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        fullPanchang = decoded["selected_date"] as Map<String, dynamic>?;
        nextPanchang = decoded["next_date"] as Map<String, dynamic>?;

        if (fullPanchang != null) {
          lastFetchDate = today;
          lastLang = lang;
          errorMessage = null;
        } else {
          errorMessage = "Invalid panchang data";
        }
      } else {
        errorMessage = "Server error: ${res.statusCode}";
      }
    } catch (e) {
      errorMessage = "Network error: $e";
    }

    isLoading = false;
    notifyListeners();
  }

  bool _shouldResetCache(DateTime now) {
    if (lastFetchDate == null) return true;

    final last = DateTime.parse(lastFetchDate!);
    final today = DateTime(now.year, now.month, now.day);
    final resetTime = DateTime(now.year, now.month, now.day, cacheResetHour);

    return now.isAfter(resetTime) && last.isBefore(today);
  }

  // =============================================================
  // GETTERS (Purane naam ke hisaab se)
  // =============================================================
  String get sunrise => fullPanchang?["sunrise"]?.toString() ?? "--";
  String get sunset => fullPanchang?["sunset"]?.toString() ?? "--";

  String get tithiName => fullPanchang?["tithi"]?["name"]?.toString() ?? "--";
  String get tithiPaksha =>
      fullPanchang?["tithi"]?["paksha"]?.toString() ?? "--";

  String get nakshatra =>
      fullPanchang?["nakshatra"]?["name"]?.toString() ?? "--";
  String get weekday => fullPanchang?["weekday"]?.toString() ?? "--";
  String get monthName => fullPanchang?["month_name"]?.toString() ?? "--";

  String get yoga => fullPanchang?["yoga"]?["name"]?.toString() ?? "--";
  String get karan => fullPanchang?["karan"]?["name"]?.toString() ?? "--";

  String get rahukaalStart =>
      fullPanchang?["rahu_kaal"]?["start"]?.toString() ?? "--";
  String get rahukaalEnd =>
      fullPanchang?["rahu_kaal"]?["end"]?.toString() ?? "--";

  String get abhijitStart =>
      fullPanchang?["abhijit_muhurta"]?["start"]?.toString() ?? "--";
  String get abhijitEnd =>
      fullPanchang?["abhijit_muhurta"]?["end"]?.toString() ?? "--";

  String get brahmaStart =>
      fullPanchang?["brahma_muhurta"]?["start"]?.toString() ?? "--";
  String get brahmaEnd =>
      fullPanchang?["brahma_muhurta"]?["end"]?.toString() ?? "--";

  String get panchakMessage =>
      fullPanchang?["panchak"]?["message"]?.toString() ?? "--";
  bool get isPanchak => fullPanchang?["panchak"]?["active"] ?? false;

  bool get hasError => errorMessage != null;

  List<dynamic> get chaughadiyaDay =>
      fullPanchang?["chaughadiya"]?["day"] ?? [];
  List<dynamic> get chaughadiyaNight =>
      fullPanchang?["chaughadiya"]?["night"] ?? [];

  // Current Chaughadiya
  Map<String, dynamic>? getCurrentChaughadiya() {
    if (fullPanchang == null) return null;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final sunriseMin = _toMinutes(sunrise);
    final sunsetMin = _toMinutes(sunset);

    final isDay = currentMinutes >= sunriseMin && currentMinutes < sunsetMin;
    final slots = isDay ? chaughadiyaDay : chaughadiyaNight;

    if (slots.isEmpty) return null;

    for (final slot in slots) {
      final start = _toMinutes(slot["start"] ?? "");
      final end = _toMinutes(slot["end"] ?? "");

      if (start < end) {
        if (currentMinutes >= start && currentMinutes < end) return slot;
      } else {
        if (currentMinutes >= start || currentMinutes < end) return slot;
      }
    }
    return null;
  }

  int _toMinutes(String time) {
    if (time.isEmpty) return 0;
    try {
      final parts = time.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (_) {
      return 0;
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }
}
