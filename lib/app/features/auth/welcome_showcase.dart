import 'package:flutter/material.dart';
import 'package:jyotishasha_app/app/routes/app_routes.dart';

/// 🌅 Welcome Showcase
/// 3 onboarding slides explaining app features.
/// Last slide has "Start Free Trial" button → navigates to Dashboard.
class WelcomeShowcase extends StatefulWidget {
  const WelcomeShowcase({super.key});

  @override
  State<WelcomeShowcase> createState() => _WelcomeShowcaseState();
}

class _WelcomeShowcaseState extends State<WelcomeShowcase> {
  final PageController _pageController = PageController();
  int currentIndex = 0;

  /// Slide data (can be moved to JSON later)
  final List<Map<String, String>> pages = [
    {
      'title': 'Personalized Astrology',
      'desc': 'Every prediction crafted uniquely from your birth chart.',
      'image': 'https://cdn-icons-png.flaticon.com/512/7906/7906761.png',
    },
    {
      'title': 'Daily & Weekly Insights',
      'desc': 'Track your mood, energy, and luck everyday.',
      'image': 'https://cdn-icons-png.flaticon.com/512/5172/5172435.png',
    },
    {
      'title': '15-Day Free Premium Access',
      'desc': 'Unlock personalized horoscope & kundali insights.',
      'image': 'https://cdn-icons-png.flaticon.com/512/868/868786.png',
    },
  ];

  void _nextPage() {
    if (currentIndex < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // 🔮 Go to Dashboard
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => currentIndex = index);
                },
                itemBuilder: (_, index) {
                  final item = pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(item['image']!, height: 220),
                        const SizedBox(height: 40),
                        Text(
                          item['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          item['desc']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 🔘 Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: currentIndex == index ? 12 : 8,
                  height: currentIndex == index ? 12 : 8,
                  decoration: BoxDecoration(
                    color: currentIndex == index
                        ? Colors.deepPurple
                        : Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 🟣 Next / Get Started Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _nextPage,
                child: Text(
                  currentIndex == pages.length - 1
                      ? 'Start Free Premium →'
                      : 'Next →',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
