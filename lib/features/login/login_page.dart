import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../core/constants/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final auth = AuthService();
  bool _isLoading = false;

  // ---------------------------------------------------------
  // ⭐ GOOGLE LOGIN (Final Implementation)
  // ---------------------------------------------------------
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    final user = await auth.signInWithGoogle();

    setState(() => _isLoading = false);

    if (!mounted || user == null) return;

    final uid = user.uid;
    final firestore = FirebaseFirestore.instance;

    try {
      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('profiles')
          .doc('default')
          .get();

      if (doc.exists) {
        context.go('/dashboard'); // Existing user
      } else {
        context.go('/birth'); // New user setup
      }
    } catch (e) {
      debugPrint("Login profile check error: $e");
      context.go('/birth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFFF5F8),
                    Color(0xFFFCEFF9),
                    Color(0xFFFEEFF5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // ⭐ App Logo
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 2,
                        ),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.08),
                            Colors.white,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(
                        Icons.star_rate_rounded,
                        size: 54,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ⭐ Heading
                    Text(
                      "Welcome to Jyotishasha",
                      style: GoogleFonts.montserrat(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Personalized Kundali • Daily Insights • AskNow",
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 50),

                    // ---------------------------------------------------------
                    // ⭐ FINAL GOOGLE LOGIN BUTTON
                    // ---------------------------------------------------------
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleLogin,
                        icon: const Icon(
                          Icons.g_mobiledata,
                          size: 28,
                          color: Colors.white,
                        ),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            "Continue with Google",
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDB4437),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ---------------------------------------------------------
                    // ⭐ Terms
                    // ---------------------------------------------------------
                    Text(
                      "By continuing, you agree to our Terms & Privacy Policy.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ---------------------------------------------------------
          // ⭐ Loading Overlay
          // ---------------------------------------------------------
          if (_isLoading)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.35),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
