import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/dashboard_card.dart';
import 'package:jyotishasha_app/app/services/daily_horoscope_service.dart';
import 'package:jyotishasha_app/app/features/horoscope/pages/daily_horoscope_page.dart';
import 'package:jyotishasha_app/app/routes/app_routes.dart'; // 🆕 for Kundali navigation

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _user;
  int _selectedIndex = 0; // 🆕 for bottom nav control

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists) {
      setState(() => _user = doc.data());
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  bool _isTrialActive(Map<String, dynamic> user) {
    if (user['trial_end_at'] == null) return false;
    final end = (user['trial_end_at'] as Timestamp).toDate();
    return DateTime.now().isBefore(end);
  }

  bool _isSubscribed(Map<String, dynamic> user) {
    return user['is_subscribed'] == true;
  }

  // 🧭 Handle bottom navigation actions
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 2) {
      // Kundali tab
      Navigator.pushNamed(context, AppRoutes.tools);
    }
    // You can extend for other tabs later (Dashboard, Horoscope, etc.)
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = _user!['name'] ?? 'User';
    final greeting = _getGreeting();
    final trialActive = _isTrialActive(_user!);
    final subscribed = _isSubscribed(_user!);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $name 👋',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  DashboardCard(
                    title: 'Daily Horoscope',
                    icon: Icons.wb_sunny_outlined,
                    unlocked: trialActive || subscribed,
                    onTap: () async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) return;

                      final service = DailyHoroscopeService();
                      final data = await service.fetchDailyHoroscope(uid);

                      if (!context.mounted) return;
                      if (data != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DailyHoroscopePage(horoscopeData: data),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Failed to load horoscope. Please try again.",
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  DashboardCard(
                    title: 'Weekly Horoscope',
                    icon: Icons.calendar_today,
                    unlocked: subscribed,
                  ),
                  DashboardCard(
                    title: 'Panchang & Updates',
                    icon: Icons.brightness_5_outlined,
                    unlocked: true,
                  ),
                  DashboardCard(
                    title: 'Ask Now',
                    icon: Icons.chat_bubble_outline,
                    unlocked: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // 🪐 Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_sunny_outlined),
            label: 'Horoscope',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Kundali',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
