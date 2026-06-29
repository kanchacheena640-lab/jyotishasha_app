import '../user/user_identity.dart';

/// Immutable point-in-time authentication state.
final class AuthenticationState {
  const AuthenticationState({
    this.isAuthenticated,
    this.identity,
    this.errorMessage,
  });

  static const Object _unset = Object();

  final bool? isAuthenticated;
  final UserIdentity? identity;
  final String? errorMessage;

  factory AuthenticationState.fromJson(Map<String, dynamic> json) {
    final identityJson = _mapValue(json['identity']) ?? _mapValue(json['user']);

    return AuthenticationState(
      isAuthenticated: _boolValue(
        json['is_authenticated'] ??
            json['isAuthenticated'] ??
            json['authenticated'],
      ),
      identity: identityJson != null || _containsIdentity(json)
          ? UserIdentity.fromJson(identityJson ?? json)
          : null,
      errorMessage: _stringValue(json, const [
        'error',
        'error_message',
        'errorMessage',
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_authenticated': isAuthenticated,
      'identity': identity?.toJson(),
      'error': errorMessage,
    };
  }

  AuthenticationState copyWith({
    Object? isAuthenticated = _unset,
    Object? identity = _unset,
    Object? errorMessage = _unset,
  }) {
    return AuthenticationState(
      isAuthenticated: identical(isAuthenticated, _unset)
          ? this.isAuthenticated
          : isAuthenticated as bool?,
      identity: identical(identity, _unset)
          ? this.identity
          : identity as UserIdentity?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthenticationState &&
            other.isAuthenticated == isAuthenticated &&
            other.identity == identity &&
            other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(isAuthenticated, identity, errorMessage);

  static bool? _boolValue(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return null;
  }

  static String? _stringValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) return value.toString();
    }
    return null;
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
}
