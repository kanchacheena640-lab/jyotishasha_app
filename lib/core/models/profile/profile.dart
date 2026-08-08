import 'birth_details.dart';
import 'profile_settings.dart';

/// Immutable application profile contract for Firestore profile documents.
final class Profile {
  const Profile({
    this.id,
    this.name,
    this.birthDetails,
    this.settings,
    this.lagna,
    this.moonSign,
    this.nakshatra,
    this.backendUserId,
    this.backendProfileId,
    this.createdAt,
    this.updatedAt,
  });

  static const Object _unset = Object();

  final String? id;
  final String? name;
  final BirthDetails? birthDetails;
  final ProfileSettings? settings;
  final String? lagna;
  final String? moonSign;
  final String? nakshatra;
  final int? backendUserId;
  final int? backendProfileId;
  final Object? createdAt;
  final Object? updatedAt;

  factory Profile.fromJson(Map<String, dynamic> json) {
    final birthJson = _mapValue(json['birth_details']);
    final settingsJson = _mapValue(json['settings']);

    return Profile(
      id: _stringValue(json, const ['id', 'profile_id', 'profileId']),
      name: _stringValue(json, const ['name']),
      birthDetails: birthJson != null || _containsBirthDetails(json)
          ? BirthDetails.fromJson(birthJson ?? json)
          : null,
      settings: settingsJson != null || _containsSettings(json)
          ? ProfileSettings.fromJson(settingsJson ?? json)
          : null,
      lagna: _stringValue(json, const ['lagna']),
      moonSign: _stringValue(json, const ['moon_sign', 'moonSign']),
      nakshatra: _stringValue(json, const ['nakshatra']),
      backendUserId: _intValue(
        json['backend_user_id'] ??
            json['backendUserId'] ??
            json['backendUserID'],
      ),
      backendProfileId: _intValue(
        json['backend_profile_id'] ??
            json['backendProfileId'] ??
            json['backendProfileID'],
      ),
      createdAt: json['createdAt'] ?? json['created_at'],
      updatedAt: json['updatedAt'] ?? json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (birthDetails != null) ...birthDetails!.toJson(),
      if (settings != null) ...settings!.toJson(),
      'lagna': lagna,
      'moon_sign': moonSign,
      'nakshatra': nakshatra,
      'backend_user_id': backendUserId,
      'backend_profile_id': backendProfileId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Profile copyWith({
    Object? id = _unset,
    Object? name = _unset,
    Object? birthDetails = _unset,
    Object? settings = _unset,
    Object? lagna = _unset,
    Object? moonSign = _unset,
    Object? nakshatra = _unset,
    Object? backendUserId = _unset,
    Object? backendProfileId = _unset,
    Object? createdAt = _unset,
    Object? updatedAt = _unset,
  }) {
    return Profile(
      id: identical(id, _unset) ? this.id : id as String?,
      name: identical(name, _unset) ? this.name : name as String?,
      birthDetails: identical(birthDetails, _unset)
          ? this.birthDetails
          : birthDetails as BirthDetails?,
      settings: identical(settings, _unset)
          ? this.settings
          : settings as ProfileSettings?,
      lagna: identical(lagna, _unset) ? this.lagna : lagna as String?,
      moonSign: identical(moonSign, _unset)
          ? this.moonSign
          : moonSign as String?,
      nakshatra: identical(nakshatra, _unset)
          ? this.nakshatra
          : nakshatra as String?,
      backendUserId: identical(backendUserId, _unset)
          ? this.backendUserId
          : backendUserId as int?,
      backendProfileId: identical(backendProfileId, _unset)
          ? this.backendProfileId
          : backendProfileId as int?,
      createdAt: identical(createdAt, _unset) ? this.createdAt : createdAt,
      updatedAt: identical(updatedAt, _unset) ? this.updatedAt : updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Profile &&
            other.id == id &&
            other.name == name &&
            other.birthDetails == birthDetails &&
            other.settings == settings &&
            other.lagna == lagna &&
            other.moonSign == moonSign &&
            other.nakshatra == nakshatra &&
            other.backendUserId == backendUserId &&
            other.backendProfileId == backendProfileId &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    birthDetails,
    settings,
    lagna,
    moonSign,
    nakshatra,
    backendUserId,
    backendProfileId,
    createdAt,
    updatedAt,
  );

  static String? _stringValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) return value.toString();
    }
    return null;
  }

  static int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static Map<String, dynamic>? _mapValue(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return null;
  }

  static bool _containsBirthDetails(Map<String, dynamic> json) {
    return const [
      'dob',
      'date_of_birth',
      'tob',
      'time_of_birth',
      'pob',
      'place_name',
      'placeName',
      'lat',
      'latitude',
      'lng',
      'longitude',
      'place_id',
      'placeId',
      'timezone',
      'tz',
    ].any(json.containsKey);
  }

  static bool _containsSettings(Map<String, dynamic> json) {
    return const [
      'language',
      'lang',
      'gender',
      'ayanamsa',
      'isActive',
      'is_active',
      'profile_complete',
      'profileComplete',
      'is_complete',
    ].any(json.containsKey);
  }
}
