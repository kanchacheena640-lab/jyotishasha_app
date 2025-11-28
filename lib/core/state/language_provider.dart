import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String currentLang = 'en'; // default

  /// 🚀 Set language + persist + notify
  Future<void> setLanguage(String lang) async {
    currentLang = lang;

    // ⭐ Save in persistent storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("app_lang", lang);

    notifyListeners();
  }

  /// Clean getter (no unnecessary print spam)
  bool get isHindi => currentLang == 'hi';

  /// ⚡ Load saved language when app starts
  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    currentLang = prefs.getString("app_lang") ?? 'en';
    notifyListeners();
  }
}
