import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/welcome_gift_provider.dart';
import 'package:jyotishasha_app/features/explore/explore_page.dart';

/// New, standalone screen for the Welcome Gift onboarding flow (not a
/// reuse of any existing screen). Shown when the Home Hero's Welcome Gift
/// card is tapped.
///
/// Redesigned for a premium onboarding presentation — layout/styling only;
/// the claim behavior is unchanged (still a simulated local claim, see
/// [WelcomeGiftProvider.claim] for where real backend integration will
/// attach later) and navigation is unchanged (Claim → Explore).
class WelcomeGiftPage extends StatelessWidget {
  const WelcomeGiftPage({super.key});

  /// Soft gold accent used only on this screen, alongside the app's
  /// existing purple [AppColors.primary] — "premium white / gold
  /// styling" per spec.
  static const Color _gold = Color(0xFFB8860B);
  static const Color _goldTint = Color(0xFFFCF1D6);

  static const List<_GiftReport> _reports = [
    _GiftReport(emoji: '❤️', titleEn: 'Love Report', titleHi: 'प्रेम रिपोर्ट'),
    _GiftReport(emoji: '💼', titleEn: 'Career Report', titleHi: 'करियर रिपोर्ट'),
    _GiftReport(emoji: '💰', titleEn: 'Finance Report', titleHi: 'वित्त रिपोर्ट'),
    _GiftReport(emoji: '🌿', titleEn: 'Health Report', titleHi: 'स्वास्थ्य रिपोर्ट'),
    _GiftReport(
      emoji: '👨‍👩‍👧',
      titleEn: 'Family Report',
      titleHi: 'परिवार रिपोर्ट',
    ),
  ];

  Future<void> _handleClaim(BuildContext context) async {
    final provider = context.read<WelcomeGiftProvider>();

    // Unchanged temporary behavior: simulate successful activation + mark
    // claimed only. No report generation, no subscription activation, no
    // backend call — see WelcomeGiftProvider.claim().
    await provider.claim();

    if (!context.mounted) return;

    // Unchanged navigation: replaces this screen so the back stack
    // returns to Home, not back into the Welcome Gift screen.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ExplorePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = context.watch<LanguageProvider>().currentLang == 'hi';
    final isClaiming = context.watch<WelcomeGiftProvider>().isClaiming;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F6),
        elevation: 0,
        foregroundColor: const Color(0xFF1F1B2E),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(isHindi: isHindi, gold: _gold, goldTint: _goldTint),
                    const SizedBox(height: 28),
                    _SectionLabel(
                      text: isHindi ? 'प्रीमियम रिपोर्ट' : 'Premium Reports',
                    ),
                    const SizedBox(height: 12),
                    for (final report in _reports) ...[
                      _ReportCard(
                        report: report,
                        isHindi: isHindi,
                        gold: _gold,
                        goldTint: _goldTint,
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 12),
                    _MembershipCard(isHindi: isHindi, gold: _gold),
                  ],
                ),
              ),
            ),
            _ClaimButton(
              isClaiming: isClaiming,
              isHindi: isHindi,
              onClaim: () => _handleClaim(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// "🎁 Welcome Gift" + "Unlock your personalized astrology experience."
class _Header extends StatelessWidget {
  const _Header({required this.isHindi, required this.gold, required this.goldTint});

  final bool isHindi;
  final Color gold;
  final Color goldTint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: goldTint,
            shape: BoxShape.circle,
          ),
          child: const Text('🎁', style: TextStyle(fontSize: 28)),
        ),
        const SizedBox(height: 14),
        Text(
          isHindi ? 'वेलकम गिफ्ट' : 'Welcome Gift',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1B2E),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isHindi
              ? 'अपना पर्सनलाइज़्ड ज्योतिष अनुभव अनलॉक करें।'
              : 'Unlock your personalized astrology experience.',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Small uppercase eyebrow label used to organize the reports section
/// without reading as a marketing banner.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFF9CA3AF),
        letterSpacing: 1.0,
      ),
    );
  }
}

class _GiftReport {
  const _GiftReport({
    required this.emoji,
    required this.titleEn,
    required this.titleHi,
  });

  final String emoji;
  final String titleEn;
  final String titleHi;
}

/// A premium report card — an emoji badge, the report name, a "Premium
/// Report · Birth Chart Based" caption carrying a small gold premium
/// icon, and a trailing arrow. Deliberately heavier and more visual than
/// a settings-style list row (larger badge, generous padding, soft
/// shadow) per spec ("should look premium, not like settings tiles").
/// Not tappable — purely presentational, matching the original spec's
/// "no navigation" for these cards; the arrow is a premium affordance
/// cue, not a control.
class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.isHindi,
    required this.gold,
    required this.goldTint,
  });

  final _GiftReport report;
  final bool isHindi;
  final Color gold;
  final Color goldTint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFE6D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(report.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? report.titleHi : report.titleEn,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1B2E),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, size: 13, color: gold),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        isHindi
                            ? 'प्रीमियम रिपोर्ट · जन्म कुंडली आधारित'
                            : 'Premium Report · Birth Chart Based',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Color(0xFFC4B5D6),
          ),
        ],
      ),
    );
  }
}

/// "7 Days Premium Membership" + description — no countdown, no pricing.
class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.isHindi, required this.gold});

  final bool isHindi;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFF3E8FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4D9FA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEFE6D8)),
            ),
            child: Icon(Icons.auto_awesome_rounded, size: 20, color: gold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi
                      ? '7 दिनों की प्रीमियम मेंबरशिप'
                      : '7 Days Premium Membership',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1B2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isHindi
                      ? 'सभी सेक्शन के लिए वर्तमान ग्रह अपडेट प्राप्त करें।'
                      : 'Access current planetary updates for all sections.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                    height: 1.4,
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

class _ClaimButton extends StatelessWidget {
  const _ClaimButton({
    required this.isClaiming,
    required this.isHindi,
    required this.onClaim,
  });

  final bool isClaiming;
  final bool isHindi;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2)),
        ],
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: isClaiming ? null : onClaim,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: isClaiming
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  isHindi ? 'फ्री एक्सेस पाएं' : 'Claim Free Access',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
