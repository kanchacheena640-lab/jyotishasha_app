// 🎨 app_theme.dart
// ---------------------------------------------------------
// Centralized theme configuration for Jyotishasha App.
// Manages colors, typography, and component styling.
// ---------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 🌞 Light theme
  static ThemeData get lightTheme => ThemeData(
    primarySwatch: Colors.deepPurple,
    scaffoldBackgroundColor: Colors.white,
    textTheme: GoogleFonts.montserratTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
