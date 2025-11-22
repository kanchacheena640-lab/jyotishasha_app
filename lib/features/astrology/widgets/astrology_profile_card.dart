import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AstrologyProfileCard extends StatelessWidget {
  final Map<String, dynamic> kundali;

  const AstrologyProfileCard({super.key, required this.kundali});

  @override
  Widget build(BuildContext context) {
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

    // Nakshatra smart detection
    final nakshatra = _extractNakshatra(kundali);

    // Moon image
    final moon = rashi.toLowerCase().replaceAll(" ", "_");
    final moonImagePath = "assets/zodiac/$moon.png";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ************ ORIGINAL CARD (UNCHANGED) ************
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
              // LEFT SIDE TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Astrology Profile",
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _info("Name", profile["name"]),
                    _info("DOB", _format(profile["dob"])),
                    _info("TOB", profile["tob"]),
                    _info("POB", profile["pob"] ?? profile["place"]),

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

        // ************ BLUE SECTION OUTSIDE CARD ************
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ⭐ SINGLE LINE — Rashi | Ascendant | Nakshatra
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF3B56A6), // DARK BLUE
                  fontSize: 13, // SMALL PREMIUM SIZE
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
                children: [
                  TextSpan(text: "Rashi: $rashi"),
                  TextSpan(text: "   |   "),
                  TextSpan(text: "Ascendant: $lagna"),
                  TextSpan(text: "   |   "),
                  TextSpan(text: "Nakshatra: $nakshatra"),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ⭐ SECOND LINE — Active Planets
            Text(
              "Active Planets: $activeDasha",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: const Color(0xFF3B56A6), // SAME DARK BLUE
                fontSize: 13, // SAME SMALL SIZE
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ************ Helper Methods ************

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
      style: GoogleFonts.montserrat(
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
