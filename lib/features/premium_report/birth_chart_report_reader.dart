import 'package:flutter/material.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/models/premium_reports/premium_ai_report_contracts.dart';
import 'package:jyotishasha_app/core/repositories/implementations/http_premium_ai_report_repository.dart';
import 'package:jyotishasha_app/core/repositories/premium_ai_report_repository.dart';
import 'package:jyotishasha_app/features/premium_report/premium_report_type.dart';
import 'package:jyotishasha_app/features/subscription/subscription_page.dart';

/// The single Premium Report screen — reached directly from Explore's
/// report cards, passing only a [PremiumReportType] (no backend id, no
/// pre-fetched report data). Replaces the previous two-screen flow
/// (Explore → PremiumReportLandingPage → BirthChartReportReader); the
/// landing page has been removed from navigation entirely, so this is
/// now the only screen a report card opens.
///
/// Content sourcing, per report:
/// - **Love**: the only segment with a registered backend generator
///   (`modules/ai_report_engine/generator_registry.py` only registers
///   `"LOVE"` — see [PremiumAiReportSegments]'s own doc comment). Its
///   free "Your Love DNA" section and the "Current Phase" premium
///   sub-section both call the existing, unmodified
///   [PremiumAiReportRepository] (`GET /api/premium-report`,
///   `report_type=DNA`/`CURRENT_PHASE`) — the exact same repository
///   `PremiumAiReportPage`/Account → "AI Love Insights" already uses.
/// - **Career / Finance / Health / Family**: no backend generator exists
///   for these segments yet (confirmed via the same generator registry
///   reference above) — calling them would 400 regardless of
///   entitlement. These continue to use the existing static content
///   already defined in [PremiumReportContent] (`about` — the same
///   per-type paragraph the now-removed landing page used) rather than
///   inventing new copy or a new backend call.
/// - "Current Timing" has no corresponding backend report type for any
///   segment (only `DNA`/`CURRENT_PHASE`/`DAILY_INSIGHT` exist) and
///   reuses the existing static Timeline content built for this screen
///   previously. "Next Change" likewise has no corresponding backend
///   field or prior static content anywhere in this codebase — rather
///   than invent copy for it, it shows an explicit "not available yet"
///   notice.
///
/// No backend, AI prompt, report-generation, subscription/entitlement,
/// or API logic is modified anywhere in this file — only consumed via
/// the repository interface exactly as it already existed.
class BirthChartReportReader extends StatefulWidget {
  const BirthChartReportReader({
    required this.type,
    super.key,
    PremiumAiReportRepository? repository,
  }) : _repository = repository;

  final PremiumReportType type;
  final PremiumAiReportRepository? _repository;

  @override
  State<BirthChartReportReader> createState() => _BirthChartReportReaderState();
}

class _BirthChartReportReaderState extends State<BirthChartReportReader> {
  static const Color _gold = Color(0xFFB8860B);

  late final PremiumAiReportRepository _repository =
      widget._repository ?? HttpPremiumAiReportRepository();

  /// Only Love has a registered backend generator today — see the class
  /// doc comment. Every other segment stays on existing static content.
  bool get _hasRealContent => widget.type == PremiumReportType.love;

  bool _dnaLoading = false;
  PremiumAiReportResult? _dnaResult;

  bool _phaseLoading = false;
  PremiumAiReportResult? _phaseResult;

  /// Deliberately NOT persisted anywhere (no provider field, no saved
  /// preference) — every fresh mount of this page starts collapsed, per
  /// spec: "DNA is mostly static... daily usage should naturally focus
  /// on the live sections below."
  bool _dnaExpanded = false;

  @override
  void initState() {
    super.initState();
    if (_hasRealContent) {
      // Deferred to after the first frame — `_loadDna`/`_loadCurrentPhase`
      // read `Localizations.localeOf(context)`, which Flutter forbids
      // depending on synchronously during initState (the dependency
      // wouldn't be tracked correctly). Same pattern already used
      // elsewhere in this app (e.g. `GreetingHeaderWidget`,
      // `WelcomeGiftPage`'s membership strip).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadDna();
        _loadCurrentPhase();
      });
    }
  }

  bool get _isHindi =>
      mounted && Localizations.localeOf(context).languageCode == 'hi';

  Future<void> _loadDna() async {
    setState(() => _dnaLoading = true);
    final isHindi = _isHindi;
    final result = await _repository.getReport(
      segment: PremiumAiReportSegments.love,
      reportType: PremiumAiReportTypes.dna,
      language: isHindi ? 'hi' : 'en',
    );
    if (!mounted) return;
    setState(() {
      _dnaResult = result;
      _dnaLoading = false;
    });
  }

  Future<void> _loadCurrentPhase() async {
    setState(() => _phaseLoading = true);
    final isHindi = _isHindi;
    final result = await _repository.getReport(
      segment: PremiumAiReportSegments.love,
      reportType: PremiumAiReportTypes.currentPhase,
      language: isHindi ? 'hi' : 'en',
    );
    if (!mounted) return;
    setState(() {
      _phaseResult = result;
      _phaseLoading = false;
    });
  }

  static String _shortName(PremiumReportType type, bool isHindi) => switch (type) {
    PremiumReportType.love => isHindi ? 'प्रेम' : 'Love',
    PremiumReportType.career => isHindi ? 'करियर' : 'Career',
    PremiumReportType.finance => isHindi ? 'वित्त' : 'Finance',
    PremiumReportType.health => isHindi ? 'स्वास्थ्य' : 'Health',
    PremiumReportType.family => isHindi ? 'परिवार' : 'Family',
  };

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    final content = widget.type.content;
    final shortName = _shortName(widget.type, isHindi);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F6),
        elevation: 0,
        foregroundColor: const Color(0xFF1F1B2E),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header — title + "Premium Report" badge, unchanged.
              _ReaderHeader(content: content, isHindi: isHindi, gold: _gold),
              const SizedBox(height: 26),

              // 2. FREE SECTION — "Your {X} DNA" / "Birth Chart Based".
              _SectionLabel(
                text: isHindi ? 'आपकी $shortName DNA' : 'Your $shortName DNA',
              ),
              const SizedBox(height: 3),
              Text(
                isHindi ? 'जन्म कुंडली आधारित' : 'Birth Chart Based',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 10),
              _FreeDnaSection(
                shortName: shortName,
                isHindi: isHindi,
                expanded: _dnaExpanded,
                onToggle: () => setState(() => _dnaExpanded = !_dnaExpanded),
                loading: _hasRealContent && _dnaLoading,
                result: _hasRealContent ? _dnaResult : null,
                fallbackText: content.about(isHindi),
                onRetry: _loadDna,
                gold: _gold,
              ),
              const SizedBox(height: 26),

              // 3. PREMIUM SECTION — "Current {X} Phase", with exactly
              // three sub-sections: Current Phase / Current Timing /
              // Next Change.
              _SectionLabel(
                text: isHindi
                    ? 'वर्तमान $shortName चरण'
                    : 'Current $shortName Phase',
              ),
              const SizedBox(height: 12),
              _PremiumSubsection(
                label: isHindi ? 'वर्तमान चरण' : 'Current Phase',
                loading: _hasRealContent && _phaseLoading,
                result: _hasRealContent ? _phaseResult : null,
                fallbackText: isHindi
                    ? 'यह एक स्थिर पूर्वावलोकन है। प्रीमियम मेंबरशिप इस सेक्शन को आपकी '
                        'वर्तमान ग्रह स्थिति के साथ लगातार अपडेट करती है।'
                    : 'This is a static preview. Premium Membership continuously '
                        'updates this section with your current planetary condition.',
                isHindi: isHindi,
                onRetry: _loadCurrentPhase,
                gold: _gold,
              ),
              const SizedBox(height: 12),
              _PremiumSubsection(
                label: isHindi ? 'वर्तमान समय' : 'Current Timing',
                loading: false,
                result: null,
                fallbackText: isHindi ? 'जन्म कुंडली आधार — वर्तमान' : 'Birth Chart Foundation — Current',
                isHindi: isHindi,
                onRetry: null,
                gold: _gold,
              ),
              const SizedBox(height: 12),
              _NextChangeSubsection(isHindi: isHindi),
              const SizedBox(height: 26),

              // 4. Subscription CTA — reuses the exact same navigation
              // every other "unlock premium" action in this app already
              // uses; no new payment/purchase flow.
              _SubscriptionCta(isHindi: isHindi),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header — Back (AppBar, wired automatically by Navigator), Report
/// Title, "Premium Report" badge. Unchanged from before.
class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader({required this.content, required this.isHindi, required this.gold});

  final PremiumReportContent content;
  final bool isHindi;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content.title(isHindi),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1B2E),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFCF1D6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium_rounded, size: 13, color: gold),
              const SizedBox(width: 6),
              Text(
                isHindi ? 'प्रीमियम रिपोर्ट' : 'Premium Report',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: gold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1F1B2E),
      ),
    );
  }
}

/// Renders one AI-report body: loading spinner, the backend's own
/// content on success, an entitlement notice when the backend denies
/// access, a retry notice for any other error, or — when [result] is
/// `null` (no backend call was ever made for this segment) — the
/// existing static [fallbackText].
Widget _aiBody({
  required bool loading,
  required PremiumAiReportResult? result,
  required String fallbackText,
  required bool isHindi,
  required VoidCallback? onRetry,
  int? maxLines,
}) {
  if (loading) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  const bodyStyle = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: Color(0xFF4B5563),
    height: 1.5,
  );

  if (result == null) {
    return Text(
      fallbackText,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: bodyStyle,
    );
  }

  if (result.isSuccess) {
    return Text(
      result.content ?? '',
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: bodyStyle,
    );
  }

  if (result.isEntitlementDenied) {
    return Text(
      isHindi
          ? 'इस सामग्री को देखने के लिए सदस्यता आवश्यक है। नीचे दिए गए बटन से सदस्यता प्लान देखें।'
          : 'A subscription is required to view this content. See the '
              'subscription button below.',
      style: bodyStyle.copyWith(color: const Color(0xFFB8860B), fontWeight: FontWeight.w600),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        result.errorMessage ??
            (isHindi
                ? 'सामग्री लोड करने में समस्या हुई।'
                : 'Something went wrong loading this content.'),
        style: bodyStyle,
      ),
      if (onRetry != null) ...[
        const SizedBox(height: 6),
        InkWell(
          onTap: onRetry,
          child: Text(
            isHindi ? 'पुनः प्रयास करें' : 'Retry',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    ],
  );
}

/// Section 2 — FREE SECTION card. Collapsed by default to ~5 lines with
/// a "Read Full {X} DNA →" toggle that expands the SAME card in place
/// (never a navigation, never a new screen) to "Show Less ↑". Expansion
/// state lives only in the parent State's field — never persisted.
class _FreeDnaSection extends StatelessWidget {
  const _FreeDnaSection({
    required this.shortName,
    required this.isHindi,
    required this.expanded,
    required this.onToggle,
    required this.loading,
    required this.result,
    required this.fallbackText,
    required this.onRetry,
    required this.gold,
  });

  final String shortName;
  final bool isHindi;
  final bool expanded;
  final VoidCallback onToggle;
  final bool loading;
  final PremiumAiReportResult? result;
  final String fallbackText;
  final VoidCallback onRetry;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    // Only offer the expand/collapse toggle once there's real readable
    // content on screen — not while loading, and not over an
    // error/entitlement notice.
    final currentResult = result;
    final canToggle = !loading && (currentResult == null || currentResult.isSuccess);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE4FB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _aiBody(
            loading: loading,
            result: result,
            fallbackText: fallbackText,
            isHindi: isHindi,
            onRetry: onRetry,
            maxLines: expanded ? null : 5,
          ),
          if (canToggle) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: onToggle,
              child: Text(
                expanded
                    ? (isHindi ? 'कम दिखाएं ↑' : 'Show Less ↑')
                    : (isHindi
                          ? 'पूरी $shortName DNA पढ़ें →'
                          : 'Read Full $shortName DNA →'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One PREMIUM SECTION sub-card — "Current Phase" / "Current Timing".
/// No expand/collapse (only the free DNA section has that per spec).
class _PremiumSubsection extends StatelessWidget {
  const _PremiumSubsection({
    required this.label,
    required this.loading,
    required this.result,
    required this.fallbackText,
    required this.isHindi,
    required this.onRetry,
    required this.gold,
  });

  final String label;
  final bool loading;
  final PremiumAiReportResult? result;
  final String fallbackText;
  final bool isHindi;
  final VoidCallback? onRetry;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE4FB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 15, color: gold),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F1B2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _aiBody(
            loading: loading,
            result: result,
            fallbackText: fallbackText,
            isHindi: isHindi,
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}

/// "Next Change" — no backend report type and no pre-existing static
/// content anywhere maps to this label for any of the 5 reports. Rather
/// than invent copy for it, this shows an explicit, honest
/// "not available yet" notice — the same spirit as this app's other
/// empty-state messages (e.g. `SubscriptionPage`'s "No subscription
/// information available yet.").
class _NextChangeSubsection extends StatelessWidget {
  const _NextChangeSubsection({required this.isHindi});

  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE4FB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHindi ? 'अगला बदलाव' : 'Next Change',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1B2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isHindi ? 'यह सेक्शन अभी उपलब्ध नहीं है।' : "This section isn't available yet.",
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

/// 4. Subscription CTA — pushes the existing [SubscriptionPage], the
/// exact same navigation every other "unlock premium" action in this
/// app already uses (`premium_gate.dart`'s `requirePremium`, Explore's
/// membership strip, `_PremiumAiReportContentPage`'s Subscribe button).
/// No new purchase/payment UI.
class _SubscriptionCta extends StatelessWidget {
  const _SubscriptionCta({required this.isHindi});

  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionPage()),
        ),
        icon: const Icon(Icons.workspace_premium_rounded, size: 18),
        label: Text(
          isHindi ? 'सदस्यता प्लान देखें' : 'View Subscription Plans',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
