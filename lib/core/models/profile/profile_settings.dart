/// Immutable profile-specific settings and flags.
final class ProfileSettings {
  const ProfileSettings({
    this.language,
    this.gender,
    this.ayanamsa,
    this.isActive,
    this.isComplete,
  });

  static const Object _unset = Object();

  final String? language;
  final String? gender;
  final String? ayanamsa;
  final bool? isActive;
  final bool? isComplete;

  factory ProfileSettings.fromJson(Map<String, dynamic> json) {
    return ProfileSettings(
      language: _stringValue(json, const ['language', 'lang']),
      gender: _stringValue(json, const ['gender']),
      ayanamsa: _stringValue(json, const ['ayanamsa']),
      isActive: _boolValue(json['isActive'] ?? json['is_active']),
      isComplete: _boolValue(
        json['profile_complete'] ??
            json['profileComplete'] ??
            json['is_complete'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'gender': gender,
      'ayanamsa': ayanamsa,
      'isActive': isActive,
      'profile_complete': isComplete,
    };
  }

  ProfileSettings copyWith({
    Object? language = _unset,
    Object? gender = _unset,
    Object? ayanamsa = _unset,
    Object? isActive = _unset,
    Object? isComplete = _unset,
  }) {
    return ProfileSettings(
      language: identical(language, _unset)
          ? this.language
          : language as String?,
      gender: identical(gender, _unset) ? this.gender : gender as String?,
      ayanamsa: identical(ayanamsa, _unset)
          ? this.ayanamsa
          : ayanamsa as String?,
      isActive: identical(isActive, _unset) ? this.isActive : isActive as bool?,
      isComplete: identical(isComplete, _unset)
          ? this.isComplete
          : isComplete as bool?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProfileSettings &&
            other.language == language &&
            other.gender == gender &&
            other.ayanamsa == ayanamsa &&
            other.isActive == isActive &&
            other.isComplete == isComplete;
  }

  @override
  int get hashCode =>
      Object.hash(language, gender, ayanamsa, isActive, isComplete);

  static String? _stringValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) return value.toString();
    }
    return null;
  }

  static bool? _boolValue(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return null;
  }
}
