// lib/features/kundali/widgets/planet_card.dart

import 'package:flutter/material.dart';

import 'package:jyotishasha_app/features/kundali/data/identity_report_availability.dart';
import 'package:jyotishasha_app/features/kundali/widgets/report_availability_action.dart';

/// F8.3/F8.6 — the one reusable card used by all nine Planetary
/// Influences cards (Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn,
/// Rahu, Ketu). Layout is always Planet Icon + Name → Current Position
/// (max one line) → one-line Impact → Bottom Action; only the content
/// and [status] differ per card — no per-card layout variants.
///
/// Visual language matches [IdentityCard] and the rest of Home: white
/// background, 18dp radius, soft lavender border, subtle shadow. The
/// bottom action itself is the shared [ReportAvailabilityAction] used by
/// [IdentityCard] too, so report-status branching lives in one place.
class PlanetCard extends StatelessWidget {
  const PlanetCard({
    super.key,
    required this.icon,
    required this.name,
    required this.position,
    required this.impact,
    required this.status,
    required this.isHindi,
    this.onViewReport,
  });

  final String icon;
  final String name;
  final String position;
  final String impact;
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
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1B2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            position,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            impact,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
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
