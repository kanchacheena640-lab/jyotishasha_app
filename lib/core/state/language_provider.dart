import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  String currentLang = 'en'; // default

  void setLanguage(String lang) {
    print("🌐 [LanguageProvider] SET LANGUAGE CALLED → $lang");
    currentLang = lang;

    // Extra debug
    print("🌐 [LanguageProvider] CURRENT LANG NOW → $currentLang");

    notifyListeners();
  }

  bool get isHindi {
    final val = currentLang == 'hi';
    print("🌐 [LanguageProvider] isHindi → $val");
    return val;
  }
}
