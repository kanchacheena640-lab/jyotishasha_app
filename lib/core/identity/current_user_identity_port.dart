/// Synchronous boundary for retrieving the current Firebase user identity.
abstract interface class CurrentUserIdentityPort {
  String? get currentFirebaseUid;
}
