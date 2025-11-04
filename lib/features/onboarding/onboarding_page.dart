import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = [
      (
        "Personalized Guidance, Absolutely Free",
        "We created Jyotishasha to make authentic astrology accessible to everyone.",
      ),
      (
        "Your Stars, Your Story",
        "No two charts are the same — get a truly personalized daily horoscope.",
      ),
      (
        "Enjoy 15 Days of Premium Astrology — Free!",
        "Unlock personalized chat, advanced horoscope insights & muhurth features.",
      ),
    ];

    return Scaffold(
      body: PageView.builder(
        itemCount: pages.length,
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4B0082), Color(0xFFFBBF24)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                pages[i].$1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                pages[i].$2,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 50),
              if (i == pages.length - 1)
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text("Continue"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
