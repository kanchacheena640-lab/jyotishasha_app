import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:jyotishasha_app/core/constants/planet_meta.dart';
import 'package:jyotishasha_app/core/state/transit_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';
import 'package:jyotishasha_app/features/transit/pages/transit_content_page.dart';

/// Parses `TransitProvider.allPlanets`'s `next_change` field (already
/// formatted as dd-mm-yyyy, occasionally ISO) into a [DateTime]. Shared by
/// the priority sort and the F6.1.1 card footer's "Next Change" label so
/// both read the exact same value — no duplicated parsing/business logic.
DateTime? _parseNextChange(String raw) {
  if (raw.isEmpty || raw == '--') return null;
  final iso = DateTime.tryParse(raw);
  if (iso != null) return iso;
  final parts = raw.split('-');
  if (parts.length == 3) {
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day != null && month != null && year != null) {
      return DateTime(year, month, day);
    }
  }
  return null;
}

/// "Current Planetary Influence" — F6.1 premium one-card-at-a-time carousel.
/// Uses exactly the same [TransitProvider.allPlanets] data, house
/// computation, nearest-transit-first priority sort (from F2.2, untouched),
/// and navigation as before; only presentation changed (one [PageView] card
/// per planet, plus a row of pagination dots — one per planet, see
/// [_PlanetPaginationDots] — to jump between them, instead of nine
/// stacked tiles). The first page is always `sortedPlanets.first` — the
/// same highest-priority planet the old sort already put on top.
class TransitAlertWidget extends StatefulWidget {
  const TransitAlertWidget({super.key});

  @override
  State<TransitAlertWidget> createState() => _TransitAlertWidgetState();
}

class _TransitAlertWidgetState extends State<TransitAlertWidget> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TransitProvider>();
    final profileP = context.watch<ProfileProvider>();
    final t = AppLocalizations.of(context)!;
    final isHindi = t.localeName.startsWith("hi");

    if (p.isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (p.allPlanets.isEmpty) return const SizedBox.shrink();

    // Nearest transit/change date first, farthest last — exactly the F2.2
    // sort, untouched. The first visible carousel page is always
    // `sortedPlanets.first`, i.e. this same highest-priority planet.
    final sortedPlanets = [...p.allPlanets];
    sortedPlanets.sort((a, b) {
      final da = _parseNextChange(a["next_change"]?.toString() ?? "");
      final db = _parseNextChange(b["next_change"]?.toString() ?? "");
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

    final safeIndex = _currentIndex.clamp(0, sortedPlanets.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // F6.6 visual audit: heading now uses the same small-purple-
        // divider-flanked treatment as "Current Timing" and "Today's
        // Essentials", instead of being the only titled Home section
        // without it.
        _buildHeading(isHindi),
        const SizedBox(height: 4),
        Text(
          isHindi ? 'आपकी जन्म कुंडली के आधार पर।' : 'Based on your birth chart.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 14),
        _PlanetPaginationDots(
          count: sortedPlanets.length,
          currentIndex: safeIndex,
          onSelect: _goToPage,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _pageController,
            itemCount: sortedPlanets.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _PlanetCard(
                planet: sortedPlanets[index],
                transitProvider: p,
                profileProvider: profileP,
                t: t,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Centered heading with small purple divider lines on both sides —
  /// same treatment as "Current Timing" and "Today's Essentials" (F6.6).
  Widget _buildHeading(bool isHindi) {
    Widget divider() => Container(
      width: 24,
      height: 1,
      color: const Color(0xFF6B21A8).withValues(alpha: 0.3),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        divider(),
        const SizedBox(width: 10),
        Text(
          isHindi ? 'वर्तमान ग्रह प्रभाव' : 'Current Planetary Influence',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F1B2E),
          ),
        ),
        const SizedBox(width: 10),
        divider(),
      ],
    );
  }
}

/// Pagination dots — one per planet, replacing the old symbol-chip row.
/// The chip row (small circular planet-symbol icons in a horizontally
/// scrollable strip) didn't read as "swipeable carousel" at a glance, and
/// its own independent horizontal scroll meant only ~8 of the 9 chips
/// fit the initial viewport with no visible affordance that a 9th
/// existed off-screen. Dots are a standard carousel convention, laid out
/// in a single non-scrolling centered [Row] that always shows every dot
/// (never clipped/overflowing), and the active dot's elongated shape
/// makes current position unambiguous.
///
/// `count` is always `sortedPlanets.length` — never hardcoded — so this
/// reflects however many planets `TransitProvider.allPlanets` actually
/// returned; it does not assume 9. Swiping the [PageView] (via
/// `onPageChanged` in the parent) updates the active dot; tapping a dot
/// still jumps to that page, same interaction the old chips supported.
class _PlanetPaginationDots extends StatelessWidget {
  const _PlanetPaginationDots({
    required this.count,
    required this.currentIndex,
    required this.onSelect,
  });

  final int count;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          GestureDetector(
            key: ValueKey('planet_dot_$i'),
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelect(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: i == currentIndex ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == currentIndex
                      ? const Color(0xFF6B21A8)
                      : const Color(0xFFE4D9FA),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// One premium planet card — icon, name, a one-line "influencing your
/// Nth House" sentence, a short keyword tag line, and "Read More →".
/// Same white / 18dp radius / soft lavender border / subtle shadow
/// language as `TodaysEssentialsWidget`'s cards. Tapping the card reuses
/// the exact same navigation + `fetchTransitContent` call as before.
class _PlanetCard extends StatelessWidget {
  const _PlanetCard({
    required this.planet,
    required this.transitProvider,
    required this.profileProvider,
    required this.t,
  });

  final Map<String, dynamic> planet;
  final TransitProvider transitProvider;
  final ProfileProvider profileProvider;
  final AppLocalizations t;

  static const Map<String, int> _rashiMap = {
    "Aries": 1,
    "Taurus": 2,
    "Gemini": 3,
    "Cancer": 4,
    "Leo": 5,
    "Virgo": 6,
    "Libra": 7,
    "Scorpio": 8,
    "Sagittarius": 9,
    "Capricorn": 10,
    "Aquarius": 11,
    "Pisces": 12,
  };

  static const Map<String, String> _planetHindi = {
    "Sun": "सूर्य",
    "Moon": "चंद्र",
    "Mars": "मंगल",
    "Mercury": "बुध",
    "Jupiter": "गुरु",
    "Venus": "शुक्र",
    "Saturn": "शनि",
    "Rahu": "राहु",
    "Ketu": "केतु",
  };

  // Each planet's single-word core trait, taken from the existing
  // `PlanetMeta.effect` field (e.g. Mars → "Courage & Energy" → "Courage")
  // — real, already-in-the-app data, not new content.
  static const Map<String, String> _traitHindi = {
    "Sun": "आत्मविश्वास",
    "Moon": "भावनाएं",
    "Mercury": "संचार",
    "Mars": "साहस",
    "Jupiter": "ज्ञान",
    "Venus": "प्रेम",
    "Saturn": "अनुशासन",
    "Rahu": "महत्वाकांक्षा",
    "Ketu": "वैराग्य",
  };

  // Short, standard house-signification keyword pairs (1st–12th) — a
  // presentational lookup table in the same style as the planet/rashi
  // name maps already in this file, not new business logic.
  static const Map<int, List<String>> _houseThemes = {
    1: ['Self', 'Identity'],
    2: ['Wealth', 'Speech'],
    3: ['Courage', 'Siblings'],
    4: ['Home', 'Comfort'],
    5: ['Creativity', 'Children'],
    6: ['Career', 'Health'],
    7: ['Partnership', 'Marriage'],
    8: ['Transformation', 'Mystery'],
    9: ['Fortune', 'Wisdom'],
    10: ['Status', 'Achievement'],
    11: ['Gains', 'Aspirations'],
    12: ['Spirituality', 'Release'],
  };

  static const Map<int, List<String>> _houseThemesHindi = {
    1: ['स्वयं', 'पहचान'],
    2: ['धन', 'वाणी'],
    3: ['साहस', 'भाई-बहन'],
    4: ['घर', 'सुख'],
    5: ['रचनात्मकता', 'संतान'],
    6: ['करियर', 'स्वास्थ्य'],
    7: ['साझेदारी', 'विवाह'],
    8: ['परिवर्तन', 'रहस्य'],
    9: ['भाग्य', 'ज्ञान'],
    10: ['स्थिति', 'उपलब्धि'],
    11: ['लाभ', 'आकांक्षाएं'],
    12: ['अध्यात्म', 'मुक्ति'],
  };

  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = t.localeName.startsWith("hi");

    final lagna = profileProvider.activeProfile?["lagna"] ?? "Aries";
    final lagnaNum = _rashiMap[lagna] ?? 1;
    final planetRashiNum = planet["rashi_number"] ?? 1;
    final house = (planetRashiNum - lagnaNum + 12) % 12 + 1;

    final planetKey = planet["name"] as String;
    final planetName = isHindi ? (_planetHindi[planetKey] ?? planetKey) : planetKey;

    final trait = isHindi
        ? (_traitHindi[planetKey] ?? '')
        : (PlanetMeta.allPlanets
                  .firstWhere(
                    (p) => p['name'] == planetKey,
                    orElse: () => const {'effect': ''},
                  )['effect']
                  as String)
              .split(' & ')
              .first;

    final houseThemes = isHindi
        ? (_houseThemesHindi[house] ?? const [])
        : (_houseThemes[house] ?? const []);
    final tags = [...houseThemes, if (trait.isNotEmpty) trait].join(' • ');

    final sentence = isHindi
        ? "$planetName अभी आपके $houseवें भाव को प्रभावित कर रहा है।"
        : "$planetName is currently influencing your ${_ordinal(house)} House.";

    // Same `next_change` value the priority sort already reads (via the
    // same shared `_parseNextChange`) — just formatted for display, not
    // recomputed.
    final nextChangeDate = _parseNextChange(
      planet["next_change"]?.toString() ?? "",
    );
    final nextChangeLabel = nextChangeDate == null
        ? null
        : DateFormat('d MMM yyyy').format(nextChangeDate);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          final profile = profileProvider.activeProfile;
          if (profile == null) return;

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransitContentPage()),
          );

          Future.microtask(() {
            transitProvider.fetchTransitContent(
              ascendant: profile["lagna"] ?? "Aries",
              planet: planet["name"],
              lagnaRashi: lagnaNum,
              planetRashi: planetRashiNum,
              lang: t.localeName.substring(0, 2),
            );
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE4D9FA)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFF3EEFF),
                    child: ClipOval(
                      child: Image.asset(
                        "assets/planets/${planetKey.toLowerCase()}.webp",
                        width: 30,
                        height: 30,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.circle,
                          size: 18,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    planetName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                sentence,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                  height: 1.35,
                ),
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  isHindi ? 'प्रभाव' : 'Affects',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tags,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B21A8),
                  ),
                ),
              ],
              const Expanded(child: SizedBox.shrink()),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (nextChangeLabel != null)
                    Text(
                      '${t.transitNextChange}: $nextChangeLabel',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF757575),
                      ),
                    ),
                  Text(
                    isHindi ? "पूरे प्रभाव पढ़ें →" : "Read Full Effects →",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B21A8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
