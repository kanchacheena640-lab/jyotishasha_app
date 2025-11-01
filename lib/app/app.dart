// 🌟 app.dart
// ---------------------------------------------------------
// Root configuration of the Jyotishasha Application
// ---------------------------------------------------------
// Responsibilities:
// - Defines MaterialApp structure
// - Applies global theme from app_theme.dart
// - Loads routes from app_routes.dart
// ---------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:jyotishasha_app/app/routes/app_routes.dart';
import 'package:jyotishasha_app/app/theme/app_theme.dart';

class JyotishashaApp extends StatelessWidget {
  const JyotishashaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jyotishasha',
      theme: AppTheme.lightTheme, // 🎨 Global theme
      initialRoute: AppRoutes.splash, // 🚪 Start from Splash Page
      routes: AppRoutes.routes, // 🗺️ Routing map
    );
  }
}
