import '../contract_support.dart';

final class ResourceDto extends ContractValue {
  const ResourceDto({this.type, this.id, this.url, this.meta});
  final String? type;
  final String? id;
  final String? url;
  final JsonMap? meta;

  factory ResourceDto.fromJson(JsonMap json) => ResourceDto(
    type: asString(json['type']),
    id: asString(json['id']),
    url: asString(json['url']),
    meta: asJsonMap(json['meta']),
  );
  JsonMap toJson() => {'type': type, 'id': id, 'url': url, 'meta': meta};
  ResourceDto copyWith({
    Object? type = contractUnchanged,
    Object? id = contractUnchanged,
    Object? url = contractUnchanged,
    Object? meta = contractUnchanged,
  }) => ResourceDto(
    type: identical(type, contractUnchanged) ? this.type : type as String?,
    id: identical(id, contractUnchanged) ? this.id : id as String?,
    url: identical(url, contractUnchanged) ? this.url : url as String?,
    meta: identical(meta, contractUnchanged) ? this.meta : meta as JsonMap?,
  );
  @override
  List<Object?> get props => [type, id, url, meta];
}

final class EventDto extends ContractValue {
  const EventDto({this.id, this.type, this.title, this.body, this.date});
  final int? id;
  final String? type;
  final String? title;
  final String? body;
  final String? date;

  factory EventDto.fromJson(JsonMap json) => EventDto(
    id: asInt(json['id']),
    type: asString(json['type']),
    title: asString(json['title']),
    body: asString(json['body']),
    date: asString(json['date']),
  );
  JsonMap toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'body': body,
    'date': date,
  };
  EventDto copyWith({
    Object? id = contractUnchanged,
    Object? type = contractUnchanged,
    Object? title = contractUnchanged,
    Object? body = contractUnchanged,
    Object? date = contractUnchanged,
  }) => EventDto(
    id: identical(id, contractUnchanged) ? this.id : id as int?,
    type: identical(type, contractUnchanged) ? this.type : type as String?,
    title: identical(title, contractUnchanged) ? this.title : title as String?,
    body: identical(body, contractUnchanged) ? this.body : body as String?,
    date: identical(date, contractUnchanged) ? this.date : date as String?,
  );
  @override
  List<Object?> get props => [id, type, title, body, date];
}

final class EventResourceResponse extends ContractValue {
  const EventResourceResponse({this.schemaVersion, this.event, this.resource});
  final int? schemaVersion;
  final EventDto? event;
  final ResourceDto? resource;

  factory EventResourceResponse.fromJson(JsonMap json) => EventResourceResponse(
    schemaVersion: asInt(json['schema_version']),
    event: asModel(json['event'], EventDto.fromJson),
    resource: asModel(json['resource'], ResourceDto.fromJson),
  );
  JsonMap toJson() => {
    'schema_version': schemaVersion,
    'event': event?.toJson(),
    'resource': resource?.toJson(),
  };
  EventResourceResponse copyWith({
    Object? schemaVersion = contractUnchanged,
    Object? event = contractUnchanged,
    Object? resource = contractUnchanged,
  }) => EventResourceResponse(
    schemaVersion: identical(schemaVersion, contractUnchanged)
        ? this.schemaVersion
        : schemaVersion as int?,
    event: identical(event, contractUnchanged) ? this.event : event as EventDto?,
    resource: identical(resource, contractUnchanged)
        ? this.resource
        : resource as ResourceDto?,
  );
  @override
  List<Object?> get props => [schemaVersion, event, resource];
}
