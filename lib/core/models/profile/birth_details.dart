/// Immutable birth and location details used by a profile.
final class BirthDetails {
  const BirthDetails({
    this.dateOfBirth,
    this.timeOfBirth,
    this.placeOfBirth,
    this.latitude,
    this.longitude,
    this.placeId,
    this.timezone,
  });

  static const Object _unset = Object();

  final String? dateOfBirth;
  final String? timeOfBirth;
  final String? placeOfBirth;
  final double? latitude;
  final double? longitude;
  final String? placeId;
  final String? timezone;

  factory BirthDetails.fromJson(Map<String, dynamic> json) {
    return BirthDetails(
      dateOfBirth: _stringValue(json, const [
        'dob',
        'date_of_birth',
        'dateOfBirth',
      ]),
      timeOfBirth: _stringValue(json, const [
        'tob',
        'time_of_birth',
        'timeOfBirth',
      ]),
      placeOfBirth: _stringValue(json, const [
        'pob',
        'place_name',
        'placeName',
        'place_of_birth',
      ]),
      latitude: _doubleValue(json['lat'] ?? json['latitude']),
      longitude: _doubleValue(json['lng'] ?? json['longitude'] ?? json['lon']),
      placeId: _stringValue(json, const ['place_id', 'placeId']),
      timezone: _stringValue(json, const ['timezone', 'tz']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dob': dateOfBirth,
      'tob': timeOfBirth,
      'pob': placeOfBirth,
      'lat': latitude,
      'lng': longitude,
      'place_id': placeId,
      'timezone': timezone,
    };
  }

  BirthDetails copyWith({
    Object? dateOfBirth = _unset,
    Object? timeOfBirth = _unset,
    Object? placeOfBirth = _unset,
    Object? latitude = _unset,
    Object? longitude = _unset,
    Object? placeId = _unset,
    Object? timezone = _unset,
  }) {
    return BirthDetails(
      dateOfBirth: identical(dateOfBirth, _unset)
          ? this.dateOfBirth
          : dateOfBirth as String?,
      timeOfBirth: identical(timeOfBirth, _unset)
          ? this.timeOfBirth
          : timeOfBirth as String?,
      placeOfBirth: identical(placeOfBirth, _unset)
          ? this.placeOfBirth
          : placeOfBirth as String?,
      latitude: identical(latitude, _unset)
          ? this.latitude
          : latitude as double?,
      longitude: identical(longitude, _unset)
          ? this.longitude
          : longitude as double?,
      placeId: identical(placeId, _unset) ? this.placeId : placeId as String?,
      timezone: identical(timezone, _unset)
          ? this.timezone
          : timezone as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BirthDetails &&
            other.dateOfBirth == dateOfBirth &&
            other.timeOfBirth == timeOfBirth &&
            other.placeOfBirth == placeOfBirth &&
            other.latitude == latitude &&
            other.longitude == longitude &&
            other.placeId == placeId &&
            other.timezone == timezone;
  }

  @override
  int get hashCode => Object.hash(
    dateOfBirth,
    timeOfBirth,
    placeOfBirth,
    latitude,
    longitude,
    placeId,
    timezone,
  );

  static String? _stringValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) return value.toString();
    }
    return null;
  }

  static double? _doubleValue(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
