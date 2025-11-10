import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/features/tools/tool_result_page.dart';
import 'package:provider/provider.dart';
import 'package:jyotishasha_app/core/state/kundali_provider.dart';

/// 🔮 Astrology Tools (Category-wise)
class AstrologyPage extends StatelessWidget {
  const AstrologyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Map<String, List<Map<String, dynamic>>> categorizedTools = {
      "🔮 Basic Tools": [
        {"name": "Free Kundali", "icon": Icons.self_improvement},
        {"name": "Rashi Finder", "icon": Icons.star_border_purple500_outlined},
        {"name": "Lagna Finder", "icon": Icons.wb_sunny_outlined},
        {"name": "Grah Dasha Finder", "icon": Icons.brightness_6_outlined},
        {"name": "Gemstone Suggestion", "icon": Icons.diamond_outlined},
      ],
      "⚡ Dosha Tools": [
        {"name": "Mangal Dosh", "icon": Icons.whatshot_outlined},
        {"name": "Kaalsarp Dosh", "icon": Icons.coronavirus_outlined},
        {"name": "Sadhesati Calculator", "icon": Icons.timelapse_outlined},
        {"name": "Pitra Dosh", "icon": Icons.family_restroom_outlined},
        {"name": "Nadi Dosh", "icon": Icons.favorite_outline},
        {"name": "Grahan Dosh", "icon": Icons.dark_mode_outlined},
        {"name": "Guru Chandal Dosh", "icon": Icons.waves_outlined},
      ],
      "👑 Yog Tools": [
        {"name": "Parashari Rajyog", "icon": Icons.auto_graph_outlined},
        {"name": "Neechbhang Rajyog", "icon": Icons.trending_up_outlined},
        {"name": "Gajakesari Yog", "icon": Icons.emoji_events_outlined},
        {"name": "Chandra Mangal Rajyog", "icon": Icons.brightness_5_outlined},
        {
          "name": "Panch Mahapurush Yog",
          "icon": Icons.workspace_premium_outlined,
        },
        {"name": "Dhan Yog", "icon": Icons.currency_rupee_outlined},
        {"name": "Vipreet Rajyog", "icon": Icons.change_circle_outlined},
        {"name": "Lakshmi Yog", "icon": Icons.spa_outlined},
        {"name": "Budh Aditya Yog", "icon": Icons.lightbulb_outline},
        {"name": "Adhi Rajyog", "icon": Icons.bar_chart_outlined},
        {"name": "Kendra Trikon Rajyog", "icon": Icons.insights_outlined},
        {"name": "Raja Sambandha Yog", "icon": Icons.group_outlined},
      ],
      "💼 Life Path Tools": [
        {"name": "Career Path", "icon": Icons.work_outline_outlined},
        {"name": "Marriage Path", "icon": Icons.favorite_outline},
        {"name": "Foreign Travel", "icon": Icons.flight_takeoff_outlined},
        {"name": "Business Path", "icon": Icons.business_outlined},
        {"name": "Government Job", "icon": Icons.account_balance_outlined},
        {"name": "Love Life", "icon": Icons.heart_broken_outlined},
      ],
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Astrology Tools"),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFreeBirthChartCard(context, theme),
            const SizedBox(height: 20),

            // 🔮 Section-wise Tools
            ...categorizedTools.entries.map((entry) {
              final category = entry.key;
              final tools = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    category,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: category.contains("Dosha")
                          ? Colors.redAccent
                          : Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tools.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                    itemBuilder: (context, index) {
                      final tool = tools[index];
                      return _buildToolCard(
                        context,
                        tool["icon"],
                        tool["name"],
                      );
                    },
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 🪔 Free Birth Chart Section
  Widget _buildFreeBirthChartCard(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFFBBF24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "🪔 Generate Your Free Birth Chart",
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            "Get your personalized Kundali with Lagna, Rashi, and Dasha insights.",
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: Colors.white70,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () async {
              final provider = Provider.of<KundaliProvider>(
                context,
                listen: false,
              );

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final kundaliData = await provider.fetchKundali(
                name: "Ravi Om Joshi",
                dob: "31-03-1985",
                tob: "19:45",
                pob: "Lucknow, India",
              );

              if (context.mounted) Navigator.pop(context);

              if (kundaliData != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ToolResultPage(
                      toolId: "free-kundali",
                      formData: kundaliData,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to load Kundali data")),
                );
              }
            },
            icon: const Icon(Icons.self_improvement),
            label: const Text("Generate Now"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🌟 Tool Card
  Widget _buildToolCard(BuildContext context, IconData icon, String name) {
    // 🕓 Tools not yet launched
    final comingSoonTools = [
      "Pitra Dosh",
      "Nadi Dosh",
      "Grahan Dosh",
      "Guru Chandal Dosh",
    ];

    final isComingSoon = comingSoonTools.contains(name);

    return GestureDetector(
      onTap: () {
        if (isComingSoon) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Coming Soon!")));
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ToolResultPage(
              toolId: name.toLowerCase().replaceAll(' ', '-'),
              formData: {
                "name": "Ravi Om Joshi",
                "dob": "31-03-1985",
                "tob": "07:45 PM",
                "pob": "Lucknow, India",
              },
            ),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF3E5F5), Color(0xFFEDE7F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(2, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 34, color: Colors.deepPurple),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🔖 "Coming Soon" label overlay
          if (isComingSoon)
            Positioned(
              bottom: 6,
              child: Text(
                "Coming Soon",
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
