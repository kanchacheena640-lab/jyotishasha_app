typedef JsonMap = Map<String, dynamic>;

const Object contractUnchanged = Object();

abstract base class ContractValue {
  const ContractValue();

  List<Object?> get props;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other.runtimeType == runtimeType &&
            other is ContractValue &&
            deepEquals(other.props, props);
  }

  @override
  int get hashCode => deepHash(props);
}

JsonMap? asJsonMap(Object? value) {
  if (value is JsonMap) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return null;
}

List<JsonMap> asJsonMapList(Object? value) {
  if (value is! List) return const [];
  return value.map(asJsonMap).whereType<JsonMap>().toList(growable: false);
}

String? asString(Object? value) => value?.toString();

String? stringFrom(JsonMap json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) return value.toString();
  }
  return null;
}

int? asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

bool? asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}

List<String>? asStringList(Object? value) {
  if (value is! List) return null;
  return value.map((item) => item.toString()).toList(growable: false);
}

List<T>? asModelList<T>(Object? value, T Function(JsonMap json) fromJson) {
  if (value is! List) return null;
  return value
      .map(asJsonMap)
      .whereType<JsonMap>()
      .map(fromJson)
      .toList(growable: false);
}

T? asModel<T>(Object? value, T Function(JsonMap json) fromJson) {
  final json = asJsonMap(value);
  return json == null ? null : fromJson(json);
}

Map<String, T>? asModelMap<T>(
  Object? value,
  T Function(JsonMap json) fromJson,
) {
  final json = asJsonMap(value);
  if (json == null) return null;
  return json.map((key, item) {
    return MapEntry(key, fromJson(asJsonMap(item) ?? const {}));
  });
}

Map<String, dynamic>? modelMapToJson<T>(
  Map<String, T>? value,
  JsonMap Function(T item) toJson,
) {
  return value?.map((key, item) => MapEntry(key, toJson(item)));
}

List<JsonMap>? modelsToJson<T>(
  List<T>? value,
  JsonMap Function(T item) toJson,
) {
  return value?.map(toJson).toList(growable: false);
}

bool deepEquals(Object? left, Object? right) {
  if (identical(left, right)) return true;
  if (left is List && right is List) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (!deepEquals(left[index], right[index])) return false;
    }
    return true;
  }
  if (left is Map && right is Map) {
    if (left.length != right.length) return false;
    for (final key in left.keys) {
      if (!right.containsKey(key) || !deepEquals(left[key], right[key])) {
        return false;
      }
    }
    return true;
  }
  return left == right;
}

int deepHash(Object? value) {
  if (value is List) return Object.hashAll(value.map(deepHash));
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort(
        (left, right) => left.key.toString().compareTo(right.key.toString()),
      );
    return Object.hashAll(
      entries.map(
        (entry) => Object.hash(deepHash(entry.key), deepHash(entry.value)),
      ),
    );
  }
  return value.hashCode;
}
