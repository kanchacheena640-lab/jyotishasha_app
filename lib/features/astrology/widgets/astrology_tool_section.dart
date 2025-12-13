// lib/features/astrology/widgets/astrology_tool_section.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/firebase_kundali_provider.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';
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

//
// ⭐ SAFE TOOL DATA RESOLVER (Original stable version + light fixes only)
//
dynamic _resolveToolData(String id, Map k, AppLocalizations t) {
  // ⭐ Rashi Finder
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

  // ⭐ Gemstone (CTA removed)
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

  // ⭐ Lagna Finder
  if (id == "lagna") {
    // Try planet_overview → ascendant
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

    // fallback (old working logic)
    return {
      "title": "${t.lagna_title} ${k["lagna_sign"] ?? "-"}",
      "text": k["lagna_trait"] ?? "",
    };
  }

  // ⭐ Planet Detail
  if (id.startsWith("planet_")) {
    final name = id.replaceFirst("planet_", "");
    return (k["planet_overview"] ?? []).firstWhere(
      (p) => p["planet"].toString().toLowerCase() == name.toLowerCase(),
      orElse: () => null,
    );
  }

  // ⭐ House Detail
  if (id.startsWith("house_")) {
    final hn = int.parse(id.replaceFirst("house_", ""));
    return (k["houses_overview"] ?? []).firstWhere(
      (h) => h["house"] == hn,
      orElse: () => null,
    );
  }

  // ⭐ Current Dasha
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

  // ⭐ Life Aspect
  if (id.startsWith("life_")) {
    final list = k["life_aspects"] ?? [];
    final index = int.parse(id.replaceFirst("life_", "")) - 1;
    return index < list.length ? list[index] : null;
  }

  // ⭐ Yog Dosh
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

class _AstrologyToolSectionState extends State<AstrologyToolSection> {
  int _selected = 0;

  final ScrollController _tabScrollController = ScrollController();
  final List<GlobalKey> _chipKeys = List.generate(6, (_) => GlobalKey());

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

  void _scrollToSelectedChip() {
    try {
      final ctx = _chipKeys[_selected].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          alignment: 0.5,
          curve: Curves.easeOut,
        );
      }
    } catch (_) {}
  }

  /// TOOL CARD
  Widget _toolCard({
    required String name,
    required String id,
    required String icon,
    required AppLocalizations t,
  }) {
    return InkWell(
      onTap: () {
        final firebase = context.read<FirebaseKundaliProvider>();
        final current = firebase.kundaliData ?? {};

        var data = _resolveToolData(id, current, t);

        String title = name;
        if (id == "current_dasha" && data != null) {
          title = "${data["mahadasha"]} ${t.tool_mahadasha}";
        }

        context.push(
          "/astrology/detail",
          extra: {"title": title, "id": id, "data": data, "kundali": current},
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
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
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
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

  /// GRID
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final firebase = context.watch<FirebaseKundaliProvider>();
    final k = firebase.kundaliData ?? {};

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

        /// CATEGORY TABS
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
                      style: TextStyle(
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

        _buildGrid(pages[_selected], t),
      ],
    );
  }
}
