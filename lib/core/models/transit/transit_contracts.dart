import '../contract_support.dart';

final class PlanetTransitPosition extends ContractValue {
  const PlanetTransitPosition({this.rashi, this.degree, this.motion});
  final String? rashi;
  final double? degree;
  final String? motion;
  factory PlanetTransitPosition.fromJson(JsonMap json) => PlanetTransitPosition(
    rashi: asString(json['rashi']),
    degree: asDouble(json['degree']),
    motion: asString(json['motion']),
  );
  JsonMap toJson() => {'rashi': rashi, 'degree': degree, 'motion': motion};
  PlanetTransitPosition copyWith({
    Object? rashi = contractUnchanged,
    Object? degree = contractUnchanged,
    Object? motion = contractUnchanged,
  }) => PlanetTransitPosition(
    rashi: identical(rashi, contractUnchanged) ? this.rashi : rashi as String?,
    degree: identical(degree, contractUnchanged)
        ? this.degree
        : degree as double?,
    motion: identical(motion, contractUnchanged)
        ? this.motion
        : motion as String?,
  );
  @override
  List<Object?> get props => [rashi, degree, motion];
}

final class FutureTransit extends ContractValue {
  const FutureTransit({this.enteringDate, this.rashi, this.details});
  final String? enteringDate;
  final String? rashi;
  final JsonMap? details;
  factory FutureTransit.fromJson(JsonMap json) => FutureTransit(
    enteringDate: stringFrom(json, const ['entering_date', 'enteringDate']),
    rashi: asString(json['rashi']),
    details: asJsonMap(json['details']),
  );
  JsonMap toJson() => {
    'entering_date': enteringDate,
    'rashi': rashi,
    'details': details,
  };
  FutureTransit copyWith({
    Object? enteringDate = contractUnchanged,
    Object? rashi = contractUnchanged,
    Object? details = contractUnchanged,
  }) => FutureTransit(
    enteringDate: identical(enteringDate, contractUnchanged)
        ? this.enteringDate
        : enteringDate as String?,
    rashi: identical(rashi, contractUnchanged) ? this.rashi : rashi as String?,
    details: identical(details, contractUnchanged)
        ? this.details
        : details as JsonMap?,
  );
  @override
  List<Object?> get props => [enteringDate, rashi, details];
}

final class CurrentTransitResponse extends ContractValue {
  const CurrentTransitResponse({this.positions, this.futureTransits});
  final Map<String, PlanetTransitPosition>? positions;
  final Map<String, List<FutureTransit>>? futureTransits;
  factory CurrentTransitResponse.fromJson(JsonMap json) {
    final futureJson = asJsonMap(json['future_transits']);
    return CurrentTransitResponse(
      positions: asModelMap(json['positions'], PlanetTransitPosition.fromJson),
      futureTransits: futureJson?.map(
        (key, value) => MapEntry(
          key,
          asModelList(value, FutureTransit.fromJson) ?? const [],
        ),
      ),
    );
  }
  JsonMap toJson() => {
    'positions': modelMapToJson(positions, (item) => item.toJson()),
    'future_transits': futureTransits?.map(
      (key, value) =>
          MapEntry(key, modelsToJson(value, (item) => item.toJson())),
    ),
  };
  CurrentTransitResponse copyWith({
    Object? positions = contractUnchanged,
    Object? futureTransits = contractUnchanged,
  }) => CurrentTransitResponse(
    positions: identical(positions, contractUnchanged)
        ? this.positions
        : positions as Map<String, PlanetTransitPosition>?,
    futureTransits: identical(futureTransits, contractUnchanged)
        ? this.futureTransits
        : futureTransits as Map<String, List<FutureTransit>>?,
  );
  @override
  List<Object?> get props => [positions, futureTransits];
}

final class TransitPlanetView extends ContractValue {
  const TransitPlanetView({
    this.name,
    this.rashi,
    this.rashiNumber,
    this.degree,
    this.motion,
    this.nextChange,
  });
  final String? name;
  final String? rashi;
  final int? rashiNumber;
  final String? degree;
  final String? motion;
  final String? nextChange;
  factory TransitPlanetView.fromJson(JsonMap json) => TransitPlanetView(
    name: asString(json['name']),
    rashi: asString(json['rashi']),
    rashiNumber: asInt(json['rashi_number']),
    degree: asString(json['degree']),
    motion: asString(json['motion']),
    nextChange: asString(json['next_change']),
  );
  JsonMap toJson() => {
    'name': name,
    'rashi': rashi,
    'rashi_number': rashiNumber,
    'degree': degree,
    'motion': motion,
    'next_change': nextChange,
  };
  TransitPlanetView copyWith({
    Object? name = contractUnchanged,
    Object? rashi = contractUnchanged,
    Object? rashiNumber = contractUnchanged,
    Object? degree = contractUnchanged,
    Object? motion = contractUnchanged,
    Object? nextChange = contractUnchanged,
  }) => TransitPlanetView(
    name: identical(name, contractUnchanged) ? this.name : name as String?,
    rashi: identical(rashi, contractUnchanged) ? this.rashi : rashi as String?,
    rashiNumber: identical(rashiNumber, contractUnchanged)
        ? this.rashiNumber
        : rashiNumber as int?,
    degree: identical(degree, contractUnchanged)
        ? this.degree
        : degree as String?,
    motion: identical(motion, contractUnchanged)
        ? this.motion
        : motion as String?,
    nextChange: identical(nextChange, contractUnchanged)
        ? this.nextChange
        : nextChange as String?,
  );
  @override
  List<Object?> get props => [
    name,
    rashi,
    rashiNumber,
    degree,
    motion,
    nextChange,
  ];
}

final class TransitContentRequest extends ContractValue {
  const TransitContentRequest({
    this.ascendant,
    this.planet,
    this.house,
    this.language,
  });
  final String? ascendant;
  final String? planet;
  final int? house;
  final String? language;
  factory TransitContentRequest.fromJson(JsonMap json) => TransitContentRequest(
    ascendant: asString(json['ascendant']),
    planet: asString(json['planet']),
    house: asInt(json['house']),
    language: stringFrom(json, const ['lang', 'language']),
  );
  JsonMap toJson() => {
    'ascendant': ascendant,
    'planet': planet,
    'house': house,
    'lang': language,
  };
  TransitContentRequest copyWith({
    Object? ascendant = contractUnchanged,
    Object? planet = contractUnchanged,
    Object? house = contractUnchanged,
    Object? language = contractUnchanged,
  }) => TransitContentRequest(
    ascendant: identical(ascendant, contractUnchanged)
        ? this.ascendant
        : ascendant as String?,
    planet: identical(planet, contractUnchanged)
        ? this.planet
        : planet as String?,
    house: identical(house, contractUnchanged) ? this.house : house as int?,
    language: identical(language, contractUnchanged)
        ? this.language
        : language as String?,
  );
  @override
  List<Object?> get props => [ascendant, planet, house, language];
}

final class TransitContentSection extends ContractValue {
  const TransitContentSection({this.title, this.content, this.points});
  final String? title;
  final String? content;
  final List<String>? points;
  factory TransitContentSection.fromJson(JsonMap json) => TransitContentSection(
    title: asString(json['title']),
    content: stringFrom(json, const ['content', 'text', 'summary']),
    points: asStringList(json['points']),
  );
  JsonMap toJson() => {'title': title, 'content': content, 'points': points};
  TransitContentSection copyWith({
    Object? title = contractUnchanged,
    Object? content = contractUnchanged,
    Object? points = contractUnchanged,
  }) => TransitContentSection(
    title: identical(title, contractUnchanged) ? this.title : title as String?,
    content: identical(content, contractUnchanged)
        ? this.content
        : content as String?,
    points: identical(points, contractUnchanged)
        ? this.points
        : points as List<String>?,
  );
  @override
  List<Object?> get props => [title, content, points];
}

final class TransitContentResponse extends ContractValue {
  const TransitContentResponse({
    this.heading,
    this.summary,
    this.sections,
    this.points,
    this.closing,
    this.articleUrl,
  });
  final String? heading;
  final String? summary;
  final List<TransitContentSection>? sections;
  final List<String>? points;
  final String? closing;
  final String? articleUrl;
  factory TransitContentResponse.fromJson(JsonMap json) =>
      TransitContentResponse(
        heading: asString(json['heading']),
        summary: asString(json['summary']),
        sections: asModelList(json['sections'], TransitContentSection.fromJson),
        points: asStringList(json['points']),
        closing: asString(json['closing']),
        articleUrl: stringFrom(json, const ['article_url', 'articleUrl']),
      );
  JsonMap toJson() => {
    'heading': heading,
    'summary': summary,
    'sections': modelsToJson(sections, (item) => item.toJson()),
    'points': points,
    'closing': closing,
    'article_url': articleUrl,
  };
  TransitContentResponse copyWith({
    Object? heading = contractUnchanged,
    Object? summary = contractUnchanged,
    Object? sections = contractUnchanged,
    Object? points = contractUnchanged,
    Object? closing = contractUnchanged,
    Object? articleUrl = contractUnchanged,
  }) => TransitContentResponse(
    heading: identical(heading, contractUnchanged)
        ? this.heading
        : heading as String?,
    summary: identical(summary, contractUnchanged)
        ? this.summary
        : summary as String?,
    sections: identical(sections, contractUnchanged)
        ? this.sections
        : sections as List<TransitContentSection>?,
    points: identical(points, contractUnchanged)
        ? this.points
        : points as List<String>?,
    closing: identical(closing, contractUnchanged)
        ? this.closing
        : closing as String?,
    articleUrl: identical(articleUrl, contractUnchanged)
        ? this.articleUrl
        : articleUrl as String?,
  );
  @override
  List<Object?> get props => [
    heading,
    summary,
    sections,
    points,
    closing,
    articleUrl,
  ];
}
