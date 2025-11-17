import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/widgets/kundali_chart_north_widget.dart';
import 'kundali_section_detail_page.dart';

class KundaliDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const KundaliDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final profile = Map<String, dynamic>.from(data["profile"] ?? {});
    final location = Map<String, dynamic>.from(data["location"] ?? {});
    final dasha = Map<String, dynamic>.from(
      data["dasha_summary"]?["current_block"] ?? {},
    );

    // ⭐ FINAL FIX — exact backend path
    final List<dynamic> planets = List<dynamic>.from(
      data["chart_data"]?["planets"] ?? [],
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _HeaderSection(
              profile: profile,
              location: location,
              lagna: data["lagna_sign"] ?? "-",
              rashi: data["rashi"] ?? "-",
              mahadasha: dasha["mahadasha"] ?? "-",
              antardasha: dasha["antardasha"] ?? "-",
              planets: planets,
            ),
            const SizedBox(height: 16),

            // GRID CARDS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildGrid(context),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final List<_KTile> tiles = [
      _KTile("🧿", "Lagna Insight", data["lagna_trait"]),
      _KTile("🌙", "Rashi Traits", data["moon_traits"]),
      _KTile("☀️", "Planet Overview", data["planet_overview"]),
      _KTile("🏠", "House Overview", data["houses_overview"]),
      _KTile("⚡", "Yogas & Doshas", data["yogas"]),
      _KTile("💎", "Gemstone Suggestion", data["gemstone_suggestion"]),
      _KTile("🕉️", "Vimshottari Dasha", data["dasha_summary"]),
      _KTile("📿", "Current Dasha", data["grah_dasha_block"]),
      _KTile("🛰️", "Transit Analysis", data["transit_analysis"]),
      _KTile("❤️", "Life Aspects", data["life_aspects"]),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, i) {
        final t = tiles[i];
        return _DashTile(
          emoji: t.emoji,
          title: t.title,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    KundaliSectionDetailPage(title: t.title, data: t.data),
              ),
            );
          },
        );
      },
    );
  }
}

class _KTile {
  final String emoji;
  final String title;
  final dynamic data;
  _KTile(this.emoji, this.title, this.data);
}

//
// ---------------------- HEADER SECTION ----------------------
//

class _HeaderSection extends StatelessWidget {
  final Map<String, dynamic> profile;
  final Map<String, dynamic> location;
  final String lagna;
  final String rashi;
  final String mahadasha;
  final String antardasha;
  final List<dynamic> planets;

  const _HeaderSection({
    required this.profile,
    required this.location,
    required this.lagna,
    required this.rashi,
    required this.mahadasha,
    required this.antardasha,
    required this.planets,
  });

  // Capitalize each word
  String _cap(String? text) {
    if (text == null || text.isEmpty) return "-";
    return text
        .trim()
        .split(" ")
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(" ");
  }

  // Convert yyyy-mm-dd → dd-mm-yyyy
  String _formatDob(String? dob) {
    if (dob == null || dob.isEmpty) return "-";
    if (dob.contains("-")) {
      final p = dob.split("-");
      if (p.length == 3 && p[0].length == 4) {
        return "${p[2]}-${p[1]}-${p[0]}";
      }
    }
    return dob;
  }

  @override
  Widget build(BuildContext context) {
    print("🟦 PROFILE: $profile");
    print("🟦 PROFILE.pob: ${profile["pob"]}");

    print("🟩 LOCATION: $location");
    print("🟩 LOCATION.place_name: ${location["place_name"]}");

    final String name = _cap(profile["name"]);
    final String dob = _formatDob(profile["dob"]);
    final String tob = profile["tob"] ?? "-";

    // DEBUG BEFORE FINAL RESOLUTION
    print("🟧 BEFORE RESOLVE → profile.pob: ${profile["pob"]}");
    print("🟧 BEFORE RESOLVE → location.place_name: ${location["place_name"]}");
    print("🟧 BEFORE RESOLVE → profile.place_name: ${profile["place_name"]}");

    final String pob = profile["pob"] ?? "-";
    print("📍 DEBUG POB from profile.place_name = $pob");

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // ⭐ One-line typewriter style
          Text(
            "Name: $name  |  DOB: $dob  |  TOB: $tob  |",
            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 5),

          // ⭐ BIGGER KUNDALI CHART WITH SPACING
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFF5EAFE), // very light divine lavender center glow
                    Color(0xFF6D28D9), // Jyotishasha purple mid
                    Color(0xFF4C1D95), // deep cosmic purple edges
                  ],
                  stops: [0.15, 0.55, 1.0], // stronger center glow
                  radius: 1.1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x805B21B6), // purple ambient shadow
                    blurRadius: 24,
                    spreadRadius: 6,
                    offset: Offset(0, 8), // SHADOW DOWN → chart looks raised
                  ),
                  BoxShadow(
                    color:
                        Colors.white30, // top white highlight → EMBOSS effect
                    blurRadius: 12,
                    spreadRadius: -2,
                    offset: Offset(0, -4),
                  ),
                ],
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white24, width: 1.2),
              ),
              child: Center(
                child: KundaliChartNorthWidget(
                  planets: planets,
                  lagnaSign: lagna,
                  size: 240,
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Lagna: $lagna  |  Rashi: $rashi  |  Current Dasha: $mahadasha",
            style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

//
// ---------------------- GRID TILE ----------------------
//

class _DashTile extends StatelessWidget {
  final String emoji;
  final String title;
  final VoidCallback onTap;

  const _DashTile({
    required this.emoji,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(2, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
