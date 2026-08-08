import '../contract_support.dart';

final class PanchangRequest extends ContractValue {
  const PanchangRequest({
    this.latitude,
    this.longitude,
    this.date,
    this.language,
  });
  final double? latitude;
  final double? longitude;
  final String? date;
  final String? language;
  factory PanchangRequest.fromJson(JsonMap json) => PanchangRequest(
    latitude: asDouble(json['latitude'] ?? json['lat']),
    longitude: asDouble(json['longitude'] ?? json['lng']),
    date: asString(json['date']),
    language: stringFrom(json, const ['language', 'lang']),
  );
  JsonMap toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'date': date,
    'language': language,
  };
  PanchangRequest copyWith({
    Object? latitude = contractUnchanged,
    Object? longitude = contractUnchanged,
    Object? date = contractUnchanged,
    Object? language = contractUnchanged,
  }) => PanchangRequest(
    latitude: identical(latitude, contractUnchanged)
        ? this.latitude
        : latitude as double?,
    longitude: identical(longitude, contractUnchanged)
        ? this.longitude
        : longitude as double?,
    date: identical(date, contractUnchanged) ? this.date : date as String?,
    language: identical(language, contractUnchanged)
        ? this.language
        : language as String?,
  );
  @override
  List<Object?> get props => [latitude, longitude, date, language];
}

final class TimeRange extends ContractValue {
  const TimeRange({this.start, this.end});
  final String? start;
  final String? end;
  factory TimeRange.fromJson(JsonMap json) =>
      TimeRange(start: asString(json['start']), end: asString(json['end']));
  JsonMap toJson() => {'start': start, 'end': end};
  TimeRange copyWith({
    Object? start = contractUnchanged,
    Object? end = contractUnchanged,
  }) => TimeRange(
    start: identical(start, contractUnchanged) ? this.start : start as String?,
    end: identical(end, contractUnchanged) ? this.end : end as String?,
  );
  @override
  List<Object?> get props => [start, end];
}

base class PanchangNamedElement extends ContractValue {
  const PanchangNamedElement({
    this.name,
    this.localizedName,
    this.start,
    this.end,
    this.details,
  });
  final String? name;
  final String? localizedName;
  final String? start;
  final String? end;
  final JsonMap? details;

  factory PanchangNamedElement.fromJson(JsonMap json) => PanchangNamedElement(
    name: asString(json['name']),
    localizedName: stringFrom(json, const [
      'name_hi',
      'localized_name',
      'localizedName',
    ]),
    start: asString(json['start']),
    end: asString(json['end']),
    details: asJsonMap(json['details']),
  );
  JsonMap toJson() => {
    'name': name,
    'name_hi': localizedName,
    'start': start,
    'end': end,
    'details': details,
  };
  PanchangNamedElement copyWith({
    Object? name = contractUnchanged,
    Object? localizedName = contractUnchanged,
    Object? start = contractUnchanged,
    Object? end = contractUnchanged,
    Object? details = contractUnchanged,
  }) => PanchangNamedElement(
    name: identical(name, contractUnchanged) ? this.name : name as String?,
    localizedName: identical(localizedName, contractUnchanged)
        ? this.localizedName
        : localizedName as String?,
    start: identical(start, contractUnchanged) ? this.start : start as String?,
    end: identical(end, contractUnchanged) ? this.end : end as String?,
    details: identical(details, contractUnchanged)
        ? this.details
        : details as JsonMap?,
  );
  @override
  List<Object?> get props => [name, localizedName, start, end, details];
}

final class Tithi extends PanchangNamedElement {
  const Tithi({
    super.name,
    super.localizedName,
    super.start,
    super.end,
    super.details,
    this.paksha,
  });
  final String? paksha;
  factory Tithi.fromJson(JsonMap json) {
    final base = PanchangNamedElement.fromJson(json);
    return Tithi(
      name: base.name,
      localizedName: base.localizedName,
      start: base.start,
      end: base.end,
      details: base.details,
      paksha: asString(json['paksha']),
    );
  }
  @override
  JsonMap toJson() => {...super.toJson(), 'paksha': paksha};
  @override
  Tithi copyWith({
    Object? name = contractUnchanged,
    Object? localizedName = contractUnchanged,
    Object? start = contractUnchanged,
    Object? end = contractUnchanged,
    Object? details = contractUnchanged,
    Object? paksha = contractUnchanged,
  }) => Tithi(
    name: identical(name, contractUnchanged) ? this.name : name as String?,
    localizedName: identical(localizedName, contractUnchanged)
        ? this.localizedName
        : localizedName as String?,
    start: identical(start, contractUnchanged) ? this.start : start as String?,
    end: identical(end, contractUnchanged) ? this.end : end as String?,
    details: identical(details, contractUnchanged)
        ? this.details
        : details as JsonMap?,
    paksha: identical(paksha, contractUnchanged)
        ? this.paksha
        : paksha as String?,
  );
  @override
  List<Object?> get props => [...super.props, paksha];
}

final class Nakshatra extends PanchangNamedElement {
  const Nakshatra({
    super.name,
    super.localizedName,
    super.start,
    super.end,
    super.details,
    this.pada,
    this.rawPada,
  });
  final int? pada;
  final Object? rawPada;
  factory Nakshatra.fromJson(JsonMap json) {
    final base = PanchangNamedElement.fromJson(json);
    return Nakshatra(
      name: base.name,
      localizedName: base.localizedName,
      start: base.start,
      end: base.end,
      details: base.details,
      pada: asInt(json['pada']),
      rawPada: json['pada'],
    );
  }
  @override
  JsonMap toJson() => {...super.toJson(), 'pada': rawPada ?? pada};
  @override
  Nakshatra copyWith({
    Object? name = contractUnchanged,
    Object? localizedName = contractUnchanged,
    Object? start = contractUnchanged,
    Object? end = contractUnchanged,
    Object? details = contractUnchanged,
    Object? pada = contractUnchanged,
    Object? rawPada = contractUnchanged,
  }) => Nakshatra(
    name: identical(name, contractUnchanged) ? this.name : name as String?,
    localizedName: identical(localizedName, contractUnchanged)
        ? this.localizedName
        : localizedName as String?,
    start: identical(start, contractUnchanged) ? this.start : start as String?,
    end: identical(end, contractUnchanged) ? this.end : end as String?,
    details: identical(details, contractUnchanged)
        ? this.details
        : details as JsonMap?,
    pada: identical(pada, contractUnchanged) ? this.pada : pada as int?,
    rawPada: identical(rawPada, contractUnchanged) ? this.rawPada : rawPada,
  );
  @override
  List<Object?> get props => [...super.props, pada, rawPada];
}

final class ChaughadiyaSlot extends ContractValue {
  const ChaughadiyaSlot({
    this.name,
    this.nameEn,
    this.start,
    this.end,
    this.nature,
    this.natureEn,
    this.active,
  });
  final String? name;
  final String? nameEn;
  final String? start;
  final String? end;
  final String? nature;
  final String? natureEn;
  final bool? active;
  factory ChaughadiyaSlot.fromJson(JsonMap json) => ChaughadiyaSlot(
    name: asString(json['name']),
    nameEn: asString(json['name_en']),
    start: asString(json['start']),
    end: asString(json['end']),
    nature: asString(json['nature']),
    natureEn: asString(json['nature_en']),
    active: asBool(json['active']),
  );
  JsonMap toJson() => {
    'name': name,
    'name_en': nameEn,
    'start': start,
    'end': end,
    'nature': nature,
    'nature_en': natureEn,
    'active': active,
  };
  ChaughadiyaSlot copyWith({
    Object? name = contractUnchanged,
    Object? nameEn = contractUnchanged,
    Object? start = contractUnchanged,
    Object? end = contractUnchanged,
    Object? nature = contractUnchanged,
    Object? natureEn = contractUnchanged,
    Object? active = contractUnchanged,
  }) => ChaughadiyaSlot(
    name: identical(name, contractUnchanged) ? this.name : name as String?,
    nameEn: identical(nameEn, contractUnchanged) ? this.nameEn : nameEn as String?,
    start: identical(start, contractUnchanged) ? this.start : start as String?,
    end: identical(end, contractUnchanged) ? this.end : end as String?,
    nature: identical(nature, contractUnchanged)
        ? this.nature
        : nature as String?,
    natureEn: identical(natureEn, contractUnchanged)
        ? this.natureEn
        : natureEn as String?,
    active: identical(active, contractUnchanged)
        ? this.active
        : active as bool?,
  );
  @override
  List<Object?> get props => [name, nameEn, start, end, nature, natureEn, active];
}

final class ChaughadiyaSchedule extends ContractValue {
  const ChaughadiyaSchedule({this.day, this.night});
  final List<ChaughadiyaSlot>? day;
  final List<ChaughadiyaSlot>? night;
  factory ChaughadiyaSchedule.fromJson(JsonMap json) => ChaughadiyaSchedule(
    day: asModelList(json['day'], ChaughadiyaSlot.fromJson),
    night: asModelList(json['night'], ChaughadiyaSlot.fromJson),
  );
  JsonMap toJson() => {
    'day': modelsToJson(day, (item) => item.toJson()),
    'night': modelsToJson(night, (item) => item.toJson()),
  };
  ChaughadiyaSchedule copyWith({
    Object? day = contractUnchanged,
    Object? night = contractUnchanged,
  }) => ChaughadiyaSchedule(
    day: identical(day, contractUnchanged)
        ? this.day
        : day as List<ChaughadiyaSlot>?,
    night: identical(night, contractUnchanged)
        ? this.night
        : night as List<ChaughadiyaSlot>?,
  );
  @override
  List<Object?> get props => [day, night];
}

final class PanchakStatus extends ContractValue {
  const PanchakStatus({this.active, this.message, this.start, this.end});
  final bool? active;
  final String? message;
  final String? start;
  final String? end;
  factory PanchakStatus.fromJson(JsonMap json) => PanchakStatus(
    active: asBool(json['active']),
    message: asString(json['message']),
    start: asString(json['start']),
    end: asString(json['end']),
  );
  JsonMap toJson() => {
    'active': active,
    'message': message,
    'start': start,
    'end': end,
  };
  PanchakStatus copyWith({
    Object? active = contractUnchanged,
    Object? message = contractUnchanged,
    Object? start = contractUnchanged,
    Object? end = contractUnchanged,
  }) => PanchakStatus(
    active: identical(active, contractUnchanged)
        ? this.active
        : active as bool?,
    message: identical(message, contractUnchanged)
        ? this.message
        : message as String?,
    start: identical(start, contractUnchanged) ? this.start : start as String?,
    end: identical(end, contractUnchanged) ? this.end : end as String?,
  );
  @override
  List<Object?> get props => [active, message, start, end];
}

final class PanchangEvent extends ContractValue {
  const PanchangEvent({
    this.id,
    this.title,
    this.start,
    this.end,
    this.type,
    this.details,
  });
  final String? id;
  final String? title;
  final String? start;
  final String? end;
  final String? type;
  final JsonMap? details;
  factory PanchangEvent.fromJson(JsonMap json) => PanchangEvent(
    id: asString(json['id']),
    title: stringFrom(json, const ['title', 'name']),
    start: asString(json['start']),
    end: asString(json['end']),
    type: asString(json['type']),
    details: asJsonMap(json['details']),
  );
  JsonMap toJson() => {
    'id': id,
    'title': title,
    'start': start,
    'end': end,
    'type': type,
    'details': details,
  };
  PanchangEvent copyWith({
    Object? id = contractUnchanged,
    Object? title = contractUnchanged,
    Object? start = contractUnchanged,
    Object? end = contractUnchanged,
    Object? type = contractUnchanged,
    Object? details = contractUnchanged,
  }) => PanchangEvent(
    id: identical(id, contractUnchanged) ? this.id : id as String?,
    title: identical(title, contractUnchanged) ? this.title : title as String?,
    start: identical(start, contractUnchanged) ? this.start : start as String?,
    end: identical(end, contractUnchanged) ? this.end : end as String?,
    type: identical(type, contractUnchanged) ? this.type : type as String?,
    details: identical(details, contractUnchanged)
        ? this.details
        : details as JsonMap?,
  );
  @override
  List<Object?> get props => [id, title, start, end, type, details];
}

final class PanchangDay extends ContractValue {
  const PanchangDay({
    this.date,
    this.language,
    this.sunrise,
    this.sunset,
    this.weekday,
    this.monthName,
    this.tithi,
    this.nakshatra,
    this.yoga,
    this.karan,
    this.rahuKaal,
    this.abhijitMuhurta,
    this.brahmaMuhurta,
    this.panchak,
    this.chaughadiya,
    this.events,
  });
  final String? date;
  final String? language;
  final String? sunrise;
  final String? sunset;
  final String? weekday;
  final String? monthName;
  final Tithi? tithi;
  final Nakshatra? nakshatra;
  final PanchangNamedElement? yoga;
  final PanchangNamedElement? karan;
  final TimeRange? rahuKaal;
  final TimeRange? abhijitMuhurta;
  final TimeRange? brahmaMuhurta;
  final PanchakStatus? panchak;
  final ChaughadiyaSchedule? chaughadiya;
  final List<PanchangEvent>? events;

  factory PanchangDay.fromJson(JsonMap json) => PanchangDay(
    date: stringFrom(json, const ['date', 'selected_date']),
    language: stringFrom(json, const ['language', 'lang']),
    sunrise: asString(json['sunrise']),
    sunset: asString(json['sunset']),
    weekday: asString(json['weekday']),
    monthName: asString(json['month_name']),
    tithi: asModel(json['tithi'], Tithi.fromJson),
    nakshatra: asModel(json['nakshatra'], Nakshatra.fromJson),
    yoga: asModel(json['yoga'], PanchangNamedElement.fromJson),
    karan: asModel(json['karan'], PanchangNamedElement.fromJson),
    rahuKaal: asModel(json['rahu_kaal'], TimeRange.fromJson),
    abhijitMuhurta: asModel(json['abhijit_muhurta'], TimeRange.fromJson),
    brahmaMuhurta: asModel(json['brahma_muhurta'], TimeRange.fromJson),
    panchak: asModel(json['panchak'], PanchakStatus.fromJson),
    chaughadiya: asModel(json['chaughadiya'], ChaughadiyaSchedule.fromJson),
    events: asModelList(json['events'], PanchangEvent.fromJson),
  );
  JsonMap toJson() => {
    'date': date,
    'language': language,
    'sunrise': sunrise,
    'sunset': sunset,
    'weekday': weekday,
    'month_name': monthName,
    'tithi': tithi?.toJson(),
    'nakshatra': nakshatra?.toJson(),
    'yoga': yoga?.toJson(),
    'karan': karan?.toJson(),
    'rahu_kaal': rahuKaal?.toJson(),
    'abhijit_muhurta': abhijitMuhurta?.toJson(),
    'brahma_muhurta': brahmaMuhurta?.toJson(),
    'panchak': panchak?.toJson(),
    'chaughadiya': chaughadiya?.toJson(),
    'events': modelsToJson(events, (item) => item.toJson()),
  };
  PanchangDay copyWith({
    Object? date = contractUnchanged,
    Object? language = contractUnchanged,
    Object? sunrise = contractUnchanged,
    Object? sunset = contractUnchanged,
    Object? weekday = contractUnchanged,
    Object? monthName = contractUnchanged,
    Object? tithi = contractUnchanged,
    Object? nakshatra = contractUnchanged,
    Object? yoga = contractUnchanged,
    Object? karan = contractUnchanged,
    Object? rahuKaal = contractUnchanged,
    Object? abhijitMuhurta = contractUnchanged,
    Object? brahmaMuhurta = contractUnchanged,
    Object? panchak = contractUnchanged,
    Object? chaughadiya = contractUnchanged,
    Object? events = contractUnchanged,
  }) => PanchangDay(
    date: identical(date, contractUnchanged) ? this.date : date as String?,
    language: identical(language, contractUnchanged)
        ? this.language
        : language as String?,
    sunrise: identical(sunrise, contractUnchanged)
        ? this.sunrise
        : sunrise as String?,
    sunset: identical(sunset, contractUnchanged)
        ? this.sunset
        : sunset as String?,
    weekday: identical(weekday, contractUnchanged)
        ? this.weekday
        : weekday as String?,
    monthName: identical(monthName, contractUnchanged)
        ? this.monthName
        : monthName as String?,
    tithi: identical(tithi, contractUnchanged) ? this.tithi : tithi as Tithi?,
    nakshatra: identical(nakshatra, contractUnchanged)
        ? this.nakshatra
        : nakshatra as Nakshatra?,
    yoga: identical(yoga, contractUnchanged)
        ? this.yoga
        : yoga as PanchangNamedElement?,
    karan: identical(karan, contractUnchanged)
        ? this.karan
        : karan as PanchangNamedElement?,
    rahuKaal: identical(rahuKaal, contractUnchanged)
        ? this.rahuKaal
        : rahuKaal as TimeRange?,
    abhijitMuhurta: identical(abhijitMuhurta, contractUnchanged)
        ? this.abhijitMuhurta
        : abhijitMuhurta as TimeRange?,
    brahmaMuhurta: identical(brahmaMuhurta, contractUnchanged)
        ? this.brahmaMuhurta
        : brahmaMuhurta as TimeRange?,
    panchak: identical(panchak, contractUnchanged)
        ? this.panchak
        : panchak as PanchakStatus?,
    chaughadiya: identical(chaughadiya, contractUnchanged)
        ? this.chaughadiya
        : chaughadiya as ChaughadiyaSchedule?,
    events: identical(events, contractUnchanged)
        ? this.events
        : events as List<PanchangEvent>?,
  );
  @override
  List<Object?> get props => [
    date,
    language,
    sunrise,
    sunset,
    weekday,
    monthName,
    tithi,
    nakshatra,
    yoga,
    karan,
    rahuKaal,
    abhijitMuhurta,
    brahmaMuhurta,
    panchak,
    chaughadiya,
    events,
  ];
}

final class PanchangResponse extends ContractValue {
  const PanchangResponse({this.selectedDate, this.nextDate});
  final PanchangDay? selectedDate;
  final PanchangDay? nextDate;
  factory PanchangResponse.fromJson(JsonMap json) => PanchangResponse(
    selectedDate: asModel(json['selected_date'], PanchangDay.fromJson),
    nextDate: asModel(json['next_date'], PanchangDay.fromJson),
  );
  JsonMap toJson() => {
    'selected_date': selectedDate?.toJson(),
    'next_date': nextDate?.toJson(),
  };
  PanchangResponse copyWith({
    Object? selectedDate = contractUnchanged,
    Object? nextDate = contractUnchanged,
  }) => PanchangResponse(
    selectedDate: identical(selectedDate, contractUnchanged)
        ? this.selectedDate
        : selectedDate as PanchangDay?,
    nextDate: identical(nextDate, contractUnchanged)
        ? this.nextDate
        : nextDate as PanchangDay?,
  );
  @override
  List<Object?> get props => [selectedDate, nextDate];
}

final class PanchangCacheKey extends ContractValue {
  const PanchangCacheKey({
    this.date,
    this.latitude,
    this.longitude,
    this.language,
  });
  final String? date;
  final double? latitude;
  final double? longitude;
  final String? language;
  factory PanchangCacheKey.fromJson(JsonMap json) => PanchangCacheKey(
    date: asString(json['date']),
    latitude: asDouble(json['latitude'] ?? json['lat']),
    longitude: asDouble(json['longitude'] ?? json['lng']),
    language: stringFrom(json, const ['language', 'lang']),
  );
  JsonMap toJson() => {
    'date': date,
    'latitude': latitude,
    'longitude': longitude,
    'language': language,
  };
  PanchangCacheKey copyWith({
    Object? date = contractUnchanged,
    Object? latitude = contractUnchanged,
    Object? longitude = contractUnchanged,
    Object? language = contractUnchanged,
  }) => PanchangCacheKey(
    date: identical(date, contractUnchanged) ? this.date : date as String?,
    latitude: identical(latitude, contractUnchanged)
        ? this.latitude
        : latitude as double?,
    longitude: identical(longitude, contractUnchanged)
        ? this.longitude
        : longitude as double?,
    language: identical(language, contractUnchanged)
        ? this.language
        : language as String?,
  );
  @override
  List<Object?> get props => [date, latitude, longitude, language];
}
