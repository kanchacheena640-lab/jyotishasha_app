import 'package:flutter/material.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

/// "Shubh Muhurta" — F6.7 premium redesign, bringing this section into the
/// same white-card / soft-lavender-border / subtle-shadow / centered-
/// divider-heading design language already used by Current Timing,
/// Today's Essentials, and Current Planetary Influence.
///
/// Presentation only: the category list (`muhurthList`), its order, and
/// both navigation callbacks (`onTapType`, `onSeeMore`) are unchanged —
/// same data, same taps, same destinations. `MuhurthPage`, the backend,
/// and the Shareable Cards engine are untouched by this widget entirely.
///
/// Card content is Icon + Category Name. A "Next Date" line was part of
/// the original spec, but no per-category date is available here without
/// a new backend call from Home — this widget only ever receives static
/// category labels from `dashboard_home_section.dart`, with no date data.
/// Adding a fetch would be a business-logic/data change, not a UI
/// redesign, so it was intentionally left out (see the F6.7 deliverable).
class ShubhMuhurthPreviewWidget extends StatelessWidget {
  final List<Map<String, String>> muhurthList;

  /// Tap on a category card.
  final Function(String type)? onTapType;

  /// "View All Upcoming Muhurth →".
  final VoidCallback? onSeeMore;

  const ShubhMuhurthPreviewWidget({
    super.key,
    required this.muhurthList,
    this.onTapType,
    this.onSeeMore,
  });

  // =========================
  // ICONS — same mapping as before, just rendered smaller/monochrome now.
  // =========================

  IconData _getIcon(String type) {
    switch (type) {
      case 'marriage':
        return Icons.favorite_rounded;

      case 'grah_pravesh':
        return Icons.home_rounded;

      case 'vehicle':
        return Icons.directions_car_rounded;

      case 'naamkaran':
        return Icons.child_care_rounded;

      case 'gold':
        return Icons.workspace_premium_rounded;

      case 'travel':
        return Icons.flight_takeoff_rounded;

      case 'property':
        return Icons.house_rounded;

      case 'childbirth':
        return Icons.pregnant_woman_rounded;

      default:
        return Icons.auto_awesome_rounded;
    }
  }

  // =========================
  // TYPE MAPPING — unchanged.
  // =========================

  String _getType(String event) {
    event = event.toLowerCase();

    if (event.contains('naam') || event.contains('नाम')) {
      return 'naamkaran';
    }

    if (event.contains('marriage') ||
        event.contains('vivah') ||
        event.contains('विवाह')) {
      return 'marriage';
    }

    if (event.contains('griha') ||
        event.contains('grah') ||
        event.contains('गृह')) {
      return 'grah_pravesh';
    }

    if (event.contains('vehicle') || event.contains('वाहन')) {
      return 'vehicle';
    }

    if (event.contains('gold') || event.contains('सोना')) {
      return 'gold';
    }

    if (event.contains('travel') || event.contains('यात्रा')) {
      return 'travel';
    }

    if (event.contains('property') || event.contains('संपत्ति')) {
      return 'property';
    }

    if (event.contains('child') || event.contains('शिशु')) {
      return 'childbirth';
    }

    return 'marriage';
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = AppLocalizations.of(
      context,
    )!.localeName.startsWith('hi');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildHeading(isHindi),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: muhurthList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final item = muhurthList[index];

            final event = item['event_hi']?.isNotEmpty == true
                ? item['event_hi']!
                : (item['event'] ?? '');

            final type = _getType(event);
            final icon = _getIcon(type);

            return _CategoryCard(
              icon: icon,
              label: event,
              onTap: () => onTapType?.call(type),
            );
          },
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: onSeeMore,
          child: Text(
            isHindi
                ? 'सभी आगामी मुहूर्त देखें →'
                : 'View All Upcoming Muhurth →',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B21A8),
            ),
          ),
        ),
      ],
    );
  }

  /// Centered heading with small purple divider lines on both sides — same
  /// treatment as "Current Timing", "Today's Essentials", and "Current
  /// Planetary Influence" (F6.6/F6.7).
  Widget _buildHeading(bool isHindi) {
    Widget divider() => Container(
      width: 24,
      height: 1,
      color: const Color(0xFF6B21A8).withValues(alpha: 0.3),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        divider(),
        const SizedBox(width: 10),
        Text(
          isHindi ? 'शुभ मुहूर्त' : 'Shubh Muhurta',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F1B2E),
          ),
        ),
        const SizedBox(width: 10),
        divider(),
      ],
    );
  }
}

/// One compact category card — white background, 18dp radius, 1dp Soft
/// Lavender border, subtle shadow: the exact same card language already
/// used by Today's Essentials and the Current Planetary Influence card.
/// No gradients, no coloured backgrounds, no oversized icons.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: const Color(0xFF6B21A8)),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1B2E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
