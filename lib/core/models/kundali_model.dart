import 'dart:convert';

/// 🌞 Basic Planet structure
class Planet {
  final String name;
  final String sign;
  final int house;
  final double degree;
  final String nakshatra;
  final int pada;

  Planet({
    required this.name,
    required this.sign,
    required this.house,
    required this.degree,
    required this.nakshatra,
    required this.pada,
  });

  factory Planet.fromJson(Map<String, dynamic> json) {
    return Planet(
      name: json['name'] ?? '',
      sign: json['sign'] ?? '',
      house: json['house'] ?? 0,
      degree: (json['degree'] ?? 0).toDouble(),
      nakshatra: json['nakshatra'] ?? '',
      pada: json['pada'] ?? 0,
    );
  }
}

/// 🏠 House Overview
class HouseOverview {
  final int house;
  final String focus;
  final List<String> notablePlanets;
  final String summary;

  HouseOverview({
    required this.house,
    required this.focus,
    required this.notablePlanets,
    required this.summary,
  });

  factory HouseOverview.fromJson(Map<String, dynamic> json) {
    final planets =
        (json['notable_placements'] as List?)
            ?.map((e) => e['planet'].toString())
            .toList() ??
        [];
    return HouseOverview(
      house: json['house'] ?? 0,
      focus: json['focus'] ?? '',
      notablePlanets: planets,
      summary: json['summary'] ?? '',
    );
  }
}

/// 💫 Dasha summary
class DashaSummary {
  final String mahadasha;
  final String antardasha;
  final String impactSnippet;
  final String period;

  DashaSummary({
    required this.mahadasha,
    required this.antardasha,
    required this.impactSnippet,
    required this.period,
  });

  factory DashaSummary.fromJson(Map<String, dynamic> json) {
    final block = json['current_block'] ?? {};
    return DashaSummary(
      mahadasha: block['mahadasha'] ?? '',
      antardasha: block['antardasha'] ?? '',
      impactSnippet: block['impact_snippet'] ?? '',
      period: block['period'] ?? '',
    );
  }
}

/// 💎 Gemstone suggestion
class GemstoneSuggestion {
  final String gemstone;
  final String planet;
  final String substone;
  final String paragraph;

  GemstoneSuggestion({
    required this.gemstone,
    required this.planet,
    required this.substone,
    required this.paragraph,
  });

  factory GemstoneSuggestion.fromJson(Map<String, dynamic> json) {
    final gem = json['gemstone_suggestion'] ?? {};
    return GemstoneSuggestion(
      gemstone: gem['gemstone'] ?? '',
      planet: gem['planet'] ?? '',
      substone: gem['substone'] ?? '',
      paragraph: gem['paragraph'] ?? '',
    );
  }
}

/// 🌙 Moon traits
class MoonTraits {
  final String title;
  final String element;
  final String personality;
  final String rulingPlanet;
  final String symbol;
  final String image;

  MoonTraits({
    required this.title,
    required this.element,
    required this.personality,
    required this.rulingPlanet,
    required this.symbol,
    required this.image,
  });

  factory MoonTraits.fromJson(Map<String, dynamic> json) {
    final moon = json['moon_traits'] ?? {};
    return MoonTraits(
      title: moon['title'] ?? '',
      element: moon['element'] ?? '',
      personality: moon['personality'] ?? '',
      rulingPlanet: moon['ruling_planet'] ?? '',
      symbol: moon['symbol'] ?? '',
      image: moon['image'] ?? '',
    );
  }
}

/// 🔮 Core Kundali Model
class KundaliModel {
  final String lagnaSign;
  final String rashi;
  final String name;
  final String dob;
  final String tob;
  final String place;
  final List<Planet> planets;
  final List<HouseOverview> houses;
  final DashaSummary dashaSummary;
  final GemstoneSuggestion gemstone;
  final MoonTraits moonTraits;

  KundaliModel({
    required this.lagnaSign,
    required this.rashi,
    required this.name,
    required this.dob,
    required this.tob,
    required this.place,
    required this.planets,
    required this.houses,
    required this.dashaSummary,
    required this.gemstone,
    required this.moonTraits,
  });

  factory KundaliModel.fromJson(Map<String, dynamic> json) {
    final chart = json['chart_data'] ?? {};
    final profile = json['profile'] ?? {};
    final planets =
        (chart['planets'] as List?)?.map((e) => Planet.fromJson(e)).toList() ??
        [];
    final houses =
        (json['houses_overview'] as List?)
            ?.map((e) => HouseOverview.fromJson(e))
            .toList() ??
        [];

    return KundaliModel(
      lagnaSign: json['lagna_sign'] ?? '',
      rashi: json['rashi'] ?? '',
      name: profile['name'] ?? '',
      dob: profile['dob'] ?? '',
      tob: profile['tob'] ?? '',
      place: profile['place'] ?? '',
      planets: planets,
      houses: houses,
      dashaSummary: DashaSummary.fromJson(json['dasha_summary'] ?? {}),
      gemstone: GemstoneSuggestion.fromJson(json),
      moonTraits: MoonTraits.fromJson(json),
    );
  }

  static KundaliModel fromRawJson(String str) =>
      KundaliModel.fromJson(json.decode(str));
}
