import 'package:flutter/material.dart';
import '../../data/card_model.dart';

class SharePoster extends StatelessWidget {
  final CardModel card;

  const SharePoster({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      height: 1920,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0f172a), Color(0xFF7c3aed)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 100),
        child: Column(
          children: [
            /// 🔥 TOP ICON (attraction)
            Icon(_getIcon(card.type), size: 80, color: Colors.white),

            const SizedBox(height: 40),

            /// 🔥 TITLE
            Text(
              card.getTitle('en'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 40),

            /// 🔥 CONTENT BOX (well defined boundary)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  card.getContent('en'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            /// 🔥 CTA SECTION
            Column(
              children: [
                const Text(
                  "Check your personalized horoscope",
                  style: TextStyle(fontSize: 24, color: Colors.white70),
                ),
                const SizedBox(height: 10),
                Text(
                  card.cta ?? "Download Jyotishasha App",
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// 🔥 BRAND
            const Text(
              "Jyotishasha",
              style: TextStyle(fontSize: 22, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 ICON LOGIC
  IconData _getIcon(String type) {
    switch (type) {
      case "morning":
        return Icons.wb_sunny;
      case "evening":
        return Icons.nightlight_round;
      case "chaughadiya":
        return Icons.access_time;
      case "panchak":
        return Icons.warning_amber_rounded;
      case "deep_remedy":
        return Icons.auto_awesome;
      default:
        return Icons.star;
    }
  }
}
