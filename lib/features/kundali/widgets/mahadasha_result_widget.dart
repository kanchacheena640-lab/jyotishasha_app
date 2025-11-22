import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MahadashaResultWidget extends StatelessWidget {
  final Map<String, dynamic> data; // kept for compatibility
  final Map<String, dynamic> kundali;

  const MahadashaResultWidget({
    super.key,
    required this.data,
    required this.kundali,
  });

  @override
  Widget build(BuildContext context) {
    final dashaSummary =
        (kundali['dasha_summary'] ?? {}) as Map<String, dynamic>;

    if (dashaSummary.isEmpty) {
      return _emptyState(context);
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

    final mahaName = (currentBlock['mahadasha'] ?? '-').toString();
    final antarName = (currentBlock['antardasha'] ?? '-').toString();

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _headerCard(
            context,
            mahaName: mahaName,
            antarName: antarName,
            period: currentBlock['period']?.toString(),
            impact: currentBlock['impact_snippet']?.toString(),
          ),
          const SizedBox(height: 16),
          _tabBar(context),
          const SizedBox(height: 12),
          // Important: fixed height so TabBarView works inside scroll
          SizedBox(
            height: 420,
            child: TabBarView(
              children: [
                _currentMahadashaTab(
                  context,
                  currentMaha: currentMaha,
                  currentAntar: currentAntar,
                ),
                _allMahadashasTab(
                  context,
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

  // ------------------------------------------------------------
  // HEADER CARD: Current Mahadasha → Antardasha + Prediction
  // ------------------------------------------------------------
  Widget _headerCard(
    BuildContext context, {
    required String mahaName,
    required String antarName,
    String? period,
    String? impact,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.14),
            colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Dasha',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$mahaName  →  $antarName',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const Spacer(),
              if (period != null)
                Text(
                  period,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.65),
                  ),
                  textAlign: TextAlign.right,
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (impact != null && impact.trim().isNotEmpty)
            Text(
              impact,
              style: GoogleFonts.montserrat(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                height: 1.4,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // TAB BAR
  // ------------------------------------------------------------
  Widget _tabBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
          width: 0.9,
        ),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
        labelStyle: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Current Mahadasha'),
          Tab(text: 'All Mahadashas'),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // TAB 1: CURRENT MAHADASHA → Vertical Antar List
  // ------------------------------------------------------------
  Widget _currentMahadashaTab(
    BuildContext context, {
    required Map<String, dynamic> currentMaha,
    required Map<String, dynamic> currentAntar,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final mahaName = (currentMaha['mahadasha'] ?? '-').toString();
    final mahaStart = currentMaha['start']?.toString();
    final mahaEnd = currentMaha['end']?.toString();

    final antarList =
        (currentMaha['antardashas'] as List?)?.cast<Map<String, dynamic>>() ??
        [];

    return ListView(
      padding: const EdgeInsets.only(top: 4, left: 2, right: 2, bottom: 12),
      children: [
        // Mahadasha timeline bar
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.25),
              width: 0.9,
            ),
          ),
          child: Row(
            children: [
              _verticalDotBar(context),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mahaName,
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (mahaStart != null && mahaEnd != null)
                      Text(
                        '${_formatDate(mahaStart)}  –  ${_formatDate(mahaEnd)}',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        Text(
          'Antardasha Timeline',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.85),
          ),
        ),
        const SizedBox(height: 6),

        // Antar list (vertical)
        ...antarList.map((antar) {
          final antarName = (antar['planet'] ?? '-').toString();
          final start = antar['start']?.toString();
          final end = antar['end']?.toString();

          final isCurrent =
              antarName == (currentAntar['planet'] ?? '').toString() &&
              start == currentAntar['start']?.toString() &&
              end == currentAntar['end']?.toString();

          return _antarRow(
            context,
            planet: antarName,
            start: start,
            end: end,
            isCurrent: isCurrent,
          );
        }).toList(),
      ],
    );
  }

  Widget _antarRow(
    BuildContext context, {
    required String planet,
    String? start,
    String? end,
    required bool isCurrent,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrent
            ? colorScheme.primary.withOpacity(0.08)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? colorScheme.primary.withOpacity(0.7)
              : colorScheme.outline.withOpacity(0.2),
          width: isCurrent ? 1.2 : 0.8,
        ),
      ),
      child: Row(
        children: [
          // Dot + line
          Container(
            width: 16,
            alignment: Alignment.centerLeft,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent
                    ? colorScheme.primary
                    : colorScheme.primary.withOpacity(0.4),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planet,
                  style: GoogleFonts.montserrat(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (start != null && end != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_formatDate(start)}  –  ${_formatDate(end)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Now',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // TAB 2: ALL MAHADASHA LIST (VERTICAL) → Bottom Sheet for Antars
  // ------------------------------------------------------------
  Widget _allMahadashasTab(
    BuildContext context, {
    required List<Map<String, dynamic>> allMahadashas,
    required String currentMahadashaName,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      itemBuilder: (context, index) {
        final maha = allMahadashas[index];
        final name = (maha['mahadasha'] ?? '-').toString();
        final start = maha['start']?.toString();
        final end = maha['end']?.toString();
        final isCurrent = name == currentMahadashaName;

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showAntardashaBottomSheet(context, maha, isCurrent),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrent
                    ? colorScheme.primary.withOpacity(0.75)
                    : colorScheme.outline.withOpacity(0.25),
                width: isCurrent ? 1.3 : 0.9,
              ),
            ),
            child: Row(
              children: [
                _verticalDotBar(context),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (start != null && end != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${_formatDate(start)}  –  ${_formatDate(end)}',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 18,
                  color: colorScheme.onSurface.withOpacity(0.5),
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

  void _showAntardashaBottomSheet(
    BuildContext context,
    Map<String, dynamic> maha,
    bool isCurrent,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final name = (maha['mahadasha'] ?? '-').toString();
    final start = maha['start']?.toString();
    final end = maha['end']?.toString();
    final antarList =
        (maha['antardashas'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outline.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '$name Mahadasha',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
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
                            color: colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Current',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (start != null && end != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDate(start)}  –  ${_formatDate(end)}',
                      style: GoogleFonts.montserrat(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Antardasha Timeline',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: antarList.length,
                      itemBuilder: (context, index) {
                        final antar = antarList[index];
                        final antarName = (antar['planet'] ?? '-').toString();
                        final aStart = antar['start']?.toString();
                        final aEnd = antar['end']?.toString();

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.25),
                              width: 0.9,
                            ),
                          ),
                          child: Row(
                            children: [
                              _verticalDotBar(context, small: true),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      antarName,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    if (aStart != null && aEnd != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          '${_formatDate(aStart)}  –  ${_formatDate(aEnd)}',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                            color: colorScheme.onSurface
                                                .withOpacity(0.7),
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

  // ------------------------------------------------------------
  // SMALL HELPERS
  // ------------------------------------------------------------
  Widget _verticalDotBar(BuildContext context, {bool small = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final height = small ? 30.0 : 38.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 2,
          height: height / 2.4,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.32),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        Container(
          width: small ? 8 : 10,
          height: small ? 8 : 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primary,
          ),
        ),
        Container(
          width: 2,
          height: height / 2.4,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.18),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const monthNames = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final d = dt.day.toString().padLeft(2, '0');
      final m = monthNames[dt.month];
      final y = dt.year.toString();
      return '$d $m $y';
    } catch (_) {
      return raw;
    }
  }

  Widget _emptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
          width: 0.9,
        ),
      ),
      child: Text(
        'Dasha data is not available for this profile.',
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface.withOpacity(0.75),
        ),
      ),
    );
  }
}
