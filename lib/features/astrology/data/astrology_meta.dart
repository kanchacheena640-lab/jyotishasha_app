// ------------------------------------------------------------
// ASTROLOGY META (UI RULES + CATEGORY LOGIC + ICON MAP)
// ------------------------------------------------------------
class AstrologyMeta {
  // ============================================================
  // 1) PROFILE TOOLS (Static, always visible)
  // ============================================================
  static List<Map<String, dynamic>> profileTools() {
    return const [
      {"id": "rashi", "name": "Rashi Finder", "icon": "🌙"},
      {"id": "lagna", "name": "Lagna Finder", "icon": "📍"},
      {"id": "gemstone", "name": "Gemstone Suggestion", "icon": "💎"},
    ];
  }

  // ============================================================
  // 2) PLANET CATEGORY — driven by backend JSON
  // ============================================================
  static List<Map<String, dynamic>> planetCategory(List<dynamic> planets) {
    return planets.map((item) {
      final p = item is Map ? item : <String, dynamic>{};
      final name = p["planet"]?.toString() ?? "Planet";

      return {"id": "planet_$name", "name": name, "icon": _planetIcon(name)};
    }).toList();
  }

  // ============================================================
  // 3) HOUSE CATEGORY — dynamic, 1 to 12
  // ============================================================
  static List<Map<String, dynamic>> houseCategory(List<dynamic> houses) {
    if (houses.isEmpty) return [];

    return houses.map((item) {
      final Map<String, dynamic> h = (item is Map<String, dynamic>) ? item : {};

      final int num = h["house"] is int ? h["house"] : 0;

      return {"id": "house_$num", "name": "House $num", "icon": "🏠"};
    }).toList();
  }

  // ============================================================
  // 4) MAHADASHA CATEGORY — static options
  // ============================================================
  static List<Map<String, dynamic>> mahadashaCategory(Map kundali) {
    return const [
      {"id": "current_dasha", "name": "Current Dasha", "icon": "⏳"},
      {"id": "timeline", "name": "Full Timeline", "icon": "📜"},
    ];
  }

  // ============================================================
  // 5) YOG / DOSH CATEGORY — dynamic
  // ============================================================
  static List<Map<String, dynamic>> yogaCategory(Map yogas) {
    if (yogas.isEmpty) return [];

    return yogas.entries.map((e) {
      final key = e.key;
      final d = e.value is Map ? e.value : {};

      return {"id": "yoga_$key", "name": d["name"] ?? key, "icon": "✨"};
    }).toList();
  }

  // ============================================================
  // 6) LIFE ASPECT CATEGORY — Dynamic from List
  // ============================================================
  static List<Map<String, dynamic>> lifeAspectCategory(List<dynamic> aspects) {
    if (aspects.isEmpty) return [];

    return aspects.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value is Map ? entry.value : {};

      final name = item["aspect"]?.toString() ?? "Aspect ${index + 1}";

      return {"id": "life_${index + 1}", "name": name, "icon": _lifeIcon(name)};
    }).toList();
  }

  // ICONS BASED ON ASPECT NAME
  static String _lifeIcon(String name) {
    final n = name.toLowerCase();

    if (n.contains("career") || n.contains("public")) return "💼";
    if (n.contains("wealth") || n.contains("finance")) return "💰";
    if (n.contains("health")) return "💊";
    if (n.contains("marriage") || n.contains("partnership")) return "❤️";
    if (n.contains("family") || n.contains("home")) return "🏡";
    if (n.contains("children") || n.contains("creativity")) return "🎨";
    if (n.contains("mind") || n.contains("emotion")) return "🧠";
    if (n.contains("spiritual") || n.contains("karma")) return "🕉️";
    if (n.contains("social") || n.contains("network")) return "🌐";
    if (n.contains("property") || n.contains("assets")) return "🏠";

    return "✨";
  }

  // ============================================================
  // 7) PLANET ICON MAP — complete set
  // ============================================================
  static String _planetIcon(String? p) {
    if (p == null) return "⭐";

    switch (p.toLowerCase()) {
      case "sun":
        return "☀️";
      case "moon":
        return "🌙";
      case "mars":
        return "🔥";
      case "mercury":
        return "🧠";
      case "jupiter":
        return "📚";
      case "venus":
        return "💖";
      case "saturn":
        return "🪐";
      case "rahu":
        return "🌑";
      case "ketu":
        return "🔱";
      case "ascendant (lagna)":
        return "🧿";
      default:
        return "⭐";
    }
  }
}
