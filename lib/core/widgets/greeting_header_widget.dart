// lib/core/widgets/greeting_header_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/features/horoscope/horoscope_page.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';

class GreetingHeaderWidget extends StatelessWidget {
  const GreetingHeaderWidget({super.key});

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

    // 🔁 Language change hone par Daily API dobara fetch hogi
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildZodiacIcon(sign),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(lang),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            _buildNotificationBell(context),
          ],
        ),

        const SizedBox(height: 24),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "TODAY'S VIBE",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white70,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.more_horiz, color: Colors.white70),
                ],
              ),

              if (intro != null) ...[
                const SizedBox(height: 12),
                Text(
                  intro,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              _buildReadMoreBtn(context, lang),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notifications coming soon!")),
        );
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
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZodiacIcon(String? sign) {
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Colors.amber, Colors.orange]),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.asset(_zodiacAsset(sign), fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildReadMoreBtn(BuildContext context, String lang) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HoroscopePage(initialTab: 0)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang == "hi" ? "विस्तार से पढ़ें" : "Read Detailed",
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 28, backgroundColor: Colors.white),
                  const SizedBox(width: 12),
                  Container(width: 120, height: 30, color: Colors.white),
                ],
              ),
              const CircleAvatar(radius: 20, backgroundColor: Colors.white),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ],
      ),
    );
  }
}
