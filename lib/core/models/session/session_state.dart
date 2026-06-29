/// Immutable lifecycle state for a point-in-time session snapshot.
final class SessionState {
  const SessionState({
    this.status,
    this.isRestoring,
    this.isBackendLinked,
    this.errorMessage,
  });

  static const Object _unset = Object();

  final String? status;
  final bool? isRestoring;
  final bool? isBackendLinked;
  final String? errorMessage;

  factory SessionState.fromJson(Map<String, dynamic> json) {
    return SessionState(
      status: _stringValue(json, const ['status', 'session_status']),
      isRestoring: _boolValue(
        json['is_restoring'] ?? json['isRestoring'] ?? json['restoring'],
      ),
      isBackendLinked: _boolValue(
        json['is_backend_linked'] ??
            json['isBackendLinked'] ??
            json['backend_linked'],
      ),
      errorMessage: _stringValue(json, const [
        'error',
        'error_message',
        'errorMessage',
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'is_restoring': isRestoring,
      'is_backend_linked': isBackendLinked,
      'error': errorMessage,
    };
  }

  SessionState copyWith({
    Object? status = _unset,
    Object? isRestoring = _unset,
    Object? isBackendLinked = _unset,
    Object? errorMessage = _unset,
  }) {
    return SessionState(
      status: identical(status, _unset) ? this.status : status as String?,
      isRestoring: identical(isRestoring, _unset)
          ? this.isRestoring
          : isRestoring as bool?,
      isBackendLinked: identical(isBackendLinked, _unset)
          ? this.isBackendLinked
          : isBackendLinked as bool?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SessionState &&
            other.status == status &&
            other.isRestoring == isRestoring &&
            other.isBackendLinked == isBackendLinked &&
            other.errorMessage == errorMessage;
  }

  @override
  int get hashCode =>
      Object.hash(status, isRestoring, isBackendLinked, errorMessage);

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
}
