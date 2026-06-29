import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../services/backend_auth_service.dart';
import '../../models/session/authentication_state.dart';
import '../../models/session/session.dart';
import '../../models/session/session_state.dart';
import '../../models/user/user.dart';
import '../../models/user/user_identity.dart';
import '../session_repository.dart';

final class FirebaseSessionRepository implements SessionRepository {
  FirebaseSessionRepository({
    firebase.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? firebase.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final firebase.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<Session?> watchSession() =>
      _auth.authStateChanges().asyncMap(_sessionFromFirebaseUser);

  @override
  Future<Session?> getCurrentSession() =>
      _sessionFromFirebaseUser(_auth.currentUser);

  @override
  Future<Session> signIn({required String provider}) async {
    final normalized = provider.trim().toLowerCase();
    final firebaseUser = switch (normalized) {
      'google' => await _signInWithGoogle(),
      'facebook' => await _signInWithFacebook(),
      _ => throw ArgumentError.value(provider, 'provider'),
    };
    final session = await _sessionFromFirebaseUser(firebaseUser);
    if (session == null) {
      return const Session(
        authentication: AuthenticationState(isAuthenticated: false),
        state: SessionState(status: 'cancelled'),
      );
    }
    return session;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();

    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect();
        await googleSignIn.signOut();
      }
    } catch (_) {}

    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }

  @override
  Future<String?> getBackendToken(String firebaseUid) =>
      BackendAuthService.getBackendToken(firebaseUid);

  Future<firebase.User?> _signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = firebase.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred = await _auth.signInWithCredential(credential);
    return userCred.user;
  }

  Future<firebase.User?> _signInWithFacebook() async {
    final result = await FacebookAuth.instance.login();
    if (result.status != LoginStatus.success) return null;

    final credential = firebase.FacebookAuthProvider.credential(
      result.accessToken!.tokenString,
    );

    final userCred = await _auth.signInWithCredential(credential);
    return userCred.user;
  }

  Future<Session?> _sessionFromFirebaseUser(firebase.User? firebaseUser) async {
    if (firebaseUser == null) return null;

    final snapshot = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
    final persisted = snapshot.data();
    final identity = UserIdentity(
      firebaseUid: firebaseUser.uid,
      name: firebaseUser.displayName,
      email: firebaseUser.email,
      phone: firebaseUser.phoneNumber,
      photoUrl: firebaseUser.photoURL,
      provider: persisted?['provider']?.toString() ?? _providerFor(firebaseUser),
    );
    final user = persisted == null
        ? User(identity: identity)
        : User.fromJson({...persisted, ...identity.toJson()});
    final backendUserId = user.backendUserId;

    return Session(
      user: user,
      authentication: AuthenticationState(
        isAuthenticated: true,
        identity: identity,
      ),
      state: SessionState(
        status: 'authenticated',
        isRestoring: false,
        isBackendLinked: backendUserId != null,
      ),
      backendUserId: backendUserId,
    );
  }

  String? _providerFor(firebase.User firebaseUser) {
    for (final info in firebaseUser.providerData) {
      final providerId = info.providerId.trim().toLowerCase();
      switch (providerId) {
        case 'google.com':
          return 'google';
        case 'facebook.com':
          return 'facebook';
      }
    }
    return null;
  }
}
