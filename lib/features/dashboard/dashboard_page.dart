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
import 'package:jyotishasha_app/l10n/app_localizations.dart';

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

  bool _initialized = false; // 🛑 Prevent double-init
  bool _listenerAttached = false; // 🛑 Prevent multiple listeners

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized) {
        _initialized = true;
        _initFlow();
      }

      _attachProfileSwitchListener(); // SAFE
    });
  }

  // --------------------------------------------------
  // SAFE LISTENER: only attach once
  // --------------------------------------------------
  void _attachProfileSwitchListener() {
    if (_listenerAttached) return;
    _listenerAttached = true;

    final profileProvider = context.read<ProfileProvider>();

    profileProvider.addListener(() async {
      if (!mounted) return;

      print("🔄 PROFILE SWITCH TRIGGER");

      await _loadAndRefreshAll();
    });
  }

  // --------------------------------------------------
  // FULL LOAD SEQUENCE
  // --------------------------------------------------
  Future<void> _loadAndRefreshAll() async {
    final firebaseKundali = context.read<FirebaseKundaliProvider>();
    await firebaseKundali.loadFromFirebaseProfile(context);

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
    await context.read<PanchangProvider>().loadPanchang(lat: lat, lng: lng);
  }

  // --------------------------------------------------
  // FIRST BOOT LOAD
  // --------------------------------------------------
  Future<void> _initFlow() async {
    try {
      print("🟣 Dashboard INIT START");

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _loadAndRefreshAll();

      print("🏁 Dashboard INIT DONE");
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

  // --------------------------------------------------
  // DOUBLE BACK EXIT HANDLER
  // --------------------------------------------------
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
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: AppLocalizations.of(context)!.dashboard_home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.star_border),
              activeIcon: const Icon(Icons.star),
              label: AppLocalizations.of(context)!.dashboard_astrology,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.description_outlined),
              activeIcon: const Icon(Icons.description),
              label: AppLocalizations.of(context)!.dashboard_reports,
            ),
            BottomNavigationBarItem(
              icon: const _AskNowIcon(),
              activeIcon: const Icon(Icons.chat),
              label: AppLocalizations.of(context)!.dashboard_ask_now,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: AppLocalizations.of(context)!.dashboard_profile,
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
// ASK NOW ICON
// --------------------------------------------------
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
