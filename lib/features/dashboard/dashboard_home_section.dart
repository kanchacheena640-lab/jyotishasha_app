// dart
import 'dart:convert';

// flutter
import 'package:flutter/material.dart';

// third-party
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// localization
import 'package:jyotishasha_app/l10n/app_localizations.dart';

// core
import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/widgets/keyboard_dismiss.dart';
import 'package:jyotishasha_app/core/widgets/greeting_header_widget.dart';
import 'package:jyotishasha_app/core/widgets/horoscope_card_widget.dart';
import 'package:jyotishasha_app/core/widgets/panchang_card_widget.dart';
import 'package:jyotishasha_app/core/widgets/shubh_muhurth_banner_widget.dart';
import 'package:jyotishasha_app/core/widgets/app_footer_feedback_widget.dart';
import 'package:jyotishasha_app/core/widgets/astrology_studio_widget.dart';
import 'package:jyotishasha_app/services/blog_service.dart';

// features
import 'package:jyotishasha_app/features/panchang/panchang_page.dart';
import 'package:jyotishasha_app/features/muhurth/muhurth_page.dart';
import 'package:jyotishasha_app/features/horoscope/horoscope_page.dart';
import 'package:jyotishasha_app/features/manual_kundali/manual_kundali_form_page.dart';
import 'package:jyotishasha_app/core/models/blog_models.dart';
import 'package:jyotishasha_app/core/widgets/blog_carousel_widget.dart';

// providers
import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/firebase_kundali_provider.dart';

/// 🌟 Dashboard Home (Light, Elegant & Unified)
class DashboardHomeSection extends StatelessWidget {
  const DashboardHomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daily = context.watch<DailyProvider>();
    final t = AppLocalizations.of(context)!;

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

              // 🌞 Darshan Instruction + Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                child: Center(
                  child: Text(
                    t.darshanInstruction,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 15, // same as banner
                      fontWeight: FontWeight.w600, // same as banner
                      color: AppColors.textPrimary, // same as banner
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => context.push('/darshan'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // LEFT TEXT
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.todaysDayLord,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              t.darshanWithMantra,
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),

                        // RIGHT OM BUTTON
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.22),
                            border: Border.all(
                              color: Colors.white30,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            "ॐ",
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const PanchangCardWidget(),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ShubhMuhurthBannerWidget(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MuhurthPage()),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

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
                      vertical: 16,
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
                              t.createManualKundali,
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.enterNameDateBirthplace,
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.2,
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
              const SizedBox(height: 22),

              // 🔭 Astrology Studio + Heading
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.exploreYourChart,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AstrologyStudioWidget(
                      kundali:
                          context.read<FirebaseKundaliProvider>().kundaliData ??
                          {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ⭐ ADD BLOG SECTION HERE
              _buildBlogSection(context),

              const SizedBox(height: 28),

              KeyboardDismissOnTap(child: AppFooterFeedbackWidget()),
            ],
          ),
        ),
      ),
    );
  }

  // 🕉️ Panchang Card (old helper - unused currently)
  Widget _buildPanchangCard(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

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

          // ❗ This is static demo text (not real Panchang)
          // Keeping it English or Hindi isn't needed for now
          Text(
            t.panchangTitle, // 👈 best ARB replacement for demo
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
                t.panchangViewFull,
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
    final t = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ⭐ TODAY Horoscope (Dashboard Summary Card)
          HoroscopeCardWidget(title: t.today),

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
                  icon: const Icon(Icons.calendar_today, size: 20),
                  label: Text(t.tomorrow),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(.3),
                      width: 1.3,
                    ),
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                  icon: const Icon(Icons.view_week, size: 20),
                  label: Text(t.weekly),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(.3),
                      width: 1.3,
                    ),
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
  IconData _getIcon(BuildContext context, String title) {
    final t = AppLocalizations.of(context)!;

    switch (title) {
      case "Free Kundali":
      case "फ्री कुंडली":
        return Icons.self_improvement;

      case "Lagna Finder":
      case "लग्न फाइंडर":
        return Icons.wb_sunny_outlined;

      case "Rashi Finder":
      case "राशि फाइंडर":
        return Icons.star_outline;

      case "Love Match":
      case "लव मैच":
        return Icons.favorite_outline;

      case "Rajyog Check":
      case "राजयोग चेक":
        return Icons.auto_graph;

      case "Health Insight":
      case "हेल्थ इनसाइट":
        return Icons.health_and_safety;

      default:
        return Icons.api;
    }
  }

  // 📰 App Blogs Section (AstroBlog.in)
  Widget _buildBlogSection(BuildContext context) {
    return FutureBuilder(
      future: BlogService.fetchBlogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Failed to load blogs"));
        }

        // Cast list safely
        final List<BlogPost> posts = snapshot.data as List<BlogPost>? ?? [];

        if (posts.isEmpty) {
          return const Center(child: Text("No blogs available"));
        }

        // Convert BlogPost → Map<String, String>  (Widget expects Map list)
        final mapped = posts.map((p) => p.toMap()).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: BlogCarouselWidget(
            blogs: mapped,
            onExplore: () {
              launchUrl(Uri.parse("https://astroblog.in/category/app-blogs/"));
            },
          ),
        );
      },
    );
  }
}
