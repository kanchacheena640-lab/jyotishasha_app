import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/state/firebase_kundali_provider.dart';
import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/panchang_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

import 'package:jyotishasha_app/core/ads/banner_ad_widget.dart';

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
  bool _profileListenerAttached = false;
  bool _languageListenerAttached = false;

  String? _lastActiveId;
  String? _lastLang;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized) {
        _initialized = true;

        context.read<ProfileProvider>().loadProfiles();

        _initFlow();
      }

      _attachProfileSwitchListener();
      _attachLanguageListener();
    });
  }

  // ------------------------------------------------------------
  // GET backend_user_id SAFELY
  // ------------------------------------------------------------
  Future<int?> _getBackendUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    return doc.data()?["backend_user_id"];
  }

  // ------------------------------------------------------------
  // PROFILE SWITCH LISTENER
  // ------------------------------------------------------------
  void _attachProfileSwitchListener() {
    if (_profileListenerAttached) return;
    _profileListenerAttached = true;

    final profileProvider = context.read<ProfileProvider>();

    profileProvider.addListener(() async {
      if (!mounted) return;

      final newId = profileProvider.activeProfileId;

      if (newId != null && newId != _lastActiveId) {
        _lastActiveId = newId;
        await _loadAndRefreshAll();
      }
    });
  }

  // ------------------------------------------------------------
  // LANGUAGE CHANGE LISTENER
  // ------------------------------------------------------------
  void _attachLanguageListener() {
    if (_languageListenerAttached) return;
    _languageListenerAttached = true;

    final langProvider = context.read<LanguageProvider>();

    langProvider.addListener(() async {
      if (!mounted) return;

      final newLang = langProvider.currentLang;

      if (newLang != _lastLang) {
        _lastLang = newLang;

        print("🌐 LANG CHANGE → Refreshing Kundali + Daily + Panchang");

        final kundaliProvider = context.read<FirebaseKundaliProvider>();
        final profileProvider = context.read<ProfileProvider>();

        await kundaliProvider.loadFromFirebaseProfile(context, lang: newLang);

        final kd = kundaliProvider.kundaliData;
        if (kd == null) return;

        final lagna = kd["lagna_sign"] ?? "";
        final lat = kd["location"]?["lat"] ?? 26.8467;
        final lng = kd["location"]?["lng"] ?? 80.9462;

        final backendUserId = await _getBackendUserId();
        final backendProfileId =
            profileProvider.activeProfile?["backend_profile_id"];

        await context.read<DailyProvider>().fetchDaily(
          lagna: lagna,
          lat: lat,
          lon: lng,
          lang: newLang,
          backendUserId: backendUserId,
          backendProfileId: backendProfileId,
        );

        await context.read<PanchangProvider>().fetchPanchang(
          lat: lat,
          lng: lng,
          lang: newLang,
        );

        print("🌐 LANG REFRESH DONE");
      }
    });
  }

  // ------------------------------------------------------------
  // FULL REFRESH
  // ------------------------------------------------------------
  Future<void> _loadAndRefreshAll() async {
    final kundaliProvider = context.read<FirebaseKundaliProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final lang = context.read<LanguageProvider>().currentLang;

    await kundaliProvider.loadFromFirebaseProfile(context, lang: lang);

    final kd = kundaliProvider.kundaliData;
    if (kd == null) return;

    final lagna = kd["lagna_sign"] ?? "";
    final lat = kd["location"]?["lat"] ?? 26.8467;
    final lng = kd["location"]?["lng"] ?? 80.9462;

    final backendUserId = await _getBackendUserId();
    final backendProfileId =
        profileProvider.activeProfile?["backend_profile_id"];

    await context.read<DailyProvider>().fetchDaily(
      lagna: lagna,
      lat: lat,
      lon: lng,
      lang: lang,
      backendUserId: backendUserId,
      backendProfileId: backendProfileId,
    );

    await context.read<PanchangProvider>().fetchPanchang(
      lat: lat,
      lng: lng,
      lang: lang,
    );
  }

  // ------------------------------------------------------------
  // FIRST INIT
  // ------------------------------------------------------------
  Future<void> _initFlow() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _loadAndRefreshAll();
    } catch (_) {}
  }

  final List<Widget> _pages = const [
    DashboardHomeSection(),
    AstrologyPage(),
    ReportCatalogPage(),
    AskNowChatPage(),
    ProfilePage(),
  ];

  // ------------------------------------------------------------
  // DOUBLE BACK EXIT
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

        body: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _pages[_currentIndex],
              ),
            ),

            // ⭐ Show ads only on tabs 0, 2, 4
            if (_currentIndex == 0) const BannerAdWidget(),
          ],
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
