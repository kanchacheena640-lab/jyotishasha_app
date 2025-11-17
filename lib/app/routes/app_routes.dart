import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jyotishasha_app/features/darshan/darshan_page.dart';

// 🌅 Entry Screens
import '../../features/splash/splash_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/login/login_page.dart';
import '../../features/birth/birth_detail_page.dart';

// 🏠 Main Sections
import '../../features/dashboard/dashboard_page.dart';
import '../../features/astrology/astrology_page.dart';
import '../../features/reports/pages/report_catalog_page.dart';
import '../../features/asknow/asknow_chat_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/subscription/subscription_page.dart';

// ⚠️ Utility
// optional: if not created yet, comment it
// import '../../features/error/error_page.dart';

final GoRouter appRouter = GoRouter(
  debugLogDiagnostics: true,
  initialLocation: '/splash',

  // 🔐 Redirect based on Firebase Auth state
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final goingToLogin = state.matchedLocation == '/login';
    final goingToSplash = state.matchedLocation == '/splash';

    // 1️⃣ If user is not logged in → always go to login (except splash)
    if (user == null && !goingToLogin && !goingToSplash) {
      return '/login';
    }

    // 2️⃣ If user already logged in and trying to open login → go to dashboard
    if (user != null && goingToLogin) {
      return '/dashboard';
    }

    // 3️⃣ Otherwise → continue normally
    return null;
  },

  // ✅ Fallback for unknown routes
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        '404 — Page Not Found',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    ),
  ),

  routes: [
    // Root redirect
    GoRoute(path: '/', redirect: (_, __) => '/splash'),

    // 🌅 Entry flow
    GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/birth', builder: (_, __) => const BirthDetailPage()),

    // 🏠 Main sections
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
    GoRoute(path: '/astrology', builder: (_, __) => const AstrologyPage()),
    GoRoute(path: '/reports', builder: (_, __) => const ReportCatalogPage()),
    GoRoute(path: '/asknow', builder: (_, __) => const AskNowChatPage()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
    GoRoute(
      path: '/subscription',
      builder: (_, __) => const SubscriptionPage(),
    ),
    GoRoute(
      path: '/darshan',
      name: 'darshan',
      builder: (context, state) => const DarshanPage(),
    ),
  ],
);
