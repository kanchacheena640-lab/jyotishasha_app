import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/state/kundali_provider.dart';
import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/panchang_provider.dart';

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

    Future.microtask(() async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final firestore = FirebaseFirestore.instance;

        // STEP 1 → Get active profile ID
        final userDoc = await firestore.collection('users').doc(user.uid).get();
        final activeProfileId = userDoc.data()?['activeProfileId'];
        if (activeProfileId == null) return;

        // STEP 2 → Load profile snapshot
        final profileSnap = await firestore
            .collection('users')
            .doc(user.uid)
            .collection('profiles')
            .doc(activeProfileId)
            .get();

        if (!profileSnap.exists) return;

        final kundaliProvider = Provider.of<KundaliProvider>(
          context,
          listen: false,
        );

        // -----------------------------------------------------
        // 1️⃣ Load Full Kundali (Active Profile)
        // -----------------------------------------------------
        await kundaliProvider.loadFromActiveProfile();

        final kd = kundaliProvider.kundaliData;
        if (kd == null) return;

        // Extract lang
        final fullLang = kd['language']?.toString() ?? 'en';
        final lang = fullLang.length >= 2 ? fullLang.substring(0, 2) : 'en';

        // Extract Lat/Lng safely
        final lat = kd['location']?['lat'] ?? kd['lat'] ?? 26.8467;

        final lng = kd['location']?['lng'] ?? kd['lng'] ?? 80.9462;

        // -----------------------------------------------------
        // 2️⃣ Personalized Daily Horoscope
        // -----------------------------------------------------
        final dailyProvider = Provider.of<DailyProvider>(
          context,
          listen: false,
        );

        await dailyProvider.fetchDaily(
          lagna: kd['lagna_sign'] ?? '',
          lat: lat,
          lon: lng,
          lang: lang,
        );

        // -----------------------------------------------------
        // 3️⃣ Panchang (Abhijit / Rahukaal)
        // -----------------------------------------------------
        final panchangProvider = Provider.of<PanchangProvider>(
          context,
          listen: false,
        );

        await panchangProvider.fetchPanchang(
          date: DateTime.now(),
          lat: lat,
          lng: lng,
        );
      } catch (e) {
        debugPrint("Dashboard init error: $e");
      }
    });
  }

  final List<Widget> _pages = const [
    DashboardHomeSection(),
    AstrologyPage(),
    ReportCatalogPage(),
    AskNowChatPage(),
    ProfilePage(),
  ];

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

    await Future.delayed(const Duration(milliseconds: 150));
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
          unselectedItemColor: AppColors.textPrimary.withValues(alpha: 0.5),
          backgroundColor: AppColors.surface,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w400,
          ),
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

class _AskNowIcon extends StatelessWidget {
  const _AskNowIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
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
