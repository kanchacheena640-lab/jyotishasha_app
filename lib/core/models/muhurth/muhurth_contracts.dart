import '../contract_support.dart';

final class MuhurthActivity extends ContractValue {
  const MuhurthActivity({this.code, this.name});
  final String? code;
  final String? name;
  factory MuhurthActivity.fromJson(JsonMap json) => MuhurthActivity(
    code: stringFrom(json, const ['code', 'activity', 'id']),
    name: stringFrom(json, const ['name', 'title']),
  );
  JsonMap toJson() => {'code': code, 'name': name};
  MuhurthActivity copyWith({
    Object? code = contractUnchanged,
    Object? name = contractUnchanged,
  }) => MuhurthActivity(
    code: identical(code, contractUnchanged) ? this.code : code as String?,
    name: identical(name, contractUnchanged) ? this.name : name as String?,
  );
  @override
  List<Object?> get props => [code, name];
}

final class MuhurthRequest extends ContractValue {
  const MuhurthRequest({
    this.activity,
    this.latitude,
    this.longitude,
    this.days,
    this.topK,
    this.language,
  });
  final String? activity;
  final double? latitude;
  final double? longitude;
  final int? days;
  final int? topK;
  final String? language;
  factory MuhurthRequest.fromJson(JsonMap json) => MuhurthRequest(
    activity: asString(json['activity']),
    latitude: asDouble(json['latitude'] ?? json['lat']),
    longitude: asDouble(json['longitude'] ?? json['lng']),
    days: asInt(json['days']),
    topK: asInt(json['top_k'] ?? json['topK']),
    language: stringFrom(json, const ['language', 'lang']),
  );
  JsonMap toJson() => {
    'activity': activity,
    'latitude': latitude,
    'longitude': longitude,
    'days': days,
    'top_k': topK,
    'language': language,
  };
  MuhurthRequest copyWith({
    Object? activity = contractUnchanged,
    Object? latitude = contractUnchanged,
    Object? longitude = contractUnchanged,
    Object? days = contractUnchanged,
    Object? topK = contractUnchanged,
    Object? language = contractUnchanged,
  }) => MuhurthRequest(
    activity: identical(activity, contractUnchanged)
        ? this.activity
        : activity as String?,
    latitude: identical(latitude, contractUnchanged)
        ? this.latitude
        : latitude as double?,
    longitude: identical(longitude, contractUnchanged)
        ? this.longitude
        : longitude as double?,
    days: identical(days, contractUnchanged) ? this.days : days as int?,
    topK: identical(topK, contractUnchanged) ? this.topK : topK as int?,
    language: identical(language, contractUnchanged)
        ? this.language
        : language as String?,
  );
  @override
  List<Object?> get props => [
    activity,
    latitude,
    longitude,
    days,
    topK,
    language,
  ];
}

final class MuhurthReason extends ContractValue {
  const MuhurthReason({this.type, this.name, this.description, this.details});
  final String? type;
  final String? name;
  final String? description;
  final JsonMap? details;
  factory MuhurthReason.fromJson(JsonMap json) => MuhurthReason(
    type: asString(json['type']),
    name: stringFrom(json, const ['name', 'title']),
    description: stringFrom(json, const ['description', 'reason', 'summary']),
    details: asJsonMap(json['details']),
  );
  factory MuhurthReason.fromValue(Object? value) {
    final json = asJsonMap(value);
    return json == null
        ? MuhurthReason(description: asString(value))
        : MuhurthReason.fromJson(json);
  }
  JsonMap toJson() => {
    'type': type,
    'name': name,
    'description': description,
    'details': details,
  };
  MuhurthReason copyWith({
    Object? type = contractUnchanged,
    Object? name = contractUnchanged,
    Object? description = contractUnchanged,
    Object? details = contractUnchanged,
  }) => MuhurthReason(
    type: identical(type, contractUnchanged) ? this.type : type as String?,
    name: identical(name, contractUnchanged) ? this.name : name as String?,
    description: identical(description, contractUnchanged)
        ? this.description
        : description as String?,
    details: identical(details, contractUnchanged)
        ? this.details
        : details as JsonMap?,
  );
  @override
  List<Object?> get props => [type, name, description, details];
}

final class MuhurthResult extends ContractValue {
  const MuhurthResult({
    this.date,
    this.start,
    this.end,
    this.score,
    this.reasons,
    this.tithi,
    this.nakshatra,
    this.weekday,
  });
  final String? date;
  final String? start;
  final String? end;
  final double? score;
  final List<MuhurthReason>? reasons;
  final JsonMap? tithi;
  final JsonMap? nakshatra;
  final String? weekday;
  factory MuhurthResult.fromJson(JsonMap json) => MuhurthResult(
    date: asString(json['date']),
    start: asString(json['start']),
    end: asString(json['end']),
    score: asDouble(json['score']),
    reasons: json['reasons'] is List
        ? (json['reasons'] as List)
              .map(MuhurthReason.fromValue)
              .toList(growable: false)
        : null,
    tithi: asJsonMap(json['tithi']),
    nakshatra: asJsonMap(json['nakshatra']),
    weekday: asString(json['weekday']),
  );
  JsonMap toJson() => {
    'date': date,
    'start': start,
    'end': end,
    'score': score,
    'reasons': modelsToJson(reasons, (item) => item.toJson()),
    'tithi': tithi,
    'nakshatra': nakshatra,
    'weekday': weekday,
  };
  MuhurthResult copyWith({
    Object? date = contractUnchanged,
    Object? start = contractUnchanged,
    Object? end = contractUnchanged,
    Object? score = contractUnchanged,
    Object? reasons = contractUnchanged,
    Object? tithi = contractUnchanged,
    Object? nakshatra = contractUnchanged,
    Object? weekday = contractUnchanged,
  }) => MuhurthResult(
    date: identical(date, contractUnchanged) ? this.date : date as String?,
    start: identical(start, contractUnchanged) ? this.start : start as String?,
    end: identical(end, contractUnchanged) ? this.end : end as String?,
    score: identical(score, contractUnchanged) ? this.score : score as double?,
    reasons: identical(reasons, contractUnchanged)
        ? this.reasons
        : reasons as List<MuhurthReason>?,
    tithi: identical(tithi, contractUnchanged) ? this.tithi : tithi as JsonMap?,
    nakshatra: identical(nakshatra, contractUnchanged)
        ? this.nakshatra
        : nakshatra as JsonMap?,
    weekday: identical(weekday, contractUnchanged)
        ? this.weekday
        : weekday as String?,
  );
  @override
  List<Object?> get props => [
    date,
    start,
    end,
    score,
    reasons,
    tithi,
    nakshatra,
    weekday,
  ];
}

final class MuhurthResponse extends ContractValue {
  const MuhurthResponse({this.results});
  final List<MuhurthResult>? results;
  factory MuhurthResponse.fromJson(JsonMap json) => MuhurthResponse(
    results: asModelList(json['results'], MuhurthResult.fromJson),
  );
  JsonMap toJson() => {
    'results': modelsToJson(results, (item) => item.toJson()),
  };
  MuhurthResponse copyWith({Object? results = contractUnchanged}) =>
      MuhurthResponse(
        results: identical(results, contractUnchanged)
            ? this.results
            : results as List<MuhurthResult>?,
      );
  @override
  List<Object?> get props => [results];
}

final class MuhurthCacheKey extends ContractValue {
  const MuhurthCacheKey({
    this.activity,
    this.latitude,
    this.longitude,
    this.days,
    this.language,
  });
  final String? activity;
  final double? latitude;
  final double? longitude;
  final int? days;
  final String? language;
  factory MuhurthCacheKey.fromJson(JsonMap json) => MuhurthCacheKey(
    activity: asString(json['activity']),
    latitude: asDouble(json['latitude'] ?? json['lat']),
    longitude: asDouble(json['longitude'] ?? json['lng']),
    days: asInt(json['days']),
    language: stringFrom(json, const ['language', 'lang']),
  );
  JsonMap toJson() => {
    'activity': activity,
    'latitude': latitude,
    'longitude': longitude,
    'days': days,
    'language': language,
  };
  MuhurthCacheKey copyWith({
    Object? activity = contractUnchanged,
    Object? latitude = contractUnchanged,
    Object? longitude = contractUnchanged,
    Object? days = contractUnchanged,
    Object? language = contractUnchanged,
  }) => MuhurthCacheKey(
    activity: identical(activity, contractUnchanged)
        ? this.activity
        : activity as String?,
    latitude: identical(latitude, contractUnchanged)
        ? this.latitude
        : latitude as double?,
    longitude: identical(longitude, contractUnchanged)
        ? this.longitude
        : longitude as double?,
    days: identical(days, contractUnchanged) ? this.days : days as int?,
    language: identical(language, contractUnchanged)
        ? this.language
        : language as String?,
  );
  @override
  List<Object?> get props => [activity, latitude, longitude, days, language];
}
