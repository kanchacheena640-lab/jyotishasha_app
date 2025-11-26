// lib/features/dashboard/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/state/firebase_kundali_provider.dart';
import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/panchang_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';

// Pages
import '../astrology/astrology_page.dart';
import '../reports/pages/report_catalog_page.dart';
import '../profile/profile_page.dart';
import 'dashboard_home_section.dart';
import '../asknow/asknow_chat_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  DateTime? _lastPressed;

  @override
  void initState() {
    super.initState();

    // RUN INIT FLOW ONCE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFlow();
    });

    // SETUP LISTENER SAFELY
    final profileProvider = context.read<ProfileProvider>();

    profileProvider.addListener(() async {
      if (!mounted) return;

      print("🔄 Profile switched → Reloading Dashboard...");

      final firebaseKundali = context.read<FirebaseKundaliProvider>();
      await firebaseKundali.loadFromFirebaseProfile();

      final kd = firebaseKundali.kundaliData;
      if (kd == null) return;

      final lang = (kd['language'] ?? "en").substring(0, 2);
      final lagna = kd['lagna_sign'] ?? '';
      final lat = kd['location']?['lat'] ?? 26.8467;
      final lng = kd['location']?['lng'] ?? 80.9462;

      // DAILY
      await context.read<DailyProvider>().fetchDaily(
        lagna: lagna,
        lat: lat,
        lon: lng,
        lang: lang,
      );

      // PANCHANG
      await context.read<PanchangProvider>().fetchPanchang(
        date: DateTime.now(),
        lat: lat,
        lng: lng,
      );
    });
  }

  // ----------------------
  // INITIAL BOOT FLOW
  // ----------------------
  Future<void> _initFlow() async {
    try {
      print("🟣 Dashboard init START");

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final firebaseKundali = context.read<FirebaseKundaliProvider>();
      await firebaseKundali.loadFromFirebaseProfile();

      final kd = firebaseKundali.kundaliData;
      if (kd == null) return;

      final lang = (kd['language'] ?? "en").substring(0, 2);
      final lagna = kd['lagna_sign'] ?? '';
      final lat = kd['location']?['lat'] ?? 26.8467;
      final lng = kd['location']?['lng'] ?? 80.9462;

      // DAILY
      await context.read<DailyProvider>().fetchDaily(
        lagna: lagna,
        lat: lat,
        lon: lng,
        lang: lang,
      );

      // PANCHANG
      await context.read<PanchangProvider>().fetchPanchang(
        date: DateTime.now(),
        lat: lat,
        lng: lng,
      );

      print("🏁 Dashboard Init Completed");
    } catch (e) {
      print("❌ Dashboard init ERROR: $e");
    }
  }

  final List<Widget> _pages = const [
    DashboardHomeSection(),
    AstrologyPage(),
    ReportCatalogPage(),
    AskNowChatPage(),
    ProfilePage(),
  ];

  // -----------------------------
  // DOUBLE BACK EXIT HANDLER
  // -----------------------------
  Future<void> _handleBackPress() async {
    final now = DateTime.now();

    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    if (_lastPressed == null ||
        now.difference(_lastPressed!) > const Duration(seconds: 2)) {
      _lastPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Press back again to minimize app"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 120));
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _pages[_currentIndex],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: AppColors.textPrimary.withOpacity(0.5),
          backgroundColor: AppColors.surface,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star_border),
              activeIcon: Icon(Icons.star),
              label: "Astrology",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description),
              label: "Reports",
            ),
            BottomNavigationBarItem(
              icon: _AskNowIcon(),
              activeIcon: Icon(Icons.chat),
              label: "Ask Now",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}

// ⭐ ASK NOW ICON WITH FREE TAG
class _AskNowIcon extends StatelessWidget {
  const _AskNowIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Icon(Icons.chat_bubble_outline),
        Positioned(
          right: -10,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              "FREE",
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
