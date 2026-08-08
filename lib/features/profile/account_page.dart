// lib/features/profile/account_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:jyotishasha_app/core/messaging/fcm_token_manager.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/state/subscription_provider.dart';
import 'package:jyotishasha_app/core/utils/premium_gate.dart';
import 'package:jyotishasha_app/features/premium_reports/premium_ai_report_page.dart';
import 'package:jyotishasha_app/features/reports/pages/report_catalog_page.dart';
import 'package:jyotishasha_app/features/subscription/subscription_page.dart';

/// The single-user "Account" experience replacing the old multi-profile
/// [ProfilePage] on the bottom nav. The multi-profile UI (add/switch/edit/
/// delete other profiles) is intentionally NOT rebuilt here — it still
/// exists in `profile_page.dart` and friends, just no longer reachable from
/// the bottom nav.
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProfileProvider>().loadProfiles();

      // Same provider may already be populated (e.g. the user already
      // visited SubscriptionPage this session) — avoid an unnecessary
      // duplicate fetch, matching KundaliOverviewPage's identical guard.
      final subscription = context.read<SubscriptionProvider>();
      if (subscription.subscriptionData == null && !subscription.isLoading) {
        subscription.loadSubscriptionInfo();
      }
    });
  }

  void _openPremiumReports() {
    requirePremium(context, () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReportCatalogPage()),
      );
    });
  }

  /// S5.X — always navigates to [SubscriptionPage], regardless of
  /// current status. Previously the only way in was [_openPremiumReports]
  /// via `requirePremium`'s fallback, which only fires when the user is
  /// NOT already subscribed — an already-subscribed user had no way
  /// back into the subscription screen at all.
  void _openSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionPage()),
    );
  }

  /// S5.X — entry point for the entitlement-gated AI Love Insights
  /// reports (`GET /api/premium-report`, segment LOVE). Same
  /// `requirePremium` gate as [_openPremiumReports] — trial counts as
  /// premium here too, matching the backend's own trial-grants-all-
  /// segments behavior.
  void _openAiLoveInsights() {
    requirePremium(context, () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumAiReportPage()),
      );
    });
  }

  // Ported verbatim from the old ProfilePage's logout flow — this is
  // existing, already-working auth logic, not a new feature.
  Future<void> _logout() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Logout Successfully"),
        duration: Duration(milliseconds: 800),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 600));

    try {
      await fcmTokenManager.clearOnLogout();
    } catch (_) {}

    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
  }

  void _showComingSoon(bool isHindi) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isHindi ? 'जल्द आ रहा है' : 'Coming Soon'),
        duration: const Duration(seconds: 1),
      ),
    );
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

  String _zodiacSlug(String? sign) {
    if (sign == null || sign.isEmpty) return 'leo';
    return _zodiacSlugByKey[sign.toLowerCase().trim()] ?? 'leo';
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    final provider = context.watch<ProfileProvider>();
    final profile = provider.activeProfile ?? const {};
    final subscriptionData = context.watch<SubscriptionProvider>()
        .subscriptionData;

    final name = (profile["name"] ?? "").toString().trim();
    final displayName = name.isEmpty ? (isHindi ? "अतिथि" : "Guest") : name;
    final dob = (profile["dob"] ?? "").toString();
    final pob = (profile["pob"] ?? "").toString();
    final moonSign = profile["moon_sign"]?.toString();
    final lagna = profile["lagna"]?.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F9),
      body: SafeArea(
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi ? 'अकाउंट' : 'Account',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildTopCard(
                      isHindi,
                      displayName,
                      dob,
                      pob,
                      moonSign,
                      lagna,
                    ),
                    const SizedBox(height: 16),
                    _buildSubscriptionCard(isHindi, subscriptionData),
                    const SizedBox(height: 10),
                    _AccountActionRow(
                      icon: Icons.workspace_premium_outlined,
                      title: isHindi
                          ? 'सदस्यता प्रबंधित करें'
                          : 'Manage Subscription',
                      onTap: _openSubscription,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isHindi ? 'सेवाएं' : 'Services',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _AccountActionRow(
                      icon: Icons.picture_as_pdf_outlined,
                      title: isHindi
                          ? 'मुफ़्त राशिफल PDF'
                          : 'Free Horoscope PDF',
                      onTap: () => _showComingSoon(isHindi),
                    ),
                    const SizedBox(height: 10),
                    _AccountActionRow(
                      icon: Icons.description_outlined,
                      title: isHindi ? 'प्रीमियम रिपोर्ट्स' : 'Premium Reports',
                      onTap: _openPremiumReports,
                    ),
                    const SizedBox(height: 10),
                    _AccountActionRow(
                      icon: Icons.favorite_outline_rounded,
                      title: isHindi ? 'एआई लव इनसाइट्स' : 'AI Love Insights',
                      onTap: _openAiLoveInsights,
                    ),
                    const SizedBox(height: 10),
                    _AccountActionRow(
                      icon: Icons.download_outlined,
                      title: isHindi ? 'डाउनलोड्स' : 'Downloads',
                      onTap: () => _showComingSoon(isHindi),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isHindi ? 'सामान्य' : 'General',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _AccountActionRow(
                      icon: Icons.settings_outlined,
                      title: isHindi ? 'सेटिंग्स' : 'Settings',
                      onTap: () => _showComingSoon(isHindi),
                    ),
                    const SizedBox(height: 10),
                    _AccountActionRow(
                      icon: Icons.help_outline_rounded,
                      title: isHindi ? 'सहायता व समर्थन' : 'Help & Support',
                      onTap: () => _showComingSoon(isHindi),
                    ),
                    const SizedBox(height: 10),
                    _AccountActionRow(
                      icon: Icons.logout_rounded,
                      title: isHindi ? 'लॉगआउट' : 'Logout',
                      iconColor: const Color(0xFFDC2626),
                      titleColor: const Color(0xFFDC2626),
                      onTap: _logout,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTopCard(
    bool isHindi,
    String name,
    String dob,
    String pob,
    String? moonSign,
    String? lagna,
  ) {
    final birthDetails = [
      dob,
      pob,
    ].where((s) => s.trim().isNotEmpty).join('  •  ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDEDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFF3F1FF),
                backgroundImage: AssetImage(
                  'assets/zodiac/${_zodiacSlug(moonSign)}.webp',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (birthDetails.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        birthDetails,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (moonSign != null || lagna != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (moonSign != null)
                  Expanded(
                    child: _birthDetailChip(
                      isHindi ? 'चंद्र राशि' : 'Moon Sign',
                      moonSign,
                    ),
                  ),
                if (moonSign != null && lagna != null)
                  const SizedBox(width: 10),
                if (lagna != null)
                  Expanded(
                    child: _birthDetailChip(isHindi ? 'लग्न' : 'Lagna', lagna),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _birthDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  /// S5.3 — reads the live `SubscriptionProvider.subscriptionData`
  /// (`GET /api/profile/subscription-info`) instead of the previous
  /// hardcoded "Free User" placeholder. The backend's own `plan`/`status`
  /// strings are shown as-is (only capitalized for display, matching
  /// `SubscriptionPage`'s exact convention) — never inferred, never
  /// recomputed. While `data` is `null` (not loaded yet, or the load
  /// failed) this shows a neutral "-" rather than assuming Free/Premium.
  Widget _buildSubscriptionCard(bool isHindi, Map<String, dynamic>? data) {
    final plan = (data?['plan']?.toString().trim().isNotEmpty ?? false)
        ? data!['plan'].toString()
        : '-';
    final rawStatus = data?['status']?.toString().trim();
    final status = (rawStatus == null || rawStatus.isEmpty)
        ? '-'
        : rawStatus[0].toUpperCase() + rawStatus.substring(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF3F1FF),
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              size: 18,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? 'सदस्यता' : 'Subscription',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  plan == '-' ? status : '$plan • $status',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
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

class _AccountActionRow extends StatelessWidget {
  const _AccountActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor = const Color(0xFF4F46E5),
    this.titleColor = const Color(0xFF111827),
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEDEDF2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.1),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: Color(0xFFBBBBBB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
