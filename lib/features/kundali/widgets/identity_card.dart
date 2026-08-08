// lib/features/kundali/widgets/identity_card.dart

import 'package:flutter/material.dart';

import 'package:jyotishasha_app/features/kundali/data/identity_report_availability.dart';
import 'package:jyotishasha_app/features/kundali/widgets/report_availability_action.dart';

/// F8.2/F8.6 — the one reusable card used by every "Know Yourself" entry
/// (Ascendant, Moon Sign, Nakshatra, Current Dasha). Layout is always
/// Title → Value → Summary (max two lines — detailed explanations belong
/// on the report page, not here) → Bottom Action; only the content and
/// [status] differ per card — no per-card layout variants.
///
/// Visual language matches the rest of Home: white background, 18dp
/// radius, soft lavender border, subtle shadow.
///
/// The bottom action never navigates anywhere (out of scope for F8.2) —
/// when [status] is [ReportAvailabilityStatus.available] it is rendered
/// as tappable (calling [onViewReport] if one is supplied); when
/// [ReportAvailabilityStatus.comingSoon] it is grey and genuinely
/// non-interactive, not just visually disabled.
class IdentityCard extends StatelessWidget {
  const IdentityCard({
    super.key,
    required this.title,
    required this.value,
    required this.summary,
    required this.status,
    required this.isHindi,
    this.onViewReport,
  });

  final String title;
  final String value;
  final String summary;
  final ReportAvailabilityStatus status;
  final bool isHindi;
  final VoidCallback? onViewReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1B2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
              height: 1.3,
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
