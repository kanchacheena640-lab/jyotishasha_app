import 'package:flutter/material.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/models/alerts/alerts_dashboard_contracts.dart';
import 'package:jyotishasha_app/core/repositories/alerts_dashboard_repository.dart';
import 'package:jyotishasha_app/core/repositories/implementations/http_alerts_dashboard_repository.dart';
import 'package:jyotishasha_app/core/sharing/share_service.dart';
import 'package:jyotishasha_app/features/subscription/subscription_page.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

/// "Alerts & Opportunities" — the sixth premium subscription section
/// (see `modules/entitlement/subscription_sections.py` in the backend
/// repo). A focused, self-contained screen: loading, current alert(s)
/// (strongest first, at most 2 -- the backend's existing hardened
/// Alerts Engine selection, never re-decided here), a reassuring
/// zero-current-alerts state, a locked state reusing the existing
/// subscription/paywall UX, and an error+retry state.
///
/// Never fetches or displays raw detected candidates -- only whatever
/// `GET /api/alerts/current` itself already narrowed to. Never renders
/// an internal technical name (event_id, confidence, detection state) --
/// only the deterministic, catalog-driven title/message the backend
/// already built.
class AlertsDashboardPage extends StatefulWidget {
  const AlertsDashboardPage({super.key, AlertsDashboardRepository? repository})
    : _repository = repository;

  final AlertsDashboardRepository? _repository;

  @override
  State<AlertsDashboardPage> createState() => _AlertsDashboardPageState();
}

class _AlertsDashboardPageState extends State<AlertsDashboardPage> {
  late final AlertsDashboardRepository _repository =
      widget._repository ?? HttpAlertsDashboardRepository();

  Future<AlertsDashboardResult>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = _repository.getCurrentAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F9),
        elevation: 0,
        foregroundColor: const Color(0xFF111827),
        title: Text(
          isHindi ? 'अलर्ट और अवसर' : 'Alerts & Opportunities',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        actions: [
          IconButton(
            tooltip: isHindi ? 'ताज़ा करें' : 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _load();
            await _future;
          },
          child: FutureBuilder<AlertsDashboardResult>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return _LoadingState(isHindi: isHindi);
              }

              final result = snapshot.data;
              if (result == null) {
                return _ErrorState(isHindi: isHindi, onRetry: _load);
              }

              if (result.isLocked) {
                return _LockedState(isHindi: isHindi);
              }

              if (!result.isSuccess) {
                return _ErrorState(isHindi: isHindi, onRetry: _load);
              }

              if (result.alerts.isEmpty) {
                return _EmptyState(isHindi: isHindi);
              }

              return _AlertsList(alerts: result.alerts, isHindi: isHindi);
            },
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.isHindi});

  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.isHindi, required this.onRetry});

  final bool isHindi;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
        Icon(
          Icons.cloud_off_rounded,
          size: 40,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 14),
        Text(
          isHindi
              ? 'अभी आपके अलर्ट लोड नहीं हो सके। कृपया पुनः प्रयास करें।'
              : 'Unable to load your alerts right now. Please try again.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(isHindi ? 'पुनः प्रयास करें' : 'Try Again'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

/// Reused subscription/paywall UX -- same shape as
/// `BirthChartReportReader`'s own `_PremiumLockedSection` /
/// `_SubscriptionCta` (lock icon, "Unlock with Premium Membership",
/// existing `SubscriptionPage`) rather than a second, bespoke paywall.
class _LockedState extends StatelessWidget {
  const _LockedState({required this.isHindi});

  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.16),
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFFCF1D6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_rounded,
            size: 28,
            color: Color(0xFFB8860B),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          isHindi
              ? 'अलर्ट और अवसर आपकी वर्तमान योजना में शामिल नहीं है'
              : 'Alerts & Opportunities is not included in your current plan',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1B2E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isHindi
              ? 'प्रीमियम मेंबरशिप के साथ अनलॉक करें'
              : 'Unlock with Premium Membership',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFFB8860B),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Reassuring, neutral empty state -- never invents astrology content
/// when the Engine genuinely has nothing current to show.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isHindi});

  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFF3E8FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.self_improvement_rounded,
            size: 28,
            color: Color(0xFF6B21A8),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          isHindi
              ? 'अभी आपके लिए कोई सक्रिय अलर्ट नहीं है'
              : 'No active alerts for you right now',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1B2E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isHindi
              ? 'जब कोई सार्थक संकेत मिलेगा, हम आपको यहीं दिखाएंगे।'
              : 'When something meaningful comes up, we’ll show it here.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

class _AlertsList extends StatelessWidget {
  const _AlertsList({required this.alerts, required this.isHindi});

  final List<AlertItem> alerts;
  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        for (var i = 0; i < alerts.length; i++) ...[
          _AlertCard(alert: alerts[i], isStrongest: i == 0, isHindi: isHindi),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

/// One selected alert. The strongest (first) card is visually more
/// prominent; a second card, when genuinely qualified, is shown plainer
/// beneath it -- never re-ranked or re-selected on the client, only
/// displayed in the order the backend already returned.
class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.isStrongest,
    required this.isHindi,
  });

  final AlertItem alert;
  final bool isStrongest;
  final bool isHindi;

  static const Map<String, Color> _severityColors = {
    'CRITICAL': Color(0xFFDC2626),
    'HIGH': Color(0xFFB8860B),
    'MEDIUM': Color(0xFF6B21A8),
    'LOW': Color(0xFF6B7280),
  };

  static const Map<String, String> _severityLabelsEn = {
    'CRITICAL': 'Important',
    'HIGH': 'Notable',
    'MEDIUM': 'Worth Knowing',
    'LOW': 'Gentle Signal',
  };

  static const Map<String, String> _severityLabelsHi = {
    'CRITICAL': 'महत्वपूर्ण',
    'HIGH': 'उल्लेखनीय',
    'MEDIUM': 'जानने योग्य',
    'LOW': 'हल्का संकेत',
  };

  String _categoryLabel(bool isHindi) {
    const en = {
      'emotional': 'Emotional',
      'vitality': 'Vitality',
      'financial': 'Financial',
      'timing': 'Timing',
      'health': 'Health',
      'relationship': 'Relationship',
      'travel': 'Travel',
      'learning': 'Learning',
      'general': 'General',
    };
    const hi = {
      'emotional': 'भावनात्मक',
      'vitality': 'ऊर्जा',
      'financial': 'वित्तीय',
      'timing': 'समय',
      'health': 'स्वास्थ्य',
      'relationship': 'संबंध',
      'travel': 'यात्रा',
      'learning': 'सीखना',
      'general': 'सामान्य',
    };
    final map = isHindi ? hi : en;
    return map[alert.category] ?? (isHindi ? 'सामान्य' : 'General');
  }

  void _share(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    ShareService.share(
      ShareableContent(
        title: alert.title,
        description: alert.message,
        brandingTagline: t.shareBranding,
        downloadAppLabel: t.shareDownloadApp,
        visitWebsiteLabel: t.shareVisitWebsite,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final severity = alert.severity?.toUpperCase();
    final severityColor = _severityColors[severity] ?? const Color(0xFF6B21A8);
    final severityLabel = isHindi
        ? (_severityLabelsHi[severity] ?? _severityLabelsHi['MEDIUM']!)
        : (_severityLabelsEn[severity] ?? _severityLabelsEn['MEDIUM']!);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isStrongest ? const Color(0xFFEDE4FB) : const Color(0xFFF0F0F5),
          ),
          boxShadow: isStrongest
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    severityLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: severityColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _categoryLabel(isHindi),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _share(context),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.share_rounded,
                      size: 16,
                      color: Color(0xFFC4B5D6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              alert.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              alert.message,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
