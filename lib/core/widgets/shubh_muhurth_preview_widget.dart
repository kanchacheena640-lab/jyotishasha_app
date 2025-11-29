import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

class ShubhMuhurthPreviewWidget extends StatelessWidget {
  final List<Map<String, String>> muhurthList;
  final VoidCallback? onSeeMore;

  const ShubhMuhurthPreviewWidget({
    super.key,
    required this.muhurthList,
    this.onSeeMore,
  });

  // Emoji mapping
  String _getEmoji(String event) {
    event = event.toLowerCase();
    if (event.contains('marriage')) return '💍';
    if (event.contains('vivah')) return '💍';
    if (event.contains('griha') || event.contains('grah')) return '🏠';
    if (event.contains('vehicle') || event.contains('car')) return '🚗';
    if (event.contains('naam') || event.contains('naming')) return '👶';
    return '🌸';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // Gradient
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
          // 🌈 Localized Gradient Heading
          ShaderMask(
            shaderCallback: (bounds) => jyotishashaGradient.createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
            child: Text(
              t.shubhUpcomingTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                textStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ⭐ Compact Horizontal Cards
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: muhurthList.length,
              itemBuilder: (context, index) {
                final item = muhurthList[index];
                final emoji = _getEmoji(item['event'] ?? '');

                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEDE7FF), Color(0xFFD6CCFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(1, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date + Emoji
                      Text(
                        "$emoji  ${item['date'] ?? ''}",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3A0CA3),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Event name (already localized by backend)
                      Text(
                        item['event'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF240046),
                        ),
                      ),

                      const Spacer(),

                      // ⭐ Score
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            "${item['score'] ?? ''}${t.shubhScoreSuffix}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF3C096C),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ⭐ Localized "See More"
          GestureDetector(
            onTap: onSeeMore,
            child: Text(
              t.shubhSeeMore,
              style: GoogleFonts.montserrat(
                textStyle: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF5A189A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
