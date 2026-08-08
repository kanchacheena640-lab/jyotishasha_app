import '../contract_support.dart';

final class HoroscopeQuery extends ContractValue {
  const HoroscopeQuery({this.sign, this.language, this.year, this.month});
  final String? sign;
  final String? language;
  final int? year;
  final String? month;

  factory HoroscopeQuery.fromJson(JsonMap json) => HoroscopeQuery(
    sign: asString(json['sign']),
    language: stringFrom(json, const ['lang', 'language']),
    year: asInt(json['year']),
    month: asString(json['month']),
  );
  JsonMap toJson() => {
    'sign': sign,
    'lang': language,
    'year': year,
    'month': month,
  };
  HoroscopeQuery copyWith({
    Object? sign = contractUnchanged,
    Object? language = contractUnchanged,
    Object? year = contractUnchanged,
    Object? month = contractUnchanged,
  }) => HoroscopeQuery(
    sign: identical(sign, contractUnchanged) ? this.sign : sign as String?,
    language: identical(language, contractUnchanged)
        ? this.language
        : language as String?,
    year: identical(year, contractUnchanged) ? this.year : year as int?,
    month: identical(month, contractUnchanged) ? this.month : month as String?,
  );
  @override
  List<Object?> get props => [sign, language, year, month];
}

final class HoroscopeCacheKey extends ContractValue {
  const HoroscopeCacheKey({this.sign, this.language, this.period, this.year});
  final String? sign;
  final String? language;
  final String? period;
  final int? year;

  factory HoroscopeCacheKey.fromJson(JsonMap json) => HoroscopeCacheKey(
    sign: asString(json['sign']),
    language: stringFrom(json, const ['language', 'lang']),
    period: stringFrom(json, const ['period', 'month']),
    year: asInt(json['year']),
  );
  JsonMap toJson() => {
    'sign': sign,
    'language': language,
    'period': period,
    'year': year,
  };
  HoroscopeCacheKey copyWith({
    Object? sign = contractUnchanged,
    Object? language = contractUnchanged,
    Object? period = contractUnchanged,
    Object? year = contractUnchanged,
  }) => HoroscopeCacheKey(
    sign: identical(sign, contractUnchanged) ? this.sign : sign as String?,
    language: identical(language, contractUnchanged)
        ? this.language
        : language as String?,
    period: identical(period, contractUnchanged)
        ? this.period
        : period as String?,
    year: identical(year, contractUnchanged) ? this.year : year as int?,
  );
  @override
  List<Object?> get props => [sign, language, period, year];
}

final class DailyHoroscope extends ContractValue {
  const DailyHoroscope({
    this.heading,
    this.intro,
    this.paragraph,
    this.tips,
    this.luckyColor,
    this.luckyNumber,
  });
  final String? heading;
  final String? intro;
  final String? paragraph;
  final String? tips;
  final String? luckyColor;
  final String? luckyNumber;

  factory DailyHoroscope.fromJson(JsonMap json) => DailyHoroscope(
    heading: asString(json['heading']),
    intro: asString(json['intro']),
    paragraph: asString(json['paragraph']),
    tips: asString(json['tips']),
    luckyColor: asString(json['lucky_color']),
    luckyNumber: asString(json['lucky_number']),
  );
  JsonMap toJson() => {
    'heading': heading,
    'intro': intro,
    'paragraph': paragraph,
    'tips': tips,
    'lucky_color': luckyColor,
    'lucky_number': luckyNumber,
  };
  DailyHoroscope copyWith({
    Object? heading = contractUnchanged,
    Object? intro = contractUnchanged,
    Object? paragraph = contractUnchanged,
    Object? tips = contractUnchanged,
    Object? luckyColor = contractUnchanged,
    Object? luckyNumber = contractUnchanged,
  }) => DailyHoroscope(
    heading: identical(heading, contractUnchanged)
        ? this.heading
        : heading as String?,
    intro: identical(intro, contractUnchanged) ? this.intro : intro as String?,
    paragraph: identical(paragraph, contractUnchanged)
        ? this.paragraph
        : paragraph as String?,
    tips: identical(tips, contractUnchanged) ? this.tips : tips as String?,
    luckyColor: identical(luckyColor, contractUnchanged)
        ? this.luckyColor
        : luckyColor as String?,
    luckyNumber: identical(luckyNumber, contractUnchanged)
        ? this.luckyNumber
        : luckyNumber as String?,
  );
  @override
  List<Object?> get props => [
    heading,
    intro,
    paragraph,
    tips,
    luckyColor,
    luckyNumber,
  ];
}

final class MonthlyHoroscope extends ContractValue {
  const MonthlyHoroscope({
    this.title,
    this.theme,
    this.careerMoney,
    this.loveRelationships,
    this.healthLifestyle,
    this.monthlyAdvice,
    this.keyDates,
  });
  final String? title;
  final String? theme;
  final String? careerMoney;
  final String? loveRelationships;
  final String? healthLifestyle;
  final String? monthlyAdvice;
  final List<String>? keyDates;

  factory MonthlyHoroscope.fromJson(JsonMap json) => MonthlyHoroscope(
    title: asString(json['title']),
    theme: asString(json['theme']),
    careerMoney: asString(json['career_money']),
    loveRelationships: asString(json['love_relationships']),
    healthLifestyle: asString(json['health_lifestyle']),
    monthlyAdvice: asString(json['monthly_advice']),
    keyDates: asStringList(json['key_dates']),
  );
  JsonMap toJson() => {
    'title': title,
    'theme': theme,
    'career_money': careerMoney,
    'love_relationships': loveRelationships,
    'health_lifestyle': healthLifestyle,
    'monthly_advice': monthlyAdvice,
    'key_dates': keyDates,
  };
  MonthlyHoroscope copyWith({
    Object? title = contractUnchanged,
    Object? theme = contractUnchanged,
    Object? careerMoney = contractUnchanged,
    Object? loveRelationships = contractUnchanged,
    Object? healthLifestyle = contractUnchanged,
    Object? monthlyAdvice = contractUnchanged,
    Object? keyDates = contractUnchanged,
  }) => MonthlyHoroscope(
    title: identical(title, contractUnchanged) ? this.title : title as String?,
    theme: identical(theme, contractUnchanged) ? this.theme : theme as String?,
    careerMoney: identical(careerMoney, contractUnchanged)
        ? this.careerMoney
        : careerMoney as String?,
    loveRelationships: identical(loveRelationships, contractUnchanged)
        ? this.loveRelationships
        : loveRelationships as String?,
    healthLifestyle: identical(healthLifestyle, contractUnchanged)
        ? this.healthLifestyle
        : healthLifestyle as String?,
    monthlyAdvice: identical(monthlyAdvice, contractUnchanged)
        ? this.monthlyAdvice
        : monthlyAdvice as String?,
    keyDates: identical(keyDates, contractUnchanged)
        ? this.keyDates
        : keyDates as List<String>?,
  );
  @override
  List<Object?> get props => [
    title,
    theme,
    careerMoney,
    loveRelationships,
    healthLifestyle,
    monthlyAdvice,
    keyDates,
  ];
}

final class HoroscopeSection extends ContractValue {
  const HoroscopeSection({
    this.key,
    this.title,
    this.content,
    this.points,
    this.heading,
    this.contentData,
    this.rawData,
  });
  final String? key;
  final String? title;
  final String? content;
  final List<String>? points;
  final String? heading;
  final Object? contentData;
  final JsonMap? rawData;

  factory HoroscopeSection.fromJson(JsonMap json) {
    final rawData = Map<String, dynamic>.from(json);
    final rawContent =
        rawData.containsKey('content')
            ? rawData['content']
            : rawData.containsKey('text')
            ? rawData['text']
            : rawData['summary'];
    return HoroscopeSection(
      key: stringFrom(json, const ['key', 'type']),
      title: stringFrom(json, const ['title', 'heading']),
      content:
          rawContent is String ? rawContent : stringFrom(json, const ['text', 'summary']),
      points: asStringList(json['points']),
      heading: stringFrom(json, const ['heading', 'title']),
      contentData: rawContent,
      rawData: rawData,
    );
  }
  JsonMap toJson() {
    final json = Map<String, dynamic>.from(rawData ?? const {});
    if (key != null) json['key'] = key;
    if (title != null) json['title'] = title;
    if (heading != null) json['heading'] = heading;
    if (points != null) json['points'] = points;

    if (contentData != null) {
      if (json.containsKey('content') || !json.containsKey('text')) {
        json['content'] = contentData;
      } else {
        json['text'] = contentData;
      }
    } else if (content != null) {
      if (json.containsKey('content') || !json.containsKey('text')) {
        json['content'] = content;
      } else {
        json['text'] = content;
      }
    }

    return json;
  }
  HoroscopeSection copyWith({
    Object? key = contractUnchanged,
    Object? title = contractUnchanged,
    Object? content = contractUnchanged,
    Object? points = contractUnchanged,
    Object? heading = contractUnchanged,
    Object? contentData = contractUnchanged,
    Object? rawData = contractUnchanged,
  }) => HoroscopeSection(
    key: identical(key, contractUnchanged) ? this.key : key as String?,
    title: identical(title, contractUnchanged) ? this.title : title as String?,
    content: identical(content, contractUnchanged)
        ? this.content
        : content as String?,
    points: identical(points, contractUnchanged)
        ? this.points
        : points as List<String>?,
    heading: identical(heading, contractUnchanged)
        ? this.heading
        : heading as String?,
    contentData: identical(contentData, contractUnchanged)
        ? this.contentData
        : contentData,
    rawData: identical(rawData, contractUnchanged)
        ? this.rawData
        : rawData as JsonMap?,
  );
  @override
  List<Object?> get props => [
    key,
    title,
    content,
    points,
    heading,
    contentData,
    rawData,
  ];
}

final class YearlyHoroscope extends ContractValue {
  const YearlyHoroscope({this.title, this.sections, this.rawData});
  final String? title;
  final Map<String, HoroscopeSection>? sections;
  final JsonMap? rawData;

  factory YearlyHoroscope.fromJson(JsonMap json) {
    const keys = [
      'introduction',
      'planetary_overview',
      'career_finance',
      'love_relationships',
      'health_wellness',
      'spirituality_remedies',
      'final_summary',
    ];
    final rawData = Map<String, dynamic>.from(json);
    final sections = <String, HoroscopeSection>{};
    for (final key in keys) {
      final value = json[key];
      if (value is Map) {
        sections[key] = HoroscopeSection.fromJson({
          'key': key,
          ...?asJsonMap(value),
        });
      } else if (value != null) {
        sections[key] = HoroscopeSection(
          key: key,
          content: value is String ? value : null,
          contentData: value,
          rawData: {'key': key, 'content': value},
        );
      }
    }
    return YearlyHoroscope(
      title: asString(json['title']),
      sections: sections.isEmpty ? null : sections,
      rawData: rawData,
    );
  }
  JsonMap toJson() {
    final json = Map<String, dynamic>.from(rawData ?? const {});
    if (title != null) json['title'] = title;
    sections?.forEach((key, value) {
      json[key] = value.toJson();
    });
    return json;
  }
  YearlyHoroscope copyWith({
    Object? title = contractUnchanged,
    Object? sections = contractUnchanged,
    Object? rawData = contractUnchanged,
  }) => YearlyHoroscope(
    title: identical(title, contractUnchanged) ? this.title : title as String?,
    sections: identical(sections, contractUnchanged)
        ? this.sections
        : sections as Map<String, HoroscopeSection>?,
    rawData: identical(rawData, contractUnchanged)
        ? this.rawData
        : rawData as JsonMap?,
  );
  @override
  List<Object?> get props => [title, sections, rawData];
}

final class PersonalizedHoroscopeResponse extends ContractValue {
  const PersonalizedHoroscopeResponse({this.ok, this.horoscope, this.error});
  final bool? ok;
  final JsonMap? horoscope;
  final String? error;

  factory PersonalizedHoroscopeResponse.fromJson(JsonMap json) =>
      PersonalizedHoroscopeResponse(
        ok: asBool(json['ok']),
        horoscope: asJsonMap(json['horoscope']),
        error: asString(json['error']),
      );
  JsonMap toJson() => {'ok': ok, 'horoscope': horoscope, 'error': error};
  PersonalizedHoroscopeResponse copyWith({
    Object? ok = contractUnchanged,
    Object? horoscope = contractUnchanged,
    Object? error = contractUnchanged,
  }) => PersonalizedHoroscopeResponse(
    ok: identical(ok, contractUnchanged) ? this.ok : ok as bool?,
    horoscope: identical(horoscope, contractUnchanged)
        ? this.horoscope
        : horoscope as JsonMap?,
    error: identical(error, contractUnchanged) ? this.error : error as String?,
  );
  @override
  List<Object?> get props => [ok, horoscope, error];
}
