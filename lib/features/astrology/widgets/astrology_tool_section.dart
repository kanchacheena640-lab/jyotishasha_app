// lib/features/astrology/widgets/astrology_tool_section.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:jyotishasha_app/features/astrology/data/astrology_meta.dart';

class AstrologyToolSection extends StatefulWidget {
  final Map<String, dynamic> kundali;

  const AstrologyToolSection({super.key, required this.kundali});

  @override
  State<AstrologyToolSection> createState() => _AstrologyToolSectionState();
}

/// ============================================================================
/// 🔥 RESOLVE TOOL DATA
/// ============================================================================
dynamic _resolveToolData(String id, Map k) {
  // PROFILE TOOLS
  // ============================================================
  // ⭐ RASHI (Moon Sign) — Final Clean Block
  // ============================================================
  if (id == "rashi") {
    final mt = k["moon_traits"] ?? {};

    return {
      // Rashi name (Cancer, Leo…)
      "result": k["rashi"],

      // Personality paragraph → taken from moon_traits
      "text": mt["personality"] ?? "",

      // Optional extras for detail widget
      "title": mt["title"] ?? "",
      "image": mt["image"],
      "element": mt["element"],
      "symbol": mt["symbol"],
      "ruling_planet": mt["ruling_planet"],
    };
  }

  // ============================================================
  // ⭐ GEMSTONE (CTA removed) — Final Clean Block
  // ============================================================
  if (id == "gemstone") {
    // Ensure dict form
    final g = Map<String, dynamic>.from(k["gemstone_suggestion"] ?? {});

    // ❌ CTA remove from gemstone block
    g.remove("cta");

    return g; // Contains gemstone, planet, paragraph etc.
  }

  // ============================================================
  // ⭐ SATURN TODAY (Sade Sati Tool) — Final Clean Block
  // ============================================================
  if (id == "sadhesati") {
    final sade = k["sadhesati"] ?? {};
    final houses = (k["houses_overview"] ?? []) as List;

    // 1️⃣ Saturn current Rashi from backend (correct field)
    final saturnSign = sade["saturn_rashi"]?.toString() ?? "-";

    // 2️⃣ Find house where Saturn is placed based on sign match
    int? saturnHouse;
    String saturnFocus = "important areas of life";

    for (var h in houses) {
      final placements = (h["notable_placements"] ?? []) as List;

      if (placements.any(
        (p) => p["sign"].toString().toLowerCase() == saturnSign.toLowerCase(),
      )) {
        saturnHouse = h["house"]; // house number
        saturnFocus = h["focus"] ?? saturnFocus; // house focus text
        break;
      }
    }

    // Fallback (rare case)
    saturnHouse ??= 0;

    // 3️⃣ Final Text — Your exact required edition
    final text =
        "Saturn is currently in the ${saturnHouse}th house of $saturnSign Rashi.\n\n"
        "Currently Saturn is transiting through the house of $saturnFocus. "
        "This may bring slow progress, steady discipline, and inner restructuring — "
        "but this phase helps build long-term strength, maturity, and clarity.\n\n"
        "✨ Get the full Saturn Transit Report for the next 10 Years in just ₹101 ✨";

    return {
      "result": "Saturn Today",
      "text": text,
      "house": saturnHouse,
      "rashi": saturnSign,
    };
  }

  // ============================================================
  // ⭐ LAGNA TOOL — Final Clean Block
  // ============================================================
  if (id == "lagna") {
    return {
      "result": k["lagna_sign"], // e.g., Libra
      "text": k["lagna_trait"] ?? "", // backend paragraph
      "title": "Your Ascendant (Lagna)", // optional widget use
    };
  }

  // PLANETS
  if (id.startsWith("planet_")) {
    final name = id.replaceFirst("planet_", "");
    final planets = k["planet_overview"] ?? [];

    return planets.firstWhere(
      (p) => p["planet"].toString().toLowerCase() == name.toLowerCase(),
      orElse: () => null,
    );
  }

  // HOUSE
  if (id.startsWith("house_")) {
    final hn = int.parse(id.replaceFirst("house_", ""));
    final houses = k["houses_overview"] ?? [];

    return houses.firstWhere((h) => h["house"] == hn, orElse: () => null);
  }

  // MAHADASHA
  if (id == "current_dasha") return k["dasha_summary"]?["current_block"];
  if (id == "timeline") return k["dasha_summary"];

  // LIFE ASPECT
  if (id.startsWith("life_")) {
    final index = int.parse(id.replaceFirst("life_", "")) - 1;
    final list = k["life_aspects"] ?? [];
    if (index < list.length) return list[index];
  }

  // YOG–DOSH–SADHESATI resolver
  if (id.startsWith("yoga_")) {
    final key = id.replaceFirst("yoga_", "");
    final yogas = k["yogas"] ?? {};

    // 1️⃣ Try direct yoga match
    if (yogas[key] is Map) {
      final d = Map<String, dynamic>.from(yogas[key]);
      d["id"] = key;
      return d;
    }

    // 2️⃣ Try dosh map inside k["dosh"] (if structure exists)
    final doshMap = k["dosh"] ?? {};
    if (doshMap[key] is Map) {
      final d = Map<String, dynamic>.from(doshMap[key]);
      d["id"] = key;
      return d;
    }

    // 3️⃣ Special case: Sade Sati (sadhesati)
    if (key == "sadhesati" && k["sadhesati"] is Map) {
      final d = Map<String, dynamic>.from(k["sadhesati"]);
      d["id"] = "sadhesati";
      return d;
    }

    // 4️⃣ Special case: Manglik
    if (key == "manglik_dosh" && k["manglik_dosh"] is Map) {
      final d = Map<String, dynamic>.from(k["manglik_dosh"]);
      d["id"] = "manglik_dosh";
      return d;
    }

    // 5️⃣ Special case: Kaalsarp
    if (key == "kaalsarp_dosh" && k["kaalsarp_dosh"] is Map) {
      final d = Map<String, dynamic>.from(k["kaalsarp_dosh"]);
      d["id"] = "kaalsarp_dosh";
      return d;
    }
  }

  return null;
}

/// ============================================================================
/// 🔥 MAIN UI
/// ============================================================================
class _AstrologyToolSectionState extends State<AstrologyToolSection> {
  int _selected = 0;

  final List<String> categories = [
    "Profile",
    "Planets",
    "House",
    "Mahadasha",
    "Life Aspect",
    "Yog & Dosh",
  ];

  /// --------------------------------------------------------------------------
  /// EMBOSSED MINI TOOL CARD
  /// --------------------------------------------------------------------------
  Widget _toolCard({
    required String name,
    required String id,
    required String icon,
  }) {
    return InkWell(
      onTap: () {
        final k = widget.kundali;
        var data = _resolveToolData(id, k);

        // 🔥 CLEAN CURRENT MAHADASHA PAYLOAD
        if (id == "current_dasha") {
          final block = k["dasha_summary"]?["current_block"] ?? {};

          data = {
            "mahadasha": block["mahadasha"] ?? block["planet"] ?? "",
            "antardasha": block["antardasha"] ?? "",
            "start": block["start"],
            "end": block["end"],
            "impact_snippet": block["impact_snippet"],
            "impact_snippet_hi": block["impact_snippet_hi"],
          };
        }

        // 🔥 FIX TITLE
        String realTitle;

        if (id == "current_dasha") {
          realTitle = "${data["mahadasha"]} Mahadasha";
        } else if (id == "timeline") {
          realTitle = "Mahadasha Timeline";
        } else {
          realTitle = name;
        }

        // 🔥 NAVIGATE
        context.push(
          "/astrology/detail",
          extra: {"title": realTitle, "id": id, "data": data, "kundali": k},
        );
      },

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFF4EEFF), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
            BoxShadow(
              color: Colors.white70,
              blurRadius: 6,
              offset: const Offset(-3, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D1B69),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(icon, style: const TextStyle(fontSize: 22)),
          ],
        ),
      ),
    );
  }

  /// --------------------------------------------------------------------------
  /// CATEGORY GRID
  /// --------------------------------------------------------------------------
  Widget _buildGrid(List<Map<String, dynamic>> data) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, i) {
        final x = data[i];
        return _toolCard(name: x["name"], id: x["id"], icon: x["icon"] ?? "✨");
      },
    );
  }

  /// --------------------------------------------------------------------------
  /// BUILD
  /// --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final k = widget.kundali;

    final planets = k["planet_overview"] ?? [];
    final houses = k["houses_overview"] ?? [];
    final yogas = k["yogas"] ?? {};
    final lifeAspects = k["life_aspects"] ?? [];

    final pages = [
      AstrologyMeta.profileTools(),
      AstrologyMeta.planetCategory(planets),
      AstrologyMeta.houseCategory(houses),
      AstrologyMeta.mahadashaCategory(k),
      AstrologyMeta.lifeAspectCategory(lifeAspects),
      AstrologyMeta.yogaCategory(yogas),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        // CATEGORY CHIPS
        SizedBox(
          height: 45,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final selected = _selected == index;

              return GestureDetector(
                onTap: () => setState(() => _selected = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF7C3AED) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF7C3AED)
                          : Colors.black26,
                      width: 1.2,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      categories[index],
                      style: GoogleFonts.montserrat(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        _buildGrid(pages[_selected]),
      ],
    );
  }
}
