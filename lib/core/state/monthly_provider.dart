import 'package:flutter/foundation.dart';

import '../models/horoscope/horoscope_contracts.dart';
import '../repositories/horoscope_repository.dart';
import '../repositories/implementations/http_horoscope_repository.dart';

class MonthlyProvider extends ChangeNotifier {
  MonthlyProvider({HoroscopeRepository? horoscopeRepository})
    : _horoscopeRepository =
          horoscopeRepository ?? HttpHoroscopeRepository();

  final HoroscopeRepository _horoscopeRepository;

  bool isLoading = false;
  String? errorMessage;

  // MONTHLY FIELDS
  String? title;
  String? theme;
  String? careerMoney;
  String? loveRelationships;
  String? healthLifestyle;
  String? monthlyAdvice;
  List<String>? keyDates;

  // CACHE
  String? _lastSign;
  String? _lastLang;
  String? _lastMonth; // yyyy-MM

  Future<void> fetchMonthly({
    required String sign,
    required String lang,
    bool force = false,
  }) async {
    final s = sign.toLowerCase().trim();
    final l = lang.toLowerCase().trim();
    final m =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

    // Guard (cache hit)
    if (!force &&
        _lastSign == s &&
        _lastLang == l &&
        _lastMonth == m &&
        theme != null) {
      return;
    }

    // Clear old data
    title = null;
    theme = null;
    careerMoney = null;
    loveRelationships = null;
    healthLifestyle = null;
    monthlyAdvice = null;
    keyDates = null;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await _horoscopeRepository.getMonthlyHoroscope(
        HoroscopeQuery(sign: s, language: l),
      );

      title = data.title?.toString();
      theme = data.theme?.toString();
      careerMoney = data.careerMoney?.toString();
      loveRelationships = data.loveRelationships?.toString();
      healthLifestyle = data.healthLifestyle?.toString();
      monthlyAdvice = data.monthlyAdvice?.toString();
      keyDates = data.keyDates;

      _lastSign = s;
      _lastLang = l;
      _lastMonth = m;
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

  /// Call on profile change / language change
  void reset() {
    isLoading = false;
    errorMessage = null;

    title = null;
    theme = null;
    careerMoney = null;
    loveRelationships = null;
    healthLifestyle = null;
    monthlyAdvice = null;
    keyDates = null;

    _lastSign = null;
    _lastLang = null;
    _lastMonth = null;

    notifyListeners();
  }
}
