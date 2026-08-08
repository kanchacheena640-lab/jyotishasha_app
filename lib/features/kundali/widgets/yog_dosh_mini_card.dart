// lib/features/kundali/widgets/yog_dosh_mini_card.dart

import 'package:flutter/material.dart';

import 'package:jyotishasha_app/features/kundali/data/identity_report_availability.dart';
import 'package:jyotishasha_app/features/kundali/widgets/report_availability_action.dart';

/// F8.5.2 — the one reusable compact card used by both the Active Yogas
/// and Active Doshas grids. Layout is always a large centered Icon →
/// centered Name → Bottom Action; no description, no effect text, no
/// long copy — deliberately compact, matching `LifeReportCard`'s premium
/// grid-tile feel rather than the older full-width [YogDoshCard] report
/// layout.
///
/// Visual language matches [IdentityCard]/`PlanetCard`/`LifeReportCard`
/// and the rest of the Kundali page: white background, 18dp radius, soft
/// lavender border, subtle shadow. The bottom action is the same shared
/// [ReportAvailabilityAction] those cards use, so report-status
/// branching lives in one place.
class YogDoshMiniCard extends StatelessWidget {
  const YogDoshMiniCard({
    super.key,
    required this.icon,
    required this.name,
    required this.status,
    required this.isHindi,
    this.onViewReport,
  });

  final String icon;
  final String name;
  final ReportAvailabilityStatus status;
  final bool isHindi;
  final VoidCallback? onViewReport;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1B2E),
            ),
          ),
          const SizedBox(height: 10),
          ReportAvailabilityAction(
            status: status,
            isHindi: isHindi,
            onTap: onViewReport,
          ),
        ],
      ),
    );
  }
}
