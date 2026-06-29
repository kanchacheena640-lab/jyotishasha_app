/// Immutable identity data shared by user and session contracts.
final class UserIdentity {
  const UserIdentity({
    this.firebaseUid,
    this.name,
    this.email,
    this.phone,
    this.photoUrl,
    this.provider,
  });

  static const Object _unset = Object();

  final String? firebaseUid;
  final String? name;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final String? provider;

  factory UserIdentity.fromJson(Map<String, dynamic> json) {
    return UserIdentity(
      firebaseUid: _stringValue(json, const [
        'uid',
        'firebase_uid',
        'firebaseUid',
      ]),
      name: _stringValue(json, const ['name', 'displayName', 'display_name']),
      email: _stringValue(json, const ['email']),
      phone: _stringValue(json, const ['phone', 'phoneNumber', 'phone_number']),
      photoUrl: _stringValue(json, const [
        'photo',
        'photoURL',
        'photoUrl',
        'photo_url',
      ]),
      provider: _stringValue(json, const ['provider']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': firebaseUid,
      'name': name,
      'email': email,
      'phone': phone,
      'photo': photoUrl,
      'provider': provider,
    };
  }

  UserIdentity copyWith({
    Object? firebaseUid = _unset,
    Object? name = _unset,
    Object? email = _unset,
    Object? phone = _unset,
    Object? photoUrl = _unset,
    Object? provider = _unset,
  }) {
    return UserIdentity(
      firebaseUid: identical(firebaseUid, _unset)
          ? this.firebaseUid
          : firebaseUid as String?,
      name: identical(name, _unset) ? this.name : name as String?,
      email: identical(email, _unset) ? this.email : email as String?,
      phone: identical(phone, _unset) ? this.phone : phone as String?,
      photoUrl: identical(photoUrl, _unset)
          ? this.photoUrl
          : photoUrl as String?,
      provider: identical(provider, _unset)
          ? this.provider
          : provider as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UserIdentity &&
            other.firebaseUid == firebaseUid &&
            other.name == name &&
            other.email == email &&
            other.phone == phone &&
            other.photoUrl == photoUrl &&
            other.provider == provider;
  }

  @override
  int get hashCode =>
      Object.hash(firebaseUid, name, email, phone, photoUrl, provider);

  static String? _stringValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) return value.toString();
    }
    return null;
  }
}
