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

  // SAFE LISTENERS
  bool _profileListenerAttached = false;
  bool _languageListenerAttached = false;

  // LAST KNOWN VALUES
  String? _lastActiveId;
  String? _lastLang;

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
      _attachLanguageListener();
    });
  }

  // ------------------------------------------------------------------
  // PROFILE SWITCH LISTENER (SAFE)
  // ------------------------------------------------------------------
  void _attachProfileSwitchListener() {
    if (_profileListenerAttached) return;
    _profileListenerAttached = true;

    final profileProvider = context.read<ProfileProvider>();

    profileProvider.addListener(() async {
      if (!mounted) return;
      final newId = profileProvider.activeProfileId;

      if (newId != null && newId != _lastActiveId) {
        print("👤 PROFILE SWITCH DETECTED → Reload all");
        _lastActiveId = newId;
        await _loadAndRefreshAll(); // safe, single call
      }
    });
  }

  // ------------------------------------------------------------------
  // LANGUAGE CHANGE LISTENER (SAFE)
  // ------------------------------------------------------------------
  void _attachLanguageListener() {
    if (_languageListenerAttached) return;
    _languageListenerAttached = true;

    final langProvider = context.read<LanguageProvider>();

    langProvider.addListener(() async {
      if (!mounted) return;

      final newLang = langProvider.currentLang;

      if (newLang != _lastLang) {
        print("🌐 LANGUAGE CHANGE DETECTED → Reload all");
        _lastLang = newLang;

        await _loadAndRefreshAll(); // safe, single call
      }
    });
  }

  // ------------------------------------------------------------------
  // MASTER REFRESH FUNCTION (SAFE, SEQUENTIAL)
  // ------------------------------------------------------------------
  Future<void> _loadAndRefreshAll() async {
    print("⚡ DASHBOARD → START REFRESH");

    final kundaliProvider = context.read<FirebaseKundaliProvider>();
    final lang = context.read<LanguageProvider>().currentLang;

    // LOAD KUNDALI
    await kundaliProvider.loadFromFirebaseProfile(context, lang: lang);

    final kd = kundaliProvider.kundaliData;
    if (kd == null) {
      print("❌ kundaliData NULL → Skip refresh");
      return;
    }

    final lagna = kd["lagna_sign"] ?? "";
    final lat = kd["location"]?["lat"] ?? 26.8467;
    final lng = kd["location"]?["lng"] ?? 80.9462;

    print("➡ DAILY API CALL → lagna=$lagna lang=$lang");

    // REFRESH DAILY
    await context.read<DailyProvider>().fetchDaily(
      lagna: lagna,
      lat: lat,
      lon: lng,
      lang: lang,
    );

    print("➡ PANCHANG API CALL");
    await context.read<PanchangProvider>().fetchPanchang(
      lat: lat,
      lng: lng,
      lang: lang,
    );

    print("✅ DASHBOARD → REFRESH COMPLETE\n");
  }

  // ------------------------------------------------------------------
  // FIRST TIME BOOT
  // ------------------------------------------------------------------
  Future<void> _initFlow() async {
    try {
      print("🟣 INIT START");

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("❌ No Firebase User");
        return;
      }

      await _loadAndRefreshAll();
      print("🏁 INIT DONE");
    } catch (e) {
      print("❌ INIT ERROR: $e");
    }
  }

  final List<Widget> _pages = const [
    DashboardHomeSection(),
    AstrologyPage(),
    ReportCatalogPage(),
    AskNowChatPage(),
    ProfilePage(),
  ];

  // ------------------------------------------------------------------
  // DOUBLE BACK TO EXIT
  // ------------------------------------------------------------------
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
        if (!didPop) _handleBackPress();
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
              icon: const Icon(Icons.chat_bubble_outline),
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
