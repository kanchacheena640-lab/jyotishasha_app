// lib/core/widgets/greeting_header_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/features/horoscope/horoscope_page.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/services/notification_service.dart';
import 'package:jyotishasha_app/core/state/notification_provider.dart';
import 'package:jyotishasha_app/core/notifications/notification_dispatcher.dart';
import 'package:jyotishasha_app/core/state/welcome_gift_provider.dart';
import 'package:jyotishasha_app/features/welcome_gift/welcome_gift_page.dart';
import 'package:jyotishasha_app/main.dart' show notificationNavigationService;

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

    // Welcome Gift — decide the card's visibility (never claimed vs.
    // already claimed) before the user can interact with anything below.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WelcomeGiftProvider>().loadStatus();
    });
  }

  String _getGreeting(String lang) {
    return (lang == "hi") ? "नमस्कार" : "Namaskar";
  }

  static const Map<String, String> _zodiacSlugByKey = {
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

  static const Map<String, String> _zodiacEnglishNames = {
    'aries': 'Aries',
    'taurus': 'Taurus',
    'gemini': 'Gemini',
    'cancer': 'Cancer',
    'leo': 'Leo',
    'virgo': 'Virgo',
    'libra': 'Libra',
    'scorpio': 'Scorpio',
    'sagittarius': 'Sagittarius',
    'capricorn': 'Capricorn',
    'aquarius': 'Aquarius',
    'pisces': 'Pisces',
  };

  static const Map<String, String> _zodiacHindiNames = {
    'aries': 'मेष',
    'taurus': 'वृषभ',
    'gemini': 'मिथुन',
    'cancer': 'कर्क',
    'leo': 'सिंह',
    'virgo': 'कन्या',
    'libra': 'तुला',
    'scorpio': 'वृश्चिक',
    'sagittarius': 'धनु',
    'capricorn': 'मकर',
    'aquarius': 'कुंभ',
    'pisces': 'मीन',
  };

  /// F4.1.5 typography polish — the zodiac line now reads "♋ Cancer"
  /// instead of "You are Cancer,".
  static const Map<String, String> _zodiacSymbol = {
    'aries': '♈',
    'taurus': '♉',
    'gemini': '♊',
    'cancer': '♋',
    'leo': '♌',
    'virgo': '♍',
    'libra': '♎',
    'scorpio': '♏',
    'sagittarius': '♐',
    'capricorn': '♑',
    'aquarius': '♒',
    'pisces': '♓',
  };

  /// Normalizes a raw profile sign string (English or Hindi) to a
  /// canonical slug, used to look up the display name and symbol.
  String _zodiacSlug(String? sign) {
    if (sign == null || sign.isEmpty) return 'leo';
    final key = sign.toLowerCase().trim();
    return _zodiacSlugByKey[key] ?? 'leo';
  }

  String _zodiacDisplayName(String? sign, String lang) {
    final slug = _zodiacSlug(sign);
    final names = lang == 'hi' ? _zodiacHindiNames : _zodiacEnglishNames;
    return names[slug] ?? (lang == 'hi' ? _zodiacHindiNames['leo']! : _zodiacEnglishNames['leo']!);
  }

  /// "Hi Ravi" / "नमस्ते, Ravi" — the name stays in Latin script in Hindi
  /// too, matching this app's established convention.
  String _hiGreeting(String lang, String name) {
    return lang == 'hi' ? 'नमस्ते, $name' : 'Hi $name';
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
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBFF),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
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

    // GreetingHeaderWidget is now a pure header: Container → Top Row →
    // Greeting Block → END. No secondary content is rendered here.
    //
    // `_buildHoroscopeCard` and `_buildQuickActions` used to be rendered
    // below the top row; `_buildHoroscopeCard` is kept intact (unmodified,
    // unreferenced) for reuse later, and `_buildQuickActions` was removed
    // entirely per F4.1.3 "Header Architecture Cleanup".
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔹 TOP ROW (F4.1.6 "Minimal Premium Header") — no zodiac icon
        /// at all; greeting starts flush at the card's left padding,
        /// language chip + bell on the right.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _hiGreeting(lang, formattedName()),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1B2E),
                  letterSpacing: 0.1,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildLanguageSwitch(context, lang),
            const SizedBox(width: 10),
            _buildNotificationBell(context),
          ],
        ),
        const SizedBox(height: 12),
        /// 🔹 Zodiac line + Astrology Profile CTA — unchanged content,
        /// typography, and spacing (see `_buildGreetingBlock`).
        _buildGreetingBlock(context, lang, sign),
      ],
    );
  }

  /// "♋ Cancer" (zodiac symbol + name) → Welcome Gift card (replaces the
  /// former "Your Astrology Profile" CTA row in this same slot — see
  /// `_buildWelcomeGiftCard`). "Hi Ravi" now lives in the top row
  /// alongside the language chip + bell — see `_buildActualContent`.
  Widget _buildGreetingBlock(BuildContext context, String lang, String? sign) {
    final zodiac = _zodiacDisplayName(sign, lang);
    final symbol = _zodiacSymbol[_zodiacSlug(sign)] ?? _zodiacSymbol['leo']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$symbol $zodiac',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4C1D95),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        _buildWelcomeGiftCard(context, lang),
        const SizedBox(height: 6),
      ],
    );
  }

  /// Welcome Gift card — replaces the former "Your Astrology Profile" CTA
  /// row in this slot. Shown only while `WelcomeGiftProvider.isClaimed`
  /// is false (and the flag has finished loading); once claimed, this
  /// renders nothing and never reappears, per spec. Tapping opens the new,
  /// standalone `WelcomeGiftPage` — no reused screen.
  Widget _buildWelcomeGiftCard(BuildContext context, String lang) {
    final gift = context.watch<WelcomeGiftProvider>();

    if (gift.isLoading || gift.isClaimed) return const SizedBox.shrink();

    final isHindi = lang == 'hi';

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeGiftPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F5FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4D9FA)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHindi ? '🎁 वेलकम गिफ्ट' : '🎁 Welcome Gift',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B21A8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isHindi
                        ? '5 पर्सनलाइज़्ड प्रीमियम रिपोर्ट पाएं\n(जन्म कुंडली पर आधारित)'
                        : 'Unlock 5 Personalized Premium Reports\n(Birth Chart Based)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1B2E),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isHindi
                        ? '+ 15 दिनों की प्रीमियम मेंबरशिप'
                        : '+ 15 Days Premium Membership',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isHindi ? 'फ्री एक्सेस पाएं →' : 'Claim Free Access →',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B21A8),
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

  /// Compact, premium redesign: smaller footprint, calmer two-tone gradient
  /// (was a 3-stop vivid gradient), tighter padding, shorter preview text,
  /// and no CTA row — quick actions now live in their own section below.
  /// Same title/preview/"Read More" content and navigation as before.
  Widget _buildHoroscopeCard(BuildContext context, String? intro, String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6D5AE6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white70,
              letterSpacing: 1.1,
            ),
          ),

          const SizedBox(height: 6),

          /// TEXT
          Text(
            intro ?? "Loading...",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 8),

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
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shared height for the language chip and notification bell (F4.1.7) —
  /// the bell's own diameter (previous padding 6.63 × 2 + icon 15) is the
  /// baseline both controls are now built to, so they visually belong to
  /// the same design system.
  static const double _headerControlHeight = 28.0;

  /// A single compact chip showing only the active language (not a
  /// segmented EN/HI toggle) — tapping it switches to the other language,
  /// reusing the same `LanguageProvider.setLanguage` call as before.
  Widget _buildLanguageSwitch(BuildContext context, String lang) {
    final languageProvider = context.read<LanguageProvider>();
    final nextCode = lang == 'en' ? 'hi' : 'en';

    return GestureDetector(
      onTap: () => languageProvider.setLanguage(nextCode),
      child: Container(
        // F4.1.7 polish: height matched to the bell's diameter
        // (_headerControlHeight) so both controls share the same visual
        // height; radius is now half that height, keeping a true pill
        // shape instead of a fixed 20 that no longer matched the height.
        height: _headerControlHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(_headerControlHeight / 2),
        ),
        child: Text(
          lang.toUpperCase(),
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
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
        // F4.1.7 polish: explicit width/height (_headerControlHeight,
        // matching the language chip) instead of padding-derived sizing;
        // icon centered via Stack's `alignment`.
        width: _headerControlHeight,
        height: _headerControlHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFECE8F5), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              size: 15,
              color: Color(0xFF1F1B2E),
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

                // Same NotificationDispatcher used by the FCM tap path
                // (main.dart) — Notification Center and FCM must resolve
                // to the identical destination shape.
                final destination =
                    NotificationDispatcher.fromNotificationCenterItem(n);

                print("CLICKED ID: $id");

                // 🔹 Extract dependencies first
                final provider = context.read<NotificationProvider>();

                // 🔥 MARK AS READ
                if (id != null) {
                  await NotificationService.markAsRead(id);
                } else {
                  print("❌ Invalid notification id");
                }

                // 🔄 REFRESH BELL COUNT
                await provider.loadUnreadCount();

                if (!mounted) return;

                // 🔄 REFRESH LIST UI
                setState(() {
                  _future = NotificationService.getNotifications();
                });

                // 🚀 NAVIGATION — N1: routed through the SAME
                // NotificationNavigationService the FCM tap path
                // (main.dart::handleNotificationTap) uses, instead of a
                // separate context.push('/event', ...) call — one shared
                // routing contract for both entry points, per N1's own
                // architecture requirement. Bell is only ever opened from
                // /dashboard (GreetingHeaderWidget's only mount point), so
                // openDestination()'s dashboard-reset is a no-op here; the
                // resulting stack is unchanged from before this fix.
                if (!context.mounted) return;
                notificationNavigationService.openDestination(destination);
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
