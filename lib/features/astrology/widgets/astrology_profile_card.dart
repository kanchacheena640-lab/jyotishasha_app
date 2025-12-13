import 'package:flutter/material.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

class AstrologyProfileCard extends StatelessWidget {
  final Map<String, dynamic> kundali;

  const AstrologyProfileCard({super.key, required this.kundali});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final profile = kundali["profile"] ?? {};

    final lagna = (kundali["lagna_sign"] ?? "-").toString();
    final rashi = (kundali["rashi"] ?? "-").toString();

    final maha =
        kundali["dasha_summary"]?["current_block"]?["mahadasha"]?.toString() ??
        "-";
    final antar =
        kundali["dasha_summary"]?["current_block"]?["antardasha"]?.toString() ??
        "-";
    final activeDasha = "$maha - $antar";

    final nakshatra = _extractNakshatra(kundali);

    final moon = rashi.toLowerCase().replaceAll(" ", "_");
    final moonImagePath = "assets/zodiac/$moon.png";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ⭐ MAIN PURPLE CARD
        Container(
          margin: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.profile_title, // ⭐ LOCALIZED
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _info(t.profile_name, profile["name"]),
                    _info(t.profile_dob, _format(profile["dob"])),
                    _info(t.profile_tob, profile["tob"]),
                    _info(
                      t.profile_pob,
                      profile["pob"] ?? profile["place"] ?? "-",
                    ),

                    const SizedBox(height: 14),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // RIGHT SIDE IMAGE
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 95,
                  height: 95,
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      colors: [Color(0xFFF5EAFE), Color(0xFF7C3AED)],
                      stops: [0.25, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 1.2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      moonImagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.brightness_2,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ⭐ OUTSIDE BLUE TEXT SECTION
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ⭐ Rashi | Lagna | Nakshatra
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  color: const Color(0xFF3B56A6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
                children: [
                  TextSpan(text: "${t.profile_rashi}: $rashi"),
                  const TextSpan(text: "   |   "),
                  TextSpan(text: "${t.profile_lagna}: $lagna"),
                  const TextSpan(text: "   |   "),
                  TextSpan(text: "${t.profile_nakshatra}: $nakshatra"),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ⭐ ACTIVE DASHAS
            Text(
              "${t.profile_active_planets}: $activeDasha",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF3B56A6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _extractNakshatra(Map<String, dynamic> kundali) {
    final fbNak = kundali["nakshatra"];
    if (fbNak is String && fbNak.trim().isNotEmpty) return fbNak.trim();

    final planets = kundali["planet_overview"] ?? [];
    for (var p in planets) {
      if (p["planet"]?.toString().toLowerCase() == "moon") {
        final summary = p["summary"]?.toString() ?? "";
        final lines = summary.split("\n");
        for (var line in lines) {
          if (line.contains("Nakshatra")) {
            return line.split(":")[1].split("(")[0].trim();
          }
        }
      }
    }
    return "-";
  }

  Widget _info(String label, dynamic value) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Text(
      "$label: ${value ?? "-"}",
      style: TextStyle(
        color: Colors.white.withOpacity(0.90),
        fontSize: 13.5,
        height: 1.3,
      ),
    ),
  );

  String _format(String? d) {
    if (d == null || !d.contains("-")) return d ?? "-";
    final p = d.split("-");
    return "${p[2]}-${p[1]}-${p[0]}";
  }
}
