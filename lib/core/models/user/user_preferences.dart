/// Immutable user-level preferences stored on the root user document.
final class UserPreferences {
  const UserPreferences({
    this.activeProfileId,
    this.language,
    this.fcmToken,
    this.fcmUpdatedAt,
  });

  static const Object _unset = Object();

  final String? activeProfileId;
  final String? language;
  final String? fcmToken;
  final Object? fcmUpdatedAt;

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      activeProfileId: _stringValue(json, const [
        'activeProfileId',
        'active_profile_id',
      ]),
      language: _stringValue(json, const ['language', 'lang']),
      fcmToken: _stringValue(json, const ['fcm_token', 'fcmToken']),
      fcmUpdatedAt: json['fcm_updated_at'] ?? json['fcmUpdatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeProfileId': activeProfileId,
      'language': language,
      'fcm_token': fcmToken,
      'fcm_updated_at': fcmUpdatedAt,
    };
  }

  UserPreferences copyWith({
    Object? activeProfileId = _unset,
    Object? language = _unset,
    Object? fcmToken = _unset,
    Object? fcmUpdatedAt = _unset,
  }) {
    return UserPreferences(
      activeProfileId: identical(activeProfileId, _unset)
          ? this.activeProfileId
          : activeProfileId as String?,
      language: identical(language, _unset)
          ? this.language
          : language as String?,
      fcmToken: identical(fcmToken, _unset)
          ? this.fcmToken
          : fcmToken as String?,
      fcmUpdatedAt: identical(fcmUpdatedAt, _unset)
          ? this.fcmUpdatedAt
          : fcmUpdatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UserPreferences &&
            other.activeProfileId == activeProfileId &&
            other.language == language &&
            other.fcmToken == fcmToken &&
            other.fcmUpdatedAt == fcmUpdatedAt;
  }

  @override
  int get hashCode =>
      Object.hash(activeProfileId, language, fcmToken, fcmUpdatedAt);

  static String? _stringValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) return value.toString();
    }
    return null;
  }
}
