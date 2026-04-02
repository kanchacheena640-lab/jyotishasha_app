import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class YearlyProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  // YEARLY DATA
  String? title;
  Map<String, dynamic>? data;

  // CACHE
  String? _lastSign;
  String? _lastLang;
  int? _lastYear;

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

    final res = await _get(
      "https://jyotishasha-backend.onrender.com/api/yearly-horoscope"
      "?sign=$s&year=$year&lang=$l",
    );

    if (res != null) {
      title = res["title"]?.toString();
      data = res;

      _lastSign = s;
      _lastLang = l;
      _lastYear = year;
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
