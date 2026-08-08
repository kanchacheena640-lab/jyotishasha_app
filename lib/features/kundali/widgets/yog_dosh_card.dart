// lib/features/kundali/widgets/yog_dosh_card.dart

import 'package:flutter/material.dart';

import 'package:jyotishasha_app/features/kundali/data/identity_report_availability.dart';
import 'package:jyotishasha_app/features/kundali/widgets/report_availability_action.dart';

/// F8.4 — the one reusable card used by both the Yog and Dosh sections.
/// Layout is always Name → one-line Effect → Bottom Action; only the
/// content and [status] differ per card — no per-card layout variants,
/// no separate Yog vs Dosh card widget.
///
/// Visual language matches [IdentityCard]/`PlanetCard` and the rest of
/// Home: white background, 18dp radius, soft lavender border, subtle
/// shadow. The bottom action is the same shared [ReportAvailabilityAction]
/// those cards use, so report-status branching lives in one place.
class YogDoshCard extends StatelessWidget {
  const YogDoshCard({
    super.key,
    required this.name,
    required this.effect,
    required this.status,
    required this.isHindi,
    this.onViewReport,
  });

  final String name;
  final String effect;
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
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1B2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            effect,
            style: const TextStyle(
              fontSize: 13,
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
