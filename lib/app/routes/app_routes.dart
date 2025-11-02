import 'package:flutter/material.dart';
import 'package:jyotishasha_app/app/features/splash/splash_page.dart';
import 'package:jyotishasha_app/app/features/auth/login_page.dart';
import 'package:jyotishasha_app/app/features/birth/birth_detail_page.dart';
import 'package:jyotishasha_app/app/features/dashboard/dashboard_page.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const birthDetail = '/birth-detail';
  static const dashboard = '/dashboard';
}

final Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.splash: (context) => const SplashPage(),
  AppRoutes.login: (context) => const LoginPage(),
  AppRoutes.birthDetail: (context) => const BirthDetailPage(),
  AppRoutes.dashboard: (context) => const DashboardPage(),
};
