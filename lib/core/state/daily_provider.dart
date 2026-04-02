import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DailyProvider extends ChangeNotifier {
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

    final data = await _get(
      "https://jyotishasha-backend.onrender.com/api/daily-horoscope?sign=$s&lang=$l",
    );

    if (data != null) {
      dailyTitle = data["heading"]?.toString();
      intro = data["intro"]?.toString();
      paragraph = data["paragraph"]?.toString();
      tips = data["tips"]?.toString();

      luckyColor = data["lucky_color"]?.toString();
      luckyNumber = data["lucky_number"]?.toString();

      _lastSign = s;
      _lastLang = l;
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
