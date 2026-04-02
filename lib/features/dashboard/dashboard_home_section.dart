import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';
import 'package:flutter/services.dart';

// Widgets
import 'package:jyotishasha_app/core/widgets/greeting_header_widget.dart';
import 'package:jyotishasha_app/core/widgets/transit_alert_widget.dart';
import 'package:jyotishasha_app/core/widgets/panchang_card_widget.dart';
import 'package:jyotishasha_app/core/widgets/chaughadiya_alert_widget.dart';
import 'package:jyotishasha_app/core/widgets/trending_questions_widget.dart';
import 'package:jyotishasha_app/core/widgets/shubh_muhurth_banner_widget.dart';
import 'package:jyotishasha_app/core/widgets/astrology_studio_widget.dart';
import 'package:jyotishasha_app/features/muhurth/muhurth_page.dart';
import 'package:jyotishasha_app/features/reports/widgets/report_card.dart';
import 'package:jyotishasha_app/features/reports/pages/report_checkout_page.dart';
import 'package:jyotishasha_app/core/widgets/app_footer_feedback_widget.dart';

// State
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/transit_provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart'; // Ensure this is imported

class DashboardHomeSection extends StatefulWidget {
  const DashboardHomeSection({super.key});

  @override
  State<DashboardHomeSection> createState() => _DashboardHomeSectionState();
}

class _DashboardHomeSectionState extends State<DashboardHomeSection> {
  // 🔵 Home par show hone wale random reports
  List<dynamic> homeReports = [];

  @override
  void initState() {
    super.initState();

    // Home ke liye reports.json load karo
    _loadHomeReports();
  }

  // ------------------------------------------------------------
  // LOAD RANDOM REPORTS FOR HOME PAGE
  // ------------------------------------------------------------
  Future<void> _loadHomeReports() async {
    try {
      final lang = context.read<LanguageProvider>().currentLang;

      // reports.json asset load
      final data = await rootBundle.loadString("assets/data/reports.json");

      final List<dynamic> list = jsonDecode(data);

      // 🔁 language aware mapping
      final processed = list.map((r) {
        final report = Map<String, dynamic>.from(r);

        if (lang == "hi" && report["title_hi"] != null) {
          report["title"] = report["title_hi"];
        }

        return report;
      }).toList();

      // random shuffle
      final shuffled = List.from(processed)..shuffle();

      setState(() {
        homeReports = shuffled.take(5).toList();
      });
    } catch (e) {
      debugPrint("❌ Home reports load error: $e");
    }
  }

  // ⭐ Professional Refresh Logic (Parallel Execution)
  Future<void> _onRefresh() async {
    final profile = context.read<ProfileProvider>().activeProfile ?? {};
    final sign = profile["rashi"] ?? profile["sign"];
    final lang = context.read<LanguageProvider>().currentLang;

    await Future.wait([
      if (sign != null)
        context.read<DailyProvider>().fetchDaily(
          sign: sign,
          lang: lang,
          force: true,
        ),
      context.read<TransitProvider>().fetchTransit(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F9),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF6366F1),
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              /// ─────────────────────────────────────────
              /// 1️⃣ USER GREETING SECTION
              /// Personalized welcome + quick astro context
              /// ─────────────────────────────────────────
              const SliverToBoxAdapter(child: GreetingHeaderWidget()),

              /// Main scrollable home content
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 24),

                    /// ─────────────────────────────────────────
                    /// 2️⃣ CHAUGHADIYA LIVE TICKER
                    /// Real-time auspicious / inauspicious time indicator
                    /// ─────────────────────────────────────────
                    const ChaughadiyaAlertWidget(),

                    const SizedBox(height: 24),

                    /// ─────────────────────────────────────────
                    /// 3️⃣ DAY LORD DARSHAN CTA
                    /// Spiritual daily guidance entry point
                    /// ─────────────────────────────────────────
                    _buildDayLordCTA(context, t),

                    const SizedBox(height: 24),

                    /// ─────────────────────────────────────────
                    /// 4️⃣ LIVE TRANSIT ALERT
                    /// Current planetary movement insights
                    /// ─────────────────────────────────────────
                    const TransitAlertWidget(),

                    const SizedBox(height: 24),

                    /// ─────────────────────────────────────────
                    /// 5️⃣ TODAY'S PANCHANG SNAPSHOT
                    /// Tithi, Nakshatra, Rahu Kaal, Abhijit etc.
                    /// ─────────────────────────────────────────
                    const PanchangCardWidget(),

                    const SizedBox(height: 24),

                    /// ─────────────────────────────────────────
                    /// 6️⃣ UPCOMING SHUBH MUHURTH
                    /// Quick access to auspicious activity dates
                    /// ─────────────────────────────────────────
                    ShubhMuhurthBannerWidget(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MuhurthPage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    /// ─────────────────────────────────────────
                    /// 7️⃣ TRENDING ASTRO QUESTIONS
                    /// Entry point for AskNow / consultation funnel
                    /// ─────────────────────────────────────────
                    _buildSectionHeader(t.trendingGeneral),

                    const SizedBox(height: 12),

                    const TrendingQuestionsWidget(),

                    const SizedBox(height: 24),

                    /// ─────────────────────────────────────────
                    /// 8️⃣ ASTROLOGY STUDIO
                    /// Deep dive into kundali analysis sections
                    /// ─────────────────────────────────────────
                    AstrologyStudioWidget(
                      kundali:
                          context.watch<ProfileProvider>().activeProfile ?? {},
                    ),

                    const SizedBox(height: 32),

                    // ------------------------------------------------------------
                    // 9️⃣ TRENDING REPORTS (HOME BOTTOM)
                    // Random paid reports show karega
                    // ------------------------------------------------------------
                    const SizedBox(height: 24),

                    _buildSectionHeader(t.trendingReports),

                    const SizedBox(height: 12),

                    // Reports list
                    homeReports.isEmpty
                        ? const SizedBox()
                        : Column(
                            children: homeReports.map((r) {
                              return ReportCard(
                                report: r,

                                // Report tap hone par checkout page open
                                onTap: () {
                                  final profile =
                                      context
                                          .read<ProfileProvider>()
                                          .activeProfile ??
                                      {};

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReportCheckoutPage(
                                        selectedReport: r,
                                        initialProfile: profile,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),

                    /// ─────────────────────────────────────────
                    /// 1️⃣0️⃣ APP FOOTER
                    /// Copyright / policy links
                    /// ─────────────────────────────────────────
                    const Divider(thickness: 0.6, color: Colors.black12),

                    const AppFooterFeedbackWidget(),

                    SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for consistent Section Titles
  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Colors.blueGrey[400],
        letterSpacing: 1.5,
      ),
    );
  }

  // Premium Day Lord CTA (Localized & Glassmorphism Fix)
  Widget _buildDayLordCTA(BuildContext context, AppLocalizations t) {
    return GestureDetector(
      onTap: () => context.push('/darshan'),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                bottom: -30,
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          "ॐ",
                          style: TextStyle(fontSize: 32, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.darshanInstruction.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.darshanWithMantra,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Footer Logic (Localized)
  Widget _buildFooter(AppLocalizations t) {
    return Column(
      children: [
        Container(width: 40, height: 2, color: Colors.grey[300]),
        const SizedBox(height: 24),
        Text(
          t.footerCopyright,
          style: TextStyle(
            color: Colors.blueGrey[300],
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          t.footerPrivacyTerms,
          style: TextStyle(fontSize: 12, color: Colors.blueGrey[400]),
        ),
      ],
    );
  }
}
