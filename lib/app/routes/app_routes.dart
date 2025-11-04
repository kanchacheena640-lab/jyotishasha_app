import 'package:go_router/go_router.dart';

// 🌅 Entry Screens
import '../../features/splash/splash_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/login/login_page.dart';
import '../../features/birth/birth_detail_page.dart';

// 🏠 Main Sections
import '../../features/dashboard/dashboard_page.dart';
import '../../features/astrology/astrology_page.dart';
import '../../features/reports/reports_page.dart';
import '../../features/asknow/asknow_chat_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/subscription/subscription_page.dart';

// ⚠️ Utility
import '../../features/error/error_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/birth', builder: (_, __) => const BirthDetailPage()),
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
    GoRoute(path: '/astrology', builder: (_, __) => const AstrologyPage()),
    GoRoute(path: '/reports', builder: (_, __) => const ReportsPage()),

    // ❌ Removed ToolResultPage from here (dynamic params — navigated via form)
    // ✅ ToolResultPage is opened via Navigator.push in ToolDetailPage
    GoRoute(path: '/asknow', builder: (_, __) => const AskNowChatPage()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
    GoRoute(
      path: '/subscription',
      builder: (_, __) => const SubscriptionPage(),
    ),
    GoRoute(path: '/error', builder: (_, __) => const ErrorPage()),
  ],
);
