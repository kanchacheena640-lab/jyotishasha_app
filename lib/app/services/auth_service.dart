// 📁 lib/app/services/auth_service.dart

// ---------------------------------------------------------
// 🔹 Imports — always at the top
// ---------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jyotishasha_app/app/routes/app_routes.dart';

// ---------------------------------------------------------
// 🔥 AuthService
// ---------------------------------------------------------
/// A singleton service class managing all authentication logic.
/// Includes Google, Facebook, and Firebase sign-in/out handling.
class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Firebase instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen user state changes globally
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // -------------------------------------------------------
  // ✅ Google Sign-In
  // -------------------------------------------------------
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // User cancelled login
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('❌ Google Sign-In Error: $e');
      return null;
    }
  }

  // -------------------------------------------------------
  // ✅ Facebook Sign-In
  // -------------------------------------------------------
  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) {
        debugPrint('⚠️ Facebook login cancelled or failed');
        return null;
      }

      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(result.accessToken!.token);

      return await _auth.signInWithCredential(facebookAuthCredential);
    } catch (e) {
      debugPrint('❌ Facebook Sign-In Error: $e');
      return null;
    }
  }

  // -------------------------------------------------------
  // ✅ Sign-Out (for all providers)
  // -------------------------------------------------------
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
      await FacebookAuth.instance.logOut();
    } catch (e) {
      debugPrint('⚠️ Sign-Out Error: $e');
    }
  }

  // -------------------------------------------------------
  // ✅ Current Firebase User
  // -------------------------------------------------------
  User? get currentUser => _auth.currentUser;
}

// ---------------------------------------------------------
// 🔹 Post-Login Handler — route user based on Firestore data
// ---------------------------------------------------------
Future<void> handlePostLogin(BuildContext context, User firebaseUser) async {
  if (!context.mounted) return;

  final FirebaseFirestore db = FirebaseFirestore.instance;
  final uid = firebaseUser.uid;

  try {
    // Check if user document exists and has filled birth details
    final doc = await db.collection('users').doc(uid).get();
    final bool hasBirthDetails =
        doc.exists && (doc.data()?['hasBirthDetails'] == true);

    // Navigate accordingly
    if (hasBirthDetails) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.birthDetail);
    }
  } catch (e) {
    debugPrint('⚠️ Firestore check failed: $e');
    // Fallback if something fails
    Navigator.pushReplacementNamed(context, AppRoutes.birthDetail);
  }
}
