import 'package:flutter/material.dart';

/// 🌈 Global Jyotishasha Brand Colors
class AppColors {
  static const Color primary = Color(0xFF7C3AED);
  static const Color secondary = Color(0xFFFBBF24);
  static const Color background = Color(0xFFF8F6FB);
  static const Color card = Colors.white;
  static const Color textDark = Colors.black87;
  static const Color textLight = Colors.white;
  static const Color accentBlue = Color(0xFF1E3A8A);

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

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.card,
      ),

      // ✅ SAFE FONT APPLY (no fontFamily param)
      textTheme: base.textTheme
          .apply(fontFamily: 'Montserrat')
          .copyWith(
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
            bodyMedium: const TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),

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

      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 2,
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

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

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}
