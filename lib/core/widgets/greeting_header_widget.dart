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
import 'package:jyotishasha_app/features/kundali/kundali_overview_page.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';
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
    return names[slug] ??
        (lang == 'hi'
            ? _zodiacHindiNames['leo']!
            : _zodiacEnglishNames['leo']!);
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
        _buildGreetingBlock(context, lang, sign, profile),
      ],
    );
  }

  /// "♋ Cancer" (zodiac symbol + name) followed by the
  /// "Your Astrology Profile   View →" CTA row — the finalized Greeting
  /// Area layout, with no gift-related UI of any kind in this slot.
  /// "Hi Ravi" lives in the top row alongside the language chip + bell —
  /// see `_buildActualContent`.
  ///
  /// Task 3 — the zodiac line is only ever shown for a real, present
  /// `moon_sign`. Previously a `null`/missing sign silently fell back to
  /// "♌ Leo" via `_zodiacSlug`'s own default, which looked exactly like a
  /// real (wrong) answer instead of an empty state. A missing sign now
  /// shows a neutral "not available yet" line instead — no zodiac symbol
  /// or name is ever invented.
  Widget _buildGreetingBlock(
    BuildContext context,
    String lang,
    String? sign,
    Map? profile,
  ) {
    final isHindi = lang == 'hi';
    final hasSign = sign != null && sign.trim().isNotEmpty;
    final zodiacLine = hasSign
        ? '${_zodiacSymbol[_zodiacSlug(sign)] ?? _zodiacSymbol['leo']!} '
              '${_zodiacDisplayName(sign, lang)}'
        : (isHindi ? '✨ राशि अभी उपलब्ध नहीं है' : '✨ Moon sign not available yet');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          zodiacLine,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4C1D95),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        _buildAstrologyProfileCta(context, lang, profile),
        const SizedBox(height: 6),
      ],
    );
  }

  /// Compact astrology-badge chip — icon + "{label}: {value or '-'}",
  /// used for Lagna/Nakshatra inside the Astrology Profile CTA. Never
  /// fabricates a value: a missing field always renders "-", exactly the
  /// same graceful-fallback convention `KundaliOverviewPage`'s own chart
  /// badges already use for the same fields.
  Widget _astrologyBadge(String icon, String label, String? value) {
    final display = (value != null && value.trim().isNotEmpty) ? value : '-';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE4D9FA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$label: $display',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Your Astrology Profile   View →" CTA — Task 3 turned this from a
  /// bare text row into a compact, clearly-tappable pill (light lavender
  /// fill `0xFFF6F3FC`, lavender border `0xFFE4D9FA`, rounded corners,
  /// small purple leading icon) — the same premium visual tokens already
  /// used throughout `KundaliOverviewPage` (chart badges, section cards),
  /// reused here rather than inventing a new design language.
  ///
  /// Task 4 — Astrology no longer occupies a bottom-nav slot (replaced by
  /// Ask Now), so "View" no longer performs the old `DashboardTabSwitcher`
  /// in-place tab switch; it now pushes the exact same, unmodified
  /// [KundaliOverviewPage] directly (default constructor — Self mode,
  /// unchanged), the same mechanism "Create Another Kundali" already
  /// uses elsewhere for its own Kundali navigation. Home stays on the
  /// navigation stack underneath and Back returns to it, same as before.
  ///
  /// Lagna/Nakshatra badges (Task 3) read directly from
  /// `ProfileProvider.activeProfile` — no new fetch, no new provider —
  /// and only appear when at least one of the two is actually present;
  /// when neither is available the badge row is omitted entirely rather
  /// than showing two empty "-" chips, per the "omit if cleaner" option.
  Widget _buildAstrologyProfileCta(
    BuildContext context,
    String lang,
    Map? profile,
  ) {
    final isHindi = lang == 'hi';
    final lagna = profile?['lagna'] as String?;
    final nakshatra = profile?['nakshatra'] as String?;
    final hasLagna = lagna != null && lagna.trim().isNotEmpty;
    final hasNakshatra = nakshatra != null && nakshatra.trim().isNotEmpty;
    final showBadges = hasLagna || hasNakshatra;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const KundaliOverviewPage()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F3FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE4D9FA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Color(0xFF6B21A8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isHindi ? 'आपकी ज्योतिष प्रोफाइल' : 'Your Astrology Profile',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F1B2E),
                    ),
                  ),
                ),
                Text(
                  isHindi ? 'देखें →' : 'View →',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B21A8),
                  ),
                ),
              ],
            ),
            if (showBadges) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _astrologyBadge(
                    '🔺',
                    isHindi ? 'लग्न' : 'Lagna',
                    hasLagna ? lagna : null,
                  ),
                  const SizedBox(width: 8),
                  _astrologyBadge(
                    '⭐',
                    isHindi ? 'नक्षत्र' : 'Nakshatra',
                    hasNakshatra ? nakshatra : null,
                  ),
                ],
              ),
            ],
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
  const NotificationPreview({super.key, this.notificationsLoader});

  /// N5: injectable in tests, exactly like EventDispatcherPage's own
  /// `EventRepository?` constructor parameter -- defaults to the real
  /// `NotificationService.getNotifications()` (which, in production,
  /// always has a real Firebase user). Widget tests use this to supply
  /// canned rows directly instead of going through Firebase Auth, which
  /// this app's headless test environment cannot initialize.
  final Future<List> Function()? notificationsLoader;

  @override
  State<NotificationPreview> createState() => _NotificationPreviewState();
}

class _NotificationPreviewState extends State<NotificationPreview> {
  late Future<List> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List> _load() {
    return widget.notificationsLoader?.call() ??
        NotificationService.getNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return FutureBuilder<List>(
      future: _future,
      builder: (context, snapshot) {
        // 🔄 LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ❌ ERROR — reuses the SAME localized copy
        // EventDispatcherPage already shows for a load failure (N5:
        // previously a hardcoded, English-only "Something went wrong").
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                t.eventLoadError,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          );
        }

        final list = snapshot.data ?? [];

        // 📭 EMPTY STATE (N5: now localized; previously English-only)
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 36,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t.bellEmptyState,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        // ✅ SUCCESS LIST
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final n = list[index];
            final isRead = n["is_read"] == true;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 4,
              ),
              // N5: a filled dot for unread, a neutral outline for read —
              // the same "is_read" field this row already carries (used
              // below to mark-read on tap), just rendered for the first
              // time instead of every row looking identical.
              tileColor: isRead ? null : const Color(0xFFF7F3FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),

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
                  _future = _load();
                });

                // 🚀 NAVIGATION — N1: routed through the SAME
                // NotificationNavigationService the FCM tap path
                // (main.dart::handleNotificationTap) uses, instead of a
                // separate context.push('/event', ...) call — one shared
                // routing contract for both entry points, per N1's own
                // architecture requirement. Bell is only ever opened from
                // /dashboard (GreetingHeaderWidget's only mount point), so
                // openDestination()'s dashboard-reset is a no-op here; the
                // resulting stack is unchanged from before this fix. A
                // failed/no-op navigation here (e.g. an unresolved route)
                // never rolls back the mark-read/refresh above — read
                // state cannot be corrupted by a bad destination.
                if (!context.mounted) return;
                notificationNavigationService.openDestination(destination);
              },

              leading: _NotificationTypeIcon(
                type: _extractType(n),
                isRead: isRead,
              ),

              title: Text(
                n["title"] ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                  fontSize: 14,
                  color: const Color(0xFF1F1B2E),
                ),
              ),

              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 3),
                  Text(
                    n["body"] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.35),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _relativeTime(n["created_at"]?.toString()),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// `n["data"]["type"]` — the same authoritative discriminator
  /// NotificationNavigationService already routes on (event/transit/
  /// dasha/dasha_pre/panchang/panchak/alert). Purely for choosing a
  /// small leading icon; never used for navigation or eligibility.
  static String? _extractType(Map n) {
    final data = n["data"];
    if (data is Map) return data["type"]?.toString();
    return null;
  }

  /// "2h ago" / "Yesterday" / "12-08-2026" — hand-rolled EN/HI, matching
  /// this file's own established convention for small display strings
  /// (_getGreeting/_hiGreeting above, and event_dispatcher_page.dart's
  /// _formatEventDate) rather than adding ICU-plural ARB entries this
  /// project's localization system has never used before. The backend
  /// sends created_at as a naive-UTC ISO string (no 'Z'/offset — the
  /// same convention every notification timestamp in this system already
  /// uses, see services/notification_lifecycle.py) -- appending 'Z'
  /// before parsing is required so Dart treats it as UTC, not local.
  String _relativeTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    final lang = context.read<LanguageProvider>().currentLang;
    final isHindi = lang == 'hi';

    final normalized = (isoString.endsWith('Z') || isoString.contains('+'))
        ? isoString
        : '${isoString}Z';
    final dt = DateTime.tryParse(normalized)?.toLocal();
    if (dt == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return isHindi ? 'अभी' : 'Just now';
    if (diff.inMinutes < 60) {
      return isHindi ? '${diff.inMinutes} मिनट पहले' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24 && dt.day == now.day) {
      return isHindi ? '${diff.inHours} घंटे पहले' : '${diff.inHours}h ago';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return isHindi ? 'कल' : 'Yesterday';
    }
    if (diff.inDays < 7) {
      return isHindi ? '${diff.inDays} दिन पहले' : '${diff.inDays}d ago';
    }
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    return '$dd-$mm-${dt.year}';
  }
}

/// Small, type-differentiated leading icon for a Bell row — purely
/// cosmetic categorization (per this task's own "type/category
/// indication only if useful"), never used for routing/eligibility, and
/// falls back to a generic bell for any unrecognized/missing type (e.g.
/// a malformed payload) rather than crashing or guessing.
class _NotificationTypeIcon extends StatelessWidget {
  const _NotificationTypeIcon({required this.type, required this.isRead});

  final String? type;
  final bool isRead;

  static const Map<String, IconData> _iconByType = {
    'event': Icons.calendar_today_rounded,
    'transit': Icons.auto_awesome_rounded,
    'dasha': Icons.hourglass_bottom_rounded,
    'dasha_pre': Icons.hourglass_top_rounded,
    'panchang': Icons.wb_sunny_rounded,
    'panchak': Icons.warning_amber_rounded,
    'alert': Icons.bolt_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _iconByType[type] ?? Icons.notifications_rounded;
    final color = isRead ? Colors.grey.shade500 : const Color(0xFF6B21A8);

    return CircleAvatar(
      radius: 16,
      backgroundColor: color.withValues(alpha: 0.12),
      child: Icon(icon, size: 16, color: color),
    );
  }
}
