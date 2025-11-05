import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/widgets/greeting_header_widget.dart';
import 'package:jyotishasha_app/core/widgets/horoscope_card_widget.dart';
import 'package:jyotishasha_app/core/widgets/shubh_muhurth_preview_widget.dart';

/// 🌟 Dashboard Home (Theme-based, Light & Professional)
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
              // 🟣 Greeting Header
              const GreetingHeaderWidget(
                userName: "Suvi",
                zodiacSign: "♑ Capricorn",
                sunriseTime: "06:27 AM",
                sunsetTime: "05:43 PM",
              ),
              const SizedBox(height: 16),

              // 🪔 Panchang Card
              _buildPanchangCard(context),
              const SizedBox(height: 24),

              // 🌙 Horoscope Section
              _buildHoroscopeSection(context),
              const SizedBox(height: 28),

              // 🌸 Shubh Muhurth Section (clean and unified)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ShubhMuhurthPreviewWidget(
                  muhurthList: [
                    {
                      "date": "Nov 5",
                      "event": "🏠 Griha Pravesh",
                      "score": "9",
                    },
                    {"date": "Nov 8", "event": "💍 Marriage", "score": "8"},
                    {
                      "date": "Nov 12",
                      "event": "🚗 Vehicle Purchase",
                      "score": "8",
                    },
                    {"date": "Nov 15", "event": "👶 Naamkaran", "score": "7"},
                  ],
                  onSeeMore: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Full Muhurth Coming Soon")),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // 🔮 Free Kundali Banner
              _buildFreeKundaliBanner(context),
              const SizedBox(height: 32),

              // 🧭 Tools Section
              _buildAstrologyToolsSection(context),
              const SizedBox(height: 32),

              // 📰 Blog Section
              _buildBlogSection(context),
            ],
          ),
        ),
      ),
    );
  }

  // 🕉️ Panchang Card
  Widget _buildPanchangCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
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
            "Auspicious time: 9:00 AM – 1:00 PM, avoid: 2:00 PM – 4:00 PM.",
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // 🌙 Horoscope Section
  Widget _buildHoroscopeSection(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today card
          const HoroscopeCardWidget(
            title: "Today",
            summary:
                "The Moon in your sign boosts emotions and intuition. Trust your instincts today.",
            luckyColor: "Lavender",
            luckyNumber: "7",
          ),

          const SizedBox(height: 12),

          // 👉 Buttons row: Tomorrow + Weekly
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: navigate to /horoscope?type=tomorrow (later)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Tomorrow horoscope coming soon"),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: const Text("Tomorrow"),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.3),
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
                  onPressed: () {
                    // TODO: navigate to /horoscope?type=weekly (later)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Weekly horoscope coming soon"),
                      ),
                    );
                  },
                  icon: const Icon(Icons.view_week),
                  label: const Text("Weekly"),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.3),
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

  // 🔮 Free Kundali Banner
  Widget _buildFreeKundaliBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.purpleGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 3)),
        ],
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
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person),
                  label: const Text("For Me"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.group),
                  label: const Text("For Others"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🧭 Astrology Tools Section
  Widget _buildAstrologyToolsSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Astrology Tools",
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Explore free astrology tools for daily insights and calculations.",
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1,
            children: [
              _toolCard(context, Icons.self_improvement, "Free Kundali"),
              _toolCard(context, Icons.wb_sunny_outlined, "Lagna Finder"),
              _toolCard(context, Icons.star_outline, "Rashi Finder"),
              _toolCard(context, Icons.favorite_outline, "Love Match"),
              _toolCard(context, Icons.auto_graph, "Rajyog Check"),
              _toolCard(context, Icons.health_and_safety, "Health Insight"),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.apps),
              label: const Text("More Tools"),
            ),
          ),
        ],
      ),
    );
  }

  // 🧩 Tool Card
  Widget _toolCard(BuildContext context, IconData icon, String title) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("$title Coming Soon"))),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📰 Blog Section
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

  // 🧩 Blog Card
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
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
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
