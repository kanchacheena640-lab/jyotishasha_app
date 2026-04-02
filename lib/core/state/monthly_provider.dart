import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MonthlyProvider extends ChangeNotifier {
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

  Future<Map<String, dynamic>?> _get(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      errorMessage = "Server error ${res.statusCode}";
      return null;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    }
  }

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

    final data = await _get(
      "https://jyotishasha-backend.onrender.com/api/monthly-horoscope?sign=$s&lang=$l",
    );

    if (data != null) {
      title = data["title"]?.toString();
      theme = data["theme"]?.toString();
      careerMoney = data["career_money"]?.toString();
      loveRelationships = data["love_relationships"]?.toString();
      healthLifestyle = data["health_lifestyle"]?.toString();
      monthlyAdvice = data["monthly_advice"]?.toString();
      keyDates = (data["key_dates"] as List?)?.cast<String>();

      _lastSign = s;
      _lastLang = l;
      _lastMonth = m;
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
