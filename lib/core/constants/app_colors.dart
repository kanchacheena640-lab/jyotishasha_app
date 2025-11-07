import 'package:flutter/material.dart';

class AppColors {
  // 🌙 Brand Palette (From Next.js Tailwind)
  static const Color primary = Color(0xFF6B21A8); // Purple
  static const Color secondary = Color(0xFF4C1D95); // Indigo shade
  static const Color accent = Color(0xFF2563EB); // Blue button
  static const Color accentDark = Color(0xFF1D4ED8); // Hover blue
  static const Color surface = Colors.white; // Card background

  // 🪔 Gradients (soft white lavender gradient)
  static const Color backgroundStart = Color(0xFFF8F6FB);
  static const Color backgroundMid = Color(0xFFFDFDFD);
  static const Color backgroundEnd = Color(0xFFFFFFFF);

  // ✨ Text Colors
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;

  // 🌈 Reusable gradients
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [backgroundStart, backgroundMid, backgroundEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [secondary, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientBlue = LinearGradient(
    colors: [Color(0xFFDBEAFE), Color(0xFFE0E7FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🔮 Purple → Gold gradient (for CTA / footer / highlights)
  static const LinearGradient gradientPurpleGold = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
