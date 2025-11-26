// lib/features/astrology/data/astrology_meta.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';

class AstrologyMeta {
  // ---------------------------------------------------------------------------
  // ⭐ GLOBAL HELPER FOR BILINGUAL TEXT
  // ---------------------------------------------------------------------------
  static String pickLang(BuildContext ctx, Map item, String key) {
    final lang = Provider.of<LanguageProvider>(ctx, listen: false).currentLang;
    final en = item[key]?.toString() ?? "";
    final hi = item["${key}_hi"]?.toString() ?? "";

    if (lang == "hi" && hi.trim().isNotEmpty) return hi;
    return en;
  }

  static String pickSimple(BuildContext ctx, String en, String hi) {
    final lang = Provider.of<LanguageProvider>(ctx, listen: false).currentLang;
    if (lang == "hi" && hi.trim().isNotEmpty) return hi;
    return en;
  }

  // ---------------------------------------------------------------------------
  // 1) PROFILE TOOLS — BILINGUAL
  // ---------------------------------------------------------------------------
  static List<Map<String, dynamic>> profileTools(BuildContext ctx) {
    return [
      {
        "id": "rashi",
        "name": pickSimple(ctx, "Rashi Finder", "राशि"),
        "icon": "🌙",
      },
      {
        "id": "lagna",
        "name": pickSimple(ctx, "Lagna Finder", "लग्न"),
        "icon": "📍",
      },
      {
        "id": "gemstone",
        "name": pickSimple(ctx, "Gemstone Suggestion", "रत्न परामर्श"),
        "icon": "💎",
      },
    ];
  }

  // ---------------------------------------------------------------------------
  // 2) PLANET CATEGORY — BILINGUAL (if backend has *_hi)
  // ---------------------------------------------------------------------------
  static List<Map<String, dynamic>> planetCategory(
    List<dynamic> planets,
    BuildContext ctx,
  ) {
    return planets.map((item) {
      final p = item is Map ? item : <String, dynamic>{};
      final name = pickLang(ctx, p, "planet");

      return {
        "id": "planet_${p["planet"]}",
        "name": name,
        "icon": _planetIcon(name),
      };
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // 3) HOUSE CATEGORY — BILINGUAL TITLES
  // ---------------------------------------------------------------------------
  static List<Map<String, dynamic>> houseCategory(
    List<dynamic> houses,
    BuildContext ctx,
  ) {
    if (houses.isEmpty) return [];

    final lang = Provider.of<LanguageProvider>(ctx, listen: false).currentLang;

    return houses.map((item) {
      final Map<String, dynamic> p = (item is Map)
          ? Map<String, dynamic>.from(item)
          : <String, dynamic>{};
      int num = int.tryParse(p["house"]?.toString() ?? "0") ?? 0;

      final enName = "House $num";
      final hiName = "$numवाँ भाव";

      return {
        "id": "house_$num",
        "name": (lang == "hi") ? hiName : enName,
        "icon": "🏠",
      };
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // 4) MAHADASHA — BILINGUAL
  // ---------------------------------------------------------------------------
  static List<Map<String, dynamic>> mahadashaCategory(
    Map kundali,
    BuildContext ctx,
  ) {
    final lang = Provider.of<LanguageProvider>(ctx, listen: false).currentLang;

    return [
      {
        "id": "current_dasha",
        "name": (lang == "hi") ? "वर्तमान दशा" : "Current Dasha",
        "icon": "⏳",
      },
      {
        "id": "timeline",
        "name": (lang == "hi") ? "महादशा" : "Full Timeline",
        "icon": "📜",
      },
    ];
  }

  // ---------------------------------------------------------------------------
  // 5) YOG / DOSH — BILINGUAL (if backend sends *_hi)
  // ---------------------------------------------------------------------------
  static List<Map<String, dynamic>> yogaCategory(Map yogas, BuildContext ctx) {
    if (yogas.isEmpty) return [];

    return yogas.entries.map((e) {
      final d = e.value is Map ? e.value : {};
      final name = pickLang(ctx, d, "name");

      return {"id": "yoga_${e.key}", "name": name, "icon": "✨"};
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // 6) LIFE ASPECT — BILINGUAL SUPPORT (FINAL PERFECT VERSION)
  // ---------------------------------------------------------------------------
  static List<Map<String, dynamic>> lifeAspectCategory(
    List<dynamic> aspects,
    BuildContext context,
  ) {
    if (aspects.isEmpty) return [];

    final lang = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).currentLang;

    return aspects.asMap().entries.map((entry) {
      final index = entry.key;

      // item must be a Map, else empty map
      final Map<String, dynamic> item = (entry.value is Map)
          ? Map<String, dynamic>.from(entry.value)
          : {};

      // Extract names
      final String en =
          item["aspect"]?.toString().trim() ?? "Aspect ${index + 1}";
      final String hi = item["aspect_hi"]?.toString().trim() ?? "";

      // Final name based on language
      final String name = (lang == "hi" && hi.isNotEmpty) ? hi : en;

      return {
        "id": "life_${index + 1}",
        "name": name,
        "icon": _lifeIcon(name), // icon English name se map hota hai, safe.
      };
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // ICON DETECTORS
  // ---------------------------------------------------------------------------
  static String _lifeIcon(String name) {
    final n = name.toLowerCase();

    if (n.contains("career") || n.contains("कैरियर")) return "💼";
    if (n.contains("wealth") || n.contains("finance") || n.contains("धन"))
      return "💰";
    if (n.contains("health") || n.contains("स्वास्थ्य")) return "💊";
    if (n.contains("marriage") || n.contains("विवाह") || n.contains("संबंध"))
      return "❤️";
    if (n.contains("family") || n.contains("परिवार") || n.contains("घर"))
      return "🏡";
    if (n.contains("children") || n.contains("बच्चे") || n.contains("संतान"))
      return "🎨";
    if (n.contains("mind") || n.contains("emotion") || n.contains("मन"))
      return "🧠";
    if (n.contains("spiritual") ||
        n.contains("आध्यात्मिक") ||
        n.contains("कर्म"))
      return "🕉️";
    if (n.contains("social") || n.contains("network") || n.contains("समाज"))
      return "🌐";

    return "✨";
  }

  static String _planetIcon(String? p) {
    if (p == null) return "⭐";

    switch (p.toLowerCase()) {
      case "sun":
      case "सूर्य":
        return "☀️";
      case "moon":
      case "चंद्र":
        return "🌙";
      case "mars":
      case "मंगल":
        return "🔥";
      case "mercury":
      case "बुध":
        return "🧠";
      case "jupiter":
      case "गुरु":
        return "📚";
      case "venus":
      case "शुक्र":
        return "💖";
      case "saturn":
      case "शनि":
        return "🪐";
      case "rahu":
      case "राहु":
        return "🌑";
      case "ketu":
      case "केतु":
        return "🔱";
      default:
        return "⭐";
    }
  }
}
