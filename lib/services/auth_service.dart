import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:jyotishasha_app/services/backend_auth_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ----------------------------------------------------------
  // 🔹 GOOGLE SIGN-IN
  // ----------------------------------------------------------
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;

      if (user != null) {
        debugPrint("🔥 LOGIN STEP 1: user मिला ${user.uid}");

        Future.microtask(() {
          _createOrUpdateUser(user, "google");
        });

        debugPrint("🔥 LOGIN STEP 2: backend sync started");
      }
      return user;
    } catch (e) {
      debugPrint("❌ Google sign-in error: $e");
      rethrow;
    }
  }

  // ----------------------------------------------------------
  // 🔹 FACEBOOK SIGN-IN
  // ----------------------------------------------------------
  Future<User?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) return null;

      final OAuthCredential credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;

      if (user != null) await _createOrUpdateUser(user, "facebook");
      return user;
    } catch (e) {
      debugPrint("❌ Facebook sign-in error: $e");
      rethrow;
    }
  }

  // ----------------------------------------------------------
  // 🔥 FIRESTORE + BACKEND SYNC (MANDATORY)
  // ----------------------------------------------------------
  Future<void> _createOrUpdateUser(User user, String provider) async {
    try {
      debugPrint("🔥 SYNC START");

      final docRef = _firestore.collection("users").doc(user.uid);
      final snap = await docRef.get();
      final now = DateTime.now().toIso8601String();

      // ------------------------------
      // 1) Update Firestore
      // ------------------------------
      if (snap.exists) {
        await docRef.update({
          "name": user.displayName ?? "",
          "email": user.email ?? "",
          "photo": user.photoURL ?? "",
          "provider": provider,
          "lastLogin": now,
          "updatedAt": now,
        });
      } else {
        await docRef.set({
          "uid": user.uid,
          "name": user.displayName ?? "",
          "email": user.email ?? "",
          "photo": user.photoURL ?? "",
          "provider": provider,
          "createdAt": now,
          "updatedAt": now,
          "lastLogin": now,
          "activeProfileId": null,
          "backend_user_id": null,
        });
      }

      debugPrint("✅ Firestore user synced");

      // ------------------------------
      // 2) Register on Backend
      // ------------------------------
      final backendId = await BackendAuthService.registerFirebaseUser(
        firebaseUid: user.uid,
        email: user.email,
        phone: user.phoneNumber,
        name: user.displayName,
      );

      if (backendId != null) {
        await docRef.update({"backend_user_id": backendId});
        debugPrint("🔥 Backend user synced (id = $backendId)");
      } else {
        debugPrint("⚠️ Backend sync failed");
      }

      debugPrint("🔥 SYNC END");
    } catch (e) {
      debugPrint("❌ Sync error: $e");
    }
  }

  // ----------------------------------------------------------
  // 🔹 LOGOUT
  // ----------------------------------------------------------
  Future<void> signOut() async {
    try {
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

      debugPrint("✅ User fully signed out");
    } catch (e) {
      debugPrint("❌ Logout error: $e");
      rethrow;
    }
  }
}
