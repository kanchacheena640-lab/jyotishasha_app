// lib/features/premium_reports/premium_ai_report_page.dart

import 'package:flutter/material.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/models/premium_reports/premium_ai_report_contracts.dart';
import 'package:jyotishasha_app/core/repositories/implementations/http_premium_ai_report_repository.dart';
import 'package:jyotishasha_app/core/repositories/premium_ai_report_repository.dart';
import 'package:jyotishasha_app/features/subscription/subscription_page.dart';

/// S5.X — minimal client for the entitlement-gated AI Premium Report
/// engine (`GET /api/premium-report`). Segment `LOVE` only: the only
/// segment with a registered generator server-side (see
/// `PremiumAiReportSegments`'s doc comment) — `CAREER`/`FINANCE`/
/// `HEALTH`/`FAMILY`/`ALERTS` have no generator yet and would 400
/// regardless of subscription, so this page does not offer them.
///
/// Distinct from `ReportCatalogPage`/`report_payment_page.dart` — that
/// is the pre-existing, unrelated one-off `reports51` IAP flow
/// (ESR-023) and is untouched by this feature.
class PremiumAiReportPage extends StatelessWidget {
  const PremiumAiReportPage({super.key});

  static const _reportTypes = [
    (
      type: PremiumAiReportTypes.dna,
      titleEn: 'Love DNA',
      titleHi: 'लव डीएनए',
      subtitleEn: 'Your core relationship blueprint',
      subtitleHi: 'आपका मूल रिश्ता खाका',
    ),
    (
      type: PremiumAiReportTypes.currentPhase,
      titleEn: 'Current Phase',
      titleHi: 'वर्तमान चरण',
      subtitleEn: 'Where your love life stands right now',
      subtitleHi: 'अभी आपका प्रेम जीवन कहाँ खड़ा है',
    ),
    (
      type: PremiumAiReportTypes.dailyInsight,
      titleEn: 'Daily Insight',
      titleHi: 'दैनिक जानकारी',
      subtitleEn: "Today's love guidance",
      subtitleHi: 'आज का प्रेम मार्गदर्शन',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: const Color(0xFF1F1B2E),
        title: Text(
          isHindi ? 'एआई लव इनसाइट्स' : 'AI Love Insights',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final report in _reportTypes) ...[
              _ReportTypeTile(
                title: isHindi ? report.titleHi : report.titleEn,
                subtitle: isHindi ? report.subtitleHi : report.subtitleEn,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _PremiumAiReportContentPage(
                      reportType: report.type,
                      title: isHindi ? report.titleHi : report.titleEn,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportTypeTile extends StatelessWidget {
  const _ReportTypeTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4D9FA)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F1B2E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
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

/// Fetches and displays one segment/report-type's content. Loading →
/// content-or-error, exactly the pattern `SubscriptionPage`/
/// `KundaliOverviewPage` already use elsewhere in this app.
class _PremiumAiReportContentPage extends StatefulWidget {
  const _PremiumAiReportContentPage({
    required this.reportType,
    required this.title,
    PremiumAiReportRepository? repository,
  }) : _repository = repository;

  final String reportType;
  final String title;
  final PremiumAiReportRepository? _repository;

  @override
  State<_PremiumAiReportContentPage> createState() =>
      _PremiumAiReportContentPageState();
}

class _PremiumAiReportContentPageState
    extends State<_PremiumAiReportContentPage> {
  late final PremiumAiReportRepository _repository =
      widget._repository ?? HttpPremiumAiReportRepository();

  bool _isLoading = true;
  PremiumAiReportResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final isHindi =
        mounted && Localizations.localeOf(context).languageCode == 'hi';
    final result = await _repository.getReport(
      segment: PremiumAiReportSegments.love,
      reportType: widget.reportType,
      language: isHindi ? 'hi' : 'en',
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1F1B2E),
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(child: _buildBody(isHindi)),
    );
  }

  Widget _buildBody(bool isHindi) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final result = _result;
    if (result == null || !result.isSuccess) {
      return _buildError(result, isHindi);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Text(
        result.content ?? '',
        style: const TextStyle(
          fontSize: 15,
          height: 1.6,
          color: Color(0xFF1F1B2E),
        ),
      ),
    );
  }

  Widget _buildError(PremiumAiReportResult? result, bool isHindi) {
    final isEntitlementDenied = result?.isEntitlementDenied ?? false;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEntitlementDenied
                  ? Icons.workspace_premium_outlined
                  : Icons.error_outline_rounded,
              size: 40,
              color: const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 12),
            Text(
              // Backend's own message verbatim — this client never
              // rewrites the reason a report couldn't be shown.
              result?.errorMessage ??
                  (isHindi
                      ? 'रिपोर्ट लोड करने में समस्या हुई।'
                      : 'Something went wrong loading this report.'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 16),
            if (isEntitlementDenied)
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscriptionPage()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(isHindi ? 'सब्सक्राइब करें' : 'Subscribe'),
              )
            else
              OutlinedButton(
                onPressed: _load,
                child: Text(isHindi ? 'पुनः प्रयास करें' : 'Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
