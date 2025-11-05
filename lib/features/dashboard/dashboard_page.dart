import 'package:flutter/material.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';

// 🔹 Import actual feature pages
import '../astrology/astrology_page.dart';
import '../reports/reports_page.dart';
import '../profile/profile_page.dart';
import 'dashboard_home_section.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  // ✅ Organized page list (Home → Astrology → Reports → AskNow → Profile)
  final List<Widget> _pages = const [
    DashboardHomeSection(),
    AstrologyPage(),
    ReportsPage(),
    _AskNowPlaceholder(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // 🔹 Page content
      body: _pages[_currentIndex],

      // 🔹 Bottom Navigation Bar (Theme-based)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),

        // ✅ Colors now from theme
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
            icon: Icon(Icons.chat_bubble_outline),
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
    );
  }
}

// 🔸 Temporary AskNow Placeholder (kept minimal and themed)
class _AskNowPlaceholder extends StatelessWidget {
  const _AskNowPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "💬 Ask Now Chat Coming Soon",
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
