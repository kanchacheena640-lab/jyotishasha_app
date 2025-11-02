import 'package:flutter/material.dart';
import '../widgets/tool_card.dart';
import 'tool_loader_page.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  // NOTE: abhi ke liye inline data; baad me separate data file bana denge.
  List<Map<String, dynamic>> get _tools => const [
    {
      "title": "Rashi Finder",
      "slug": "rashi-finder",
      "icon": Icons.auto_awesome,
      "desc": "Find your Moon sign using DOB, TOB & place.",
    },
    {
      "title": "Lagna Finder",
      "slug": "lagna-finder",
      "icon": Icons.explore,
      "desc": "Know your Ascendant sign and its influence.",
    },
    {
      "title": "Grah Dasha Finder",
      "slug": "grah-dasha-finder",
      "icon": Icons.timelapse,
      "desc": "See your Mahadasha & Antardasha timeline.",
    },
    {
      "title": "Sade Sati Check",
      "slug": "sade-sati-check",
      "icon": Icons.shield_moon_outlined,
      "desc": "Check Saturn’s Sade Sati & impact.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2FF),
      appBar: AppBar(
        title: const Text("Astrology Tools"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: GridView.builder(
          itemCount: _tools.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.90,
          ),
          itemBuilder: (context, i) {
            final t = _tools[i];
            return ToolCard(
              title: t["title"],
              description: t["desc"],
              icon: t["icon"],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ToolLoaderPage(
                      toolTitle: t['title'],
                      toolSlug: t['slug'],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
