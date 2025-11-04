import 'package:flutter/material.dart';

// 🔹 Import actual pages
import '../astrology/astrology_page.dart';
import '../reports/reports_page.dart';
import '../profile/profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  // ✅ Real pages list (Panchang removed)
  final List<Widget> _pages = const [
    _DashboardHomePlaceholder(), // Dashboard home
    AstrologyPage(), // Astrology tools tab
    ReportsPage(), // Reports tab
    _AskNowPlaceholder(), // Ask Now
    ProfilePage(), // Profile tab
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FB),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: "Astrology"),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: "Reports",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Ask Now"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// 🔸 temporary placeholder for Dashboard
class _DashboardHomePlaceholder extends StatelessWidget {
  const _DashboardHomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "🏠 Dashboard Home (Cards will load here soon)",
        style: TextStyle(
          fontSize: 20,
          color: Colors.deepPurple,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// 🔸 temporary placeholder for AskNow
class _AskNowPlaceholder extends StatelessWidget {
  const _AskNowPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "💬 Ask Now Chat Coming Soon",
        style: TextStyle(
          fontSize: 20,
          color: Colors.deepPurple,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
