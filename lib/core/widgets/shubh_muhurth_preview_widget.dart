import 'package:flutter/material.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

class ShubhMuhurthPreviewWidget extends StatelessWidget {
  final List<Map<String, String>> muhurthList;

  /// 🔥 Tap on capsule
  final Function(String type)? onTapType;

  /// 🔥 View More
  final VoidCallback? onSeeMore;

  const ShubhMuhurthPreviewWidget({
    super.key,
    required this.muhurthList,
    this.onTapType,
    this.onSeeMore,
  });

  // =========================
  // 🔥 ICONS
  // =========================

  IconData _getIcon(String type) {
    switch (type) {
      case 'marriage':
        return Icons.favorite;

      case 'grah_pravesh':
        return Icons.home;

      case 'vehicle':
        return Icons.directions_car;

      case 'naamkaran':
        return Icons.child_care;

      case 'gold':
        return Icons.workspace_premium;

      case 'travel':
        return Icons.flight_takeoff;

      case 'property':
        return Icons.house;

      case 'childbirth':
        return Icons.pregnant_woman;

      default:
        return Icons.auto_awesome;
    }
  }

  // =========================
  // 🔥 TYPE MAPPING
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
    final t = AppLocalizations.of(context)!;

    const jyotishashaGradient = LinearGradient(
      colors: [Color(0xFFFF9933), Color(0xFF8E2DE2)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// 🔥 Heading
          ShaderMask(
            shaderCallback: (bounds) => jyotishashaGradient.createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
            child: Text(
              t.shubhUpcomingTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 18),

          /// 🔥 CAPSULE GRID
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: muhurthList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final item = muhurthList[index];

              final event = item['event_hi']?.isNotEmpty == true
                  ? item['event_hi']!
                  : (item['event'] ?? '');

              final type = _getType(event);

              final icon = _getIcon(type);

              return GestureDetector(
                onTap: () {
                  onTapType?.call(type);
                },

                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF4EEFF), Color(0xFFE5D9FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),

                    borderRadius: BorderRadius.circular(18),

                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: Offset(1, 2),
                      ),
                    ],
                  ),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// 🔥 ICON
                      Icon(icon, size: 28, color: const Color(0xFF6D28D9)),

                      const SizedBox(height: 8),

                      /// 🔥 TITLE
                      Text(
                        event,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3A0CA3),
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 18),

          /// 🔥 SEE MORE
          GestureDetector(
            onTap: onSeeMore,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),

              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                ),

                borderRadius: BorderRadius.circular(14),

                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.26),

                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),

              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 18,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    t.viewFullMuhurthCalendar,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
