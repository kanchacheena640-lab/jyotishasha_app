import 'package:flutter/foundation.dart';

import '../models/horoscope/horoscope_contracts.dart';
import '../repositories/horoscope_repository.dart';
import '../repositories/implementations/http_horoscope_repository.dart';

class DailyProvider extends ChangeNotifier {
  DailyProvider({HoroscopeRepository? horoscopeRepository})
    : _horoscopeRepository =
          horoscopeRepository ?? HttpHoroscopeRepository();

  final HoroscopeRepository _horoscopeRepository;

  bool isLoading = false;
  String? errorMessage;

  // DAILY FIELDS
  String? dailyTitle;
  String? intro;
  String? paragraph;
  String? tips;
  String? luckyColor;
  String? luckyNumber;

  // CACHE (daily)
  String? _lastSign;
  String? _lastLang;

  String? get lastLang => _lastLang;

  Future<void> fetchDaily({
    required String sign,
    required String lang,
    bool force = false,
  }) async {
    final s = sign.toLowerCase().trim();
    final l = lang.toLowerCase().trim();

    // Guard (cache hit)
    if (!force &&
        _lastSign == s &&
        _lastLang == l &&
        intro != null &&
        paragraph != null) {
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await _horoscopeRepository.getDailyHoroscope(
        HoroscopeQuery(sign: s, language: l),
      );

      dailyTitle = data.heading?.toString();
      intro = data.intro?.toString();
      paragraph = data.paragraph?.toString();
      tips = data.tips?.toString();

      luckyColor = data.luckyColor?.toString();
      luckyNumber = data.luckyNumber?.toString();

      _lastSign = s;
      _lastLang = l;
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

  /// Call this when profile changes OR language changes OR manual refresh needed.
  void reset() {
    isLoading = false;
    errorMessage = null;

    dailyTitle = null;
    intro = null;
    paragraph = null;
    tips = null;
    luckyColor = null;
    luckyNumber = null;

    _lastSign = null;
    _lastLang = null;

    notifyListeners();
  }
}
