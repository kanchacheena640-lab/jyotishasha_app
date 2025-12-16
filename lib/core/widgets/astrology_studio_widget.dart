import 'package:flutter/material.dart';
import 'package:jyotishasha_app/features/astrology/astrology_page.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

class AstrologyStudioWidget extends StatelessWidget {
  final Map<String, dynamic> kundali;

  const AstrologyStudioWidget({super.key, required this.kundali});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!; // localization

    final List<Map<String, String>> categories = [
      {"title": t.studioProfile, "key": "profile", "icon": "🌟"},
      {"title": t.studioPlanets, "key": "planets", "icon": "🪐"},
      {"title": t.studioBhava, "key": "bhava", "icon": "🏛️"},
      {"title": t.studioDasha, "key": "dasha", "icon": "⏳"},
      {"title": t.studioLifeAspects, "key": "life", "icon": "💫"},
      {"title": t.studioYogDosh, "key": "yog", "icon": "🔱"},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔮 HEADER
          Text(
            t.astrologyStudio,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6D28D9),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            t.astrologyStudioSubtitle,
            style: TextStyle(
              fontSize: 13.8,
              height: 1.4,
              color: Colors.black87.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 18),

          // ⭐ CLASSY CATEGORY BUTTONS
          Column(
            children: categories.map((cat) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AstrologyPage(selectedSection: cat["key"]!),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(cat["icon"]!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cat["title"]!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
