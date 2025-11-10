import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/widgets/greeting_header_widget.dart';
import 'package:jyotishasha_app/core/widgets/horoscope_card_widget.dart';
import 'package:jyotishasha_app/core/widgets/shubh_muhurth_preview_widget.dart';
import 'package:jyotishasha_app/core/widgets/app_footer_feedback_widget.dart';
import 'package:jyotishasha_app/features/panchang/panchang_page.dart';
import 'package:jyotishasha_app/features/horoscope/horoscope_page.dart';
import 'package:jyotishasha_app/features/muhurth/muhurth_page.dart';
import 'package:jyotishasha_app/features/kundali/kundali_detail_page.dart';
import 'package:jyotishasha_app/features/kundali/kundali_form_page.dart';
import 'package:jyotishasha_app/features/tools/tool_result_page.dart';
import 'package:jyotishasha_app/core/widgets/panchang_card_widget.dart';
import 'package:go_router/go_router.dart';

/// 🌟 Dashboard Home (Light, Elegant & Unified)
class DashboardHomeSection extends StatelessWidget {
  const DashboardHomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GreetingHeaderWidget(),
              const SizedBox(height: 16),

              // 🌞 Darshan Button (Gradient Background + Full Width)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () {
                    context.push('/darshan');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFFBBF24)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.self_improvement_outlined,
                          size: 22,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Today's Lord : Darshan & Mantra",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const PanchangCardWidget(),
              const SizedBox(height: 16),

              _buildHoroscopeSection(context),
              const SizedBox(height: 28),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ShubhMuhurthPreviewWidget(
                  muhurthList: [
                    {"date": "Nov 5", "event": "Griha Pravesh", "score": "9"},
                    {"date": "Nov 8", "event": "Marriage", "score": "8"},
                    {
                      "date": "Nov 12",
                      "event": "🚗 Vehicle Purchase",
                      "score": "8",
                    },
                    {"date": "Nov 15", "event": "Naamkaran", "score": "7"},
                  ],
                  onSeeMore: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MuhurthPage()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              _buildFreeKundaliBanner(context),
              const SizedBox(height: 32),

              _buildAstrologyToolsSection(context),
              const SizedBox(height: 32),

              _buildBlogSection(context),
              const SizedBox(height: 24),

              AppFooterFeedbackWidget(),
            ],
          ),
        ),
      ),
    );
  }

  // 🕉️ Panchang Card ----------------------------------------------------------
  Widget _buildPanchangCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🕉️ श्री गणेशाय नमः",
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Today is Dwitiya Tithi and Nakshatra is Rohini. "
            "Auspicious time 9:00 AM – 1:00 PM • Avoid 2:00 PM – 4:00 PM.",
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PanchangPage()),
                );
              },
              child: Text(
                "View Full Panchang →",
                style: GoogleFonts.montserrat(
                  fontSize: 13.5,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🌙 Horoscope Section -------------------------------------------------------
  Widget _buildHoroscopeSection(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HoroscopeCardWidget(
            title: "Today",
            summary:
                "The Moon in your sign boosts emotions and intuition. Trust your instincts today.",
            luckyColor: "Lavender",
            luckyNumber: "7",
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HoroscopePage()),
                  ),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text("Tomorrow"),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(.3),
                    ),
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HoroscopePage()),
                  ),
                  icon: const Icon(Icons.view_week),
                  label: const Text("Weekly"),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(.3),
                    ),
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔮 Free Kundali Banner -----------------------------------------------------
  Widget _buildFreeKundaliBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.purpleGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Get Your Free Kundali Now",
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Personalized birth chart with insights for you and your loved ones.",
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // For Me → Static Demo
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final kundaliData = {
                      "profile": {
                        "name": "Suvi Vish",
                        "dob": "1997-08-14",
                        "tob": "10:15",
                        "place": "Lucknow, India",
                      },
                      "lagna_sign": "Libra",
                      "rashi": "Aquarius",
                      "lagna_trait":
                          "You are balanced, creative and diplomatic in relationships.",
                      "dasha_summary": {
                        "current_block": {
                          "mahadasha": "Venus",
                          "antardasha": "Mercury",
                          "period": "2023–2026",
                        },
                      },
                      "gemstone_suggestion": {
                        "gemstone": "Diamond",
                        "paragraph":
                            "Diamond enhances Venus energy, bringing harmony and beauty.",
                      },
                      "yogas": {
                        "Gajakesari": {"is_active": true, "strength": "Strong"},
                      },
                    };
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            KundaliDetailPage(kundaliData: kundaliData),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_outline),
                  label: const Text(
                    "For Me",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // For Others → Form
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KundaliFormPage()),
                  ),
                  icon: const Icon(Icons.group_outlined),
                  label: const Text(
                    "For Others",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🧭 Astrology Tools Section -------------------------------------------------
  Widget _buildAstrologyToolsSection(BuildContext context) {
    final theme = Theme.of(context);

    // Map tool titles to their backend IDs
    final Map<String, String> toolMap = {
      "Lagna Finder": "lagna_finder",
      "Rashi Finder": "rashi_finder",
      "Gemstone Suggestion": "gemstone_suggestion",
      "Love Match": "love-match",
      "Rajyog Check": "rajya_sambandh_rajyog",
      "Health Insight": "health_insight",
    };

    // Default sample form data (later replace with user input/profile)
    final Map<String, dynamic> defaultFormData = {
      "name": "Ravi",
      "dob": "1985-03-31",
      "tob": "19:45",
      "latitude": 26.8467,
      "longitude": 80.9462,
      "language": "hi",
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Astrology Studio",
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You don’t need an astrologer — understand your own Kundali like a pro.",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // 🔮 Tools Grid
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
              children: toolMap.entries.map((entry) {
                return _toolCard(context, _getIcon(entry.key), entry.key, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ToolResultPage(
                        toolId:
                            entry.value, // 🔮 Backend key (e.g. "lagna_finder")
                        formData:
                            defaultFormData, // 🪔 Birth details / user data
                      ),
                    ),
                  );
                });
              }).toList(),
            ),

            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("More tools coming soon...")),
                ),
                icon: const Icon(Icons.apps),
                label: const Text("More Tools"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🪔 Tool Card Widget
  Widget _toolCard(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF3E8FF), Color(0xFFEDE9FE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.deepPurple, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 Helper: Icon based on Tool
  IconData _getIcon(String title) {
    switch (title) {
      case "Free Kundali":
        return Icons.self_improvement;
      case "Lagna Finder":
        return Icons.wb_sunny_outlined;
      case "Rashi Finder":
        return Icons.star_outline;
      case "Love Match":
        return Icons.favorite_outline;
      case "Rajyog Check":
        return Icons.auto_graph;
      case "Health Insight":
        return Icons.health_and_safety;
      default:
        return Icons.api;
    }
  }

  // 📰 Blog Section ------------------------------------------------------------
  Widget _buildBlogSection(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Astrology Blog Highlights",
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Read the latest updates, tips and celestial insights.",
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _blogCard(
                  context,
                  "Full Moon in Aries — How it Affects You",
                  "Lunar Insights",
                  "https://images.unsplash.com/photo-1506744038136-46273834b3fb",
                ),
                _blogCard(
                  context,
                  "Mercury Retrograde Survival Guide",
                  "Planetary Tips",
                  "https://images.unsplash.com/photo-1523983306281-4b570fba04c4",
                ),
                _blogCard(
                  context,
                  "Top 5 Remedies for Rahu & Ketu",
                  "Astrology Remedies",
                  "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e",
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text("Explore Blog"),
            ),
          ),
        ],
      ),
    );
  }

  // 🧩 Blog Card ---------------------------------------------------------------
  Widget _blogCard(
    BuildContext context,
    String title,
    String tag,
    String imageUrl,
  ) {
    final theme = Theme.of(context);
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppColors.purpleGradient,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              imageUrl,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 100,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported, size: 40),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tag,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
