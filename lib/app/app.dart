import 'package:flutter/material.dart';
import 'package:jyotishasha_app/app/routes/app_routes.dart';
import 'package:jyotishasha_app/app/theme/app_theme.dart';

/// 🪔 JyotishashaApp — Root widget for the entire application.
/// This is the single entry point that wraps the GoRouter and global theme.
class JyotishashaApp extends StatelessWidget {
  const JyotishashaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Jyotishasha',
      debugShowCheckedModeBanner: false,

      // 🎨 Global unified theme
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,

      // 🧭 Centralized navigation via GoRouter
      routerConfig: appRouter,
    );
  }
}
