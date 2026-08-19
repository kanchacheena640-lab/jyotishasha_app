import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/subscription_provider.dart';
import 'package:jyotishasha_app/core/utils/trial_countdown.dart';
import 'package:jyotishasha_app/features/alerts/alerts_dashboard_page.dart';
import 'package:jyotishasha_app/features/premium_report/birth_chart_report_reader.dart';
import 'package:jyotishasha_app/features/premium_report/premium_report_type.dart';
import 'package:jyotishasha_app/features/subscription/subscription_page.dart';

/// "Explore" bottom-nav tab, redesigned into a Premium Reports Hub —
/// UI/styling only. Six large report cards, a compact (non-banner)
/// membership strip, and a static "Current Planetary Condition" line per
/// card. Still no backend, no report generation, no pricing, no locks —
/// every report card value on this screen remains temporary/static.
///
/// The membership strip (`_MembershipStrip`) is the one part of this
/// screen wired to something real: it reads the existing
/// [SubscriptionProvider] and reuses the existing [SubscriptionPage] —
/// no new provider, no new billing/entitlement logic, no new Plans page.
///
/// Every Premium Report card (Love, Career, Finance, Health, Family)
/// opens [BirthChartReportReader] directly, passing only its local
/// [PremiumReportType] — no backend id. The former intermediate landing
/// page has been removed from the navigation flow entirely (simplified
/// per spec: Explore → report, one screen, no detour). Alerts is not one
/// of the 5 Premium Reports (see [PremiumReportType]) — it is not an
/// AI-generated report at all — so it opens the separate
/// [AlertsDashboardPage] instead, navigated to unconditionally exactly
/// like every other card here. The entitlement decision (was Alerts
/// this profile's entitled/selected section) is never made on this
/// page — it is the backend's own `GET /api/alerts/current` call,
/// surfaced inside [AlertsDashboardPage] itself exactly like
/// [BirthChartReportReader] already surfaces its own per-segment denial
/// via its locked-section UI, reusing the same [SubscriptionPage].
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  static const List<_ExploreCategory> _categories = [
    _ExploreCategory(
      icon: Icons.favorite_rounded,
      titleEn: 'Love',
      titleHi: 'प्रेम',
      reportType: PremiumReportType.love,
    ),
    _ExploreCategory(
      icon: Icons.work_rounded,
      titleEn: 'Career',
      titleHi: 'करियर',
      reportType: PremiumReportType.career,
    ),
    _ExploreCategory(
      icon: Icons.account_balance_wallet_rounded,
      titleEn: 'Finance',
      titleHi: 'वित्त',
      reportType: PremiumReportType.finance,
    ),
    _ExploreCategory(
      icon: Icons.spa_rounded,
      titleEn: 'Health',
      titleHi: 'स्वास्थ्य',
      reportType: PremiumReportType.health,
    ),
    _ExploreCategory(
      icon: Icons.groups_rounded,
      titleEn: 'Family',
      titleHi: 'परिवार',
      reportType: PremiumReportType.family,
    ),
    _ExploreCategory(
      icon: Icons.notifications_active_rounded,
      titleEn: 'Alerts',
      titleHi: 'अलर्ट',
      reportType: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isHindi ? 'एक्सप्लोर' : 'Explore',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 14),
              _MembershipStrip(isHindi: isHindi),
              _TrialActivationCard(isHindi: isHindi),
              const SizedBox(height: 20),
              for (final category in _categories) ...[
                _ReportHubCard(category: category, isHindi: isHindi),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact membership strip — a single slim row, not a hero banner.
///
/// Reads the existing [SubscriptionProvider] (no new provider) and shows
/// exactly what the backend's `GET /api/profile/subscription-info`
/// already returns, using the same fields/precedence
/// `AccountPage`/`SubscriptionPage` already read
/// (`is_trial`/`active`/`is_active`/`in_grace_period`/`plan`/`status`) —
/// never a client-computed or invented state. Tapping always opens the
/// existing [SubscriptionPage] — the one and only Plans/Manage-Membership
/// screen in the app — regardless of the current state, per spec.
class _MembershipStrip extends StatefulWidget {
  const _MembershipStrip({required this.isHindi});

  final bool isHindi;

  @override
  State<_MembershipStrip> createState() => _MembershipStripState();
}

class _MembershipStripState extends State<_MembershipStrip> {
  @override
  void initState() {
    super.initState();
    // Same "load only if not already loaded/loading" guard AccountPage's
    // initState already uses — avoids a duplicate fetch if the user
    // already visited Account/SubscriptionPage this session.
    Future.microtask(() {
      if (!mounted) return;
      final provider = context.read<SubscriptionProvider>();
      if (provider.subscriptionData == null && !provider.isLoading) {
        provider.loadSubscriptionInfo();
      }
    });
  }

  /// Backend's own `plan` string (e.g. `"GOLD_YEARLY"`) formatted for
  /// display only — same idea as `SubscriptionPage`'s status
  /// capitalization, extended to underscore-separated values. Never
  /// translated: like `_SubscriptionInfoCard`'s plan row, the backend's
  /// plan name is shown as-is in both languages.
  String _formatPlan(String raw) {
    final words = raw
        .trim()
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty);
    return words
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  /// The one place this widget decides what text to show — every branch
  /// reads a field [SubscriptionPage]/`premium_gate.dart` already reads
  /// elsewhere; nothing here is a new subscription state.
  String _resolveState(Map<String, dynamic>? data, bool isHindi) {
    if (data == null) {
      return isHindi ? 'सदस्यता देखें' : 'View Membership';
    }

    final isTrial = data['is_trial'] == true;
    final isActive = data['active'] == true || data['is_active'] == true;
    final inGracePeriod = data['in_grace_period'] == true;

    if (inGracePeriod) {
      return isHindi ? 'ग्रेस पीरियड' : 'Grace Period';
    }
    if (isActive && isTrial) {
      // Manual Trial Activation copy: "Premium Trial Active" (was
      // "Trial Active") — the remaining-days countdown itself is a
      // separate line below, reusing TrialCountdown, not appended here.
      return isHindi ? 'प्रीमियम ट्रायल सक्रिय' : 'Premium Trial Active';
    }
    if (isActive) {
      final plan = data['plan']?.toString().trim();
      if (plan != null && plan.isNotEmpty) return _formatPlan(plan);
      return isHindi ? 'सक्रिय' : 'Active';
    }

    final status = data['status']?.toString().trim().toLowerCase();
    if (status == 'expired') {
      return isHindi ? 'समाप्त' : 'Expired';
    }
    return isHindi ? 'कोई सदस्यता नहीं' : 'No Subscription';
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = widget.isHindi;
    final provider = context.watch<SubscriptionProvider>();
    final data = provider.subscriptionData;
    final isLoading = provider.isLoading && data == null;

    // AFTER ACTIVATION: "Premium Trial Active" / "X Days Remaining" —
    // reuses the existing TrialCountdown mechanism (same one
    // account_page.dart already uses) rather than a new countdown
    // implementation. Backend's own `remaining_days`, verbatim.
    final isTrialActive = (data?['is_trial'] == true) &&
        (data?['active'] == true || data?['is_active'] == true);
    final remainingDays = data?['remaining_days'];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          // Every state — active, expired, or no subscription — opens
          // the same existing SubscriptionPage. No new Plans page.
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubscriptionPage()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEFE6D8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFCF1D6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      size: 15,
                      color: Color(0xFFB8860B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isHindi ? 'सदस्यता' : 'Membership',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F1B2E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _resolveState(data, isHindi),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B21A8),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFFC4B5D6),
                  ),
                ],
              ),
              if (isTrialActive && remainingDays != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Text(
                    TrialCountdown.label(remainingDays, isHindi),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: TrialCountdown.colorFor(remainingDays),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Manual Trial Activation — the prominent card offering the 7-day
/// free trial, shown ABOVE the 6 premium sections. Reads only
/// [SubscriptionProvider]'s existing `subscriptionData`/
/// `trialAvailable` (no new provider, no local trial state machine —
/// entitlement eligibility comes entirely from the backend, per this
/// task's own explicit constraint). Renders nothing at all — not even
/// empty space — whenever the profile isn't eligible: already on
/// TRIAL/ACTIVE/GRACE_PERIOD, already used its trial, or
/// `subscriptionData` hasn't loaded yet (defaults to `trialAvailable
/// == false`, so this card simply doesn't flash on first paint before
/// the real answer arrives).
class _TrialActivationCard extends StatelessWidget {
  const _TrialActivationCard({required this.isHindi});

  final bool isHindi;

  String _errorText(String? reason, bool isHindi) {
    switch (reason) {
      case "already_subscribed":
        return isHindi
            ? 'आपकी पहले से सक्रिय सदस्यता है।'
            : 'You already have an active subscription.';
      case "trial_already_used":
        return isHindi
            ? 'आप पहले ही अपना फ्री ट्रायल इस्तेमाल कर चुके हैं।'
            : "You've already used your free trial.";
      case "no_profile":
        return isHindi
            ? 'प्रोफ़ाइल अभी तैयार नहीं है। कृपया थोड़ी देर बाद फिर कोशिश करें।'
            : 'Profile not ready yet. Please try again shortly.';
      case "auth_failed":
        return isHindi
            ? 'प्रमाणीकरण विफल रहा। कृपया पुनः प्रयास करें।'
            : 'Unable to authenticate. Please try again.';
      case "network_error":
        return isHindi
            ? 'नेटवर्क त्रुटि। कृपया पुनः प्रयास करें।'
            : 'Network error. Please try again.';
      default:
        return isHindi
            ? 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।'
            : 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubscriptionProvider>();
    final membershipState = provider.subscriptionData?['membership_state']
        ?.toString()
        .toUpperCase();
    final eligible = provider.trialAvailable &&
        membershipState != 'TRIAL' &&
        membershipState != 'ACTIVE' &&
        membershipState != 'GRACE_PERIOD';

    if (!eligible) return const SizedBox.shrink();

    final isActivating = provider.isActivatingTrial;
    final error = provider.activateTrialErrorMessage;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6B21A8), Color(0xFF9333EA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B21A8).withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isHindi
                        ? 'आपका 7-दिन का प्रीमियम गिफ्ट तैयार है'
                        : 'Your 7-Day Premium Gift is Ready',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isHindi
                  ? '7 दिनों के लिए सभी प्रीमियम सेक्शन मुफ्त अनलॉक करें।'
                  : 'Unlock all premium sections free for 7 days.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorText(error, isHindi),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFEE2E2),
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: isActivating
                    ? null
                    : () => context.read<SubscriptionProvider>().activateTrial(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6B21A8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isActivating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF6B21A8),
                        ),
                      )
                    : Text(
                        isHindi ? 'फ्री एक्सेस पाएं' : 'Activate Free Access',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreCategory {
  const _ExploreCategory({
    required this.icon,
    required this.titleEn,
    required this.titleHi,
    required this.reportType,
  });

  final IconData icon;
  final String titleEn;
  final String titleHi;

  /// Null only for Alerts — not one of the 5 Premium Reports, so it has
  /// no [BirthChartReportReader] destination; [_ReportHubCard] routes it
  /// to [AlertsDashboardPage] instead (see that field's own check below).
  final PremiumReportType? reportType;
}

/// A large, premium-styled report card — a personalized report hub tile,
/// not a marketing teaser. Shows the category title, the static "Current
/// Planetary Condition" line beneath it, a "Premium Report · Birth Chart
/// Based" caption, and a trailing arrow.
///
/// For the 5 Premium Report categories (`category.reportType != null`),
/// tapping opens [BirthChartReportReader] directly with that type — no
/// intermediate landing page, no backend id passed. Alerts
/// (`reportType == null`, the only category with no [PremiumReportType])
/// opens [AlertsDashboardPage] instead, unconditionally, the same way
/// every other card here navigates — [AlertsDashboardPage] itself shows
/// the existing subscription/paywall UX when the backend says this
/// profile isn't entitled, no second/bespoke paywall.
class _ReportHubCard extends StatelessWidget {
  const _ReportHubCard({required this.category, required this.isHindi});

  final _ExploreCategory category;
  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    final title = isHindi ? category.titleHi : category.titleEn;
    final reportType = category.reportType;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: reportType == null
            ? () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlertsDashboardPage()),
              )
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BirthChartReportReader(type: reportType),
                  ),
                );
              },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEDE4FB)),
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
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(category.icon, size: 24, color: const Color(0xFF6B21A8)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isHindi ? 'वर्तमान ग्रह स्थिति' : 'Current Planetary Condition',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium_rounded,
                          size: 13,
                          color: Color(0xFFB8860B),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            isHindi
                                ? 'प्रीमियम रिपोर्ट · जन्म कुंडली आधारित'
                                : 'Premium Report · Birth Chart Based',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B21A8),
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
        ),
      ),
    );
  }
}
