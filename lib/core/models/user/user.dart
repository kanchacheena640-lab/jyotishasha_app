import 'user_identity.dart';
import 'user_preferences.dart';

/// Immutable application representation of the root Firestore user document.
final class User {
  const User({
    this.identity,
    this.preferences,
    this.backendUserId,
    this.createdAt,
    this.updatedAt,
    this.lastLogin,
  });

  static const Object _unset = Object();

  final UserIdentity? identity;
  final UserPreferences? preferences;
  final int? backendUserId;
  final Object? createdAt;
  final Object? updatedAt;
  final Object? lastLogin;

  factory User.fromJson(Map<String, dynamic> json) {
    final identityJson = _mapValue(json['identity']);
    final preferencesJson = _mapValue(json['preferences']);

    return User(
      identity: identityJson != null || _containsIdentity(json)
          ? UserIdentity.fromJson(identityJson ?? json)
          : null,
      preferences: preferencesJson != null || _containsPreferences(json)
          ? UserPreferences.fromJson(preferencesJson ?? json)
          : null,
      backendUserId: _intValue(
        json['backend_user_id'] ??
            json['backendUserId'] ??
            json['backendUserID'] ??
            json['user_id'],
      ),
      createdAt: json['createdAt'] ?? json['created_at'],
      updatedAt: json['updatedAt'] ?? json['updated_at'],
      lastLogin: json['lastLogin'] ?? json['last_login'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (identity != null) ...identity!.toJson(),
      if (preferences != null) ...preferences!.toJson(),
      'backend_user_id': backendUserId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastLogin': lastLogin,
    };
  }

  User copyWith({
    Object? identity = _unset,
    Object? preferences = _unset,
    Object? backendUserId = _unset,
    Object? createdAt = _unset,
    Object? updatedAt = _unset,
    Object? lastLogin = _unset,
  }) {
    return User(
      identity: identical(identity, _unset)
          ? this.identity
          : identity as UserIdentity?,
      preferences: identical(preferences, _unset)
          ? this.preferences
          : preferences as UserPreferences?,
      backendUserId: identical(backendUserId, _unset)
          ? this.backendUserId
          : backendUserId as int?,
      createdAt: identical(createdAt, _unset) ? this.createdAt : createdAt,
      updatedAt: identical(updatedAt, _unset) ? this.updatedAt : updatedAt,
      lastLogin: identical(lastLogin, _unset) ? this.lastLogin : lastLogin,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is User &&
            other.identity == identity &&
            other.preferences == preferences &&
            other.backendUserId == backendUserId &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt &&
            other.lastLogin == lastLogin;
  }

  @override
  int get hashCode => Object.hash(
    identity,
    preferences,
    backendUserId,
    createdAt,
    updatedAt,
    lastLogin,
  );

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

  static bool _containsIdentity(Map<String, dynamic> json) {
    return const [
      'uid',
      'firebase_uid',
      'firebaseUid',
      'name',
      'email',
      'phone',
      'photo',
      'provider',
    ].any(json.containsKey);
  }

  static bool _containsPreferences(Map<String, dynamic> json) {
    return const [
      'activeProfileId',
      'active_profile_id',
      'language',
      'lang',
      'fcm_token',
      'fcmToken',
      'fcm_updated_at',
      'fcmUpdatedAt',
    ].any(json.containsKey);
  }
}
