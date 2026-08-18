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
import 'package:jyotishasha_app/core/state/notification_provider.dart';

import '../asknow/asknow_chat_page.dart';
import '../reports/pages/report_catalog_page.dart';
import '../explore/explore_page.dart';
import '../profile/account_page.dart';
import 'dashboard_home_section.dart';
import 'dashboard_tab_switcher.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  DateTime? _lastPressed;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized) {
        _initialized = true;
        context.read<ProfileProvider>().loadProfiles();
        _initFlow();
      }
    });
  }

  // ------------------------------------------------------------
  // INIT FLOW
  // ------------------------------------------------------------
  Future<void> _initFlow() async {
    try {
      debugPrint("STEP A: initFlow start");

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("STEP B: user NULL");
        return;
      }

      debugPrint("STEP C: user मिला ${user.uid}");

      // 🔹 Core data load (blocking – required for UI)
      await _loadAndRefreshAll();
      debugPrint("STEP E: loadAndRefreshAll DONE");

      // 🔹 Notifications (delayed + safe)
      Future.delayed(const Duration(seconds: 2), () async {
        if (!mounted) return;

        try {
          await context.read<NotificationProvider>().loadUnreadCount();
          debugPrint("🔥 NOTIFICATION LOADED");
        } catch (e) {
          debugPrint("❌ Notification load failed: $e");
        }
      });
    } catch (e) {
      debugPrint("❌ Dashboard init error: $e");
    }
  }

  // ------------------------------------------------------------
  // LOAD DATA
  // ------------------------------------------------------------
  Future<void> _loadAndRefreshAll() async {
    debugPrint("STEP F: loadAll start");

    final kundaliProvider = context.read<FirebaseKundaliProvider>();
    final lang = context.read<LanguageProvider>().currentLang;

    await kundaliProvider.loadFromFirebaseProfile(context, lang: lang);
    debugPrint("STEP G: kundali loaded");

    final kd = kundaliProvider.kundaliData;
    if (kd == null) {
      debugPrint("STEP H: kundali NULL");
      return;
    }

    final sign = (kd["rashi"] ?? kd["lagna_sign"] ?? "aries")
        .toString()
        .toLowerCase();

    final lat = kd["location"]?["lat"] ?? 26.8467;
    final lng = kd["location"]?["lng"] ?? 80.9462;

    if (!mounted) return;
    await context.read<DailyProvider>().fetchDaily(sign: sign, lang: lang);
    debugPrint("STEP I: daily done");

    if (!mounted) return;
    await context.read<PanchangProvider>().fetchPanchang(
      lat: lat,
      lng: lng,
      lang: lang,
    );
    debugPrint("STEP J: panchang done");
  }

  // ------------------------------------------------------------
  // PAGES
  // ------------------------------------------------------------
  // Task 4 — index 1 ("Ask Now" in the bottom nav) is intentionally a
  // placeholder, never actually shown: AskNowChatPage is a full pushed
  // screen (own AppBar, own local chat state) — see _onBottomNavTap
  // below. Embedding it here would make AnimatedSwitcher/KeyedSubtree
  // dispose and rebuild it (and wipe its in-progress conversation) every
  // time the user switches to another tab and back, which a plain
  // Navigator.push avoids entirely, matching the same
  // Navigator.push(AskNowChatPage()) pattern TrendingQuestionsWidget on
  // Home already uses. Astrology/Kundali access no longer lives here at
  // all — see GreetingHeaderWidget's "Your Astrology Profile" CTA and
  // the "Create Another Kundali" entry points, both of which push
  // KundaliOverviewPage directly and are unaffected by this change.
  final List<Widget> _pages = const [
    DashboardHomeSection(),
    SizedBox.shrink(),
    ReportCatalogPage(),
    ExplorePage(),
    AccountPage(),
  ];

  // ------------------------------------------------------------
  // TAB SWITCH — single shared code path. DashboardTabSwitcher (exposed
  // to descendants via Provider below) calls this same method, so
  // switching tabs never pushes/replaces the navigation stack — Back
  // continues to work exactly as it already does for the bottom nav
  // (see _handleBackPress). Index 1 (Ask Now) never reaches this method
  // — see _onBottomNavTap, the bottom nav's own onTap.
  // ------------------------------------------------------------
  void _switchTab(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  // ------------------------------------------------------------
  // BOTTOM NAV TAP — Task 4. The only caller of BottomNavigationBar.onTap.
  // Every index except Ask Now behaves exactly as before (_switchTab).
  // Ask Now (index 1) is a plain pushed route, never an in-place tab
  // body swap — _currentIndex is left untouched, so the tab the user was
  // already on stays selected underneath, and popping Ask Now returns
  // them to exactly where they were, with that tab's state intact.
  // ------------------------------------------------------------
  void _onBottomNavTap(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AskNowChatPage()),
      );
      return;
    }
    _switchTab(index);
  }

  // ------------------------------------------------------------
  // BACK BUTTON
  // ------------------------------------------------------------
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

    SystemNavigator.pop();
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHindi = context.watch<LanguageProvider>().currentLang == 'hi';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBackPress();
      },
      // Exposes the same tab-switch method the bottom nav uses to any
      // descendant (e.g. Home's "View →" CTA) — see dashboard_tab_switcher.dart.
      child: Provider<DashboardTabSwitcher>.value(
        value: DashboardTabSwitcher(_switchTab),
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),

            // ⭐ KEY FIX prevents widget rebuild crash
            child: KeyedSubtree(
              key: ValueKey(_currentIndex),
              child: _pages[_currentIndex],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onBottomNavTap,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: AppColors.textPrimary.withValues(alpha: 0.5),
            backgroundColor: AppColors.surface,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home),
                label: AppLocalizations.of(context)!.dashboard_home,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.chat_bubble_outline),
                activeIcon: const Icon(Icons.chat),
                label: AppLocalizations.of(context)!.dashboard_ask_now,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.description_outlined),
                activeIcon: const Icon(Icons.description),
                label: AppLocalizations.of(context)!.dashboard_reports,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.explore_outlined),
                activeIcon: const Icon(Icons.explore),
                label: isHindi ? 'एक्सप्लोर' : 'Explore',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                label: isHindi ? 'अकाउंट' : 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
