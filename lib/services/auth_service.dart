import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:jyotishasha_app/core/repositories/implementations/firebase_session_repository.dart';
import 'package:jyotishasha_app/core/repositories/session_repository.dart';
import 'package:jyotishasha_app/services/backend_auth_service.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    SessionRepository? sessionRepository,
  }) : this._resolved(
         auth: auth ?? FirebaseAuth.instance,
         firestore: firestore ?? FirebaseFirestore.instance,
         sessionRepository: sessionRepository,
       );

  AuthService._resolved({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    SessionRepository? sessionRepository,
  }) : _auth = auth,
       _firestore = firestore,
       _sessionRepository =
           sessionRepository ??
           FirebaseSessionRepository(auth: auth, firestore: firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final SessionRepository _sessionRepository;

  Future<User?> signInWithGoogle() async {
    try {
      final session = await _sessionRepository.signIn(provider: 'google');
      final user = session.authentication?.isAuthenticated == true
          ? _auth.currentUser
          : null;

      if (user != null) {
        debugPrint("LOGIN STEP 1: user mila ${user.uid}");

        Future.microtask(() {
          _createOrUpdateUser(user, 'google');
        });

        debugPrint('LOGIN STEP 2: backend sync started');
      }
      return user;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      rethrow;
    }
  }

  Future<User?> signInWithFacebook() async {
    try {
      final session = await _sessionRepository.signIn(provider: 'facebook');
      final user = session.authentication?.isAuthenticated == true
          ? _auth.currentUser
          : null;

      if (user != null) {
        await _createOrUpdateUser(user, 'facebook');
      }
      return user;
    } catch (e) {
      debugPrint('Facebook sign-in error: $e');
      rethrow;
    }
  }

  Future<void> _createOrUpdateUser(User user, String provider) async {
    try {
      debugPrint('SYNC START');

      final docRef = _firestore.collection('users').doc(user.uid);
      final snap = await docRef.get();
      final now = DateTime.now().toIso8601String();

      if (snap.exists) {
        await docRef.update({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photo': user.photoURL ?? '',
          'provider': provider,
          'lastLogin': now,
          'updatedAt': now,
        });
      } else {
        await docRef.set({
          'uid': user.uid,
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photo': user.photoURL ?? '',
          'provider': provider,
          'createdAt': now,
          'updatedAt': now,
          'lastLogin': now,
          'activeProfileId': null,
          'backend_user_id': null,
        });
      }

      debugPrint('Firestore user synced');

      final backendId = await BackendAuthService.registerFirebaseUser(
        firebaseUid: user.uid,
        email: user.email,
        phone: user.phoneNumber,
        name: user.displayName,
      );

      if (backendId != null) {
        await docRef.update({'backend_user_id': backendId});
        debugPrint('Backend user synced (id = $backendId)');
      } else {
        debugPrint('Backend sync failed');
      }

      debugPrint('SYNC END');
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _sessionRepository.signOut();
      debugPrint('User fully signed out');
    } catch (e) {
      debugPrint('Logout error: $e');
      rethrow;
    }
  }
}
