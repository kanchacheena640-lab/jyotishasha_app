import 'package:flutter/material.dart';
import 'package:jyotishasha_app/core/widgets/bottom_nav_bar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  // Dummy content for demonstration
  final List<Widget> _pages = const [
    Center(child: Text('Today’s Horoscope')),
    Center(child: Text('Your Panchang')),
    Center(child: Text('Astrology for You')),
    Center(child: Text('Reports & Profile')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Dashboard'),
      ),
      body: _pages[_selectedIndex],
      // ✅ Using BottomNavBar widget from core/widgets
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
