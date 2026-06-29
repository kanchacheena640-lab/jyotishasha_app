import '../user/user.dart';
import 'authentication_state.dart';
import 'session_state.dart';

/// Immutable snapshot of Firebase and backend session data.
final class Session {
  const Session({
    this.user,
    this.authentication,
    this.state,
    this.backendUserId,
    this.backendToken,
    this.createdAt,
    this.expiresAt,
  });

  static const Object _unset = Object();

  final User? user;
  final AuthenticationState? authentication;
  final SessionState? state;
  final int? backendUserId;
  final String? backendToken;
  final Object? createdAt;
  final Object? expiresAt;

  factory Session.fromJson(Map<String, dynamic> json) {
    final userJson = _mapValue(json['user']);
    final authenticationJson =
        _mapValue(json['authentication']) ??
        _mapValue(json['authentication_state']);
    final stateJson =
        _mapValue(json['state']) ?? _mapValue(json['session_state']);

    return Session(
      user: userJson != null || _containsUser(json)
          ? User.fromJson(userJson ?? json)
          : null,
      authentication:
          authenticationJson != null || _containsAuthentication(json)
          ? AuthenticationState.fromJson(authenticationJson ?? json)
          : null,
      state: stateJson != null || _containsState(json)
          ? SessionState.fromJson(stateJson ?? json)
          : null,
      backendUserId: _intValue(
        json['backend_user_id'] ??
            json['backendUserId'] ??
            json['backendUserID'] ??
            json['user_id'],
      ),
      backendToken: _stringValue(json, const [
        'token',
        'backend_token',
        'backendToken',
        'jwt',
      ]),
      createdAt: json['createdAt'] ?? json['created_at'],
      expiresAt: json['expiresAt'] ?? json['expires_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user?.toJson(),
      'authentication': authentication?.toJson(),
      'state': state?.toJson(),
      'backend_user_id': backendUserId,
      'token': backendToken,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
    };
  }

  Session copyWith({
    Object? user = _unset,
    Object? authentication = _unset,
    Object? state = _unset,
    Object? backendUserId = _unset,
    Object? backendToken = _unset,
    Object? createdAt = _unset,
    Object? expiresAt = _unset,
  }) {
    return Session(
      user: identical(user, _unset) ? this.user : user as User?,
      authentication: identical(authentication, _unset)
          ? this.authentication
          : authentication as AuthenticationState?,
      state: identical(state, _unset) ? this.state : state as SessionState?,
      backendUserId: identical(backendUserId, _unset)
          ? this.backendUserId
          : backendUserId as int?,
      backendToken: identical(backendToken, _unset)
          ? this.backendToken
          : backendToken as String?,
      createdAt: identical(createdAt, _unset) ? this.createdAt : createdAt,
      expiresAt: identical(expiresAt, _unset) ? this.expiresAt : expiresAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Session &&
            other.user == user &&
            other.authentication == authentication &&
            other.state == state &&
            other.backendUserId == backendUserId &&
            other.backendToken == backendToken &&
            other.createdAt == createdAt &&
            other.expiresAt == expiresAt;
  }

  @override
  int get hashCode => Object.hash(
    user,
    authentication,
    state,
    backendUserId,
    backendToken,
    createdAt,
    expiresAt,
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

  static bool _containsUser(Map<String, dynamic> json) {
    return const [
      'uid',
      'firebase_uid',
      'firebaseUid',
      'name',
      'email',
      'phone',
      'photo',
      'provider',
      'activeProfileId',
      'backend_user_id',
    ].any(json.containsKey);
  }

  static bool _containsAuthentication(Map<String, dynamic> json) {
    return const [
      'is_authenticated',
      'isAuthenticated',
      'authenticated',
    ].any(json.containsKey);
  }

  static bool _containsState(Map<String, dynamic> json) {
    return const [
      'status',
      'session_status',
      'is_restoring',
      'isRestoring',
      'is_backend_linked',
      'isBackendLinked',
    ].any(json.containsKey);
  }
}
