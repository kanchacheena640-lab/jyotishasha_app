import 'package:flutter/foundation.dart';

import '../models/horoscope/horoscope_contracts.dart';
import '../repositories/horoscope_repository.dart';
import '../repositories/implementations/http_horoscope_repository.dart';

class YearlyProvider extends ChangeNotifier {
  YearlyProvider({HoroscopeRepository? horoscopeRepository})
    : _horoscopeRepository =
          horoscopeRepository ?? HttpHoroscopeRepository();

  final HoroscopeRepository _horoscopeRepository;

  bool isLoading = false;
  String? errorMessage;

  // YEARLY DATA
  String? title;
  Map<String, dynamic>? data;

  // CACHE
  String? _lastSign;
  String? _lastLang;
  int? _lastYear;

  Future<void> fetchYearly({
    required String sign,
    required int year,
    required String lang,
    bool force = false,
  }) async {
    final s = sign.toLowerCase().trim();
    final l = lang.toLowerCase().trim();

    // Guard (cache hit)
    if (!force &&
        _lastSign == s &&
        _lastLang == l &&
        _lastYear == year &&
        data != null) {
      return;
    }

    // Clear old data
    title = null;
    data = null;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final yearly = await _horoscopeRepository.getYearlyHoroscope(
        HoroscopeQuery(sign: s, language: l, year: year),
      );

      title = yearly.title?.toString();
      final rawData = yearly.rawData;
      data = rawData == null ? null : Map<String, dynamic>.from(rawData);

      _lastSign = s;
      _lastLang = l;
      _lastYear = year;
    } catch (e) {
      final message = e.toString();
      final statusMatch = RegExp(r'Horoscope API error (\d+)').firstMatch(
        message,
      );
      if (statusMatch != null) {
        errorMessage = "Server error ${statusMatch.group(1)}";
      } else {
        errorMessage = message;
      }
    }

    isLoading = false;
    notifyListeners();
  }

  /// Call on profile change / language change / year change
  void reset() {
    isLoading = false;
    errorMessage = null;

    title = null;
    data = null;

    _lastSign = null;
    _lastLang = null;
    _lastYear = null;

    notifyListeners();
  }
}
