import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Welcome to Jyotishasha",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => context.go('/birth'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 14,
                  ),
                ),
                child: const Text("Continue with Google"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/birth'),
                child: const Text("Continue with Facebook"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/birth'),
                child: const Text("Continue with Apple"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
