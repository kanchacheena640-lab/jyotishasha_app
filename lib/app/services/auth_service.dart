// 📁 lib/app/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// 🔥 AuthService
/// A singleton class managing all authentication logic in one place.
/// Includes Google & Facebook sign-in and sign-out functionality.
class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Firebase instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen user state changes globally
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// ✅ Google Sign-In
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
      print('❌ Google Sign-In Error: $e');
      return null;
    }
  }

  /// ✅ Facebook Sign-In
  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) {
        print('⚠️ Facebook login cancelled or failed');
        return null;
      }

      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(result.accessToken!.token);

      return await _auth.signInWithCredential(facebookAuthCredential);
    } catch (e) {
      print('❌ Facebook Sign-In Error: $e');
      return null;
    }
  }

  /// ✅ Sign Out (for all providers)
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
      await FacebookAuth.instance.logOut();
    } catch (e) {
      print('⚠️ Sign-Out Error: $e');
    }
  }

  /// ✅ Current Firebase User
  User? get currentUser => _auth.currentUser;
}
