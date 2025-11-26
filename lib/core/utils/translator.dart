// lib/core/utils/translator.dart

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';

/// Generic bilingual picker for any data Map that has:
/// key       → English
/// key + _hi → Hindi
String tr(BuildContext context, Map data, String key) {
  // 🔥 ONLY source of truth: LanguageProvider
  final lang = Provider.of<LanguageProvider>(
    context,
    listen: false,
  ).currentLang;

  final String en = (data[key] ?? "").toString();
  final String hi = (data["${key}_hi"] ?? "").toString();

  if (lang == "hi" && hi.trim().isNotEmpty) {
    return hi;
  }
  return en;
}
