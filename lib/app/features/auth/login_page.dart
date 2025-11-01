import 'package:flutter/material.dart';
import 'package:jyotishasha_app/app/services/auth_service.dart';
import 'package:jyotishasha_app/app/routes/app_routes.dart';

/// 🧿 LoginPage
/// Handles user authentication via Google & Facebook.
/// On successful login → navigates to DashboardPage.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  bool _loading = false;

  /// 🔥 Handle login
  Future<void> _handleLogin(String provider) async {
    setState(() => _loading = true);

    try {
      if (provider == 'google') {
        await _authService.signInWithGoogle();
      } else if (provider == 'facebook') {
        await _authService.signInWithFacebook();
      }

      // If user successfully logged in
      if (_authService.currentUser != null && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login cancelled or failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🌙 App title
                    const Text(
                      'Welcome to Jyotishasha',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // 🪙 Google Login Button
                    ElevatedButton.icon(
                      icon: Image.asset('assets/icons/google.png', height: 24),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.deepPurple),
                        ),
                      ),
                      onPressed: () => _handleLogin('google'),
                      label: const Text('Continue with Google'),
                    ),
                    const SizedBox(height: 16),

                    // 📘 Facebook Login Button
                    ElevatedButton.icon(
                      icon: Image.asset(
                        'assets/icons/facebook.png',
                        height: 24,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _handleLogin('facebook'),
                      label: const Text('Continue with Facebook'),
                    ),
                    const SizedBox(height: 30),

                    // 🧭 Skip button (temporary)
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.dashboard,
                      ),
                      child: const Text('Skip for now →'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
