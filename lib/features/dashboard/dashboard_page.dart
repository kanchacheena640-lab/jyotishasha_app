import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/state/firebase_kundali_provider.dart';
import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/panchang_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

import 'package:jyotishasha_app/core/ads/banner_ad_widget.dart';

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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _loadAndRefreshAll();
      await _printAndSaveFcmToken();
    } catch (e) {
      debugPrint("Dashboard init error: $e");
    }
  }

  // ------------------------------------------------------------
  // LOAD DATA
  // ------------------------------------------------------------
  Future<void> _loadAndRefreshAll() async {
    final kundaliProvider = context.read<FirebaseKundaliProvider>();
    final lang = context.read<LanguageProvider>().currentLang;

    await kundaliProvider.loadFromFirebaseProfile(context, lang: lang);

    final kd = kundaliProvider.kundaliData;
    if (kd == null) return;

    final sign = (kd["rashi"] ?? kd["lagna_sign"] ?? "aries")
        .toString()
        .toLowerCase();

    final lat = kd["location"]?["lat"] ?? 26.8467;
    final lng = kd["location"]?["lng"] ?? 80.9462;

    await context.read<DailyProvider>().fetchDaily(sign: sign, lang: lang);

    await context.read<PanchangProvider>().fetchPanchang(
      lat: lat,
      lng: lng,
      lang: lang,
    );
  }

  // ------------------------------------------------------------
  // FCM TOKEN SAVE
  // ------------------------------------------------------------
  Future<void> _printAndSaveFcmToken() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection("users").doc(user.uid).update(
        {"fcm_token": token, "fcm_updated_at": FieldValue.serverTimestamp()},
      );

      await _sendFcmToBackend(token);
    } catch (e) {
      debugPrint("FCM ERROR: $e");
    }
  }

  Future<void> _sendFcmToBackend(String token) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final jwtToken = await firebaseUser?.getIdToken();

      if (jwtToken == null) return;

      await http.post(
        Uri.parse(
          "https://jyotishasha-backend.onrender.com/api/users/update-fcm",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwtToken",
        },
        body: jsonEncode({"fcm_token": token}),
      );
    } catch (e) {
      debugPrint("Backend FCM error: $e");
    }
  }

  // ------------------------------------------------------------
  // PAGES
  // ------------------------------------------------------------
  final List<Widget> _pages = const [
    DashboardHomeSection(),
    AstrologyPage(),
    ReportCatalogPage(),
    AskNowChatPage(),
    ProfilePage(),
  ];

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

                // ⭐ KEY FIX prevents widget rebuild crash
                child: KeyedSubtree(
                  key: ValueKey(_currentIndex),
                  child: _pages[_currentIndex],
                ),
              ),
            ),

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
