// lib/core/widgets/greeting_header_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';

import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/features/horoscope/horoscope_page.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/services/notification_service.dart';
import 'package:jyotishasha_app/core/state/notification_provider.dart';
import 'package:jyotishasha_app/features/darshan/darshan_page.dart';
import 'package:jyotishasha_app/features/panchang/panchang_page.dart';
import '../../features/cards/presentation/cards_page.dart';

class GreetingHeaderWidget extends StatefulWidget {
  const GreetingHeaderWidget({super.key});

  @override
  State<GreetingHeaderWidget> createState() => _GreetingHeaderWidgetState();
}

class _GreetingHeaderWidgetState extends State<GreetingHeaderWidget> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final provider = context.read<NotificationProvider>();
      await provider.loadUnreadCount();
    });
  }

  String _getGreeting(String lang) {
    return (lang == "hi") ? "नमस्कार" : "Namaskar";
  }

  String _zodiacAsset(String? sign) {
    if (sign == null || sign.isEmpty) return 'assets/zodiac/leo.webp';

    final map = {
      'aries': 'aries',
      'taurus': 'taurus',
      'gemini': 'gemini',
      'cancer': 'cancer',
      'leo': 'leo',
      'virgo': 'virgo',
      'libra': 'libra',
      'scorpio': 'scorpio',
      'sagittarius': 'sagittarius',
      'capricorn': 'capricorn',
      'aquarius': 'aquarius',
      'pisces': 'pisces',
      'मेष': 'aries',
      'वृषभ': 'taurus',
      'मिथुन': 'gemini',
      'कर्क': 'cancer',
      'सिंह': 'leo',
      'कन्या': 'virgo',
      'तुला': 'libra',
      'वृश्चिक': 'scorpio',
      'धनु': 'sagittarius',
      'मकर': 'capricorn',
      'कुंभ': 'aquarius',
      'मीन': 'pisces',
    };

    final key = sign.toLowerCase().trim();
    final slug = map[key] ?? 'leo';

    return 'assets/zodiac/$slug.webp';
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().activeProfile;
    final daily = context.watch<DailyProvider>();
    final lang = context.watch<LanguageProvider>().currentLang;

    final isLoading = daily.isLoading;
    final intro = daily.intro;

    final lastLang = context.read<DailyProvider>().lastLang;

    if (lastLang != lang) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final sign =
            profile?["moon_sign"] ?? profile?["rashi"] ?? profile?["sign"];

        if (sign != null) {
          context.read<DailyProvider>().fetchDaily(
            sign: sign,
            lang: lang,
            force: true,
          );
        }
      });
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: isLoading
          ? _buildShimmerLoader()
          : _buildActualContent(context, profile, intro),
    );
  }

  Widget _buildActualContent(
    BuildContext context,
    Map? profile,
    String? intro,
  ) {
    final userName = profile?['name'] ?? "Guest";
    final sign = profile?['moon_sign'] as String?;
    final lang = context.watch<LanguageProvider>().currentLang;

    /// 🔥 SAFE NAME FORMAT
    String formattedName() {
      if (userName.trim().isEmpty) return "Guest";

      final first = userName.trim().split(" ").first;
      return first[0].toUpperCase() + first.substring(1).toLowerCase();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔹 HEADER ROW
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// LEFT SIDE (ICON + TEXT)
            Expanded(
              child: Row(
                children: [
                  _buildZodiacIcon(sign),
                  const SizedBox(width: 14),

                  /// 🔥 TEXT BLOCK (RESPONSIVE)
                  Expanded(
                    child: Text(
                      lang == "hi"
                          ? "नमस्कार ${formattedName()}"
                          : "Namaskar ${formattedName()}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            /// 🔔 NOTIFICATION BELL (RIGHT)
            _buildNotificationBell(context),
          ],
        ),

        const SizedBox(height: 22),

        /// 🔮 HOROSCOPE CARD
        _buildHoroscopeCard(context, intro, lang),
      ],
    );
  }

  Widget _buildHoroscopeCard(BuildContext context, String? intro, String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
          Text(
            lang == "hi" ? "आज का राशिफल" : "TODAY'S HOROSCOPE",
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 10),

          /// TEXT
          Text(
            intro ?? "Loading...",
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 12),

          /// READ MORE
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HoroscopePage(initialTab: 0),
                  ),
                );
              },
              child: Text(
                lang == "hi" ? "और पढ़ें →" : "Read More →",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          /// DIVIDER
          Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),

          const SizedBox(height: 16),

          /// 🔥 CTA ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              /// 🔱 MANTRA & DARSHAN
              SizedBox(
                width: 110,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DarshanPage()),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.25),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 20,
                          color: Color(0xFFFF6B6B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lang == "hi" ? "मंत्र & दर्शन" : "Mantra & Darshan",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// 📅 PANCHANG
              SizedBox(
                width: 90,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PanchangPage()),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lang == "hi" ? "पंचांग" : "Panchang",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// ✨ DIVINE WISHES
              SizedBox(
                width: 110,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CardsPage()),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.25),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 20,
                          color: Color(0xFFFBBF24),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lang == "hi" ? "दिव्य शुभकामनाएँ" : "Divine Wishes",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
    final count = context.watch<NotificationProvider>().unreadCount;

    return InkWell(
      onTap: () {
        _showNotificationSheet(context);

        // slight delay so UI feels smoother
        Future.delayed(const Duration(milliseconds: 200), () async {
          if (context.mounted) {
            await context.read<NotificationProvider>().loadUnreadCount();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              size: 24,
              color: Color(0xFF1A1A1A),
            ),

            if (count > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    count > 9 ? "9+" : "$count",
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
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

  void _showNotificationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: const NotificationPreview(),
          ),
        );
      },
    );
  }

  Widget _buildZodiacIcon(String? sign) {
    return CircleAvatar(
      radius: 28,
      backgroundImage: AssetImage(_zodiacAsset(sign)),
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.white,
      child: Container(height: 100, color: Colors.white),
    );
  }
}

class NotificationPreview extends StatefulWidget {
  const NotificationPreview({super.key});

  @override
  State<NotificationPreview> createState() => _NotificationPreviewState();
}

class _NotificationPreviewState extends State<NotificationPreview> {
  late Future<List> _future;

  @override
  void initState() {
    super.initState();
    _future = NotificationService.getNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: _future,
      builder: (context, snapshot) {
        // 🔄 LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ❌ ERROR
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong"));
        }

        final list = snapshot.data ?? [];

        // 📭 EMPTY STATE
        if (list.isEmpty) {
          return const Center(
            child: Text(
              "No notifications",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          );
        }

        // ✅ SUCCESS LIST
        // ✅ SUCCESS LIST
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final n = list[index];

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 6),

              onTap: () async {
                // 🔥 SAFE ID PARSE (important)
                final id = n["id"] is int
                    ? n["id"]
                    : int.tryParse("${n["id"]}");

                final route = n["data"]?["route"];

                print("CLICKED ID: $id");

                // 🔹 Extract dependencies first
                final provider = context.read<NotificationProvider>();
                final navigator = Navigator.of(context);

                // 🔥 MARK AS READ
                if (id != null) {
                  await NotificationService.markAsRead(id);
                } else {
                  print("❌ Invalid notification id");
                }

                // 🔄 REFRESH BELL COUNT
                await provider.loadUnreadCount();

                // 🔄 REFRESH LIST UI
                setState(() {
                  _future = NotificationService.getNotifications();
                });

                // 🚀 NAVIGATION (if exists)
                if (route != null && route.toString().isNotEmpty) {
                  navigator.pushNamed(route);
                }
              },

              title: Text(
                n["title"] ?? "",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),

              subtitle: Text(
                n["body"] ?? "",
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),

              leading: const Icon(
                Icons.notifications,
                color: Colors.deepPurple,
              ),
            );
          },
        );
      },
    );
  }
}
