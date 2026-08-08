import '../contract_support.dart';
import '../profile/birth_details.dart';

final class KundaliProfile extends ContractValue {
  const KundaliProfile({
    this.name,
    this.birthDetails,
    this.language,
    this.ayanamsa,
  });

  final String? name;
  final BirthDetails? birthDetails;
  final String? language;
  final String? ayanamsa;

  factory KundaliProfile.fromJson(JsonMap json) => KundaliProfile(
    name: asString(json['name']),
    birthDetails: BirthDetails.fromJson(json),
    language: stringFrom(json, const ['language', 'lang']),
    ayanamsa: asString(json['ayanamsa']),
  );

  JsonMap toJson() => {
    'name': name,
    ...?birthDetails?.toJson(),
    'language': language,
    'ayanamsa': ayanamsa,
  };

  KundaliProfile copyWith({
    Object? name = contractUnchanged,
    Object? birthDetails = contractUnchanged,
    Object? language = contractUnchanged,
    Object? ayanamsa = contractUnchanged,
  }) => KundaliProfile(
    name: identical(name, contractUnchanged) ? this.name : name as String?,
    birthDetails: identical(birthDetails, contractUnchanged)
        ? this.birthDetails
        : birthDetails as BirthDetails?,
    language: identical(language, contractUnchanged)
        ? this.language
        : language as String?,
    ayanamsa: identical(ayanamsa, contractUnchanged)
        ? this.ayanamsa
        : ayanamsa as String?,
  );

  @override
  List<Object?> get props => [name, birthDetails, language, ayanamsa];
}

final class KundaliRequest extends ContractValue {
  const KundaliRequest({this.profile});

  final KundaliProfile? profile;

  factory KundaliRequest.fromJson(JsonMap json) {
    final nested = asJsonMap(json['profile']);
    return KundaliRequest(profile: KundaliProfile.fromJson(nested ?? json));
  }

  JsonMap toJson() => profile?.toJson() ?? const {};

  KundaliRequest copyWith({Object? profile = contractUnchanged}) =>
      KundaliRequest(
        profile: identical(profile, contractUnchanged)
            ? this.profile
            : profile as KundaliProfile?,
      );

  @override
  List<Object?> get props => [profile];
}

final class ChartHouse extends ContractValue {
  const ChartHouse({this.house, this.sign, this.planets});

  final int? house;
  final String? sign;
  final List<String>? planets;

  factory ChartHouse.fromJson(JsonMap json) => ChartHouse(
    house: asInt(json['house']),
    sign: stringFrom(json, const ['sign', 'rashi']),
    planets: asStringList(json['planets']),
  );

  JsonMap toJson() => {'house': house, 'sign': sign, 'planets': planets};

  ChartHouse copyWith({
    Object? house = contractUnchanged,
    Object? sign = contractUnchanged,
    Object? planets = contractUnchanged,
  }) => ChartHouse(
    house: identical(house, contractUnchanged) ? this.house : house as int?,
    sign: identical(sign, contractUnchanged) ? this.sign : sign as String?,
    planets: identical(planets, contractUnchanged)
        ? this.planets
        : planets as List<String>?,
  );

  @override
  List<Object?> get props => [house, sign, planets];
}

final class PlanetPlacement extends ContractValue {
  const PlanetPlacement({
    this.name,
    this.sign,
    this.house,
    this.degree,
    this.nakshatra,
    this.pada,
    this.motion,
    this.details,
  });

  final String? name;
  final String? sign;
  final int? house;
  final double? degree;
  final String? nakshatra;
  final int? pada;
  final String? motion;
  final JsonMap? details;

  factory PlanetPlacement.fromJson(JsonMap json) => PlanetPlacement(
    name: stringFrom(json, const ['name', 'planet']),
    sign: stringFrom(json, const ['sign', 'rashi']),
    house: asInt(json['house']),
    degree: asDouble(json['degree']),
    nakshatra: asString(json['nakshatra']),
    pada: asInt(json['pada']),
    motion: asString(json['motion']),
    details: asJsonMap(json['details']),
  );

  JsonMap toJson() => {
    'name': name,
    'sign': sign,
    'house': house,
    'degree': degree,
    'nakshatra': nakshatra,
    'pada': pada,
    'motion': motion,
    'details': details,
  };

  PlanetPlacement copyWith({
    Object? name = contractUnchanged,
    Object? sign = contractUnchanged,
    Object? house = contractUnchanged,
    Object? degree = contractUnchanged,
    Object? nakshatra = contractUnchanged,
    Object? pada = contractUnchanged,
    Object? motion = contractUnchanged,
    Object? details = contractUnchanged,
  }) => PlanetPlacement(
    name: identical(name, contractUnchanged) ? this.name : name as String?,
    sign: identical(sign, contractUnchanged) ? this.sign : sign as String?,
    house: identical(house, contractUnchanged) ? this.house : house as int?,
    degree: identical(degree, contractUnchanged)
        ? this.degree
        : degree as double?,
    nakshatra: identical(nakshatra, contractUnchanged)
        ? this.nakshatra
        : nakshatra as String?,
    pada: identical(pada, contractUnchanged) ? this.pada : pada as int?,
    motion: identical(motion, contractUnchanged)
        ? this.motion
        : motion as String?,
    details: identical(details, contractUnchanged)
        ? this.details
        : details as JsonMap?,
  );

  @override
  List<Object?> get props => [
    name,
    sign,
    house,
    degree,
    nakshatra,
    pada,
    motion,
    details,
  ];
}

final class ChartData extends ContractValue {
  const ChartData({this.houses, this.planets});

  final List<ChartHouse>? houses;
  final List<PlanetPlacement>? planets;

  factory ChartData.fromJson(JsonMap json) => ChartData(
    houses: asModelList(json['houses'], ChartHouse.fromJson),
    planets: asModelList(json['planets'], PlanetPlacement.fromJson),
  );

  JsonMap toJson() => {
    'houses': modelsToJson(houses, (item) => item.toJson()),
    'planets': modelsToJson(planets, (item) => item.toJson()),
  };

  ChartData copyWith({
    Object? houses = contractUnchanged,
    Object? planets = contractUnchanged,
  }) => ChartData(
    houses: identical(houses, contractUnchanged)
        ? this.houses
        : houses as List<ChartHouse>?,
    planets: identical(planets, contractUnchanged)
        ? this.planets
        : planets as List<PlanetPlacement>?,
  );

  @override
  List<Object?> get props => [houses, planets];
}

final class NotablePlacement extends ContractValue {
  const NotablePlacement({this.planet, this.description, this.details});

  final String? planet;
  final String? description;
  final JsonMap? details;

  factory NotablePlacement.fromJson(JsonMap json) => NotablePlacement(
    planet: asString(json['planet']),
    description: stringFrom(json, const ['description', 'summary']),
    details: asJsonMap(json['details']),
  );

  JsonMap toJson() => {
    'planet': planet,
    'description': description,
    'details': details,
  };

  NotablePlacement copyWith({
    Object? planet = contractUnchanged,
    Object? description = contractUnchanged,
    Object? details = contractUnchanged,
  }) => NotablePlacement(
    planet: identical(planet, contractUnchanged)
        ? this.planet
        : planet as String?,
    description: identical(description, contractUnchanged)
        ? this.description
        : description as String?,
    details: identical(details, contractUnchanged)
        ? this.details
        : details as JsonMap?,
  );

  @override
  List<Object?> get props => [planet, description, details];
}

final class KundaliHouseOverview extends ContractValue {
  const KundaliHouseOverview({
    this.house,
    this.focus,
    this.summary,
    this.notablePlacements,
  });

  final int? house;
  final String? focus;
  final String? summary;
  final List<NotablePlacement>? notablePlacements;

  factory KundaliHouseOverview.fromJson(JsonMap json) => KundaliHouseOverview(
    house: asInt(json['house']),
    focus: asString(json['focus']),
    summary: asString(json['summary']),
    notablePlacements: asModelList(
      json['notable_placements'],
      NotablePlacement.fromJson,
    ),
  );

  JsonMap toJson() => {
    'house': house,
    'focus': focus,
    'summary': summary,
    'notable_placements': modelsToJson(
      notablePlacements,
      (item) => item.toJson(),
    ),
  };

  KundaliHouseOverview copyWith({
    Object? house = contractUnchanged,
    Object? focus = contractUnchanged,
    Object? summary = contractUnchanged,
    Object? notablePlacements = contractUnchanged,
  }) => KundaliHouseOverview(
    house: identical(house, contractUnchanged) ? this.house : house as int?,
    focus: identical(focus, contractUnchanged) ? this.focus : focus as String?,
    summary: identical(summary, contractUnchanged)
        ? this.summary
        : summary as String?,
    notablePlacements: identical(notablePlacements, contractUnchanged)
        ? this.notablePlacements
        : notablePlacements as List<NotablePlacement>?,
  );

  @override
  List<Object?> get props => [house, focus, summary, notablePlacements];
}

final class DashaPeriod extends ContractValue {
  const DashaPeriod({this.start, this.end, this.period});

  final String? start;
  final String? end;
  final String? period;

  factory DashaPeriod.fromJson(JsonMap json) => DashaPeriod(
    start: asString(json['start']),
    end: asString(json['end']),
    period: asString(json['period']),
  );

  JsonMap toJson() => {'start': start, 'end': end, 'period': period};

  DashaPeriod copyWith({
    Object? start = contractUnchanged,
    Object? end = contractUnchanged,
    Object? period = contractUnchanged,
  }) => DashaPeriod(
    start: identical(start, contractUnchanged) ? this.start : start as String?,
    end: identical(end, contractUnchanged) ? this.end : end as String?,
    period: identical(period, contractUnchanged)
        ? this.period
        : period as String?,
  );

  @override
  List<Object?> get props => [start, end, period];
}

final class Antardasha extends ContractValue {
  const Antardasha({this.planet, this.period, this.impact});

  final String? planet;
  final DashaPeriod? period;
  final String? impact;

  factory Antardasha.fromJson(JsonMap json) => Antardasha(
    planet: stringFrom(json, const ['planet', 'antardasha', 'name']),
    period: DashaPeriod.fromJson(json),
    impact: stringFrom(json, const ['impact', 'impact_snippet']),
  );

  JsonMap toJson() => {
    'planet': planet,
    ...?period?.toJson(),
    'impact': impact,
  };

  Antardasha copyWith({
    Object? planet = contractUnchanged,
    Object? period = contractUnchanged,
    Object? impact = contractUnchanged,
  }) => Antardasha(
    planet: identical(planet, contractUnchanged)
        ? this.planet
        : planet as String?,
    period: identical(period, contractUnchanged)
        ? this.period
        : period as DashaPeriod?,
    impact: identical(impact, contractUnchanged)
        ? this.impact
        : impact as String?,
  );

  @override
  List<Object?> get props => [planet, period, impact];
}

final class Mahadasha extends ContractValue {
  const Mahadasha({this.planet, this.period, this.antardashas, this.impact});

  final String? planet;
  final DashaPeriod? period;
  final List<Antardasha>? antardashas;
  final String? impact;

  factory Mahadasha.fromJson(JsonMap json) => Mahadasha(
    planet: stringFrom(json, const ['planet', 'mahadasha', 'name']),
    period: DashaPeriod.fromJson(json),
    antardashas: asModelList(json['antardashas'], Antardasha.fromJson),
    impact: stringFrom(json, const ['impact', 'impact_snippet']),
  );

  JsonMap toJson() => {
    'planet': planet,
    ...?period?.toJson(),
    'antardashas': modelsToJson(antardashas, (item) => item.toJson()),
    'impact': impact,
  };

  Mahadasha copyWith({
    Object? planet = contractUnchanged,
    Object? period = contractUnchanged,
    Object? antardashas = contractUnchanged,
    Object? impact = contractUnchanged,
  }) => Mahadasha(
    planet: identical(planet, contractUnchanged)
        ? this.planet
        : planet as String?,
    period: identical(period, contractUnchanged)
        ? this.period
        : period as DashaPeriod?,
    antardashas: identical(antardashas, contractUnchanged)
        ? this.antardashas
        : antardashas as List<Antardasha>?,
    impact: identical(impact, contractUnchanged)
        ? this.impact
        : impact as String?,
  );

  @override
  List<Object?> get props => [planet, period, antardashas, impact];
}

final class KundaliDashaSummary extends ContractValue {
  const KundaliDashaSummary({
    this.currentMahadasha,
    this.currentAntardasha,
    this.currentPeriod,
    this.impactSnippet,
    this.mahadashas,
  });

  final String? currentMahadasha;
  final String? currentAntardasha;
  final String? currentPeriod;
  final String? impactSnippet;
  final List<Mahadasha>? mahadashas;

  factory KundaliDashaSummary.fromJson(JsonMap json) {
    final current = asJsonMap(json['current_block']) ?? json;
    return KundaliDashaSummary(
      currentMahadasha: stringFrom(current, const [
        'mahadasha',
        'current_mahadasha',
      ]),
      currentAntardasha: stringFrom(current, const [
        'antardasha',
        'current_antardasha',
      ]),
      currentPeriod: asString(current['period']),
      impactSnippet: asString(current['impact_snippet']),
      mahadashas: asModelList(json['mahadashas'], Mahadasha.fromJson),
    );
  }

  JsonMap toJson() => {
    'current_block': {
      'mahadasha': currentMahadasha,
      'antardasha': currentAntardasha,
      'period': currentPeriod,
      'impact_snippet': impactSnippet,
    },
    'mahadashas': modelsToJson(mahadashas, (item) => item.toJson()),
  };

  KundaliDashaSummary copyWith({
    Object? currentMahadasha = contractUnchanged,
    Object? currentAntardasha = contractUnchanged,
    Object? currentPeriod = contractUnchanged,
    Object? impactSnippet = contractUnchanged,
    Object? mahadashas = contractUnchanged,
  }) => KundaliDashaSummary(
    currentMahadasha: identical(currentMahadasha, contractUnchanged)
        ? this.currentMahadasha
        : currentMahadasha as String?,
    currentAntardasha: identical(currentAntardasha, contractUnchanged)
        ? this.currentAntardasha
        : currentAntardasha as String?,
    currentPeriod: identical(currentPeriod, contractUnchanged)
        ? this.currentPeriod
        : currentPeriod as String?,
    impactSnippet: identical(impactSnippet, contractUnchanged)
        ? this.impactSnippet
        : impactSnippet as String?,
    mahadashas: identical(mahadashas, contractUnchanged)
        ? this.mahadashas
        : mahadashas as List<Mahadasha>?,
  );

  @override
  List<Object?> get props => [
    currentMahadasha,
    currentAntardasha,
    currentPeriod,
    impactSnippet,
    mahadashas,
  ];
}

final class YogaDoshaEntry extends ContractValue {
  const YogaDoshaEntry({
    this.name,
    this.present,
    this.description,
    this.remedies,
    this.details,
  });

  final String? name;
  final bool? present;
  final String? description;
  final List<String>? remedies;
  final JsonMap? details;

  factory YogaDoshaEntry.fromJson(JsonMap json) => YogaDoshaEntry(
    name: stringFrom(json, const ['name', 'title', 'yoga', 'dosha']),
    present: asBool(json['present'] ?? json['active'] ?? json['is_present']),
    description: stringFrom(json, const ['description', 'summary']),
    remedies: asStringList(json['remedies']),
    details: asJsonMap(json['details']),
  );

  JsonMap toJson() => {
    'name': name,
    'present': present,
    'description': description,
    'remedies': remedies,
    'details': details,
  };

  YogaDoshaEntry copyWith({
    Object? name = contractUnchanged,
    Object? present = contractUnchanged,
    Object? description = contractUnchanged,
    Object? remedies = contractUnchanged,
    Object? details = contractUnchanged,
  }) => YogaDoshaEntry(
    name: identical(name, contractUnchanged) ? this.name : name as String?,
    present: identical(present, contractUnchanged)
        ? this.present
        : present as bool?,
    description: identical(description, contractUnchanged)
        ? this.description
        : description as String?,
    remedies: identical(remedies, contractUnchanged)
        ? this.remedies
        : remedies as List<String>?,
    details: identical(details, contractUnchanged)
        ? this.details
        : details as JsonMap?,
  );

  @override
  List<Object?> get props => [name, present, description, remedies, details];
}

final class YogaDoshaCollection extends ContractValue {
  const YogaDoshaCollection({this.yogas, this.doshas});

  final List<YogaDoshaEntry>? yogas;
  final List<YogaDoshaEntry>? doshas;

  factory YogaDoshaCollection.fromJson(JsonMap json) => YogaDoshaCollection(
    yogas: asModelList(json['yogas'], YogaDoshaEntry.fromJson),
    doshas: asModelList(
      json['doshas'] ?? json['yog_doshas'],
      YogaDoshaEntry.fromJson,
    ),
  );

  JsonMap toJson() => {
    'yogas': modelsToJson(yogas, (item) => item.toJson()),
    'doshas': modelsToJson(doshas, (item) => item.toJson()),
  };

  YogaDoshaCollection copyWith({
    Object? yogas = contractUnchanged,
    Object? doshas = contractUnchanged,
  }) => YogaDoshaCollection(
    yogas: identical(yogas, contractUnchanged)
        ? this.yogas
        : yogas as List<YogaDoshaEntry>?,
    doshas: identical(doshas, contractUnchanged)
        ? this.doshas
        : doshas as List<YogaDoshaEntry>?,
  );

  @override
  List<Object?> get props => [yogas, doshas];
}

final class LifeAspect extends ContractValue {
  const LifeAspect({this.name, this.title, this.summary, this.details});

  final String? name;
  final String? title;
  final String? summary;
  final JsonMap? details;

  factory LifeAspect.fromJson(JsonMap json) => LifeAspect(
    name: stringFrom(json, const ['name', 'key', 'type']),
    title: asString(json['title']),
    summary: stringFrom(json, const ['summary', 'description', 'content']),
    details: asJsonMap(json['details']),
  );

  JsonMap toJson() => {
    'name': name,
    'title': title,
    'summary': summary,
    'details': details,
  };

  LifeAspect copyWith({
    Object? name = contractUnchanged,
    Object? title = contractUnchanged,
    Object? summary = contractUnchanged,
    Object? details = contractUnchanged,
  }) => LifeAspect(
    name: identical(name, contractUnchanged) ? this.name : name as String?,
    title: identical(title, contractUnchanged) ? this.title : title as String?,
    summary: identical(summary, contractUnchanged)
        ? this.summary
        : summary as String?,
    details: identical(details, contractUnchanged)
        ? this.details
        : details as JsonMap?,
  );

  @override
  List<Object?> get props => [name, title, summary, details];
}

final class GemstoneRecommendation extends ContractValue {
  const GemstoneRecommendation({
    this.gemstone,
    this.planet,
    this.substone,
    this.paragraph,
  });

  final String? gemstone;
  final String? planet;
  final String? substone;
  final String? paragraph;

  factory GemstoneRecommendation.fromJson(JsonMap json) =>
      GemstoneRecommendation(
        gemstone: asString(json['gemstone']),
        planet: asString(json['planet']),
        substone: asString(json['substone']),
        paragraph: stringFrom(json, const ['paragraph', 'description']),
      );

  JsonMap toJson() => {
    'gemstone': gemstone,
    'planet': planet,
    'substone': substone,
    'paragraph': paragraph,
  };

  GemstoneRecommendation copyWith({
    Object? gemstone = contractUnchanged,
    Object? planet = contractUnchanged,
    Object? substone = contractUnchanged,
    Object? paragraph = contractUnchanged,
  }) => GemstoneRecommendation(
    gemstone: identical(gemstone, contractUnchanged)
        ? this.gemstone
        : gemstone as String?,
    planet: identical(planet, contractUnchanged)
        ? this.planet
        : planet as String?,
    substone: identical(substone, contractUnchanged)
        ? this.substone
        : substone as String?,
    paragraph: identical(paragraph, contractUnchanged)
        ? this.paragraph
        : paragraph as String?,
  );

  @override
  List<Object?> get props => [gemstone, planet, substone, paragraph];
}

final class KundaliMoonTraits extends ContractValue {
  const KundaliMoonTraits({
    this.title,
    this.element,
    this.personality,
    this.rulingPlanet,
    this.symbol,
    this.image,
  });

  final String? title;
  final String? element;
  final String? personality;
  final String? rulingPlanet;
  final String? symbol;
  final String? image;

  factory KundaliMoonTraits.fromJson(JsonMap json) => KundaliMoonTraits(
    title: asString(json['title']),
    element: asString(json['element']),
    personality: asString(json['personality']),
    rulingPlanet: stringFrom(json, const ['ruling_planet', 'rulingPlanet']),
    symbol: asString(json['symbol']),
    image: asString(json['image']),
  );

  JsonMap toJson() => {
    'title': title,
    'element': element,
    'personality': personality,
    'ruling_planet': rulingPlanet,
    'symbol': symbol,
    'image': image,
  };

  KundaliMoonTraits copyWith({
    Object? title = contractUnchanged,
    Object? element = contractUnchanged,
    Object? personality = contractUnchanged,
    Object? rulingPlanet = contractUnchanged,
    Object? symbol = contractUnchanged,
    Object? image = contractUnchanged,
  }) => KundaliMoonTraits(
    title: identical(title, contractUnchanged) ? this.title : title as String?,
    element: identical(element, contractUnchanged)
        ? this.element
        : element as String?,
    personality: identical(personality, contractUnchanged)
        ? this.personality
        : personality as String?,
    rulingPlanet: identical(rulingPlanet, contractUnchanged)
        ? this.rulingPlanet
        : rulingPlanet as String?,
    symbol: identical(symbol, contractUnchanged)
        ? this.symbol
        : symbol as String?,
    image: identical(image, contractUnchanged) ? this.image : image as String?,
  );

  @override
  List<Object?> get props => [
    title,
    element,
    personality,
    rulingPlanet,
    symbol,
    image,
  ];
}

final class KundaliToolResult extends ContractValue {
  const KundaliToolResult({this.type, this.data});

  final String? type;
  final JsonMap? data;

  factory KundaliToolResult.fromJson(JsonMap json) => KundaliToolResult(
    type: stringFrom(json, const ['type', 'tool']),
    data: asJsonMap(json['data'] ?? json['result']),
  );

  JsonMap toJson() => {'type': type, 'data': data};

  KundaliToolResult copyWith({
    Object? type = contractUnchanged,
    Object? data = contractUnchanged,
  }) => KundaliToolResult(
    type: identical(type, contractUnchanged) ? this.type : type as String?,
    data: identical(data, contractUnchanged) ? this.data : data as JsonMap?,
  );

  @override
  List<Object?> get props => [type, data];
}

final class KundaliResponse extends ContractValue {
  const KundaliResponse({
    this.ok,
    this.profile,
    this.lagnaSign,
    this.rashi,
    this.chartData,
    this.planetOverview,
    this.housesOverview,
    this.dashaSummary,
    this.yogaDosha,
    this.lifeAspects,
    this.gemstoneRecommendation,
    this.moonTraits,
    this.toolResults,
    this.error,
  });

  final bool? ok;
  final KundaliProfile? profile;
  final String? lagnaSign;
  final String? rashi;
  final ChartData? chartData;
  final List<PlanetPlacement>? planetOverview;
  final List<KundaliHouseOverview>? housesOverview;
  final KundaliDashaSummary? dashaSummary;
  final YogaDoshaCollection? yogaDosha;
  final List<LifeAspect>? lifeAspects;
  final GemstoneRecommendation? gemstoneRecommendation;
  final KundaliMoonTraits? moonTraits;
  final List<KundaliToolResult>? toolResults;
  final String? error;

  factory KundaliResponse.fromJson(JsonMap json) => KundaliResponse(
    ok: asBool(json['ok']),
    profile: asModel(json['profile'], KundaliProfile.fromJson),
    lagnaSign: stringFrom(json, const ['lagna_sign', 'lagna']),
    rashi: stringFrom(json, const ['rashi', 'moon_sign']),
    chartData: asModel(json['chart_data'], ChartData.fromJson),
    planetOverview: asModelList(
      json['planet_overview'],
      PlanetPlacement.fromJson,
    ),
    housesOverview: asModelList(
      json['houses_overview'],
      KundaliHouseOverview.fromJson,
    ),
    dashaSummary: asModel(json['dasha_summary'], KundaliDashaSummary.fromJson),
    yogaDosha: YogaDoshaCollection.fromJson(json),
    lifeAspects: asModelList(json['life_aspects'], LifeAspect.fromJson),
    gemstoneRecommendation: asModel(
      json['gemstone_suggestion'],
      GemstoneRecommendation.fromJson,
    ),
    moonTraits: asModel(json['moon_traits'], KundaliMoonTraits.fromJson),
    toolResults: asModelList(json['tool_results'], KundaliToolResult.fromJson),
    error: asString(json['error']),
  );

  JsonMap toJson() => {
    'ok': ok,
    'profile': profile?.toJson(),
    'lagna_sign': lagnaSign,
    'rashi': rashi,
    'chart_data': chartData?.toJson(),
    'planet_overview': modelsToJson(planetOverview, (item) => item.toJson()),
    'houses_overview': modelsToJson(housesOverview, (item) => item.toJson()),
    'dasha_summary': dashaSummary?.toJson(),
    ...?yogaDosha?.toJson(),
    'life_aspects': modelsToJson(lifeAspects, (item) => item.toJson()),
    'gemstone_suggestion': gemstoneRecommendation?.toJson(),
    'moon_traits': moonTraits?.toJson(),
    'tool_results': modelsToJson(toolResults, (item) => item.toJson()),
    'error': error,
  };

  KundaliResponse copyWith({
    Object? ok = contractUnchanged,
    Object? profile = contractUnchanged,
    Object? lagnaSign = contractUnchanged,
    Object? rashi = contractUnchanged,
    Object? chartData = contractUnchanged,
    Object? planetOverview = contractUnchanged,
    Object? housesOverview = contractUnchanged,
    Object? dashaSummary = contractUnchanged,
    Object? yogaDosha = contractUnchanged,
    Object? lifeAspects = contractUnchanged,
    Object? gemstoneRecommendation = contractUnchanged,
    Object? moonTraits = contractUnchanged,
    Object? toolResults = contractUnchanged,
    Object? error = contractUnchanged,
  }) => KundaliResponse(
    ok: identical(ok, contractUnchanged) ? this.ok : ok as bool?,
    profile: identical(profile, contractUnchanged)
        ? this.profile
        : profile as KundaliProfile?,
    lagnaSign: identical(lagnaSign, contractUnchanged)
        ? this.lagnaSign
        : lagnaSign as String?,
    rashi: identical(rashi, contractUnchanged) ? this.rashi : rashi as String?,
    chartData: identical(chartData, contractUnchanged)
        ? this.chartData
        : chartData as ChartData?,
    planetOverview: identical(planetOverview, contractUnchanged)
        ? this.planetOverview
        : planetOverview as List<PlanetPlacement>?,
    housesOverview: identical(housesOverview, contractUnchanged)
        ? this.housesOverview
        : housesOverview as List<KundaliHouseOverview>?,
    dashaSummary: identical(dashaSummary, contractUnchanged)
        ? this.dashaSummary
        : dashaSummary as KundaliDashaSummary?,
    yogaDosha: identical(yogaDosha, contractUnchanged)
        ? this.yogaDosha
        : yogaDosha as YogaDoshaCollection?,
    lifeAspects: identical(lifeAspects, contractUnchanged)
        ? this.lifeAspects
        : lifeAspects as List<LifeAspect>?,
    gemstoneRecommendation: identical(gemstoneRecommendation, contractUnchanged)
        ? this.gemstoneRecommendation
        : gemstoneRecommendation as GemstoneRecommendation?,
    moonTraits: identical(moonTraits, contractUnchanged)
        ? this.moonTraits
        : moonTraits as KundaliMoonTraits?,
    toolResults: identical(toolResults, contractUnchanged)
        ? this.toolResults
        : toolResults as List<KundaliToolResult>?,
    error: identical(error, contractUnchanged) ? this.error : error as String?,
  );

  @override
  List<Object?> get props => [
    ok,
    profile,
    lagnaSign,
    rashi,
    chartData,
    planetOverview,
    housesOverview,
    dashaSummary,
    yogaDosha,
    lifeAspects,
    gemstoneRecommendation,
    moonTraits,
    toolResults,
    error,
  ];
}
