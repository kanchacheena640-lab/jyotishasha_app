import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PanchangProvider extends ChangeNotifier {
  Timer? _clockTimer;

  PanchangProvider() {
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      notifyListeners();
    });
  }
  bool isLoading = false;
  String? errorMessage;

  /// Selected date Panchang
  Map<String, dynamic>? fullPanchang;
  Map<String, dynamic>? nextPanchang;

  /// cache
  String? lastFetchDate;
  String? lastLang;

  double savedLat = 26.8467;
  double savedLng = 80.9462;

  final int cacheResetHour = 4;

  // ------------------------------------------------------------
  // SMART LOAD
  // ------------------------------------------------------------

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
    }

    if (lastFetchDate == today &&
        lastLang == lang &&
        fullPanchang != null &&
        nextPanchang != null &&
        (lat == null || lat == savedLat) &&
        (lng == null || lng == savedLng)) {
      return;
    }

    await fetchPanchang(lat: lat ?? savedLat, lng: lng ?? savedLng, lang: lang);
  }

  // ------------------------------------------------------------
  // API CALL
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

    const endpoint = "https://jyotishasha-backend.onrender.com/api/panchang";

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

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

        /// backend returns
        /// { selected_date : {...}, next_date : {...} }

        final selected = decoded["selected_date"];
        final next = decoded["next_date"];

        if (selected != null && selected is Map<String, dynamic>) {
          fullPanchang = selected;

          /// safety check
          if (next != null && next is Map<String, dynamic>) {
            nextPanchang = next;
          } else {
            nextPanchang = null;
          }

          lastFetchDate = today;
          lastLang = lang;
          errorMessage = null;
        } else {
          fullPanchang = null;
          nextPanchang = null;
          errorMessage = "Invalid Panchang data";
        }
      } else {
        fullPanchang = null;
        nextPanchang = null;
        errorMessage = "Server error ${res.statusCode}";
      }
    } catch (e) {
      fullPanchang = null;
      nextPanchang = null;
      errorMessage = "Network error: $e";
    }

    isLoading = false;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // Cache reset
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
  // SAFE GETTERS
  // ------------------------------------------------------------

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

  String get panchakMessage =>
      fullPanchang?["panchak"]?["message"]?.toString() ?? "--";

  bool get hasError => errorMessage != null;

  // ------------------------------------------------------------
  // CHAUGHADIYA LISTS
  // ------------------------------------------------------------

  List<dynamic> get chaughadiyaDay =>
      fullPanchang?["chaughadiya"]?["day"] ?? [];

  List<dynamic> get chaughadiyaNight =>
      fullPanchang?["chaughadiya"]?["night"] ?? [];

  // ------------------------------------------------------------
  // CURRENT CHAUGHADIYA
  // ------------------------------------------------------------

  Map<String, dynamic>? getCurrentChaughadiya() {
    if (fullPanchang == null) return null;

    final now = DateTime.now();
    // 24-घंटे के फॉर्मेट में अभी के कुल मिनट निकालें
    final currentMinutes = now.hour * 60 + now.minute;

    final daySlots = chaughadiyaDay;
    final nightSlots = chaughadiyaNight;
    final allSlots = [...daySlots, ...nightSlots];

    if (allSlots.isEmpty) return null;

    for (int i = 0; i < allSlots.length; i++) {
      final slot = allSlots[i];
      final start = _toMinutes(slot["start"]?.toString() ?? "");
      final end = _toMinutes(slot["end"]?.toString() ?? "");

      // 1. सामान्य स्लॉट (e.g., 14:00 से 15:25)
      if (start < end) {
        if (currentMinutes >= start && currentMinutes < end) {
          return slot;
        }
      }
      // 2. रात का स्लॉट जो 00:00 क्रॉस करता है (e.g., 23:00 से 01:00)
      else if (start > end) {
        if (currentMinutes >= start || currentMinutes < end) {
          return slot;
        }
      }
    }

    // --- INDUSTRY STANDARD FALLBACK ---
    // अगर कोई भी स्लॉट मैच नहीं हुआ (Borderline case),
    // तो समय के सबसे करीब वाला स्लॉट दिखा दो ताकि UI खाली न रहे।
    for (final slot in allSlots) {
      final start = _toMinutes(slot["start"]?.toString() ?? "");
      if (currentMinutes < start) return slot; // आने वाला पहला स्लॉट
    }

    return allSlots.first; // आखिरी रास्ता: पहला स्लॉट दिखाओ
  }

  // ------------------------------------------------------------
  // TIME PARSER
  // ------------------------------------------------------------

  int _toMinutes(String time) {
    if (time.isEmpty || !time.contains(":")) return 0;
    try {
      String cleanTime = time.trim().toUpperCase();
      // Regex to handle both "3:05 AM" and "03:05 AM"
      final parts = cleanTime.split(RegExp(r'[:\s]'));
      int h = int.parse(parts[0]);
      int m = int.parse(parts[1]);

      if (cleanTime.contains("PM") && h != 12) h += 12;
      if (cleanTime.contains("AM") && h == 12) h = 0;

      return h * 60 + m;
    } catch (e) {
      // Fallback for 24-hour format
      try {
        final parts = time.split(':');
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      } catch (_) {
        return 0;
      }
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }
}
