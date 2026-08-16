import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/models/premium_reports/premium_ai_report_contracts.dart';
import 'package:jyotishasha_app/core/repositories/implementations/http_premium_ai_report_repository.dart';
import 'package:jyotishasha_app/core/repositories/premium_ai_report_repository.dart';
import 'package:jyotishasha_app/core/state/subscription_provider.dart';
import 'package:jyotishasha_app/core/utils/premium_gate.dart';
import 'package:jyotishasha_app/features/premium_report/premium_report_type.dart';
import 'package:jyotishasha_app/features/subscription/subscription_page.dart';

/// The single Premium Report screen — reached directly from Explore's
/// report cards, passing only a [PremiumReportType] (no backend id, no
/// pre-fetched report data). Replaces the previous two-screen flow
/// (Explore → PremiumReportLandingPage → BirthChartReportReader); the
/// landing page has been removed from navigation entirely, so this is
/// now the only screen a report card opens.
///
/// Content sourcing, per report — Love/Career/Finance/Health/Family all
/// follow the identical path now that the backend registers a generator
/// for each (`modules/ai_report_engine/generator_registry.py` — see
/// [PremiumAiReportSegments]'s own doc comment; Love was the reference
/// implementation, unmodified by this change):
/// - The free "Your {X} DNA" section and the two premium sections each
///   call the existing, unmodified [PremiumAiReportRepository]
///   (`GET /api/premium-report`, `report_type=DNA`/`CURRENT_PHASE`/
///   `CURRENT_TIMING`, `segment` from [PremiumReportContent.segment]) —
///   the exact same repository/call shape `PremiumAiReportPage`/
///   Account → "AI Love Insights" already uses for Love. Three
///   independent calls, three independent results — `_dnaResult` /
///   `_phaseResult` / `_timingResult` — never one result reused to stand
///   in for another.
///   `DNA` is served by the backend without any entitlement check — "Your
///   {X} DNA" is the FREE section, and [_loadDna] always renders the real
///   backend response directly (loading → content → expand/collapse),
///   with no special-casing and no static fallback unless the backend
///   itself returns a genuine, non-entitlement error.
/// - `fallbackText` ([PremiumReportContent.about]) is shown only while
///   `result` is still `null` — practically never reached once a call has
///   completed, same as Love's pre-existing behavior; not a placeholder
///   standing in for real content.
/// - The `CURRENT_PHASE` call's `content` is backend-authored markdown
///   with four fixed `## `-prefixed headings, in order: "Current Phase",
///   "Next Phase Change", "Watch Out For", "Remedy For This Phase"
///   (backend verified — this file does not generate, translate,
///   reorder, or otherwise touch that copy). It does NOT carry "Current
///   Timing" — that content has its own generator/`report_type` (see
///   next point). [_splitPhaseMarkdown] (presentation-only, below)
///   detects headings by `## ` prefix (not a hardcoded count — any
///   subset the backend sends is picked up).
/// - The `CURRENT_TIMING` call is entirely separate from `CURRENT_PHASE`
///   — its own `report_type`, its own request, its own result
///   (`_timingResult`/`_loadCurrentTiming`). Its `content` is
///   backend-authored PLAIN TEXT with NO Markdown at all (verified
///   against real production responses for every segment): a 2-3
///   sentence situation, a blank line, then the literal label "Quick
///   Tip:", then one sentence. [_splitCurrentTimingContent]
///   (presentation-only, below) parses exactly this contract — it is NOT
///   [_splitPhaseMarkdown] (that one is `CURRENT_PHASE`-only, and looking
///   for `## ` headings in a response that never contains any is
///   precisely the bug this parser replaces). A response with no
///   recognizable "Quick Tip:" delimiter shows its whole content as the
///   situation and falls back to a placeholder "Quick Tip" — this
///   section previously had NO dedicated backend call at all, then later
///   had one but still mis-parsed its real plain-text shape as if it
///   were `CURRENT_PHASE`'s Markdown shape, which is why Quick Tip
///   always fell through to its placeholder and the literal words
///   "Quick Tip:" stayed visible inside the situation paragraph.
///
/// PRESENTATION ARCHITECTURE — exactly three major sections, one screen,
/// no navigation between them:
/// 1. **DNA** (free, ungated) — [_FreeDnaSection], unchanged by this
///    refactor: collapsed preview, "Read Full {X} DNA →" expands the
///    same card in place.
/// 2. **Current Phase** (premium) — [_CurrentPhaseSection]. Collapsed by
///    default to a short excerpt of the "Current Phase" heading's own
///    text; "Read Full Current Phase Report →" expands the same card in
///    place into ONE continuous report containing, in this exact order,
///    all four "Current Phase" sub-sections from the single
///    `CURRENT_PHASE` call: Current Phase, Watch Out For, Remedy For
///    This Phase, Next Phase Change. These four are never their own
///    top-level cards on this screen — they only exist as labeled
///    sub-sections inside this one expanded report (see [_SubSection]).
/// 3. **Current Timing** (premium) — [_CurrentTimingSection]. Always
///    fully expanded, immediately below Current Phase — this screen's
///    primary daily-engagement section, never collapsed and never
///    behind a "Read Full" toggle. Shows its own dedicated
///    `CURRENT_TIMING` call's "Current Timing" text plus its own "Quick
///    Tip" text — both parsed from that same, single `CURRENT_TIMING`
///    response, never from `CURRENT_PHASE`.
///
/// If `CURRENT_PHASE`'s response contains none of its four expected
/// headings (a genuinely different backend shape, an error string, or an
/// older cached response predating this markdown format), Current Phase
/// falls back to rendering its raw `content` as a single block (exactly
/// as this screen showed `CURRENT_PHASE` before any markdown sections
/// existed) and every sub-section falls back to its own placeholder copy
/// — see [_PhaseCopy] for the exact strings, preserved verbatim from
/// this screen's pre-existing behavior so older cached reports render
/// identically to before. Current Timing/Quick Tip fall back the same
/// way, independently, off their own `CURRENT_TIMING` response.
/// - Alerts is deliberately excluded from this screen entirely (see
///   [PremiumReportType] — it has no entry in that enum) and is not
///   reachable here: per `modules/models_ai_reports.py`/
///   `generator_registry.py`'s own docstrings, Alerts is not a
///   ReportGenerator segment — it is served by the separate, already-
///   complete rule engine (`modules/alerts/`) feeding the existing
///   notification pipeline, not by `GET /api/premium-report`.
///
/// Premium gate — entitlement check only, reused unmodified from
/// [hasActiveSubscription] (`premium_gate.dart`), the same function
/// `AccountPage`/`KundaliOverviewPage` already read: wraps the two
/// PREMIUM sections (Current Phase / Current Timing) independently,
/// rendering [_PremiumLockedSection] in place of either when the user
/// has no active entitlement. The FREE DNA section and the rest of this
/// screen are never gated — the report always opens.
///
/// No backend, AI prompt, report-generation, subscription/entitlement,
/// or API logic is modified anywhere in this file — only consumed via
/// the repository interface and [hasActiveSubscription] exactly as they
/// already existed.
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

  bool _dnaLoading = false;
  PremiumAiReportResult? _dnaResult;

  bool _phaseLoading = false;
  PremiumAiReportResult? _phaseResult;

  bool _timingLoading = false;
  PremiumAiReportResult? _timingResult;

  /// Deliberately NOT persisted anywhere (no provider field, no saved
  /// preference) — every fresh mount of this page starts collapsed, per
  /// spec: "DNA is mostly static... daily usage should naturally focus
  /// on the live sections below."
  bool _dnaExpanded = false;

  /// Same rationale as [_dnaExpanded] — Current Phase also starts
  /// collapsed on every fresh mount. Current Timing has no equivalent
  /// field: it is always fully expanded, per spec.
  bool _phaseExpanded = false;

  @override
  void initState() {
    super.initState();

    // Same guard AccountPage/KundaliOverviewPage already use before
    // reading `hasActiveSubscription` — avoids an unnecessary duplicate
    // fetch if some other screen already loaded it this session, while
    // still ensuring the premium gate below has real data instead of
    // defaulting every user to "locked" on a cold start.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final subscription = context.read<SubscriptionProvider>();
      if (subscription.subscriptionData == null && !subscription.isLoading) {
        subscription.loadSubscriptionInfo();
      }
    });

    // Deferred to after the first frame — `_loadDna`/`_loadCurrentPhase`/
    // `_loadCurrentTiming` read `Localizations.localeOf(context)`, which
    // Flutter forbids
    // depending on synchronously during initState (the dependency
    // wouldn't be tracked correctly). Same pattern already used
    // elsewhere in this app (e.g. `GreetingHeaderWidget`, `WelcomeGiftPage`'s
    // membership strip). Every segment takes this path now — Love was
    // the only one until its generator-registry restriction was lifted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadDna();
      _loadCurrentPhase();
      _loadCurrentTiming();
    });
  }

  bool get _isHindi =>
      mounted && Localizations.localeOf(context).languageCode == 'hi';

  Future<void> _loadDna() async {
    setState(() => _dnaLoading = true);
    final isHindi = _isHindi;
    final result = await _repository.getReport(
      segment: widget.type.content.segment,
      reportType: PremiumAiReportTypes.dna,
      language: isHindi ? 'hi' : 'en',
    );
    if (!mounted) return;
    setState(() {
      // The backend now serves `DNA` without any entitlement check, so
      // the real response is always used as-is — no fallback, no
      // entitlement special-casing. `_aiBody` still shows a genuine
      // error (network, etc.) with Retry if the call itself fails.
      _dnaResult = result;
      _dnaLoading = false;
    });
  }

  Future<void> _loadCurrentPhase() async {
    setState(() => _phaseLoading = true);
    final isHindi = _isHindi;
    final result = await _repository.getReport(
      segment: widget.type.content.segment,
      reportType: PremiumAiReportTypes.currentPhase,
      language: isHindi ? 'hi' : 'en',
    );
    if (!mounted) return;
    setState(() {
      _phaseResult = result;
      _phaseLoading = false;
    });
  }

  /// Its own `CURRENT_TIMING` call — separate from [_loadCurrentPhase],
  /// exactly like [_loadDna] is separate from both. Previously this
  /// section had no call of its own at all; see this file's class doc
  /// comment for the audit trail.
  Future<void> _loadCurrentTiming() async {
    setState(() => _timingLoading = true);
    final isHindi = _isHindi;
    final result = await _repository.getReport(
      segment: widget.type.content.segment,
      reportType: PremiumAiReportTypes.currentTiming,
      language: isHindi ? 'hi' : 'en',
    );
    if (!mounted) return;
    setState(() {
      _timingResult = result;
      _timingLoading = false;
    });
  }

  static String _shortName(PremiumReportType type, bool isHindi) =>
      switch (type) {
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

    // Rebuild when SubscriptionProvider's data changes (e.g. right after
    // initState's loadSubscriptionInfo() call resolves, or after the user
    // returns from SubscriptionPage having subscribed) — the actual
    // entitlement decision itself still comes only from the existing,
    // unmodified hasActiveSubscription(), never recomputed here.
    context.watch<SubscriptionProvider>();
    final unlocked = hasActiveSubscription(context);

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
                loading: _dnaLoading,
                result: _dnaResult,
                fallbackText: content.about(isHindi),
                onRetry: _loadDna,
                gold: _gold,
              ),
              const SizedBox(height: 26),

              // 3. PREMIUM SECTION 1/2 — "Current {X} Phase": one
              // collapsed/expandable card. Expanded, it becomes ONE
              // continuous report with four labeled sub-sections (Current
              // Phase / Watch Out For / Remedy For This Phase / Next
              // Phase Change) — never separate cards. Gated by
              // `unlocked`; the FREE DNA section above is never part of
              // this gate.
              _SectionLabel(
                text: isHindi
                    ? 'वर्तमान $shortName चरण'
                    : 'Current $shortName Phase',
              ),
              const SizedBox(height: 12),
              unlocked
                  ? _CurrentPhaseSection(
                      loading: _phaseLoading,
                      result: _phaseResult,
                      isHindi: isHindi,
                      expanded: _phaseExpanded,
                      onToggle: () =>
                          setState(() => _phaseExpanded = !_phaseExpanded),
                      onRetry: _loadCurrentPhase,
                      gold: _gold,
                    )
                  : _PremiumLockedSection(
                      label: isHindi ? 'वर्तमान चरण' : 'Current Phase',
                      isHindi: isHindi,
                      gold: _gold,
                    ),
              const SizedBox(height: 26),

              // 4. PREMIUM SECTION 2/2 — "Current Timing": always fully
              // expanded, immediately below Current Phase — this
              // screen's daily-engagement section. Its own dedicated
              // `CURRENT_TIMING` call/result (`_timingResult`),
              // independent of Current Phase's `_phaseResult`.
              // Independently gated by `unlocked`.
              _SectionLabel(
                text: isHindi
                    ? 'वर्तमान $shortName समय'
                    : 'Current $shortName Timing',
              ),
              const SizedBox(height: 12),
              unlocked
                  ? _CurrentTimingSection(
                      loading: _timingLoading,
                      result: _timingResult,
                      isHindi: isHindi,
                      onRetry: _loadCurrentTiming,
                      gold: _gold,
                    )
                  : _PremiumLockedSection(
                      label: isHindi ? 'वर्तमान समय' : 'Current Timing',
                      isHindi: isHindi,
                      gold: _gold,
                    ),
              const SizedBox(height: 26),

              // 5. Subscription CTA — reuses the exact same navigation
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
  const _ReaderHeader({
    required this.content,
    required this.isHindi,
    required this.gold,
  });

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
      style: bodyStyle.copyWith(
        color: const Color(0xFFB8860B),
        fontWeight: FontWeight.w600,
      ),
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

/// Splits the `CURRENT_PHASE` backend response into its `## `-headed
/// sections (see [BirthChartReportReader]'s class doc comment). Pure,
/// presentation-only text splitting — does not touch
/// [PremiumAiReportResult], does not re-parse JSON, and does not talk to
/// the repository. Matches heading text case-insensitively (backend copy
/// is expected to always be English headings regardless of UI language,
/// but this is a harmless safety margin, not a requirement).
///
/// Returns an empty map when no `## ` heading is found at all, so callers
/// can detect "not the new markdown shape" and fall back to rendering
/// [raw] as a single block, unchanged from this screen's pre-existing
/// behavior.
Map<String, String> _splitPhaseMarkdown(String raw) {
  final headingPattern = RegExp(r'^##[ \t]+(.+?)[ \t]*$', multiLine: true);
  final matches = headingPattern.allMatches(raw).toList();
  if (matches.isEmpty) return const {};

  final sections = <String, String>{};
  for (var i = 0; i < matches.length; i++) {
    final heading = matches[i].group(1)!.trim();
    final start = matches[i].end;
    final end = i + 1 < matches.length ? matches[i + 1].start : raw.length;
    sections[heading] = raw.substring(start, end).trim();
  }
  return sections;
}

/// Case-insensitive lookup into [_splitPhaseMarkdown]'s result — the
/// backend's own heading casing is trusted as-is, this just guards
/// against incidental case differences.
String? _phaseSection(Map<String, String> sections, String heading) {
  for (final entry in sections.entries) {
    if (entry.key.toLowerCase() == heading.toLowerCase()) return entry.value;
  }
  return null;
}

/// The result of splitting a `CURRENT_TIMING` response into its two real
/// parts. [quickTip] is null exactly when no "Quick Tip:" delimiter was
/// found at all — a genuinely different situation from an empty string,
/// so [_CurrentTimingSection] can tell "absent" apart from "empty" and
/// fall back to its own placeholder only for the former.
class _TimingParts {
  const _TimingParts({required this.situation, required this.quickTip});

  final String situation;
  final String? quickTip;
}

/// Splits a `CURRENT_TIMING` backend response into its situation text and
/// its Quick Tip — this call's OWN real, verified contract (see
/// `current_love_timing_v1.txt` and its 4 segment siblings in the backend
/// repo): plain text, NO Markdown headings at all, structured as
/// `<2-3 sentence situation>\n\n Quick Tip:\n<one sentence>`. Deliberately
/// NOT [_splitPhaseMarkdown]/[_phaseSection] (that pair is for
/// `CURRENT_PHASE`'s five `## `-headed response only, and CURRENT_TIMING's
/// real content is confirmed, from real cached production responses
/// across every segment, to contain zero `##` markers — using the
/// markdown splitter here always returned an empty sections map, which is
/// exactly why `Quick Tip:` used to bleed into the main paragraph instead
/// of being extracted).
///
/// The literal English label "Quick Tip:" (case/spacing-tolerant — also
/// matches "Quick tip:", "QUICK TIP :", etc.) is the only delimiter this
/// parser recognizes. This is deliberate, not an oversight: no real
/// Hindi `CURRENT_TIMING` response exists yet to prove what delimiter a
/// Hindi generation actually uses (the prompt's own "Structure, exactly"
/// block hardcodes the English label even under the Hindi language
/// instruction), so inventing a localized delimiter here would be
/// guessing, not supporting a proven contract. A Hindi response that
/// doesn't contain this literal label falls back to the same "Quick Tip
/// absent" placeholder path a malformed/empty response does — never a
/// crash, never invented text — until a real Hindi delimiter can be
/// confirmed from production data.
_TimingParts _splitCurrentTimingContent(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return const _TimingParts(situation: '', quickTip: null);
  }

  final labelPattern = RegExp(r'Quick[ \t]*Tip[ \t]*:', caseSensitive: false);
  final match = labelPattern.firstMatch(trimmed);
  if (match == null) {
    return _TimingParts(situation: trimmed, quickTip: null);
  }

  final situation = trimmed.substring(0, match.start).trim();
  final quickTip = trimmed.substring(match.end).trim();
  return _TimingParts(
    situation: situation.isEmpty ? trimmed : situation,
    quickTip: quickTip.isEmpty ? null : quickTip,
  );
}

/// Centralized copy for the two premium sections — kept in one place so
/// [_CurrentPhaseSection] (reading `CURRENT_PHASE`'s `_phaseResult`) and
/// [_CurrentTimingSection] (reading its own, separate `CURRENT_TIMING`
/// `_timingResult`) can never drift out of sync on heading text or
/// fallback copy, even though each now reads its own independent backend
/// response. Every `CURRENT_PHASE`-side fallback string here is preserved
/// verbatim from this screen's pre-existing behavior, so an older cached
/// report (or a response missing a heading) renders identically to
/// before this refactor — see [BirthChartReportReader]'s class doc
/// comment.
class _PhaseCopy {
  const _PhaseCopy._();

  static const String currentPhaseHeading = 'Current Phase';
  static const String watchOutForHeading = 'Watch Out For';
  static const String remedyHeading = 'Remedy For This Phase';
  static const String nextPhaseChangeHeading = 'Next Phase Change';

  static const String currentPhaseFallbackEn =
      'This is a static preview. Premium Membership continuously updates '
      'this section with your current planetary condition.';
  static const String currentPhaseFallbackHi =
      'यह एक स्थिर पूर्वावलोकन है। प्रीमियम मेंबरशिप इस सेक्शन को आपकी वर्तमान '
      'ग्रह स्थिति के साथ लगातार अपडेट करती है।';

  static const String watchOutForFallbackEn =
      'No specific watch-outs available yet.';
  static const String watchOutForFallbackHi =
      'अभी कोई विशेष सावधानी उपलब्ध नहीं है।';

  static const String remedyFallbackEn = "Remedy details aren't available yet.";
  static const String remedyFallbackHi = 'उपाय विवरण अभी उपलब्ध नहीं है।';

  static const String nextPhaseChangeFallbackEn =
      "This section isn't available yet.";
  static const String nextPhaseChangeFallbackHi =
      'यह सेक्शन अभी उपलब्ध नहीं है।';

  static const String currentTimingFallbackEn =
      "Current timing details aren't available yet.";
  static const String currentTimingFallbackHi =
      'वर्तमान समय का विवरण अभी उपलब्ध नहीं है।';

  static const String quickTipFallbackEn = 'No quick tip available yet.';
  static const String quickTipFallbackHi =
      'अभी कोई त्वरित सुझाव उपलब्ध नहीं है।';
}

/// A labeled paragraph inside the ONE continuous Current Phase report —
/// deliberately NOT a card (no background, no border): the four
/// sub-sections must read as one flowing report, not four independent
/// widgets. See [_CurrentPhaseSection].
class _SubSection extends StatelessWidget {
  const _SubSection({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1B2E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B5563),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// PREMIUM SECTION 1/2 — "Current Phase". Collapsed by default to a
/// short excerpt of just the "Current Phase" heading's own text (same
/// collapse/expand-in-place pattern as [_FreeDnaSection]); "Read Full
/// Current Phase Report →" expands the SAME card in place into ONE
/// continuous report with, in this exact order, all four "Current
/// Phase" sub-sections from the single `CURRENT_PHASE` call: Current
/// Phase, Watch Out For, Remedy For This Phase, Next Phase Change — each
/// a plain [_SubSection], never its own card.
///
/// Fallback behavior when the response doesn't contain any of the five
/// expected `## ` headings (an older cached report predating this
/// markdown format, or a genuinely different backend shape): the excerpt
/// and the expanded report's "Current Phase" sub-section both show that
/// raw `content` verbatim (exactly how this screen has always rendered
/// `CURRENT_PHASE` before any heading-splitting existed), and the other
/// three sub-sections fall back to their own [_PhaseCopy] placeholder.
/// While loading, on any error, or on an entitlement denial, this
/// renders the same single AI-body card [_PremiumSubsection] has always
/// rendered — no expand toggle, nothing to expand into yet.
class _CurrentPhaseSection extends StatelessWidget {
  const _CurrentPhaseSection({
    required this.loading,
    required this.result,
    required this.isHindi,
    required this.expanded,
    required this.onToggle,
    required this.onRetry,
    required this.gold,
  });

  final bool loading;
  final PremiumAiReportResult? result;
  final bool isHindi;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onRetry;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final label = isHindi ? 'वर्तमान चरण' : 'Current Phase';

    if (loading || r == null || !r.isSuccess) {
      return _PremiumSubsection(
        label: label,
        loading: loading,
        result: result,
        fallbackText: isHindi
            ? _PhaseCopy.currentPhaseFallbackHi
            : _PhaseCopy.currentPhaseFallbackEn,
        isHindi: isHindi,
        onRetry: onRetry,
        gold: gold,
      );
    }

    final sections = _splitPhaseMarkdown(r.content ?? '');
    final hasHeadings = sections.isNotEmpty;

    final currentPhaseBody = hasHeadings
        ? (_phaseSection(sections, _PhaseCopy.currentPhaseHeading) ??
              (isHindi
                  ? _PhaseCopy.currentPhaseFallbackHi
                  : _PhaseCopy.currentPhaseFallbackEn))
        : (r.content ?? '');

    String subSection(String heading, String fallbackEn, String fallbackHi) {
      if (!hasHeadings) return isHindi ? fallbackHi : fallbackEn;
      return _phaseSection(sections, heading) ??
          (isHindi ? fallbackHi : fallbackEn);
    }

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
          if (!expanded)
            Text(
              currentPhaseBody,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
                height: 1.5,
              ),
            )
          else ...[
            // ONE continuous report — four labeled sub-sections in the
            // backend's own order, never separate cards.
            _SubSection(label: label, body: currentPhaseBody),
            const SizedBox(height: 14),
            _SubSection(
              label: isHindi ? 'किन बातों का ध्यान रखें' : 'Watch Out For',
              body: subSection(
                _PhaseCopy.watchOutForHeading,
                _PhaseCopy.watchOutForFallbackEn,
                _PhaseCopy.watchOutForFallbackHi,
              ),
            ),
            const SizedBox(height: 14),
            _SubSection(
              label: isHindi ? 'इस चरण के लिए उपाय' : 'Remedy For This Phase',
              body: subSection(
                _PhaseCopy.remedyHeading,
                _PhaseCopy.remedyFallbackEn,
                _PhaseCopy.remedyFallbackHi,
              ),
            ),
            const SizedBox(height: 14),
            _SubSection(
              label: isHindi ? 'अगला चरण परिवर्तन' : 'Next Phase Change',
              body: subSection(
                _PhaseCopy.nextPhaseChangeHeading,
                _PhaseCopy.nextPhaseChangeFallbackEn,
                _PhaseCopy.nextPhaseChangeFallbackHi,
              ),
            ),
          ],
          const SizedBox(height: 10),
          InkWell(
            onTap: onToggle,
            child: Text(
              expanded
                  ? (isHindi ? 'कम दिखाएं ↑' : 'Show Less ↑')
                  : (isHindi
                        ? 'पूरी वर्तमान चरण रिपोर्ट पढ़ें →'
                        : 'Read Full Current Phase Report →'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// PREMIUM SECTION 2/2 — "Current Timing". Always fully expanded — never
/// collapsed, never behind a "Read Full" toggle — this screen's primary
/// daily-engagement section. Reads its OWN, independent `CURRENT_TIMING`
/// result (`result`, backed by `_timingResult`/`_loadCurrentTiming` in
/// [BirthChartReportReader]) — a separate `GET /api/premium-report` call
/// from [_CurrentPhaseSection]'s `CURRENT_PHASE`, not a second read of
/// the same response, and never reads `_phaseResult`. Shows that call's
/// own situation text plus its own Quick Tip text, both parsed from the
/// same `CURRENT_TIMING` `content` via [_splitCurrentTimingContent] --
/// that call's real, plain-text, no-Markdown contract, never
/// [_splitPhaseMarkdown]/[_phaseSection] (that pair is `CURRENT_PHASE`
/// only). Never shows `CURRENT_PHASE`'s "Remedy For This Phase".
///
/// Fallback behavior: loading / error / entitlement-denied / null result
/// render the same single AI-body card [_PremiumSubsection] has always
/// shown for "Current Timing". A successful but empty/malformed
/// `content` falls back to the placeholder "Current Timing" copy; a
/// response with no recognizable "Quick Tip:" delimiter shows its whole
/// content as the situation and falls back to the placeholder "Quick
/// Tip" copy — it never invents a tip, and the literal words "Quick
/// Tip:" never remain visible inside the situation paragraph.
class _CurrentTimingSection extends StatelessWidget {
  const _CurrentTimingSection({
    required this.loading,
    required this.result,
    required this.isHindi,
    required this.onRetry,
    required this.gold,
  });

  final bool loading;
  final PremiumAiReportResult? result;
  final bool isHindi;
  final VoidCallback onRetry;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final label = isHindi ? 'वर्तमान समय' : 'Current Timing';

    if (loading || r == null || !r.isSuccess) {
      return _PremiumSubsection(
        label: label,
        loading: loading,
        result: result,
        fallbackText: isHindi
            ? _PhaseCopy.currentTimingFallbackHi
            : _PhaseCopy.currentTimingFallbackEn,
        isHindi: isHindi,
        onRetry: onRetry,
        gold: gold,
      );
    }

    // This call's OWN content — never `CURRENT_PHASE`'s. Splits on the
    // real, plain-text "Quick Tip:" delimiter (see
    // [_splitCurrentTimingContent]'s own doc comment) — never the
    // Markdown-heading splitter `CURRENT_PHASE` uses.
    final parts = _splitCurrentTimingContent(r.content ?? '');

    final timingBody = parts.situation.isNotEmpty
        ? parts.situation
        : (isHindi
              ? _PhaseCopy.currentTimingFallbackHi
              : _PhaseCopy.currentTimingFallbackEn);

    final quickTipBody = parts.quickTip ??
        (isHindi ? _PhaseCopy.quickTipFallbackHi : _PhaseCopy.quickTipFallbackEn);

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
              Icon(Icons.wb_sunny_rounded, size: 15, color: gold),
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
          Text(
            timingBody,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _SubSection(
            label: isHindi ? 'त्वरित सुझाव' : 'Quick Tip',
            body: quickTipBody,
          ),
        ],
      ),
    );
  }
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
    final canToggle =
        !loading && (currentResult == null || currentResult.isSuccess);

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

/// One PREMIUM section rendered LOCKED — replaces [_CurrentPhaseSection]
/// / [_CurrentTimingSection] in place, same card shape, when the user has
/// no active entitlement ([hasActiveSubscription] is false). Tapping opens
/// the existing [SubscriptionPage] via the existing [requirePremium] gate
/// — no separate purchase/payment UI, no duplicated entitlement check.
class _PremiumLockedSection extends StatelessWidget {
  const _PremiumLockedSection({
    required this.label,
    required this.isHindi,
    required this.gold,
  });

  final String label;
  final bool isHindi;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => requirePremium(context, () {}),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEDE4FB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_rounded, size: 15, color: gold),
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
              Text(
                isHindi
                    ? 'प्रीमियम मेंबरशिप के साथ अनलॉक करें →'
                    : 'Unlock with Premium Membership →',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: gold,
                ),
              ),
            ],
          ),
        ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
