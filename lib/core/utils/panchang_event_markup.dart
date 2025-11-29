/// Bilingual Panchang Event Engine
/// ---------------------------------------------------------------
/// This file converts backend Panchang JSON → Hindi/English summary,
/// vrat suggestion, and special event titles.
/// ---------------------------------------------------------------
library;

class PanchangEvent {
  final String id;
  final String title;
  final String description;
  final bool isFastingDay;
  final bool isMajorFestival;

  const PanchangEvent({
    required this.id,
    required this.title,
    required this.description,
    this.isFastingDay = false,
    this.isMajorFestival = false,
  });
}

class PanchangEventMarkup {
  // ---------------------------------------------------------------------------
  // PUBLIC: Detect Events
  // ---------------------------------------------------------------------------
  static List<PanchangEvent> detectEvents(Map<String, dynamic> json) {
    final day = _selected(json);
    if (day == null) return const [];

    final lang = (day["language"] ?? "en").toString().substring(0, 2);

    final tithiName = _getNestedString(day, "tithi", "name");
    final paksha = _normalize(_getNestedString(day, "tithi", "paksha"));
    final weekday = _normalize(_getString(day, "weekday"));
    final nakshatra = _normalize(_getNestedString(day, "nakshatra", "name"));
    final month = _normalize(_getString(day, "month_name"));

    final List<PanchangEvent> ev = [];

    // ------------------ Helper: Bilingual Texts --------------------
    String t(String en, String hi) => lang == "hi" ? hi : en;

    // ----------------------------------------------------------------
    // EKADASHI
    // ----------------------------------------------------------------
    if (tithiName.toLowerCase().contains("ekadashi") ||
        tithiName.contains("एकादशी")) {
      ev.add(
        PanchangEvent(
          id: "ekadashi",
          title: t("Ekadashi Vrat", "एकादशी व्रत"),
          description: t(
            "Auspicious for devotion, light fasting and mantra chanting.",
            "भक्ति, हल्का उपवास और मंत्र-जप के लिए शुभ दिन।",
          ),
          isFastingDay: true,
        ),
      );
    }

    // ----------------------------------------------------------------
    // Purnima
    // ----------------------------------------------------------------
    if (tithiName.toLowerCase().contains("purnima") ||
        tithiName.contains("पूर्णिमा")) {
      ev.add(
        PanchangEvent(
          id: "purnima",
          title: t("Purnima", "पूर्णिमा"),
          description: t(
            "Good for meditation, charity and peaceful rituals.",
            "ध्यान, दान और शांत आध्यात्मिक कार्यों के लिए उत्तम।",
          ),
          isFastingDay: true,
        ),
      );
    }

    // ----------------------------------------------------------------
    // Amavasya
    // ----------------------------------------------------------------
    if (tithiName.toLowerCase().contains("amavasya") ||
        tithiName.contains("अमावस्या")) {
      ev.add(
        PanchangEvent(
          id: "amavasya",
          title: t("Amavasya", "अमावस्या"),
          description: t(
            "Ideal for introspection and spiritual cleansing.",
            "आत्म-चिंतन और आध्यात्मिक शुद्धि के लिए शुभ।",
          ),
          isFastingDay: true,
        ),
      );

      // Somvati Amavasya
      if (_is(weekday, "monday") || weekday == "सोमवार") {
        ev.add(
          PanchangEvent(
            id: "somvati_amavasya",
            title: t("Somvati Amavasya", "सोमवती अमावस्या"),
            description: t(
              "Powerful day for punya and spiritual merit.",
              "पुण्य और आध्यात्मिक लाभ के लिए अत्यंत शुभ।",
            ),
            isFastingDay: true,
            isMajorFestival: true,
          ),
        );
      }
    }

    // ----------------------------------------------------------------
    // Masik Shivratri
    // ----------------------------------------------------------------
    if ((_is(tithiName, "Chaturdashi") && _is(paksha, "krishna")) ||
        (tithiName.contains("चतुर्दशी") && paksha.contains("कृष्ण"))) {
      ev.add(
        PanchangEvent(
          id: "masik_shivratri",
          title: t("Masik Shivratri", "मासिक शिवरात्रि"),
          description: t(
            "Good for Shiva upasana and night meditation.",
            "शिव उपासना और रात्रि-ध्यान के लिए शुभ।",
          ),
          isFastingDay: true,
        ),
      );
    }

    // ----------------------------------------------------------------
    // Ravi / Guru Pushya
    // ----------------------------------------------------------------
    if (_is(nakshatra, "pushya") || nakshatra == "पुष्य") {
      if (_is(weekday, "sunday") || weekday == "रविवार") {
        ev.add(
          PanchangEvent(
            id: "ravi_pushya",
            title: t("Ravi Pushya Yoga", "रवि पुष्य योग"),
            description: t(
              "Great for new beginnings and auspicious purchases.",
              "नए काम और शुभ खरीदारी के लिए सर्वोत्तम।",
            ),
            isMajorFestival: true,
          ),
        );
      } else if (_is(weekday, "thursday") || weekday == "गुरुवार") {
        ev.add(
          PanchangEvent(
            id: "guru_pushya",
            title: t("Guru Pushya Yoga", "गुरु पुष्य योग"),
            description: t(
              "Favourable for education, wealth planning and good deeds.",
              "शिक्षा, धन-योजना और शुभ कार्यों के लिए उत्तम।",
            ),
            isMajorFestival: true,
          ),
        );
      }
    }

    // ----------------------------------------------------------------
    // Dhanteras
    // ----------------------------------------------------------------
    if (_is(month, "kartika") &&
        (_is(tithiName, "Trayodashi") || tithiName.contains("त्रयोदशी"))) {
      ev.add(
        PanchangEvent(
          id: "dhanteras",
          title: t("Dhanteras", "धनतेरस"),
          description: t(
            "Auspicious for health rituals and sacred purchases.",
            "आरोग्य, लक्ष्मी-पूजन और शुभ खरीदारी के लिए उत्तम।",
          ),
          isMajorFestival: true,
        ),
      );
    }

    return ev;
  }

  // ---------------------------------------------------------------------------
  // SUMMARY LINE  (Bilingual)
  // ---------------------------------------------------------------------------
  static String buildSummaryLine(Map<String, dynamic> json) {
    final day = _selected(json);
    if (day == null) return "";

    final lang = (day["language"] ?? "en").toString().substring(0, 2);

    final tithi = _getNestedString(day, "tithi", "name");
    final paksha = _getNestedString(day, "tithi", "paksha");
    final nak = _getNestedString(day, "nakshatra", "name");
    final pad = day["nakshatra"]?["pada"]?.toString() ?? "";
    final weekday = day["weekday"] ?? "";
    final month = day["month_name"] ?? "";

    final events = detectEvents(json);
    final special = events.map((e) => e.title).join(", ");

    if (lang == "hi") {
      return "आज $tithi ($paksha), नक्षत्र $nak (पद $pad)। वार: $weekday। ${special.isNotEmpty ? "विशेष: $special।" : ""}";
    }

    return "Today is $tithi ($paksha), Nakshatra $nak (Pada $pad). Day: $weekday. ${special.isNotEmpty ? "Special today: $special." : ""}";
  }

  // ---------------------------------------------------------------------------
  // VRAT LINE (Bilingual)
  // ---------------------------------------------------------------------------
  static String buildVratSuggestion(Map<String, dynamic> json) {
    final day = _selected(json);
    if (day == null) return "";

    final lang = (day["language"] ?? "en").toString().substring(0, 2);

    final vrats = detectEvents(
      json,
    ).where((e) => e.isFastingDay).map((e) => e.title).join(", ");

    if (vrats.isEmpty) return "";

    return lang == "hi"
        ? "आज आप $vrats कर सकते हैं।"
        : "Today you can observe $vrats.";
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  static Map<String, dynamic>? _selected(Map<String, dynamic> json) {
    final sel = json["selected_date"];

    if (sel is Map) {
      // Ensure type safety
      return Map<String, dynamic>.from(sel);
    }

    return Map<String, dynamic>.from(json);
  }

  static String _getString(Map<String, dynamic> map, String key) {
    final v = map[key];
    return v?.toString() ?? "";
  }

  static String _getNestedString(
    Map<String, dynamic> map,
    String parent,
    String key,
  ) {
    final p = map[parent];
    if (p is Map && p[key] != null) {
      return p[key].toString();
    }
    return "";
  }

  static int? _getNestedInt(
    Map<String, dynamic> map,
    String parent,
    String key,
  ) {
    final p = map[parent];
    if (p is Map && p[key] != null) {
      final v = p[key];
      // Safe parse (covers int, num, double, string)
      return int.tryParse(v.toString());
    }
    return null;
  }

  static String _normalize(String s) {
    return s.trim().toLowerCase();
  }

  static bool _is(String actual, String expected) {
    if (actual.isEmpty || expected.isEmpty) return false;
    return _normalize(actual) == _normalize(expected);
  }
}
