import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/state/firebase_kundali_provider.dart';
import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/panchang_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
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

  bool _initialized = false;
  bool _listenerAttached = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized) {
        _initialized = true;
        print("🟣 DASHBOARD → initFlow()");
        _initFlow();
      }

      _attachProfileSwitchListener();
    });
  }

  // --------------------------------------------------
  // SAFE LISTENER
  // --------------------------------------------------
  void _attachProfileSwitchListener() {
    if (_listenerAttached) return;
    _listenerAttached = true;

    final p = context.read<ProfileProvider>();

    p.addListener(() async {
      if (!mounted) return;

      print("🔄 DASHBOARD LISTENER → Profile switched");
      await _loadAndRefreshAll();
    });
  }

  // --------------------------------------------------
  // FULL EXPENSIVE LOAD
  // --------------------------------------------------
  Future<void> _loadAndRefreshAll() async {
    print("⚡ DASHBOARD → Loading Kundali & Daily");

    final firebaseKundali = context.read<FirebaseKundaliProvider>();
    final lang = context.read<LanguageProvider>().currentLang; // ⭐ FINAL FIXED

    // --------------------------------------------------------
    // STEP 1: Load Kundali with language
    // --------------------------------------------------------
    await firebaseKundali.loadFromFirebaseProfile(context, lang: lang);

    final kd = firebaseKundali.kundaliData;
    if (kd == null) {
      print("❌ DASHBOARD → kundaliData = NULL, skipping daily");
      return;
    }

    // --------------------------------------------------------
    // Extract values
    // --------------------------------------------------------
    final lagna = kd['lagna_sign'] ?? '';
    final lat = kd['location']?['lat'] ?? 26.8467;
    final lng = kd['location']?['lng'] ?? 80.9462;

    print("🌍 DASHBOARD → Sending Daily Request:");
    print("   - lagna: $lagna");
    print("   - lang:  $lang");
    print("   - lat/lng: $lat, $lng");

    // --------------------------------------------------------
    // STEP 2: Load Daily (language must match)
    // --------------------------------------------------------
    await context.read<DailyProvider>().fetchDaily(
      lagna: lagna,
      lat: lat,
      lon: lng,
      lang: lang,
    );

    print("📅 DASHBOARD → Loading Panchang");

    // --------------------------------------------------------
    // STEP 3: Load Panchang (language must match)
    // --------------------------------------------------------
    await context.read<PanchangProvider>().fetchPanchang(
      lat: lat,
      lng: lng,
      lang: lang, // force new API always
    );

    print("✅ DASHBOARD → All refreshed.\n\n");
  }

  // --------------------------------------------------
  // FIRST BOOT
  // --------------------------------------------------
  Future<void> _initFlow() async {
    try {
      print("🟣 Dashboard INIT START");

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("❌ No Firebase User");
        return;
      }

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
