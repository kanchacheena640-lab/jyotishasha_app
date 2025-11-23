// lib/features/astrology/widgets/astrology_tool_section.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:jyotishasha_app/features/astrology/data/astrology_meta.dart';

class AstrologyToolSection extends StatefulWidget {
  final Map<String, dynamic> kundali;
  final String? initialSection;

  const AstrologyToolSection({
    super.key,
    required this.kundali,
    this.initialSection,
  });

  @override
  State<AstrologyToolSection> createState() => _AstrologyToolSectionState();
}

/// ============================================================================
/// 🔥 TOOL RESOLVER
/// ============================================================================
dynamic _resolveToolData(String id, Map k) {
  if (id == "rashi") {
    final mt = k["moon_traits"] ?? {};
    return {
      "result": k["rashi"],
      "text": mt["personality"] ?? "",
      "title": mt["title"] ?? "",
      "image": mt["image"],
      "element": mt["element"],
      "symbol": mt["symbol"],
      "ruling_planet": mt["ruling_planet"],
    };
  }

  if (id == "gemstone") {
    final g = Map<String, dynamic>.from(k["gemstone_suggestion"] ?? {});
    g.remove("cta");
    return g;
  }

  if (id == "lagna") {
    return {
      "result": k["lagna_sign"],
      "text": k["lagna_trait"] ?? "",
      "title": "Your Ascendant (Lagna)",
    };
  }

  if (id.startsWith("planet_")) {
    final name = id.replaceFirst("planet_", "");
    return (k["planet_overview"] ?? []).firstWhere(
      (p) => p["planet"].toString().toLowerCase() == name.toLowerCase(),
      orElse: () => null,
    );
  }

  if (id.startsWith("house_")) {
    final hn = int.parse(id.replaceFirst("house_", ""));
    return (k["houses_overview"] ?? []).firstWhere(
      (h) => h["house"] == hn,
      orElse: () => null,
    );
  }

  if (id == "current_dasha") {
    return k["dasha_summary"]?["current_block"];
  }
  if (id == "timeline") return k["dasha_summary"];

  if (id.startsWith("life_")) {
    final list = k["life_aspects"] ?? [];
    final index = int.parse(id.replaceFirst("life_", "")) - 1;
    return index < list.length ? list[index] : null;
  }

  if (id.startsWith("yoga_")) {
    final key = id.replaceFirst("yoga_", "");
    final yogas = k["yogas"] ?? {};
    if (yogas[key] is Map) {
      final d = Map<String, dynamic>.from(yogas[key]);
      d["id"] = key;
      return d;
    }
  }

  return null;
}

/// ============================================================================
/// MAIN UI
/// ============================================================================
class _AstrologyToolSectionState extends State<AstrologyToolSection> {
  int _selected = 0;

  final ScrollController _tabScrollController = ScrollController();
  final List<GlobalKey> _chipKeys = List.generate(6, (_) => GlobalKey());

  final List<String> categories = [
    "Profile",
    "Planets",
    "House",
    "Mahadasha",
    "Life Aspect",
    "Yog & Dosh",
  ];

  @override
  void initState() {
    super.initState();

    final sec = widget.initialSection;
    if (sec != null) {
      switch (sec) {
        case "profile":
          _selected = 0;
          break;
        case "planets":
          _selected = 1;
          break;
        case "bhava":
        case "house":
          _selected = 2;
          break;
        case "dasha":
        case "mahadasha":
          _selected = 3;
          break;
        case "life":
          _selected = 4;
          break;
        case "yog":
          _selected = 5;
          break;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedChip();
    });
  }

  /// ⭐ Auto-center selected chip
  void _scrollToSelectedChip() {
    try {
      final ctx = _chipKeys[_selected].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          alignment: 0.5,
        );
      }
    } catch (_) {}
  }

  /// Mini card
  Widget _toolCard({
    required String name,
    required String id,
    required String icon,
  }) {
    return InkWell(
      onTap: () {
        final k = widget.kundali;
        var data = _resolveToolData(id, k);

        // Fix Mahadasha title
        String title = name;

        if (id == "current_dasha" && data != null) {
          title = "${data["mahadasha"]} Mahadasha";
        } else if (id == "timeline") {
          title = "Mahadasha Timeline";
        }

        context.push(
          "/astrology/detail",
          extra: {"title": title, "id": id, "data": data, "kundali": k},
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(2, 3),
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
            Text(icon, style: const TextStyle(fontSize: 22)),
          ],
        ),
      ),
    );
  }

  /// Grid
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

  @override
  Widget build(BuildContext context) {
    final k = widget.kundali;

    final pages = [
      AstrologyMeta.profileTools(),
      AstrologyMeta.planetCategory(k["planet_overview"] ?? []),
      AstrologyMeta.houseCategory(k["houses_overview"] ?? []),
      AstrologyMeta.mahadashaCategory(k),
      AstrologyMeta.lifeAspectCategory(k["life_aspects"] ?? []),
      AstrologyMeta.yogaCategory(k["yogas"] ?? {}),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        /// ⭐ CATEGORY CHIPS WITH AUTO CENTER
        SizedBox(
          height: 45,
          child: ListView.separated(
            controller: _tabScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final selected = _selected == index;

              return GestureDetector(
                onTap: () {
                  setState(() => _selected = index);
                  _scrollToSelectedChip();
                },
                child: AnimatedContainer(
                  key: _chipKeys[index],
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
