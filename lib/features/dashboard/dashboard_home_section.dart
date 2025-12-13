// dart

// flutter
import 'package:flutter/material.dart';

// third-party
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// localization
import 'package:jyotishasha_app/l10n/app_localizations.dart';

// core
import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/widgets/keyboard_dismiss.dart';
import 'package:jyotishasha_app/core/widgets/greeting_header_widget.dart';
import 'package:jyotishasha_app/core/widgets/panchang_card_widget.dart';
import 'package:jyotishasha_app/core/widgets/shubh_muhurth_banner_widget.dart';
import 'package:jyotishasha_app/core/widgets/app_footer_feedback_widget.dart';
import 'package:jyotishasha_app/core/widgets/astrology_studio_widget.dart';
import 'package:jyotishasha_app/services/blog_service.dart';

// features
import 'package:jyotishasha_app/features/muhurth/muhurth_page.dart';
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
              // 👋 Greeting
              GreetingHeaderWidget(daily: daily),
              const SizedBox(height: 16),

              // 🌞 Darshan Instruction
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                child: Center(
                  child: Text(
                    t.darshanInstruction,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // 🌞 Darshan Card + Bigger Om CTA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => context.push('/darshan'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 18,
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
                        // LEFT TEXT (thoda compact)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.todaysDayLord,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t.darshanWithMantra,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  color: Colors.white70,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // RIGHT BIG OM BUTTON
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.24),
                            border: Border.all(
                              color: Colors.white30,
                              width: 1.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            "ॐ",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 📿 Panchang Card
              const PanchangCardWidget(),
              const SizedBox(height: 14),

              // 🕉️ Muhurth Section – only banner (no heading)
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
              const SizedBox(height: 22),

              // 🔭 Astrology Studio – stretched with card feel
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AstrologyStudioWidget(
                    kundali:
                        context.read<FirebaseKundaliProvider>().kundaliData ??
                        {},
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // 🔮 Manual Kundali CTA – now below Studio
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.createManualKundali,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t.enterNameDateBirthplace,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.2,
                                  color: Colors.white70,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Right side icon
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

              // 📰 Blog Section
              _buildBlogSection(context),
              const SizedBox(height: 28),

              // 📝 Footer Feedback
              KeyboardDismissOnTap(child: AppFooterFeedbackWidget()),
            ],
          ),
        ),
      ),
    );
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

        final List<BlogPost> posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return const Center(child: Text("No blogs available"));
        }

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
