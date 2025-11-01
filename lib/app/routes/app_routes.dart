import 'package:flutter/material.dart';

// ✅ Corrected imports (because features folder is inside app/)
import 'package:jyotishasha_app/app/features/splash/splash_page.dart';
import 'package:jyotishasha_app/app/features/auth/login_page.dart';
import 'package:jyotishasha_app/app/features/birth/birth_detail_page.dart';
import 'package:jyotishasha_app/app/features/auth/welcome_showcase.dart';
import 'package:jyotishasha_app/app/features/dashboard/dashboard_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String birth = '/birth';
  static const String welcome = '/welcome';
  static const String dashboard = '/dashboard';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashPage(),
    login: (context) => const LoginPage(),
    birth: (context) => const BirthDetailPage(),
    welcome: (context) => const WelcomeShowcase(),
    dashboard: (context) => const DashboardPage(),
  };
}
