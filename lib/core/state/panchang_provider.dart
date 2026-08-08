import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/panchang/panchang_contracts.dart';
import '../repositories/implementations/http_panchang_repository.dart';
import '../repositories/panchang_repository.dart';

class PanchangProvider extends ChangeNotifier {
  PanchangProvider({PanchangRepository? panchangRepository})
    : _panchangRepository = panchangRepository ?? HttpPanchangRepository() {
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      notifyListeners();
    });
  }

  final PanchangRepository _panchangRepository;
  Timer? _clockTimer;

  bool isLoading = false;
  String? errorMessage;

  Map<String, dynamic>? fullPanchang;
  Map<String, dynamic>? nextPanchang;

  Map<String, dynamic>? get selectedDate => fullPanchang;
  Map<String, dynamic>? get nextDate => nextPanchang;

  String? lastFetchDate;
  String? lastLang;

  double savedLat = 26.8467;
  double savedLng = 80.9462;

  final int cacheResetHour = 4;

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

    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final response = await _panchangRepository.getPanchang(
        PanchangRequest(
          latitude: lat,
          longitude: lng,
          date: today,
          language: lang,
        ),
      );

      fullPanchang = _toRawMap(response.selectedDate);
      nextPanchang = _toRawMap(response.nextDate);

      if (fullPanchang != null) {
        lastFetchDate = today;
        lastLang = lang;
        errorMessage = null;
      } else {
        errorMessage = "Invalid panchang data";
      }
    } catch (e) {
      final message = e.toString();
      final statusMatch = RegExp(r'Panchang API error (\d+)').firstMatch(message);
      if (statusMatch != null) {
        errorMessage = "Server error: ${statusMatch.group(1)}";
      } else {
        errorMessage = "Network error: $e";
      }
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

  Map<String, dynamic>? _toRawMap(PanchangDay? day) {
    final json = day?.toJson();
    if (json == null) return null;
    return Map<String, dynamic>.from(json);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }
}
