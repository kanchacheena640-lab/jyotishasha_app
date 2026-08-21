import 'package:flutter/material.dart';
import 'package:jyotishasha_app/core/state/panchang_provider.dart';

import '../data/card_model.dart';
import '../data/card_templates.dart';
import '../data/night_thoughts.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class CardsProvider extends ChangeNotifier {
  List<CardModel> _cards = [];
  List<dynamic> _astroData = [];
  bool _loading = false;

  final Map<String, List<dynamic>> _muhurthCache = {};

  /// 🔥 ALL CARD IMAGES (ONE POOL)
  final List<String> _allImages = [
    // decor
    ...List.generate(
      6,
      (i) => "assets/cards/decor_${(i + 1).toString().padLeft(2, '0')}.webp",
    ),

    // monday
    ...List.generate(
      7,
      (i) => "assets/cards/monday_${(i + 1).toString().padLeft(2, '0')}.webp",
    ),

    // tuesday
    ...List.generate(
      7,
      (i) => "assets/cards/tuesday_${(i + 1).toString().padLeft(2, '0')}.webp",
    ),

    // wednesday
    ...List.generate(
      7,
      (i) =>
          "assets/cards/wednesday_${(i + 1).toString().padLeft(2, '0')}.webp",
    ),

    // thursday
    ...List.generate(
      5,
      (i) => "assets/cards/thursday_${(i + 1).toString().padLeft(2, '0')}.webp",
    ),

    // friday
    ...List.generate(
      6,
      (i) => "assets/cards/friday_${(i + 1).toString().padLeft(2, '0')}.webp",
    ),

    // saturday
    ...List.generate(
      5,
      (i) => "assets/cards/saturday_${(i + 1).toString().padLeft(2, '0')}.webp",
    ),

    // sunday
    ...List.generate(
      4,
      (i) => "assets/cards/sunday_${(i + 1).toString().padLeft(2, '0')}.webp",
    ),
  ];

  /// 🔥 RANDOM IMAGE FUNCTION
  final _random = Random();

  String _getRandomImage() {
    return _allImages[_random.nextInt(_allImages.length)];
  }

  String? _error;

  List<CardModel> get cards => _cards;
  bool get loading => _loading;
  String? get error => _error;

  /// ✅ MORNING IMAGE
  String _getMorningImage() {
    final now = DateTime.now();

    const dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    final dayName = dayNames[now.weekday - 1];
    final index = (now.day % 3) + 1;

    return 'assets/cards/${dayName}_0$index.webp';
  }

  /// ✅ NIGHT IMAGE
  String _getNightImage() {
    final now = DateTime.now();

    const dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    final dayName = dayNames[now.weekday - 1];

    final morningIndex = (now.day % 3) + 1;
    final nightIndex = (morningIndex % 3) + 1;

    return 'assets/cards/${dayName}_0$nightIndex.webp';
  }

  /// ✅ BILINGUAL THOUGHT
  String _getDailyNightThought(bool isHindi) {
    final now = DateTime.now();

    // same day → same index
    final index = now.year + now.month + now.day;

    if (isHindi) {
      return nightThoughtsHi[index % nightThoughtsHi.length];
    } else {
      return nightThoughtsEn[index % nightThoughtsEn.length];
    }
  }

  /// TIME LOGIC
  bool _isMorningTime() {
    final hour = DateTime.now().hour;
    return hour >= 4 && hour < 12; // 👈 FIX
  }

  bool _isNightTime() {
    final hour = DateTime.now().hour;
    return hour >= 18 && hour <= 23; // 👈 FIX
  }

  Future<void> _loadAstroJson() async {
    final String jsonString = await rootBundle.loadString(
      'assets/data/astro_cards.json',
    );

    _astroData = json.decode(jsonString);
  }

  Future<List<dynamic>> _loadInsightJson() async {
    final String jsonString = await rootBundle.loadString(
      'assets/data/insight_cards.json',
    );

    return json.decode(jsonString);
  }

  Future<List<dynamic>> _fetchMuhurthCards({
    required String activity,
    required bool isHindi,
    required PanchangProvider panchang,
  }) async {
    /// 🔥 CACHE KEY
    final cacheKey =
        "${activity}_${isHindi}_${panchang.savedLat}_${panchang.savedLng}";

    /// 🔥 MEMORY CACHE
    if (_muhurthCache.containsKey(cacheKey)) {
      return _muhurthCache[cacheKey]!;
    }

    const baseUrl = "https://jyotishasha-backend.onrender.com/api/muhurth/list";

    final body = {
      "activity": activity,
      "latitude": panchang.savedLat,
      "longitude": panchang.savedLng,
      "days": 45,
      "top_k": 5,
      "language": isHindi ? "hi" : "en",
    };

    // Release-gate fix (P0): a stalled/never-responding request (Render
    // cold start, dropped connection) previously hung this await
    // forever. TimeoutException propagates to this method's caller
    // exactly like any other exception -- caught by its existing
    // try/catch, which already resets `_loading` unconditionally.
    final res = await http
        .post(
          Uri.parse(baseUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 12));

    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);

    final results = data["results"] ?? [];

    /// 🔥 SAVE CACHE
    _muhurthCache[cacheKey] = results;

    return results;
  }

  String _planetHi(String planet) {
    switch (planet.toLowerCase()) {
      case 'sun':
        return 'सूर्य';

      case 'moon':
        return 'चंद्र';

      case 'mars':
        return 'मंगल';

      case 'mercury':
        return 'बुध';

      case 'jupiter':
        return 'गुरु';

      case 'venus':
        return 'शुक्र';

      case 'saturn':
        return 'शनि';

      case 'rahu':
        return 'राहु';

      case 'ketu':
        return 'केतु';

      default:
        return planet;
    }
  }

  Future<void> loadCards({
    required PanchangProvider panchang,
    required bool isHindi,
    String? initialType,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (_astroData.isEmpty) {
        await _loadAstroJson();
      }

      final insightData = await _loadInsightJson();

      final hasPanchang = panchang.fullPanchang != null;

      final List<CardModel> priorityCards = [];
      final List<CardModel> muhurthCards = [];
      final List<CardModel> tempCards = [];

      final String rahu = "${panchang.rahukaalStart} - ${panchang.rahukaalEnd}";
      final String abhijit =
          "${panchang.abhijitStart} - ${panchang.abhijitEnd}";

      final morningTemplate = CARD_TEMPLATES["morning"]!;
      final nightTemplate = CARD_TEMPLATES["night"]!;

      final morningContentEn = (morningTemplate["content_en"] as String)
          .replaceAll("{abhijit}", abhijit)
          .replaceAll("{rahu}", rahu);

      final morningContentHi = (morningTemplate["content_hi"] as String)
          .replaceAll("{abhijit}", abhijit)
          .replaceAll("{rahu}", rahu);

      /// 🌅 MORNING CARD
      if (_isMorningTime() && hasPanchang) {
        priorityCards.add(
          CardModel(
            type: "morning",
            designType: "image_bg",
            image: _getMorningImage(),
            titleEn: morningTemplate["title_en"],
            titleHi: morningTemplate["title_hi"],
            contentEn: morningContentEn,
            contentHi: morningContentHi,
            meta: {
              "abhijit": abhijit,
              "rahu": rahu,
              "cta_en": morningTemplate["cta_en"],
              "cta_hi": morningTemplate["cta_hi"],
              "share_en": morningTemplate["share_text_en"],
              "share_hi": morningTemplate["share_text_hi"],
            },
          ),
        );
      }

      /// 🌙 NIGHT CARD
      if (_isNightTime()) {
        final thoughtHi = _getDailyNightThought(true);
        final thoughtEn = _getDailyNightThought(false);

        priorityCards.add(
          CardModel(
            type: "night",
            designType: "image_bg",
            image: _getNightImage(),
            titleEn: nightTemplate["title_en"],
            titleHi: nightTemplate["title_hi"],

            /// ✅ FIXED
            contentEn: (nightTemplate["content_en"] as String).replaceAll(
              "{night_thought}",
              thoughtEn,
            ),

            contentHi: (nightTemplate["content_hi"] as String).replaceAll(
              "{night_thought}",
              thoughtHi,
            ),

            meta: {
              /// optional but clean
              "night_thought_en": thoughtEn,
              "night_thought_hi": thoughtHi,

              "cta_en": nightTemplate["cta_en"],
              "cta_hi": nightTemplate["cta_hi"],
              "share_en": nightTemplate["share_text_en"],
              "share_hi": nightTemplate["share_text_hi"],
            },
          ),
        );
      }

      /// 🔮 ASTRO CARD

      final filtered = List.of(_astroData);

      filtered.shuffle();

      final count = filtered.length >= 20 ? 20 : filtered.length;

      for (int i = 0; i < count; i++) {
        final astro = filtered[i];

        tempCards.add(
          CardModel(
            type: "astro",
            designType: "image_bg",
            image: _getRandomImage(),
            titleEn: "Remedy for ${astro["planet"]}",
            titleHi: "${_planetHi(astro["planet"])} के लिए उपाय",
            contentEn: astro["text_en"],
            contentHi: astro["text_hi"],
            meta: {"planet": astro["planet"]},
          ),
        );
      }

      /// 🪔 REAL MUHURTH CARDS

      final activities = [
        "naamkaran",
        "marriage",
        "grah_pravesh",
        "property",
        "gold",
        "vehicle",
        "travel",
        "childbirth",
      ];

      final titlesEn = {
        "naamkaran": "Naamkaran Muhurth",
        "marriage": "Marriage Muhurth",
        "grah_pravesh": "Griha Pravesh Muhurth",
        "property": "Property Purchase Muhurth",
        "gold": "Gold Purchase Muhurth",
        "vehicle": "Vehicle Purchase Muhurth",
        "travel": "Travel Muhurth",
        "childbirth": "Childbirth Muhurth",
      };

      final titlesHi = {
        "naamkaran": "नामकरण मुहूर्त",
        "marriage": "विवाह मुहूर्त",
        "grah_pravesh": "गृह प्रवेश मुहूर्त",
        "property": "संपत्ति क्रय मुहूर्त",
        "gold": "सोना खरीद मुहूर्त",
        "vehicle": "वाहन खरीद मुहूर्त",
        "travel": "यात्रा मुहूर्त",
        "childbirth": "शिशु जन्म मुहूर्त",
      };

      final futures = activities.map((activity) async {
        final results = await _fetchMuhurthCards(
          activity: activity,
          isHindi: isHindi,
          panchang: panchang,
        );

        return {"activity": activity, "results": results};
      }).toList();

      final responses = await Future.wait(futures);

      for (final response in responses) {
        final activity = response["activity"] as String;

        final results = response["results"] as List<dynamic>;

        if (results.isEmpty) continue;

        final compactDates = results.map((item) {
          final rawDate = item["date"]?.toString() ?? "";

          String formatted = rawDate;

          try {
            final d = DateTime.parse(rawDate);

            formatted =
                "${d.day.toString().padLeft(2, '0')}-"
                "${d.month.toString().padLeft(2, '0')}-"
                "${d.year}";
          } catch (_) {}

          final score = int.tryParse(item["score"].toString()) ?? 0;

          final percent = switch (score) {
            7 => 100,
            6 => 90,
            5 => 75,
            4 => 60,
            3 => 45,
            _ => 35,
          };

          return "$formatted  •  $percent% auspicious";
        }).toList();

        muhurthCards.add(
          CardModel(
            type: "muhurth",
            muhurthType: activity,
            designType: "muhurth",

            image: _getRandomImage(),

            titleEn: titlesEn[activity] ?? "Shubh Muhurth",

            titleHi: titlesHi[activity] ?? "शुभ मुहूर्त",

            contentEn: compactDates.join("\n"),
            contentHi: compactDates.join("\n"),
          ),
        );
      }

      /// 💡 INSIGHT CARDS

      final shuffledInsights = List.of(insightData)..shuffle();

      final insightCount = shuffledInsights.length >= 20
          ? 20
          : shuffledInsights.length;

      for (int i = 0; i < insightCount; i++) {
        final insight = shuffledInsights[i];

        tempCards.add(
          CardModel(
            type: "insight",
            designType: "image_bg",
            image: _getRandomImage(), // 👈 no image
            titleEn: "",
            titleHi: "",
            contentEn: insight["text_en"],
            contentHi: insight["text_hi"],
            meta: {
              "cta_en": "Available on Play Store",
              "cta_hi": "Play Store पर उपलब्ध",
            },
          ),
        );
      }

      if (initialType != null) {
        final matched = muhurthCards
            .where((e) => e.muhurthType == initialType)
            .toList();

        final remaining = muhurthCards
            .where((e) => e.muhurthType != initialType)
            .toList();

        _cards = [...priorityCards, ...matched, ...remaining, ...tempCards];
      } else {
        _cards = [...priorityCards, ...muhurthCards, ...tempCards];
      }
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }
}
