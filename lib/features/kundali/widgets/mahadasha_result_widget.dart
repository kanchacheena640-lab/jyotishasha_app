// lib/features/kundali/widgets/mahadasha_result_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

// ---------------------------------------------------------
// ONLY IMPACT SNIPPET IS BILINGUAL
// ---------------------------------------------------------
String pickImpact(Map<String, dynamic> json, String lang) {
  if (lang == "hi") {
    final hi = (json["impact_snippet_hi"] ?? "").toString().trim();
    if (hi.isNotEmpty) return hi;
  }
  return (json["impact_snippet"] ?? "").toString();
}

class MahadashaResultWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic> kundali;

  const MahadashaResultWidget({
    super.key,
    required this.data,
    required this.kundali,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;

    final dashaSummary =
        (kundali['dasha_summary'] ?? {}) as Map<String, dynamic>;

    if (dashaSummary.isEmpty) {
      return _emptyState(context, t);
    }

    final currentBlock =
        (dashaSummary['current_block'] ?? {}) as Map<String, dynamic>;
    final currentMaha =
        (dashaSummary['current_mahadasha'] ?? {}) as Map<String, dynamic>;
    final currentAntar =
        (dashaSummary['current_antardasha'] ?? {}) as Map<String, dynamic>;
    final allMahadashas =
        (dashaSummary['mahadashas'] as List?)?.cast<Map<String, dynamic>>() ??
        [];

    // ⭐ ONLY THESE TWO ARE BILINGUAL
    final impact = pickImpact(currentBlock, lang);

    // ⭐ ALWAYS ENGLISH PLANET NAMES
    final mahaName = currentBlock["mahadasha"]?.toString() ?? "-";
    final antarName = currentBlock["antardasha"]?.toString() ?? "-";

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _headerCard(
            context,
            t,
            mahaName: mahaName,
            antarName: antarName,
            period: currentBlock['period']?.toString(),
            impact: impact,
          ),

          const SizedBox(height: 16),
          _tabBar(context, t),
          const SizedBox(height: 12),

          SizedBox(
            height: 420,
            child: TabBarView(
              children: [
                _currentMahadashaTab(
                  context,
                  t,
                  currentMaha: currentMaha,
                  currentAntar: currentAntar,
                ),
                _allMahadashasTab(
                  context,
                  t,
                  allMahadashas: allMahadashas,
                  currentMahadashaName: mahaName,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================
  Widget _headerCard(
    BuildContext context,
    AppLocalizations t, {
    required String mahaName,
    required String antarName,
    String? period,
    String? impact,
  }) {
    final color = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.primary.withOpacity(0.14),
            color.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.primary.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.currentDasha,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              color: color.primary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),

          // CURRENT BLOCK
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "$mahaName → $antarName",
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: color.onSurface,
                  ),
                ),
              ),
              const Spacer(),
              if (period != null)
                Text(
                  period,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: color.onSurface.withOpacity(0.6),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          if (impact != null && impact.trim().isNotEmpty)
            Text(
              impact,
              style: GoogleFonts.montserrat(
                fontSize: 12.5,
                height: 1.35,
                color: color.onSurface.withOpacity(0.8),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // TAB BAR
  // =========================================================
  Widget _tabBar(BuildContext context, AppLocalizations t) {
    final color = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.outline.withOpacity(0.3)),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: color.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.montserrat(),
        labelColor: color.primary,
        unselectedLabelColor: color.onSurface.withOpacity(0.6),
        tabs: [
          Tab(text: t.currentMahadasha),
          Tab(text: t.allMahadashas),
        ],
      ),
    );
  }

  // =========================================================
  // TAB 1 — CURRENT MAHADASHA
  // =========================================================
  Widget _currentMahadashaTab(
    BuildContext context,
    AppLocalizations t, {
    required Map<String, dynamic> currentMaha,
    required Map<String, dynamic> currentAntar,
  }) {
    final color = Theme.of(context).colorScheme;

    final mahaName = currentMaha["mahadasha"]?.toString() ?? "-";
    final mahaStart = currentMaha['start']?.toString();
    final mahaEnd = currentMaha['end']?.toString();

    final antars =
        (currentMaha['antardashas'] as List?)?.cast<Map<String, dynamic>>() ??
        [];

    return ListView(
      padding: const EdgeInsets.all(4),
      children: [
        _mahaTimelineCard(context, mahaName, mahaStart, mahaEnd),
        const SizedBox(height: 12),

        Text(
          t.antardashaTimeline,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: color.onSurface.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),

        ...antars.map((a) {
          final name = a["planet"]?.toString() ?? "-";
          final start = a['start'];
          final end = a['end'];

          final isCurrent =
              name == (currentAntar['planet']?.toString() ?? "-") &&
              start == currentAntar['start'] &&
              end == currentAntar['end'];

          return _antarRow(
            context,
            t,
            planet: name,
            start: start,
            end: end,
            isCurrent: isCurrent,
          );
        }),
      ],
    );
  }

  Widget _mahaTimelineCard(
    BuildContext context,
    String name,
    String? start,
    String? end,
  ) {
    final color = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.outline.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          _dotBar(context),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                if (start != null && end != null)
                  Text(
                    "${_formatDate(start)} – ${_formatDate(end)}",
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: color.onSurface.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _antarRow(
    BuildContext context,
    AppLocalizations t, {
    required String planet,
    String? start,
    String? end,
    required bool isCurrent,
  }) {
    final color = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrent ? color.primary.withOpacity(0.10) : color.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? color.primary.withOpacity(0.7)
              : color.outline.withOpacity(0.25),
          width: isCurrent ? 1.2 : 0.8,
        ),
      ),
      child: Row(
        children: [
          _dotBar(context, small: true),
          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planet,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (start != null && end != null)
                  Text(
                    "${_formatDate(start)} – ${_formatDate(end)}",
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: color.onSurface.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),

          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                t.now,
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // TAB 2 — ALL MAHADASHAS
  // =========================================================
  Widget _allMahadashasTab(
    BuildContext context,
    AppLocalizations t, {
    required List<Map<String, dynamic>> allMahadashas,
    required String currentMahadashaName,
  }) {
    final color = Theme.of(context).colorScheme;

    return ListView.separated(
      itemBuilder: (context, i) {
        final maha = allMahadashas[i];

        final name = maha["mahadasha"]?.toString() ?? "-";
        final start = maha['start'];
        final end = maha['end'];

        final isCurrent = name == currentMahadashaName;

        return InkWell(
          onTap: () => _openAntarSheet(context, t, maha, isCurrent),
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: color.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrent
                    ? color.primary.withOpacity(0.8)
                    : color.outline.withOpacity(0.25),
                width: isCurrent ? 1.3 : 1,
              ),
            ),
            child: Row(
              children: [
                _dotBar(context),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (start != null && end != null)
                        Text(
                          "${_formatDate(start)} – ${_formatDate(end)}",
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: color.onSurface.withOpacity(0.7),
                          ),
                        ),
                    ],
                  ),
                ),

                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: color.onSurface.withOpacity(0.5),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemCount: allMahadashas.length,
    );
  }

  // =========================================================
  // BOTTOM SHEET — ANTARDASHAS
  // =========================================================
  void _openAntarSheet(
    BuildContext context,
    AppLocalizations t,
    Map<String, dynamic> maha,
    bool isCurrent,
  ) {
    final color = Theme.of(context).colorScheme;

    final name = maha["mahadasha"]?.toString() ?? "-";
    final start = maha['start'];
    final end = maha['end'];

    final antarList =
        (maha['antardashas'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color.outline.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Text(
                        t.mahadashaOf(name),
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),

                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            t.current,
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color.primary,
                            ),
                          ),
                        ),
                    ],
                  ),

                  if (start != null && end != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "${_formatDate(start)} – ${_formatDate(end)}",
                        style: GoogleFonts.montserrat(
                          fontSize: 11.5,
                          color: color.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  Text(
                    t.antardashaTimeline,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: antarList.length,
                      itemBuilder: (context, index) {
                        final antar = antarList[index];

                        final aName = antar["planet"]?.toString() ?? "-";
                        final aStart = antar['start'];
                        final aEnd = antar['end'];

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: color.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: color.outline.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              _dotBar(context, small: true),
                              const SizedBox(width: 10),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      aName,
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (aStart != null && aEnd != null)
                                      Text(
                                        "${_formatDate(aStart)} – ${_formatDate(aEnd)}",
                                        style: GoogleFonts.montserrat(
                                          fontSize: 11,
                                          color: color.onSurface.withOpacity(
                                            0.7,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================
  // HELPERS
  // =========================================================
  Widget _dotBar(BuildContext context, {bool small = false}) {
    final color = Theme.of(context).colorScheme;
    final size = small ? 30.0 : 40.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 2,
          height: size / 2.4,
          decoration: BoxDecoration(
            color: color.primary.withOpacity(0.32),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        Container(
          width: small ? 8 : 10,
          height: small ? 8 : 10,
          decoration: BoxDecoration(
            color: color.primary,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 2,
          height: size / 2.4,
          decoration: BoxDecoration(
            color: color.primary.withOpacity(0.18),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = [
        "",
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];
      return "${dt.day.toString().padLeft(2, '0')} ${months[dt.month]} ${dt.year}";
    } catch (_) {
      return raw;
    }
  }

  Widget _emptyState(BuildContext context, AppLocalizations t) {
    final color = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.outline.withOpacity(0.3)),
      ),
      child: Text(
        t.dashaDataUnavailable,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          color: color.onSurface.withOpacity(0.75),
        ),
      ),
    );
  }
}
