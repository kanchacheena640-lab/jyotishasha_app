import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/features/manual_kundali/manual_kundali_form_page.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/widgets/greeting_header_widget.dart';
import 'package:jyotishasha_app/core/widgets/horoscope_card_widget.dart';
import 'package:jyotishasha_app/core/widgets/shubh_muhurth_preview_widget.dart';
import 'package:jyotishasha_app/core/widgets/app_footer_feedback_widget.dart';
import 'package:jyotishasha_app/features/panchang/panchang_page.dart';
import 'package:jyotishasha_app/features/horoscope/horoscope_page.dart';
import 'package:jyotishasha_app/features/muhurth/muhurth_page.dart';
import 'package:jyotishasha_app/features/tools/tool_result_page.dart';
import 'package:jyotishasha_app/core/widgets/panchang_card_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:jyotishasha_app/features/astrology/astrology_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:jyotishasha_app/core/state/daily_provider.dart';

/// 🌟 Dashboard Home (Light, Elegant & Unified)
class DashboardHomeSection extends StatelessWidget {
  const DashboardHomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daily = context.watch<DailyProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GreetingHeaderWidget(daily: daily),
              const SizedBox(height: 16),

              // 🌟 Divine Energy Heading
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Connect with Divine Energy",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),

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

              // 🔮 Manual Kundali CTA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManualKundaliFormPage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF7C3AED), // Purple
                          Color(0xFFFBBF24), // Gold
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left side text
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Create Manual Kundali",
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Enter name, date & birthplace",
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),

                        // Right side modern icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_calendar_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),

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
          // ⭐ TODAY Horoscope (Dashboard Summary Card)
          const HoroscopeCardWidget(title: "Today"),

          const SizedBox(height: 12),

          Row(
            children: [
              // ⭐ Tomorrow Button → Opens Tomorrow TAB
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HoroscopePage(initialTab: 1),
                      ),
                    );
                  },
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

              // ⭐ Weekly Button → Opens Weekly TAB
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HoroscopePage(initialTab: 2),
                      ),
                    );
                  },
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

  // 🧭 Astrology Tools Section -------------------------------------------------
  Widget _buildAstrologyToolsSection(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('profiles')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 🔹 Default data (fallback)
        Map<String, dynamic> profileData = {
          "name": "Guest User",
          "dob": "1990-01-01",
          "tob": "10:00",
          "pob": "Delhi, India",
          "lat": 28.6139,
          "lng": 77.2090,
          "language": "en",
        };

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          profileData = snapshot.data!.docs.first.data();
        }

        // 🔹 Tools mapping (backend IDs)
        final Map<String, String> toolMap = {
          "Lagna Finder": "lagna_finder",
          "Rashi Finder": "rashi_finder",
          "Gemstone Suggestion": "gemstone_suggestion",
          "Love Match": "love-match",
          "Rajyog Check": "rajya_sambandh_rajyog",
          "Health Insight": "health_insight",
        };

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
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
                    return _toolCard(
                      context,
                      _getIcon(entry.key),
                      entry.key,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ToolResultPage(
                              toolId: entry.value, // Backend key (dynamic)
                              formData: {
                                "name": profileData['name'],
                                "dob": profileData['dob'],
                                "tob": profileData['tob'],
                                "pob": profileData['pob'],
                                "lat": profileData['lat'] ?? 26.8467,
                                "lng": profileData['lng'] ?? 80.9462,
                                "language": profileData['language'] ?? "en",
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AstrologyPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.apps),
                    label: const Text("More Tools"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  // 📰 Blog Section (Dynamic from WordPress) -------------------------------
  Widget _buildBlogSection(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder(
      future: http.get(
        Uri.parse(
          "https://jyotishasha.com/wp-json/wp/v2/posts?_embed&per_page=5",
        ),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Failed to load blog posts"));
        }

        final response = snapshot.data as http.Response;
        if (response.statusCode != 200) {
          return const Center(child: Text("No blog data found"));
        }

        final List posts = jsonDecode(response.body);

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
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final title = post["title"]["rendered"];
                    final imageUrl =
                        post["_embedded"]?["wp:featuredmedia"]?[0]?["source_url"] ??
                        "https://jyotishasha.com/default-thumbnail.jpg";
                    final tag =
                        post["_embedded"]?["wp:term"]?[0]?[0]?["name"] ??
                        "Astrology";

                    return _blogCard(
                      context,
                      title,
                      tag,
                      imageUrl,
                      post["link"],
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    launchUrl(Uri.parse("https://jyotishasha.com/blog"));
                  },
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text("Explore Blog"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🧩 Blog Card -----------------------------------------------------------
  Widget _blogCard(
    BuildContext context,
    String title,
    String tag,
    String imageUrl,
    String link,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(link)),
      child: Container(
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
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
      ),
    );
  }
}
