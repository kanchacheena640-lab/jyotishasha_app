import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';

/// 🌈 Global Jyotishasha Brand Colors
class AppColors {
  static const Color primary = Color(0xFF7C3AED); // Deep Purple
  static const Color secondary = Color(0xFFFBBF24); // Saffron-Gold
  static const Color background = Color(0xFFF8F6FB); // Light Lavender-White
  static const Color card = Colors.white;
  static const Color textDark = Colors.black87;
  static const Color textLight = Colors.white;
  static const Color accentBlue = Color(0xFF1E3A8A);

  // 🌈 Gradients
  static const LinearGradient gradientPurpleGold = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientBlue = LinearGradient(
    colors: [Color(0xFFDBEAFE), Color(0xFFE0E7FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// 🎨 App-Wide Theme Configuration
class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      // 🟣 Global background color
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,

      // 🧩 Consistent color scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.card,
      ),

      // 🪶 Global Text Theme
      textTheme: GoogleFonts.montserratTextTheme().copyWith(
        displayLarge: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        titleMedium: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
        bodyLarge: const TextStyle(fontSize: 16, color: AppColors.textDark),
        bodyMedium: const TextStyle(fontSize: 14, color: AppColors.textDark),
      ),

      // 🧭 AppBar Style
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),

      // 🪔 Card Style
      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 2,
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // 🔘 Button Style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
      ),

      // ✏️ Input / Form Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: const TextStyle(color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black26),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),

      // 💫 SnackBar / Dialog / Sheet Styles
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}
