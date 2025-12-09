// lib/features/astrology/widgets/manual_astrology_tool_section.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';
import 'package:jyotishasha_app/features/astrology/data/astrology_meta.dart';

class ManualAstrologyToolSection extends StatefulWidget {
  final Map<String, dynamic> kundali;
  final String? initialSection;

  const ManualAstrologyToolSection({
    super.key,
    required this.kundali,
    this.initialSection,
  });

  @override
  State<ManualAstrologyToolSection> createState() =>
      _ManualAstrologyToolSectionState();
}

//
// ⭐ This is FULLY STANDALONE — No Firebase, Only Manual Kundali
//
dynamic _resolveToolData(String id, Map k, AppLocalizations t) {
  if (id == "rashi") {
    final mt = Map<String, dynamic>.from(k["moon_traits"] ?? {});
    return {
      "title": mt["title"] ?? "",
      "text": mt["personality"] ?? "",
      "image": mt["image"],
      "element": mt["element"] ?? "",
      "symbol": mt["symbol"] ?? "",
      "ruling_planet": mt["ruling_planet"] ?? "",
    };
  }

  if (id == "gemstone") {
    final g = Map<String, dynamic>.from(k["gemstone_suggestion"] ?? {});
    g.remove("cta");
    return {
      "gemstone": g["gemstone"] ?? "-",
      "substone": g["substone"] ?? "-",
      "planet": g["planet"] ?? "-",
      "paragraph": g["paragraph"] ?? "-",
    };
  }

  if (id == "lagna") {
    final asc = (k["planet_overview"] ?? []).firstWhere((p) {
      final name = p["planet"]?.toString().toLowerCase() ?? "";
      return name.contains("ascendant") || name.contains("lagna");
    }, orElse: () => null);

    if (asc != null) {
      return {
        "title": asc["planet"] ?? "Ascendant",
        "text": asc["text"] ?? asc["summary"] ?? "",
      };
    }

    return {
      "title": "${t.lagna_title} ${k["lagna_sign"] ?? "-"}",
      "text": k["lagna_trait"] ?? "",
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
    final ds = k["dasha_summary"] ?? {};
    final block = ds["current_block"] ?? {};
    final maha = ds["current_mahadasha"] ?? {};

    return {
      "mahadasha": block["mahadasha"],
      "antardasha": block["antardasha"],
      "period": block["period"],
      "impact_snippet": block["impact_snippet"],
      "impact_snippet_hi": block["impact_snippet_hi"],
      "antardashas": maha["antardashas"] ?? [],
      "start": maha["start"],
      "end": maha["end"],
    };
  }

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

      // ⭐ ONLY SADHESATI FIX — Remove summary_block
      if (key == "sadhesati") {
        d.remove("summary_block");
      }

      return d;
    }
  }

  return null;
}

class _ManualAstrologyToolSectionState
    extends State<ManualAstrologyToolSection> {
  int _selected = 0;

  final ScrollController _tabScrollController = ScrollController();
  final _chipKeys = List.generate(6, (_) => GlobalKey());

  late List<String> categories;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final t = AppLocalizations.of(context)!;

    categories = [
      t.cat_profile,
      t.cat_planets,
      t.cat_house,
      t.cat_mahadasha,
      t.cat_life_aspect,
      t.cat_yog_dosh,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final k = widget.kundali; // ⭐ always manual kundali

    final pages = [
      AstrologyMeta.profileTools(context),
      AstrologyMeta.planetCategory(k["planet_overview"] ?? [], context),
      AstrologyMeta.houseCategory(k["houses_overview"] ?? [], context),
      AstrologyMeta.mahadashaCategory(k, context),
      AstrologyMeta.lifeAspectCategory(k["life_aspects"] ?? [], context),
      AstrologyMeta.yogaCategory(k["yogas"] ?? {}, context),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        SizedBox(
          height: 45,
          child: ListView.separated(
            controller: _tabScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              final selected = _selected == index;

              return GestureDetector(
                onTap: () => setState(() => _selected = index),
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
                  ),
                  child: Center(
                    child: Text(
                      categories[index],
                      style: GoogleFonts.montserrat(
                        color: selected ? Colors.white : Colors.black87,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        _buildGrid(pages[_selected], t),
      ],
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> data, AppLocalizations t) {
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
        return _toolCard(
          name: x["name"],
          id: x["id"],
          icon: x["icon"] ?? "✨",
          t: t,
        );
      },
    );
  }

  Widget _toolCard({
    required String name,
    required String id,
    required String icon,
    required AppLocalizations t,
  }) {
    // ⭐ Detect yog/dosh card
    final bool isYoga = id.startsWith("yoga_");

    // ⭐ Extract actual yoga key (yoga_gajakesari → gajakesari)
    String yogaKey = "";
    bool? isActive;

    if (isYoga) {
      yogaKey = id.replaceFirst("yoga_", "");
      final yogas = widget.kundali["yogas"] ?? {};
      if (yogas[yogaKey] is Map) {
        isActive = yogas[yogaKey]["is_active"] == true;
      }
    }

    // Dot UI
    Widget statusDot = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (isActive == true) ? Colors.green : Colors.red,
      ),
    );

    return InkWell(
      onTap: () {
        final current = widget.kundali;
        final data = _resolveToolData(id, current, t);

        context.push(
          "/astrology/detail",
          extra: {"title": name, "id": id, "data": data, "kundali": current},
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(2, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  // ⭐ DOT ONLY FOR YOG/DOSH CARDS
                  if (isYoga) ...[statusDot, const SizedBox(width: 6)],
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
                ],
              ),
            ),
            Text(icon, style: const TextStyle(fontSize: 22)),
          ],
        ),
      ),
    );
  }
}
