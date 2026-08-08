import 'package:firebase_auth/firebase_auth.dart';

import 'current_user_identity_port.dart';

final class FirebaseCurrentUserIdentityPort implements CurrentUserIdentityPort {
  FirebaseCurrentUserIdentityPort({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  @override
  String? get currentFirebaseUid => _firebaseAuth.currentUser?.uid;
}
