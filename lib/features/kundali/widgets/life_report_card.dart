// lib/features/kundali/widgets/life_report_card.dart

import 'package:flutter/material.dart';

import 'package:jyotishasha_app/features/kundali/data/identity_report_availability.dart';
import 'package:jyotishasha_app/features/kundali/widgets/report_availability_action.dart';

/// F8.5 — the one reusable card used by all twelve Life Area tiles in
/// the grid. Layout is always Icon → Title → one-line educational
/// Introduction → Bottom Action; only the content and [status] differ
/// per card — no per-card layout variants.
///
/// Visual language matches [IdentityCard]/`PlanetCard`/`YogDoshCard` and
/// the rest of the Kundali page: white background, 18dp radius, soft
/// lavender border, subtle shadow. The bottom action is the same shared
/// [ReportAvailabilityAction] those cards use, so report-status
/// branching lives in one place.
class LifeReportCard extends StatelessWidget {
  const LifeReportCard({
    super.key,
    required this.icon,
    required this.title,
    required this.intro,
    required this.status,
    required this.isHindi,
    this.onViewReport,
  });

  final String icon;
  final String title;
  final String intro;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1B2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            intro,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
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
