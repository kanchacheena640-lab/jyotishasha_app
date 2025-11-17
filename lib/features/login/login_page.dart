import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:jyotishasha_app/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final auth = AuthService();
  bool _isLoading = false;

  // 🔹 Google Login Flow
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final user = await auth.signInWithGoogle();
    setState(() => _isLoading = false);

    if (user == null || !mounted) return;

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
        // ✅ Default profile exists → Go to Dashboard
        context.go('/dashboard');
      } else {
        // 🆕 First-time user → Go to Birth Detail Page
        context.go('/birth');
      }
    } catch (e) {
      debugPrint('Firestore check error: $e');
      context.go('/birth'); // fallback
    }
  }

  // 🔹 Facebook Login Flow
  Future<void> _handleFacebookLogin() async {
    setState(() => _isLoading = true);
    final user = await auth.signInWithFacebook();
    setState(() => _isLoading = false);

    if (user == null || !mounted) return;

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
        context.go('/dashboard');
      } else {
        context.go('/birth');
      }
    } catch (e) {
      debugPrint('Firestore check error: $e');
      context.go('/birth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 40,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),

                      // 🔮 App Logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.1),
                              Colors.white,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          Icons.star,
                          color: AppColors.primary,
                          size: 46,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 🌟 Heading
                      Text(
                        "Welcome to Jyotishasha",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Discover your personalized astrological path",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 60),

                      // 🌸 Google Login
                      _socialButton(
                        icon: Icons.g_mobiledata,
                        text: "Continue with Google",
                        color: const Color(0xFFDB4437),
                        onTap: _isLoading ? null : _handleGoogleLogin,
                      ),

                      const SizedBox(height: 16),

                      // 💙 Facebook Login
                      _socialButton(
                        icon: Icons.facebook,
                        text: "Continue with Facebook",
                        color: const Color(0xFF1877F2),
                        onTap: _isLoading ? null : _handleFacebookLogin,
                      ),

                      const SizedBox(height: 16),

                      // 🍎 Apple Login (placeholder)
                      _socialButton(
                        icon: Icons.apple,
                        text: "Continue with Apple",
                        color: Colors.black,
                        onTap: _isLoading
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Apple login coming soon 🍎"),
                                  ),
                                );
                              },
                      ),

                      const SizedBox(height: 40),

                      // 🔸 Terms
                      Text(
                        "By continuing, you agree to our Terms & Privacy Policy",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 🔹 Loader Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  /// 🔹 Common Social Button Widget
  Widget _socialButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 24),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            text,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 3,
        ),
      ),
    );
  }
}
