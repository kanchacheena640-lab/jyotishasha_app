/// Represents a spiritually meaningful highlight for the day.
class PanchangEvent {
  final String id; // e.g. "ekadashi", "pradosh", "akshaya_tritiya"
  final String title; // Short label to show in UI
  final String description; // 1–2 line user-friendly copy
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

/// Utility to derive daily highlights from Panchang API response.
///
/// Input shape expected (from /api/panchang):
/// {
///   "selected_date": {
///     "tithi": { "name": "...", "number": 11, "paksha": "Shukla" },
///     "nakshatra": { "name": "..." },
///     "weekday": "Thursday",
///     "month_name": "Vaishakha",
///     "sunrise": "06:12",
///     "sunset": "18:22",
///     "rahu_kaal": { "start": "15:02", "end": "16:30" },
///     ...
///   }
/// }
class PanchangEventMarkup {
  /// Main entry:
  /// Pass full API JSON, returns list of detected events for that day.
  static List<PanchangEvent> detectEvents(Map<String, dynamic> panchangJson) {
    final day = _selected(panchangJson);
    if (day == null) return const [];

    final tithiName = _getNestedString(day, "tithi", "name");
    final tithiNum = _getNestedInt(day, "tithi", "number");
    final paksha = _getNestedString(day, "tithi", "paksha");
    final nakshatra = _getNestedString(day, "nakshatra", "name");
    final weekday = _normalize(_getString(day, "weekday"));
    final month = _normalize(_getString(day, "month_name"));

    final List<PanchangEvent> events = [];

    // ---------- Core fasts / vrats ----------

    // Ekadashi (all types)
    if (tithiName.toLowerCase().contains("ekadashi")) {
      events.add(
        PanchangEvent(
          id: "ekadashi",
          title: "Ekadashi Vrat",
          description:
              "Auspicious day for Lord Vishnu's worship, light food or fasting and mantra-jap.",
          isFastingDay: true,
        ),
      );
    }

    // Sankashti Chaturthi (Krishna Paksha Chaturthi)
    if (_is(tithiName, "Chaturthi") && _is(paksha, "Krishna")) {
      events.add(
        const PanchangEvent(
          id: "sankashti_chaturthi",
          title: "Sankashti Chaturthi",
          description:
              "Favourable for worship of Shri Ganesh for removal of obstacles and mental clarity.",
          isFastingDay: true,
        ),
      );
    }

    // Purnima
    if (tithiName.toLowerCase().contains("purnima")) {
      events.add(
        const PanchangEvent(
          id: "purnima",
          title: "Purnima",
          description:
              "Full Moon energies support pooja, daan, meditation and family rituals.",
          isFastingDay: true,
        ),
      );
    }

    // Amavasya
    if (tithiName.toLowerCase().contains("amavasya")) {
      events.add(
        const PanchangEvent(
          id: "amavasya",
          title: "Amavasya",
          description:
              "Suitable for introspection, pitru-tarpan and quiet spiritual practices.",
          isFastingDay: true,
        ),
      );

      // Somvati Amavasya (special)
      if (_is(weekday, "monday")) {
        events.add(
          const PanchangEvent(
            id: "somvati_amavasya",
            title: "Somvati Amavasya",
            description:
                "Rare and powerful day for punya-karma, pitru-tarpan and satvik vrat.",
            isFastingDay: true,
            isMajorFestival: true,
          ),
        );
      }
    }

    // Masik Shivratri (Krishna Paksha Chaturdashi)
    if (_is(tithiName, "Chaturdashi") && _is(paksha, "Krishna")) {
      events.add(
        const PanchangEvent(
          id: "masik_shivratri",
          title: "Masik Shivratri",
          description:
              "Night favourable for Lord Shiva's upasana, dhyaan and mantrajap.",
          isFastingDay: true,
        ),
      );
    }

    // Pradosh Vrat (Trayodashi, sandhya focus)
    if (_is(tithiName, "Trayodashi")) {
      String label = "Pradosh Vrat";
      if (_is(weekday, "monday")) {
        label = "Som Pradosh Vrat";
      } else if (_is(weekday, "tuesday")) {
        label = "Bhaum Pradosh Vrat";
      }
      events.add(
        PanchangEvent(
          id: "pradosh_vrat",
          title: label,
          description:
              "Evening period is auspicious for Shiva-puja, especially during pradosh kaal.",
          isFastingDay: true,
        ),
      );
    }

    // ---------- Yoga-based combos ----------

    // Ravi Pushya / Guru Pushya (highly auspicious for new beginnings)
    if (_is(nakshatra, "Pushya")) {
      if (_is(weekday, "sunday")) {
        events.add(
          const PanchangEvent(
            id: "ravi_pushya",
            title: "Ravi Pushya Yoga",
            description:
                "Auspicious for starting important tasks, investments and sacred purchases.",
            isMajorFestival: true,
          ),
        );
      } else if (_is(weekday, "thursday")) {
        events.add(
          const PanchangEvent(
            id: "guru_pushya",
            title: "Guru Pushya Yoga",
            description:
                "Very favourable for education, wealth planning and spiritual initiations.",
            isMajorFestival: true,
          ),
        );
      }
    }

    // ---------- Big calendar markers (rule-based, approx, only if match) ----------

    // Akshaya Tritiya: Vaishakha Shukla Tritiya
    if (_is(month, "vaishakha") &&
        _is(paksha, "Shukla") &&
        _is(tithiName, "Tritiya")) {
      events.add(
        const PanchangEvent(
          id: "akshaya_tritiya",
          title: "Akshaya Tritiya",
          description:
              "Sacred for daan, dhan, gold/property purchase and starting long-term ventures.",
          isMajorFestival: true,
        ),
      );
    }

    // Maha Shivratri: Phalguna Krishna Chaturdashi
    if (_is(month, "phalguna") &&
        _is(paksha, "Krishna") &&
        _is(tithiName, "Chaturdashi")) {
      events.add(
        const PanchangEvent(
          id: "maha_shivratri",
          title: "Maha Shivratri",
          description:
              "Powerful night-long upasana of Lord Shiva for inner strength and grace.",
          isMajorFestival: true,
          isFastingDay: true,
        ),
      );
    }

    // Karwa Chauth: Kartika Krishna Chaturthi (North tradition)
    if (_is(month, "kartika") &&
        _is(paksha, "Krishna") &&
        _is(tithiName, "Chaturthi")) {
      events.add(
        const PanchangEvent(
          id: "karwa_chauth",
          title: "Karwa Chauth",
          description:
              "Vrat observed (mainly by married women) for harmony, longevity and prosperity.",
          isMajorFestival: true,
          isFastingDay: true,
        ),
      );
    }

    // Dhanteras: Kartika Krishna Trayodashi
    if (_is(month, "kartika") &&
        _is(paksha, "Krishna") &&
        _is(tithiName, "Trayodashi")) {
      events.add(
        const PanchangEvent(
          id: "dhanteras",
          title: "Dhanteras",
          description:
              "Auspicious for Dhanvantri, Kubera, Lakshmi worship and mindful purchases.",
          isMajorFestival: true,
        ),
      );
    }

    // Diwali (Lakshmi Puja): Kartika Amavasya
    if (_is(month, "kartika") && tithiName.toLowerCase().contains("amavasya")) {
      events.add(
        const PanchangEvent(
          id: "diwali",
          title: "Deepawali (Lakshmi Pujan)",
          description:
              "Evening suited for Deepdaan, Mahalakshmi and Ganesh puja with family.",
          isMajorFestival: true,
        ),
      );
    }

    // Holika Dahan: Phalguna Purnima
    if (_is(month, "phalguna") && tithiName.toLowerCase().contains("purnima")) {
      events.add(
        const PanchangEvent(
          id: "holika_dahan",
          title: "Holika Dahan",
          description:
              "Symbolic burning of negativity; good for cleansing and fresh intentions.",
          isMajorFestival: true,
        ),
      );
    }

    // Ram Navami: Chaitra Shukla Navami
    if (_is(month, "chaitra") &&
        _is(paksha, "Shukla") &&
        _is(tithiName, "Navami")) {
      events.add(
        const PanchangEvent(
          id: "ram_navami",
          title: "Ram Navami",
          description:
              "Day to honour Shri Ram through paath, bhajan and satvik discipline.",
          isMajorFestival: true,
        ),
      );
    }

    // Krishna Janmashtami: Shravana / Bhadrapada Krishna Ashtami
    if (_is(paksha, "Krishna") &&
        _is(tithiName, "Ashtami") &&
        (_is(month, "shravana") || _is(month, "bhadrapada"))) {
      events.add(
        const PanchangEvent(
          id: "janmashtami",
          title: "Krishna Janmashtami",
          description:
              "Midnight upasana of Shri Krishna, great for bhakti, mantra and sankalp.",
          isMajorFestival: true,
          isFastingDay: true,
        ),
      );
    }

    // Guru Purnima: Ashadha Purnima
    if (_is(month, "ashadha") && tithiName.toLowerCase().contains("purnima")) {
      events.add(
        const PanchangEvent(
          id: "guru_purnima",
          title: "Guru Purnima",
          description:
              "Dedicated to Gurus; ideal for gratitude, seva and spiritual recommitment.",
          isMajorFestival: true,
        ),
      );
    }

    // If you want: yahan aur festivals add kar sakte ho same pattern se.

    return events;
  }

  /// User-facing one-line summary for Panchang card.
  /// Example:
  /// "Today is Tritiya (Krishna Paksha), Nakshatra Bharani. Special today: Ekadashi Vrat."
  static String buildSummaryLine(Map<String, dynamic> panchangJson) {
    final day = _selected(panchangJson);
    if (day == null) return "";

    final tithiName = _getNestedString(day, "tithi", "name");
    final paksha = _getNestedString(day, "tithi", "paksha");
    final nakshatra = _getNestedString(day, "nakshatra", "name");
    final weekday = _getString(day, "weekday");
    final month = _getString(day, "month_name");

    final events = detectEvents(panchangJson);

    final base = StringBuffer();

    if (tithiName.isNotEmpty) {
      base.write("Today is $tithiName");
      if (paksha.isNotEmpty) {
        base.write(" ($paksha Paksha)");
      }
      if (month.isNotEmpty) {
        base.write(" in $month month");
      }
      base.write(".");
    }

    if (nakshatra.isNotEmpty) {
      if (base.isNotEmpty) base.write(" ");
      base.write("Nakshatra is $nakshatra.");
    }

    if (weekday.isNotEmpty) {
      if (base.isNotEmpty) base.write(" ");
      base.write("Day: $weekday.");
    }

    if (events.isNotEmpty) {
      final label = events
          .map((e) => e.title)
          .toSet()
          .join(", "); // unique titles
      base.write(" Special today: $label.");
    }

    return base.toString();
  }

  /// Short line focused only on vrat suggestion:
  /// e.g. "Today you can observe Ekadashi Vrat." or "" if none.
  static String buildVratSuggestion(Map<String, dynamic> panchangJson) {
    final events = detectEvents(
      panchangJson,
    ).where((e) => e.isFastingDay).toList();
    if (events.isEmpty) return "";
    final names = events.map((e) => e.title).toSet().join(", ");
    return "Today you can observe $names.";
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static Map<String, dynamic>? _selected(Map<String, dynamic> json) {
    final sel = json["selected_date"];
    if (sel is Map<String, dynamic>) return sel;
    return json;
  }

  static String _getString(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v == null) return "";
    return v.toString();
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
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
    }
    return null;
  }

  static String _normalize(String s) => s.trim().toLowerCase();

  static bool _is(String actual, String expected) {
    if (actual.isEmpty || expected.isEmpty) return false;
    return _normalize(actual) == _normalize(expected);
  }
}
