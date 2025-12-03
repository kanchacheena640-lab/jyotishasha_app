import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';

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

      if (user != null) await _createOrUpdateUser(user, "google");
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
  // 🔥 CREATE / UPDATE ROOT USER (No backend calls here)
  // ----------------------------------------------------------
  Future<void> _createOrUpdateUser(User user, String provider) async {
    try {
      final docRef = _firestore.collection("users").doc(user.uid);
      final snap = await docRef.get();
      final now = DateTime.now().toIso8601String();

      if (snap.exists) {
        // Existing user → update login info
        await docRef.update({
          "name": user.displayName ?? "",
          "email": user.email ?? "",
          "photo": user.photoURL ?? "",
          "provider": provider,
          "lastLogin": now,
          "updatedAt": now,
        });
      } else {
        // New user → create root doc
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
          "backend_user_id": null, // will be set after profile creation
        });
      }

      debugPrint("✅ Firestore user synced: ${user.email}");
    } catch (e) {
      debugPrint("❌ Firestore sync error: $e");
    }
  }

  // ----------------------------------------------------------
  // 🔹 LOGOUT (Google + Facebook Safe)
  // ----------------------------------------------------------
  Future<void> signOut() async {
    try {
      await _auth.signOut();

      // Google safe logout
      try {
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.disconnect();
          await googleSignIn.signOut();
        }
      } catch (e) {
        debugPrint("⚠️ Google logout skipped: $e");
      }

      // Facebook safe logout
      try {
        await FacebookAuth.instance.logOut();
      } catch (e) {
        debugPrint("⚠️ Facebook logout skipped: $e");
      }

      debugPrint("✅ User fully signed out");
    } catch (e) {
      debugPrint("❌ Logout error: $e");
      rethrow;
    }
  }
}
