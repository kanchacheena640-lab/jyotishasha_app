// lib/features/kundali/kundali_overview_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/constants/planet_meta.dart';
import 'package:jyotishasha_app/core/constants/planet_names.dart';
import 'package:jyotishasha_app/core/constants/yog_dosh_meta.dart';
import 'package:jyotishasha_app/core/state/firebase_kundali_provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/manual_kundali_provider.dart';
import 'package:jyotishasha_app/core/widgets/in_app_webview.dart';
import 'package:jyotishasha_app/core/widgets/kundali_chart_north_widget.dart';
import 'package:jyotishasha_app/features/kundali/data/identity_report_availability.dart';
import 'package:jyotishasha_app/features/kundali/data/life_report_availability.dart';
import 'package:jyotishasha_app/features/kundali/data/planet_report_availability.dart';
import 'package:jyotishasha_app/features/kundali/data/report_destinations.dart';
import 'package:jyotishasha_app/features/kundali/data/yog_dosh_report_availability.dart';
import 'package:jyotishasha_app/features/kundali/widgets/identity_card.dart';
import 'package:jyotishasha_app/features/kundali/widgets/life_report_card.dart';
import 'package:jyotishasha_app/features/kundali/widgets/planet_card.dart';
import 'package:jyotishasha_app/features/kundali/widgets/yog_dosh_mini_card.dart';
import 'package:jyotishasha_app/features/manual_kundali/manual_kundali_form_page.dart';

/// BUG FIX — Nakshatra name missing. Root cause: this page read
/// `data['nakshatra']` as a plain top-level field, but the backend's
/// `/api/full-kundali-modern` response (the endpoint both
/// [FirebaseKundaliProvider] and [ManualKundaliProvider] call) does not
/// reliably populate that top-level key — confirmed by the existing,
/// already-shipped workaround in
/// `AstrologyProfileCard._extractNakshatra` (`lib/features/astrology/
/// widgets/astrology_profile_card.dart`), which has to parse the value
/// out of the Moon's `planet_overview[].summary` text instead, and
/// corroborated by `docs/esr/08_data_contract_audit.md`'s list of nested
/// keys widgets actually read off this response — a bare `nakshatra`
/// key is conspicuously absent from it.
///
/// This mirrors that exact same, already-proven extraction strategy
/// rather than inventing a new one: try the top-level field first
/// (harmless, forward-compatible if the backend ever adds it), then fall
/// back to the Moon's `planet_overview` summary text — the only place
/// this value has been reliably observed to actually be present. No
/// backend change, no fabricated value — every value here is either the
/// field the backend already sends, or `'-'`. Applies identically to
/// both providers' data, since both call the same endpoint and share the
/// same raw response shape (per the F8.AUDIT findings).
String _extractNakshatra(Map<String, dynamic> data) {
  final direct = data['nakshatra']?.toString().trim();
  if (direct != null && direct.isNotEmpty) return direct;

  final overviews = data['planet_overview'] as List<dynamic>? ?? [];
  for (final entry in overviews) {
    if (entry is! Map) continue;
    if (entry['planet']?.toString().toLowerCase() != 'moon') continue;

    final summary = entry['summary']?.toString() ?? '';
    for (final line in summary.split('\n')) {
      if (!line.contains('Nakshatra')) continue;
      final parts = line.split(':');
      if (parts.length < 2) continue;
      final value = parts[1].split('(')[0].trim();
      if (value.isNotEmpty) return value;
    }
  }
  return '-';
}

/// F8.8 — the ONE place every "View Full Free Report" CTA on this page
/// routes through. Opens [url] in the existing, generic [InAppWebView]
/// ("any feature that needs to open a URL inside the app should push
/// this widget rather than building its own WebView wiring" — its own
/// doc comment) — no new WebView architecture, no new route registered.
/// When [url] is `null` (no known destination — e.g. a COMING_SOON
/// card, or an AVAILABLE one with a known destination gap like
/// `budh_aditya_yog`, see [ReportDestinations]), this is a safe no-op,
/// identical to [ReportAvailabilityAction]'s own `onTap ?? () {}`
/// fallback for a card with no `onViewReport` supplied at all.
void _openReport(BuildContext context, String? url) {
  if (url == null) return;
  Navigator.push(context, MaterialPageRoute(builder: (_) => InAppWebView(url: url)));
}

/// F8.1 — Kundali Overview Foundation. F8.7 made this page data-source
/// independent (see [useManualProvider]) so the exact same page can show
/// either the signed-in user's own chart or a chart manually generated
/// for someone else — without duplicating the page and without the two
/// source providers ([FirebaseKundaliProvider], [ManualKundaliProvider])
/// ever touching, copying into, or overwriting one another.
///
/// Reuses the existing, already-registered [FirebaseKundaliProvider]/
/// [ManualKundaliProvider] — no new provider was created — and the
/// existing [KundaliChartNorthWidget] — no new chart widget was created.
/// Does not modify [AstrologyPage], Home, the backend, or Subscription;
/// this is a standalone, additive page.
class KundaliOverviewPage extends StatefulWidget {
  /// Whether to automatically trigger a Firebase load on mount when
  /// [FirebaseKundaliProvider] has no data yet. Only meaningful when
  /// [useManualProvider] is `false` — ignored otherwise, since a manually
  /// generated Kundali is always already present in [ManualKundaliProvider]
  /// by the time this page is reached (F8.7 never fetches on its behalf).
  /// Defaults to `true` (real production behavior for "My Kundali"); set
  /// to `false` to deterministically test the loading/error/empty states
  /// without racing a real fetch attempt.
  final bool autoLoad;

  /// F8.7 — when `true`, this page reads [ManualKundaliProvider] (a
  /// manually generated chart for someone else) instead of
  /// [FirebaseKundaliProvider] (the signed-in user's own chart). The two
  /// providers stay completely independent: no data is ever copied
  /// between them, and neither is snapshotted or restored — going Back
  /// from a manual-mode page simply pops the route, and "My Kundali"
  /// underneath is exactly as it was because [FirebaseKundaliProvider]
  /// was never touched while viewing someone else's chart.
  final bool useManualProvider;

  const KundaliOverviewPage({
    super.key,
    this.autoLoad = true,
    this.useManualProvider = false,
  });

  @override
  State<KundaliOverviewPage> createState() => _KundaliOverviewPageState();
}

class _KundaliOverviewPageState extends State<KundaliOverviewPage> {
  @override
  void initState() {
    super.initState();
    if (widget.autoLoad && !widget.useManualProvider) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    // Manual mode never fetches here — ManualKundaliProvider is always
    // already populated (by ManualKundaliFormPage) before this page is
    // reached, and F8.7 must never touch FirebaseKundaliProvider on a
    // manual-mode page.
    if (widget.useManualProvider) return;

    final provider = context.read<FirebaseKundaliProvider>();
    // Same provider may already be populated by AstrologyPage/Dashboard —
    // avoid an unnecessary duplicate fetch if data is already there.
    if (provider.kundaliData != null || provider.isLoading) return;

    final lang = context.read<LanguageProvider>().currentLang;
    await provider.loadFromFirebaseProfile(context, lang: lang);
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = context.watch<LanguageProvider>().currentLang == 'hi';

    // Both providers are always in the ambient tree (registered once,
    // app-wide, in main.dart) — watching both here and simply selecting
    // which one's fields to use keeps them fully independent (no merge,
    // no subclassing, no shared interface) while making this single page
    // work with either.
    final firebaseProvider = context.watch<FirebaseKundaliProvider>();
    final manualProvider = context.watch<ManualKundaliProvider>();

    final isLoading = widget.useManualProvider
        ? manualProvider.isLoading
        : firebaseProvider.isLoading;
    final errorMessage = widget.useManualProvider
        ? manualProvider.error
        : firebaseProvider.errorMessage;
    final kundaliData = widget.useManualProvider
        ? manualProvider.kundali
        : firebaseProvider.kundaliData;

    final manualName = widget.useManualProvider
        ? ((kundaliData?['profile'] as Map?)?['name']?.toString().trim())
        : null;
    final title = (manualName != null && manualName.isNotEmpty)
        ? manualName
        : (isHindi ? 'कुंडली' : 'Kundali');

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: const Color(0xFF1F1B2E),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: _buildBody(
          context,
          isLoading: isLoading,
          errorMessage: errorMessage,
          kundaliData: kundaliData,
          isHindi: isHindi,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required bool isLoading,
    required String? errorMessage,
    required Map<String, dynamic>? kundaliData,
    required bool isHindi,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return _StatusView(
        icon: Icons.error_outline_rounded,
        message: isHindi
            ? 'कुंडली लोड करने में समस्या हुई।'
            : 'Something went wrong loading your Kundali.',
        onRetry: _load,
        isHindi: isHindi,
      );
    }

    if (kundaliData == null) {
      return _StatusView(
        icon: Icons.auto_awesome_outlined,
        message: isHindi
            ? 'अभी कोई कुंडली डेटा उपलब्ध नहीं है।'
            : 'No Kundali data available yet.',
        onRetry: _load,
        isHindi: isHindi,
      );
    }

    final data = kundaliData;
    final profile = (data['profile'] as Map?) ?? {};
    final planets = (data['chart_data'] as Map?)?['planets'] as List<dynamic>? ?? [];
    final lagnaSign = data['lagna_sign']?.toString();
    final rashi = data['rashi']?.toString();
    final nakshatra = _extractNakshatra(data);

    // F8.6 — sections are separated by a wider gap than the spacing used
    // between cards *within* a section, so users can instantly tell where
    // one section ends and the next begins.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChartSection(
            planets: planets,
            lagnaSign: lagnaSign,
            rashi: rashi,
            nakshatra: nakshatra,
            isHindi: isHindi,
          ),
          const SizedBox(height: 24),
          _BirthDetailsSection(profile: profile, isHindi: isHindi),
          const SizedBox(height: 24),
          _IdentitySection(data: data, isHindi: isHindi),
          const SizedBox(height: 24),
          _PlanetSection(data: data, isHindi: isHindi),
          const SizedBox(height: 24),
          _YogDoshOverviewSection(data: data, isHindi: isHindi),
          const SizedBox(height: 24),
          _LifeAreasSection(isHindi: isHindi),
          // F8.7 — the "Create Another Kundali" CTA only makes sense from
          // "My Kundali" itself; a manually generated chart doesn't get
          // its own nested "create another" entry point.
          if (!widget.useManualProvider) ...[
            const SizedBox(height: 24),
            _CreateAnotherKundaliSection(isHindi: isHindi),
          ],
        ],
      ),
    );
  }
}

/// Shared card shell used by the Chart and Birth Details sections —
/// white, 18dp radius, soft lavender border, subtle shadow: the same
/// premium tokens every other card on this page (`IdentityCard`,
/// `PlanetCard`, `YogDoshMiniCard`, `LifeReportCard`) already uses,
/// normalized here in F8.6 so the whole page reads as one visual system.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4D9FA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Chart section — reuses [KundaliChartNorthWidget] exactly as
/// `AstrologyToolDetailPage` already does; no new chart rendering code.
///
/// F8.6 adds a "Birth Chart" title above the chart (consistent with
/// every other section now having a Large Title) and three compact
/// at-a-glance badges below it — Ascendant, Moon Sign, Nakshatra — built
/// from the exact same `lagna_sign`/`rashi`/`nakshatra` fields the "Know
/// Yourself" cards below already read; nothing new is calculated. The
/// Ascendant badge's icon is a static sign-name → zodiac-glyph lookup
/// (`_zodiacSymbols`), not a new astrology computation — Moon Sign and
/// Nakshatra always use a fixed 🌙/⭐ icon regardless of value, matching
/// the task's own example ("♎ Libra", "🌙 Cancer", "⭐ Chitra").
class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.planets,
    required this.lagnaSign,
    required this.rashi,
    required this.nakshatra,
    required this.isHindi,
  });

  final List<dynamic> planets;
  final String? lagnaSign;
  final String? rashi;
  final String? nakshatra;
  final bool isHindi;

  static const Map<String, String> _zodiacSymbols = {
    'Aries': '♈',
    'Taurus': '♉',
    'Gemini': '♊',
    'Cancer': '♋',
    'Leo': '♌',
    'Virgo': '♍',
    'Libra': '♎',
    'Scorpio': '♏',
    'Sagittarius': '♐',
    'Capricorn': '♑',
    'Aquarius': '♒',
    'Pisces': '♓',
  };

  Widget _badge(String icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4D9FA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1B2E),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ascendant = (lagnaSign ?? '').trim();
    final moonSign = (rashi ?? '').trim();
    final nakshatraValue = (nakshatra ?? '').trim();

    return _SectionCard(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isHindi ? 'जन्म कुंडली' : 'Birth Chart',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F1B2E),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: KundaliChartNorthWidget(
              planets: planets,
              lagnaSign: lagnaSign,
              size: 220,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge(_zodiacSymbols[ascendant] ?? '✨', ascendant.isNotEmpty ? ascendant : '-'),
              _badge('🌙', moonSign.isNotEmpty ? moonSign : '-'),
              _badge('⭐', nakshatraValue.isNotEmpty ? nakshatraValue : '-'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Birth Details section — Name / DOB / Time / Place, read from the
/// existing provider's `kundaliData["profile"]`, the same field the
/// existing `AstrologyProfileCard`/`AstrologyToolDetailPage` already read.
///
/// F8.6 — redesigned from four plain stacked "Label: Value" lines into a
/// compact 2×2 icon grid (👤 Name, 📅 DOB, 🕒 Time, 📍 Place), reducing
/// vertical height; no field, source, or formatting logic changed beyond
/// presentation.
class _BirthDetailsSection extends StatelessWidget {
  const _BirthDetailsSection({required this.profile, required this.isHindi});

  final Map profile;
  final bool isHindi;

  String _formatDob(dynamic raw) {
    final d = raw?.toString();
    if (d == null || d.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(d);
      return '${parsed.day.toString().padLeft(2, '0')}-'
          '${parsed.month.toString().padLeft(2, '0')}-'
          '${parsed.year}';
    } catch (_) {
      return d;
    }
  }

  Widget _field(String icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F1B2E),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (profile['name']?.toString().trim().isNotEmpty ?? false)
        ? profile['name'].toString()
        : '-';
    final dob = _formatDob(profile['dob']);
    final tob = profile['tob']?.toString() ?? '-';
    final pob = (profile['pob'] ?? profile['place'])?.toString() ?? '-';

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHindi ? 'जन्म विवरण' : 'Birth Details',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1B2E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _field('👤', isHindi ? 'नाम' : 'Name', name),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  '📅',
                  isHindi ? 'जन्म तिथि' : 'Date of Birth',
                  dob,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _field('🕒', isHindi ? 'जन्म समय' : 'Birth Time', tob),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  '📍',
                  isHindi ? 'जन्म स्थान' : 'Birth Place',
                  pob,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Know Yourself" section — F8.2, renamed and redesigned in F8.6. Four
/// compact [IdentityCard]s (Ascendant, Moon Sign, Nakshatra, and ONE
/// merged Current Dasha card replacing the previous separate
/// Mahadasha/Antardasha cards), all built from fields the existing
/// backend response (`FirebaseKundaliProvider.kundaliData`) already
/// provides — no new calculations, no new provider. Report availability
/// for each card comes only from [IdentityReportAvailability]; this
/// widget contains no availability if/else of its own beyond what
/// [IdentityCard] itself already renders once, internally.
///
/// The Current Dasha card shows both period names on one line
/// ("Saturn → Mercury") rather than as two separate cards, until
/// separate Antardasha reports exist (per F8.6 spec) — its status is
/// [IdentitySection.mahadasha]'s (the availability config itself is
/// untouched; this only decides which of the two existing, currently
/// identical [ReportAvailabilityStatus.comingSoon] statuses represents
/// the single merged card).
class _IdentitySection extends StatelessWidget {
  const _IdentitySection({required this.data, required this.isHindi});

  final Map<String, dynamic> data;
  final bool isHindi;

  /// The current dasha block — same `dasha_summary.current_block` object
  /// `AstrologyProfileCard`/`MahadashaResultWidget` already read for the
  /// current mahadasha/antardasha planet names and impact text.
  Map get _currentBlock =>
      ((data['dasha_summary'] as Map?)?['current_block'] as Map?) ?? {};

  /// Same bilingual `impact_snippet`/`impact_snippet_hi` field
  /// `MahadashaResultWidget.pickImpact` already reads for the current
  /// dasha period — reused here rather than recalculated.
  String _impactSummary() {
    final block = _currentBlock;
    final hi = (block['impact_snippet_hi'] ?? '').toString().trim();
    final en = (block['impact_snippet'] ?? '').toString().trim();
    final picked = isHindi && hi.isNotEmpty ? hi : en;
    if (picked.isNotEmpty) return picked;
    return isHindi
        ? 'यह आपकी वर्तमान दशा अवधि का प्रभाव है।'
        : "This is the influence of your current dasha period.";
  }

  @override
  Widget build(BuildContext context) {
    final lagnaTrait = (data['lagna_trait'] ?? '').toString().trim();
    final moonPersonality =
        ((data['moon_traits'] as Map?)?['personality'] ?? '')
            .toString()
            .trim();
    final mahadasha = (_currentBlock['mahadasha'] ?? '-').toString();
    final antardasha = (_currentBlock['antardasha'] ?? '-').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isHindi ? 'खुद को जानें' : 'Know Yourself',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1B2E),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isHindi
              ? 'आपके व्यक्तित्व और वर्तमान समय को आकार देने वाली मुख्य स्थितियां।'
              : 'The core placements shaping your personality and this '
                    'period of your life.',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B5563),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        IdentityCard(
          title: isHindi ? 'आपका लग्न' : 'Your Ascendant',
          value: (data['lagna_sign'] ?? '-').toString(),
          summary: lagnaTrait.isNotEmpty
              ? lagnaTrait
              : (isHindi
                    ? 'आपका लग्न बताता है कि दुनिया आपको कैसे देखती है।'
                    : 'Your Ascendant shapes how the world sees you.'),
          status: IdentityReportAvailability.statusOf(
            IdentitySection.ascendant,
          ),
          isHindi: isHindi,
          onViewReport: () => _openReport(
            context,
            ReportDestinations.identityUrl(IdentitySection.ascendant),
          ),
        ),
        const SizedBox(height: 10),
        IdentityCard(
          title: isHindi ? 'आपकी राशि' : 'Your Moon Sign',
          value: (data['rashi'] ?? '-').toString(),
          summary: moonPersonality.isNotEmpty
              ? moonPersonality
              : (isHindi
                    ? 'आपकी राशि आपकी भावनाओं की प्रकृति को दर्शाती है।'
                    : 'Your Moon Sign reflects your emotional nature.'),
          status: IdentityReportAvailability.statusOf(
            IdentitySection.moonSign,
          ),
          isHindi: isHindi,
          onViewReport: () => _openReport(
            context,
            ReportDestinations.identityUrl(IdentitySection.moonSign),
          ),
        ),
        const SizedBox(height: 10),
        IdentityCard(
          title: isHindi ? 'आपका नक्षत्र' : 'Your Nakshatra',
          value: _extractNakshatra(data),
          summary: isHindi
              ? 'आपका नक्षत्र आपके व्यक्तित्व के गहरे पहलुओं को दर्शाता है।'
              : 'Your Nakshatra reveals deeper patterns in your personality.',
          status: IdentityReportAvailability.statusOf(
            IdentitySection.nakshatra,
          ),
          isHindi: isHindi,
          onViewReport: () => _openReport(
            context,
            ReportDestinations.identityUrl(
              IdentitySection.nakshatra,
              value: _extractNakshatra(data),
            ),
          ),
        ),
        const SizedBox(height: 10),
        IdentityCard(
          title: isHindi ? 'वर्तमान दशा' : 'Current Dasha',
          value: '$mahadasha → $antardasha',
          summary: _impactSummary(),
          status: IdentityReportAvailability.statusOf(
            IdentitySection.mahadasha,
          ),
          isHindi: isHindi,
          // COMING_SOON — no destination to wire (see ReportDestinations,
          // Mahadasha/Antardasha intentionally return null).
        ),
      ],
    );
  }
}

/// "Planetary Influences" section — F8.3, renamed and redesigned in
/// F8.6. Nine [PlanetCard]s, always rendered in the fixed Sun → Moon →
/// Mars → Mercury → Jupiter → Venus → Saturn → Rahu → Ketu order
/// ([PlanetSection.values]) — never the backend's list order.
///
/// Position (Sign • House — F8.6 swapped the display order from the
/// original House • Sign, pure presentation, same underlying fields) is
/// read from the existing `chart_data.planets` placement list — the same
/// data [KundaliChartNorthWidget] already renders from. The one-line
/// Impact reuses the existing `planet_overview[i].summary`/`summary_hi`
/// field the old `PlanetResultWidget`/`AstrologyProfileCard` already read
/// (first non-empty line only, to keep it one-line); if no overview
/// entry exists for a planet, a neutral placeholder is shown instead —
/// no new astrology is calculated or invented anywhere in this section.
/// Report availability for each card comes only from
/// [PlanetReportAvailability]; this widget contains no availability
/// if/else of its own beyond what [PlanetCard] itself already renders
/// once, internally.
class _PlanetSection extends StatelessWidget {
  const _PlanetSection({required this.data, required this.isHindi});

  final Map<String, dynamic> data;
  final bool isHindi;

  static const _order = PlanetSection.values;

  String _canonicalName(PlanetSection section) =>
      section.name[0].toUpperCase() + section.name.substring(1);

  Map? _findPlacement(List<dynamic> entries, String name) {
    for (final e in entries) {
      if (e is Map) {
        final n = (e['name'] ?? e['planet'])?.toString();
        if (n != null && n.toLowerCase() == name.toLowerCase()) return e;
      }
    }
    return null;
  }

  Map? _findOverview(List<dynamic> entries, String name) {
    for (final e in entries) {
      if (e is Map) {
        final n = e['planet']?.toString();
        if (n != null && n.toLowerCase() == name.toLowerCase()) return e;
      }
    }
    return null;
  }

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  String _position(Map? placement) {
    if (placement == null) return '-';
    final houseRaw = placement['house'];
    final house = houseRaw is int ? houseRaw : int.tryParse('$houseRaw');
    final sign = (placement['sign'] ?? placement['rashi'])?.toString().trim();
    final parts = [
      if (sign != null && sign.isNotEmpty) sign,
      if (house != null && house > 0) '${_ordinal(house)} House',
    ];
    return parts.isEmpty ? '-' : parts.join(' • ');
  }

  String _firstLine(String text) {
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  String _impact(Map? overview) {
    if (overview != null) {
      final hi = (overview['summary_hi'] ?? '').toString();
      final en = (overview['summary'] ?? '').toString();
      final picked = _firstLine(isHindi && hi.trim().isNotEmpty ? hi : en);
      if (picked.isNotEmpty) return picked;
    }
    return isHindi
        ? 'इस ग्रह के लिए विवरण जल्द जोड़ा जाएगा।'
        : 'Details for this planet will be added soon.';
  }

  PlanetCard _buildCard(
    BuildContext context,
    PlanetSection section,
    List<dynamic> placements,
    List<dynamic> overviews,
  ) {
    final name = _canonicalName(section);
    final meta = PlanetMeta.allPlanets.firstWhere(
      (p) => p['name'] == name,
      orElse: () => const <String, dynamic>{},
    );

    return PlanetCard(
      icon: (meta['emoji'] ?? '').toString(),
      name: isHindi ? (PlanetNameMap[name]?['hi'] ?? name) : name,
      position: _position(_findPlacement(placements, name)),
      impact: _impact(_findOverview(overviews, name)),
      status: PlanetReportAvailability.statusOf(section),
      isHindi: isHindi,
      onViewReport: () =>
          _openReport(context, ReportDestinations.planetUrl(section)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final placements =
        (data['chart_data'] as Map?)?['planets'] as List<dynamic>? ?? [];
    final overviews = data['planet_overview'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isHindi ? 'ग्रहों का प्रभाव' : 'Planetary Influences',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1B2E),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isHindi
              ? 'देखें आपकी कुंडली में हर ग्रह कहां स्थित है और वह आपको कैसे प्रभावित करता है।'
              : 'See where each planet sits in your chart and how it shapes '
                    'you.',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B5563),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _order.length; i++) ...[
          _buildCard(context, _order[i], placements, overviews),
          if (i != _order.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// Yog & Dosh overview — F8.5.1/F8.5.2. Section introduction (Title +
/// one-line subtitle, the same layout philosophy [_LifeAreasSection]
/// uses), then a premium 2-column grid of compact [YogDoshMiniCard]s for
/// every ACTIVE entry the backend returns in `data['yogas']` — a
/// `Map<String, dynamic>` keyed by yog/dosh id, the exact same map every
/// existing Yog/Dosh widget (`YogDoshResultWidget`, `MangalDoshWidget`,
/// `KaalsarpDoshWidget`, `SadhesatiWidget`) already reads from. This is a
/// presentation-only redesign of F8.4/F8.5.1's vertical [YogDoshCard]
/// list — the filtering logic below (which id is a Yog vs a Dosh, which
/// entries count as "active", catalog ordering, unknown-id handling) is
/// byte-for-byte the same as the F8.4 original, just relocated here so
/// the "both empty" check and the two grids can share one computation
/// instead of duplicating it.
///
/// Visibility: a group with zero active entries is omitted entirely (no
/// heading, no per-group empty text). Only when BOTH groups are empty
/// does a single small empty-state line appear. Report availability for
/// each card comes only from [YogDoshReportAvailability]; this widget
/// contains no availability if/else of its own beyond what
/// [YogDoshMiniCard] itself already renders once, internally.
class _YogDoshOverviewSection extends StatelessWidget {
  const _YogDoshOverviewSection({required this.data, required this.isHindi});

  final Map<String, dynamic> data;
  final bool isHindi;

  static bool _isDoshId(String id) => id.contains('dosh') || id == 'sadhesati';

  static List<MapEntry<String, Map>> _activeEntries(
    Map<String, dynamic> yogas,
    bool dosh,
  ) {
    final result = <MapEntry<String, Map>>[];
    final seen = <String>{};

    for (final meta in YogDoshMeta.all) {
      final id = (meta['id'] ?? '').toString();
      seen.add(id);
      if (_isDoshId(id) != dosh) continue;
      final entry = yogas[id];
      if (entry is Map && entry['is_active'] == true) {
        result.add(MapEntry(id, entry));
      }
    }
    // Any backend id outside the known catalog — still shown if active,
    // never dropped just because it wasn't anticipated.
    for (final key in yogas.keys) {
      final id = key.toString();
      if (seen.contains(id)) continue;
      final entry = yogas[id];
      if (entry is! Map || entry['is_active'] != true) continue;
      if (_isDoshId(id) != dosh) continue;
      result.add(MapEntry(id, entry));
    }
    return result;
  }

  static String _label(String id) =>
      (YogDoshMeta.find(id)?['label'] ?? id).toString();

  static String _icon(String id, String fallback) =>
      (YogDoshMeta.find(id)?['emoji'] ?? fallback).toString();

  static String _title(Map entry, String fallbackLabel, bool isHindi) {
    final hi = (entry['heading_hi'] ?? '').toString().trim();
    final en = (entry['heading'] ?? entry['name'] ?? '').toString().trim();
    final picked = isHindi && hi.isNotEmpty ? hi : en;
    return picked.isNotEmpty ? picked : fallbackLabel;
  }

  @override
  Widget build(BuildContext context) {
    final yogas = (data['yogas'] as Map?)?.cast<String, dynamic>() ?? {};
    final activeYogs = _activeEntries(yogas, false);
    final activeDoshes = _activeEntries(yogas, true);
    final bothEmpty = activeYogs.isEmpty && activeDoshes.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isHindi ? 'योग और दोष' : 'Yog & Dosh',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1B2E),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isHindi
              ? 'विशेष ग्रह संयोजन आपके पूरे जीवन में अनोखी शक्तियाँ, अवसर और चुनौतियाँ पैदा कर सकते हैं।'
              : 'Special planetary combinations can create unique strengths, '
                    'opportunities and challenges throughout your life.',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B5563),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        if (bothEmpty)
          Text(
            isHindi
                ? 'कोई प्रमुख योग या दोष नहीं मिला।'
                : 'No major Yog or Dosh detected.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          )
        else ...[
          if (activeYogs.isNotEmpty) ...[
            Text(
              isHindi ? '✨ सक्रिय योग' : '✨ Active Yogas',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1B2E),
              ),
            ),
            const SizedBox(height: 10),
            _YogDoshGrid(
              entries: activeYogs,
              defaultIcon: '✨',
              isHindi: isHindi,
            ),
          ],
          if (activeYogs.isNotEmpty && activeDoshes.isNotEmpty)
            const SizedBox(height: 16),
          if (activeDoshes.isNotEmpty) ...[
            Text(
              isHindi ? '⚠ सक्रिय दोष' : '⚠ Active Doshas',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1B2E),
              ),
            ),
            const SizedBox(height: 10),
            _YogDoshGrid(
              entries: activeDoshes,
              defaultIcon: '⚠',
              isHindi: isHindi,
            ),
          ],
        ],
      ],
    );
  }
}

/// F8.5.2 — presentation-only premium 2-column grid of [YogDoshMiniCard]s
/// for one already-filtered, already-active list of yog/dosh entries.
/// Purely a layout widget: it does no filtering, reads no `is_active`
/// flag, and makes no availability decision of its own — it only formats
/// entries [_YogDoshOverviewSection] already resolved, exactly the same
/// [Row]-of-[Expanded] two-column approach [_LifeAreasSection] uses, for
/// visual consistency between the two sections.
class _YogDoshGrid extends StatelessWidget {
  const _YogDoshGrid({
    required this.entries,
    required this.defaultIcon,
    required this.isHindi,
  });

  final List<MapEntry<String, Map>> entries;
  final String defaultIcon;
  final bool isHindi;

  YogDoshMiniCard _buildCard(BuildContext context, MapEntry<String, Map> entry) {
    final id = entry.key;
    return YogDoshMiniCard(
      icon: _YogDoshOverviewSection._icon(id, defaultIcon),
      name: _YogDoshOverviewSection._title(
        entry.value,
        _YogDoshOverviewSection._label(id),
        isHindi,
      ),
      status: YogDoshReportAvailability.statusForId(id),
      isHindi: isHindi,
      onViewReport: () =>
          _openReport(context, ReportDestinations.yogDoshUrl(id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < entries.length; i += 2) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCard(context, entries[i])),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < entries.length
                    ? _buildCard(context, entries[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          if (i + 2 < entries.length) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Life Areas section — F8.5. A report-discovery navigation hub, not a
/// prediction, premium, or calculator section: twelve [LifeReportCard]s
/// in a premium 2-column grid, one per life-area category, always in the
/// fixed order below. Every title, icon, and one-line introduction is
/// fixed educational copy — never generated, never calculated, never
/// read from the backend (this section makes no backend call at all).
/// Report availability for each card comes only from
/// [LifeReportAvailability]; this widget contains no availability
/// if/else of its own beyond what [LifeReportCard] itself already
/// renders once, internally. No navigation, no WebView — cards are
/// display-only in this task.
class _LifeAreasSection extends StatelessWidget {
  const _LifeAreasSection({required this.isHindi});

  final bool isHindi;

  static const _order = LifeAreaSection.values;

  static const Map<LifeAreaSection, String> _icon = {
    LifeAreaSection.loveRelationship: '❤️',
    LifeAreaSection.career: '💼',
    LifeAreaSection.financeWealth: '💰',
    LifeAreaSection.marriage: '💍',
    LifeAreaSection.family: '👨‍👩‍👧',
    LifeAreaSection.children: '👶',
    LifeAreaSection.education: '🎓',
    LifeAreaSection.health: '🏥',
    LifeAreaSection.property: '🏠',
    LifeAreaSection.foreignTravel: '✈',
    LifeAreaSection.spirituality: '🧘',
    LifeAreaSection.legalMatters: '⚖',
  };

  static const Map<LifeAreaSection, String> _titleEn = {
    LifeAreaSection.loveRelationship: 'Love & Relationship',
    LifeAreaSection.career: 'Career',
    LifeAreaSection.financeWealth: 'Finance & Wealth',
    LifeAreaSection.marriage: 'Marriage',
    LifeAreaSection.family: 'Family',
    LifeAreaSection.children: 'Children',
    LifeAreaSection.education: 'Education',
    LifeAreaSection.health: 'Health',
    LifeAreaSection.property: 'Property',
    LifeAreaSection.foreignTravel: 'Foreign Travel',
    LifeAreaSection.spirituality: 'Spirituality',
    LifeAreaSection.legalMatters: 'Legal Matters',
  };

  static const Map<LifeAreaSection, String> _titleHi = {
    LifeAreaSection.loveRelationship: 'प्रेम और रिश्ते',
    LifeAreaSection.career: 'करियर',
    LifeAreaSection.financeWealth: 'धन और वित्त',
    LifeAreaSection.marriage: 'विवाह',
    LifeAreaSection.family: 'परिवार',
    LifeAreaSection.children: 'संतान',
    LifeAreaSection.education: 'शिक्षा',
    LifeAreaSection.health: 'स्वास्थ्य',
    LifeAreaSection.property: 'संपत्ति',
    LifeAreaSection.foreignTravel: 'विदेश यात्रा',
    LifeAreaSection.spirituality: 'आध्यात्म',
    LifeAreaSection.legalMatters: 'कानूनी मामले',
  };

  /// Fixed educational one-line introductions — verbatim from the F8.5
  /// task spec. Never predictions, never calculated.
  static const Map<LifeAreaSection, String> _introEn = {
    LifeAreaSection.loveRelationship:
        'Understand your relationship patterns and emotional compatibility.',
    LifeAreaSection.career:
        'Discover how your birth chart influences your profession, growth and career direction.',
    LifeAreaSection.financeWealth:
        'Explore your earning potential and wealth tendencies.',
    LifeAreaSection.marriage:
        'Understand marriage timing and relationship dynamics.',
    LifeAreaSection.family:
        'Explore harmony and responsibilities within family life.',
    LifeAreaSection.children:
        'Learn what your chart indicates about children and parenting.',
    LifeAreaSection.education:
        'Understand learning ability and educational growth.',
    LifeAreaSection.health:
        'Learn the strengths and sensitive areas indicated in your birth chart.',
    LifeAreaSection.property:
        'Understand property, land and home-related possibilities.',
    LifeAreaSection.foreignTravel:
        'See indications related to foreign travel and settlement.',
    LifeAreaSection.spirituality:
        'Discover your inner spiritual path and higher purpose.',
    LifeAreaSection.legalMatters:
        'Explore legal challenges and justice-related indications.',
  };

  static const Map<LifeAreaSection, String> _introHi = {
    LifeAreaSection.loveRelationship:
        'अपने संबंधों के पैटर्न और भावनात्मक अनुकूलता को समझें।',
    LifeAreaSection.career:
        'जानें आपकी कुंडली आपके पेशे, विकास और करियर दिशा को कैसे प्रभावित करती है।',
    LifeAreaSection.financeWealth:
        'अपनी आय क्षमता और धन की प्रवृत्तियों के बारे में जानें।',
    LifeAreaSection.marriage: 'विवाह का समय और रिश्तों की गतिशीलता को समझें।',
    LifeAreaSection.family:
        'पारिवारिक जीवन में सामंजस्य और जिम्मेदारियों को जानें।',
    LifeAreaSection.children:
        'जानें आपकी कुंडली संतान और पालन-पोषण के बारे में क्या दर्शाती है।',
    LifeAreaSection.education: 'सीखने की क्षमता और शैक्षणिक विकास को समझें।',
    LifeAreaSection.health:
        'अपनी कुंडली में दर्शाई गई ताकत और संवेदनशील क्षेत्रों को जानें।',
    LifeAreaSection.property:
        'संपत्ति, भूमि और घर से जुड़ी संभावनाओं को समझें।',
    LifeAreaSection.foreignTravel:
        'विदेश यात्रा और विदेश में बसने से जुड़े संकेत देखें।',
    LifeAreaSection.spirituality:
        'अपने आंतरिक आध्यात्मिक मार्ग और उच्च उद्देश्य को जानें।',
    LifeAreaSection.legalMatters:
        'कानूनी चुनौतियों और न्याय से जुड़े संकेतों को जानें।',
  };

  LifeReportCard _buildCard(BuildContext context, LifeAreaSection section) {
    return LifeReportCard(
      icon: _icon[section]!,
      title: isHindi ? _titleHi[section]! : _titleEn[section]!,
      intro: isHindi ? _introHi[section]! : _introEn[section]!,
      status: LifeReportAvailability.statusOf(section),
      isHindi: isHindi,
      onViewReport: () =>
          _openReport(context, ReportDestinations.lifeAreaUrl(section)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isHindi ? 'जीवन क्षेत्र' : 'Life Areas',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1B2E),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isHindi
              ? 'आपकी कुंडली केवल यह नहीं बताती कि आप कौन हैं।\n'
                    'यह जीवन के विभिन्न क्षेत्रों को भी दर्शाती है जो आपकी यात्रा को आकार देते हैं।\n'
                    'अपनी शक्तियों, अवसरों और चुनौतियों को समझने के लिए हर क्षेत्र को एक्सप्लोर करें।'
              : "Your birth chart doesn't only describe who you are.\n"
                    'It also reveals different areas of life that shape your journey.\n'
                    'Explore each area to understand your strengths, opportunities and challenges.',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B5563),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < _order.length; i += 2) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCard(context, _order[i])),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < _order.length
                    ? _buildCard(context, _order[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          if (i + 2 < _order.length) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// "Create Another Kundali" CTA — F8.7. Sits at the very end of the page
/// (never at the top, never in the AppBar, per spec), only shown for
/// "My Kundali" itself (see [KundaliOverviewPage.useManualProvider]).
/// Reuses the existing, already-working [ManualKundaliFormPage] as-is —
/// no new form, no new validation, no new location picker, no new API
/// call, no new route registration (a plain `Navigator.push`, the same
/// pattern `greeting_header_widget.dart` already uses to reach this page
/// itself). This widget makes no availability/business-logic decision of
/// its own; it only navigates.
class _CreateAnotherKundaliSection extends StatelessWidget {
  const _CreateAnotherKundaliSection({required this.isHindi});

  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHindi ? 'एक और कुंडली चाहिए?' : 'Need another Kundali?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1B2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isHindi
                ? 'अपने परिवार, दोस्तों या किसी और के लिए कुंडली बनाएं।'
                : 'Generate a Kundali for your family, friends or anyone '
                      'else.',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManualKundaliFormPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                isHindi ? 'एक और कुंडली बनाएं' : 'Create Another Kundali',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared loading/error/empty status view.
class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.icon,
    required this.message,
    required this.onRetry,
    required this.isHindi,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRetry;
  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF9CA3AF)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(isHindi ? 'पुनः प्रयास करें' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
