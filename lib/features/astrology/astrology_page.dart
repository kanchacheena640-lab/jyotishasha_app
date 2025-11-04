import 'package:flutter/material.dart';

class AstrologyPage extends StatelessWidget {
  const AstrologyPage({super.key});

  // temporary dummy tools
  final List<Map<String, dynamic>> tools = const [
    {"icon": Icons.self_improvement, "name": "Free Kundali"},
    {"icon": Icons.wb_sunny_outlined, "name": "Lagna Finder"},
    {"icon": Icons.star_border_purple500_outlined, "name": "Rashi Finder"},
    {"icon": Icons.favorite_border, "name": "Love Compatibility"},
    {"icon": Icons.auto_graph_outlined, "name": "Rajyog Check"},
    {"icon": Icons.whatshot_outlined, "name": "Mangal Dosh"},
    {"icon": Icons.health_and_safety_outlined, "name": "Health Astrology"},
    {"icon": Icons.monetization_on_outlined, "name": "Wealth Potential"},
    {"icon": Icons.flight_takeoff_outlined, "name": "Foreign Travel"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Astrology Tools"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: tools.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final tool = tools[index];
            return _buildToolCard(context, tool["icon"], tool["name"]);
          },
        ),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, IconData icon, String name) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Opening $name... (coming soon)")),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF3E5F5), Color(0xFFEDE7F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.1), // ✅ fixed
              blurRadius: 5,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 38, color: Colors.deepPurple),
            const SizedBox(height: 10),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
