import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/widgets/keyboard_dismiss.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';
import 'package:jyotishasha_app/core/ads/banner_ad_widget.dart';
import 'package:jyotishasha_app/core/widgets/global_share_button.dart';
import 'package:jyotishasha_app/core/utils/share_templates.dart';
import 'package:jyotishasha_app/services/location_service.dart';

import '../cards/data/card_model.dart';
import '../cards/presentation/widgets/card_renderer.dart';

// =============================================================================
// F6.5 — Shareable Muhurth cards, built locally from this page's own already-
// fetched backend data. No CardsProvider, no CardsPage dependency: only the
// existing, unmodified CardModel / CardRenderer / BaseCard / captureAndShare
// engine is reused, exactly as it already exists for the Cards module.
// =============================================================================

/// Muhurth API score (0–7) → an auspiciousness percentage for the shareable
/// card's date line — the exact same mapping `CardsProvider.loadCards` uses
/// for its own muhurth cards, duplicated here (not imported) so this page
/// has zero dependency on CardsProvider.
int muhurthScorePercent(int score) => switch (score) {
  7 => 100,
  6 => 90,
  5 => 75,
  4 => 60,
  3 => 45,
  _ => 35,
};

const List<String> _muhurthCardImages = [
  'assets/cards/decor_01.webp',
  'assets/cards/decor_02.webp',
  'assets/cards/decor_03.webp',
  'assets/cards/decor_04.webp',
  'assets/cards/decor_05.webp',
  'assets/cards/decor_06.webp',
];

/// Deterministic (not random) background-image pick — same result for the
/// same entry on every rebuild, so the shared card doesn't flicker between
/// a different background each time the page redraws.
String pickMuhurthCardImage(String seed) {
  final index = seed.hashCode.abs() % _muhurthCardImages.length;
  return _muhurthCardImages[index];
}

// Same title strings CardsProvider.loadCards already uses for its muhurth
// cards, duplicated here for the same "no CardsProvider dependency" reason.
const Map<String, String> _muhurthTitlesEn = {
  "naamkaran": "Naamkaran Muhurth",
  "marriage": "Marriage Muhurth",
  "grah_pravesh": "Griha Pravesh Muhurth",
  "property": "Property Purchase Muhurth",
  "gold": "Gold Purchase Muhurth",
  "vehicle": "Vehicle Purchase Muhurth",
  "travel": "Travel Muhurth",
  "childbirth": "Childbirth Muhurth",
};

const Map<String, String> _muhurthTitlesHi = {
  "naamkaran": "नामकरण मुहूर्त",
  "marriage": "विवाह मुहूर्त",
  "grah_pravesh": "गृह प्रवेश मुहूर्त",
  "property": "संपत्ति क्रय मुहूर्त",
  "gold": "सोना खरीद मुहूर्त",
  "vehicle": "वाहन खरीद मुहूर्त",
  "travel": "यात्रा मुहूर्त",
  "childbirth": "शिशु जन्म मुहूर्त",
};

/// One upcoming-date line for the shareable card — "$formattedDate  •
/// $percent% auspicious" — the exact same line format
/// `CardsProvider.loadCards`'s `compactDates` already produces.
String muhurthDateLine(String formattedDate, int score) =>
    "$formattedDate  •  ${muhurthScorePercent(score)}% auspicious";

/// Builds ONE [CardModel] for an activity's entire set of upcoming Muhurth
/// dates, exactly as already returned by the existing backend call (no new
/// backend call, no re-sorting — `dateLines` is expected in the same order
/// the backend/`muhurthResults` already provided). F6.5.2: previously this
/// built one card per date; now — mirroring the same one-card-per-activity
/// shape `CardsProvider.loadCards` already uses for its own muhurth cards
/// — it aggregates every upcoming date into a single shareable card. Feeds
/// directly into the existing, untouched [CardRenderer] → [BaseCard] →
/// `captureAndShare` engine (only the CardModel content mapping changed).
CardModel buildMuhurthCardModel({
  required String activity,
  required List<String> dateLines,
  required String image,
}) {
  final content = dateLines.join('\n');

  return CardModel(
    type: "muhurth",
    designType: "muhurth",
    muhurthType: activity,
    image: image,
    titleEn: _muhurthTitlesEn[activity] ?? "Shubh Muhurth",
    titleHi: _muhurthTitlesHi[activity] ?? "शुभ मुहूर्त",
    contentEn: content,
    contentHi: content,
    meta: {
      "share_en": ShareTemplates.muhurthaEn,
      "share_hi": ShareTemplates.muhurthaHi,
    },
  );
}

Widget adCard() {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 3,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: SizedBox(width: double.infinity, child: const BannerAdWidget()),
      ),
    ),
  );
}

// GLOBAL CACHE
Map<String, List<dynamic>> muhurthCache = {};

class MuhurthPage extends StatefulWidget {
  /// Preselects the activity/category shown — e.g. when opened from Home's
  /// Muhurta widget for a specific capsule (F6.5). Falls back to the
  /// default ("naamkaran") when null or not a recognized activity.
  final String? initialActivity;

  const MuhurthPage({super.key, this.initialActivity});

  @override
  State<MuhurthPage> createState() => _MuhurthPageState();
}

class _MuhurthPageState extends State<MuhurthPage> {
  // Hindi labels (UI only)
  final Map<String, String> activityLabelsHi = {
    "naamkaran": "नामकरण",
    "marriage": "विवाह",
    "grah_pravesh": "गृह प्रवेश",
    "property": "संपत्ति क्रय",
    "gold": "सोना खरीद",
    "vehicle": "वाहन खरीद",
    "travel": "यात्रा प्रारंभ",
    "childbirth": "शिशु जन्म",
  };

  final List<String> activities = [
    "naamkaran",
    "marriage",
    "grah_pravesh",
    "property",
    "gold",
    "vehicle",
    "travel",
    "childbirth",
  ];

  late String selectedActivity;
  bool isLoading = false;
  List<dynamic> muhurthResults = [];

  // First load guard
  bool _initialLoad = false;

  // Default Location
  String cityName = "New Delhi, India";
  double latitude = 28.6139;
  double longitude = 77.2090;

  final TextEditingController _locationController = TextEditingController();

  // REST Autocomplete UI state
  List<Map<String, String>> _placeSuggestions = [];
  bool _loadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    selectedActivity = activities.contains(widget.initialActivity)
        ? widget.initialActivity!
        : "naamkaran";
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMuhurth(); // Only once, after page fully builds
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // ⭐ GOOGLE PLACES — AUTOCOMPLETE (REST)
  // ---------------------------------------------------------------------------
  Future<List<Map<String, String>>> _fetchPlaceSuggestions(String input) async {
    if (input.trim().length < 3) return [];
    return await LocationService.fetchAutocomplete(input);
  }

  // ---------------------------------------------------------------------------
  // ⭐ GOOGLE PLACES — DETAILS → LAT/LNG (REST)
  // ---------------------------------------------------------------------------
  Future<Map<String, double>> _fetchLatLngFromPlaceId(String placeId) async {
    final res = await LocationService.fetchPlaceDetail(placeId);
    if (res == null) {
      throw Exception("Place details not found");
    }
    return {"lat": res["lat"] as double, "lng": res["lng"] as double};
  }

  // ---------------------------------------------------------------------------
  // MAIN MUHURTH API with CACHE
  // ---------------------------------------------------------------------------
  Future<void> _fetchMuhurth() async {
    final lang = AppLocalizations.of(context)!.localeName;
    final cacheKey = "$selectedActivity|$latitude|$longitude|$lang";

    // Use cache first
    if (muhurthCache.containsKey(cacheKey)) {
      setState(() {
        muhurthResults = muhurthCache[cacheKey]!;
        isLoading = false;
      });
      return;
    }

    setState(() => isLoading = true);

    const baseUrl = "https://jyotishasha-backend.onrender.com/api/muhurth/list";

    final body = {
      "activity": selectedActivity,
      "latitude": latitude,
      "longitude": longitude,
      "days": 45,
      "top_k": 5,
      "language": lang,
    };

    try {
      final res = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        muhurthCache[cacheKey] = data["results"] ?? [];

        setState(() {
          muhurthResults = muhurthCache[cacheKey]!;
        });
      } else {
        debugPrint("Muhurth API error: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching muhurth: $e");
    }

    setState(() => isLoading = false);
  }

  // ---------------------------------------------------------------------------
  // LOCATION PICKER — REST BASED
  // ---------------------------------------------------------------------------
  Future<void> _openLocationPicker() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final t = AppLocalizations.of(context)!;

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.55,
              minChildSize: 0.40,
              maxChildSize: 0.95,
              builder: (_, controller) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.muhurthChange,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // SEARCH
                        TextField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            hintText: "Search location",
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) async {
                            if (value.length < 3) {
                              setModalState(() => _placeSuggestions = []);
                              return;
                            }

                            setModalState(() => _loadingSuggestions = true);

                            final data = await _fetchPlaceSuggestions(value);

                            setModalState(() {
                              _loadingSuggestions = false;
                              _placeSuggestions = data;
                            });
                          },
                        ),

                        if (_loadingSuggestions)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: LinearProgressIndicator(),
                          ),

                        const SizedBox(height: 12),

                        // SUGGESTION LIST
                        if (_placeSuggestions.isNotEmpty)
                          Expanded(
                            child: ListView.builder(
                              controller: controller,
                              itemCount: _placeSuggestions.length,
                              itemBuilder: (context, index) {
                                final s = _placeSuggestions[index];

                                return ListTile(
                                  leading: const Icon(
                                    Icons.location_on_outlined,
                                  ),
                                  title: Text(s["description"]!),
                                  onTap: () async {
                                    _locationController.text =
                                        s["description"]!;

                                    final coords =
                                        await _fetchLatLngFromPlaceId(
                                          s["place_id"]!,
                                        );

                                    // update main state
                                    setState(() {
                                      cityName = s["description"]!;
                                      latitude = coords["lat"]!;
                                      longitude = coords["lng"]!;
                                    });

                                    Navigator.pop(context);
                                    _fetchMuhurth();
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final lang = t.localeName;
    final theme = Theme.of(context);

    return KeyboardDismissOnTap(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          centerTitle: true,
          title: Text(
            t.muhurthTitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: const [
            GlobalShareButton(
              currentPage: "panchang", // Muhurtha = Panchang category
            ),
          ],
        ),

        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LOCATION ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "📍 $cityName",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openLocationPicker,
                    icon: const Icon(Icons.location_on_outlined, size: 18),
                    label: Text(t.muhurthChange),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                t.muhurthSelectOccasion,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 8),

              // ACTIVITY DROPDOWN
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedActivity,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => selectedActivity = val);

                      if (_initialLoad) {
                        _initialLoad = false;
                        return; // avoid double fetch
                      }

                      _fetchMuhurth();
                    },
                    items: activities.map((a) {
                      final title = (lang == "hi")
                          ? activityLabelsHi[a]!
                          : a.replaceAll("_", " ").toUpperCase();

                      return DropdownMenuItem(
                        value: a,
                        child: Text(
                          title,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // RESULTS
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : muhurthResults.isEmpty
                    ? Center(
                        child: Text(
                          t.muhurthNoResults,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount:
                            muhurthResults.length +
                            (muhurthResults.length ~/ 3),
                        itemBuilder: (context, index) {
                          // after every 3 cards → 1 ad
                          if ((index + 1) % 4 == 0) {
                            return adCard();
                          }

                          final dataIndex = index - ((index + 1) ~/ 4);
                          final item = muhurthResults[dataIndex];

                          // F6.5.2: ONE shareable card per activity, built
                          // once from every upcoming date this page
                          // already fetched — not one card per date. Every
                          // row's link opens this same aggregated card.
                          return _buildMuhurthCard(
                            item,
                            t,
                            _buildActivityShareCard(),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // F6.5.2: ONE shareable card for the whole activity, built from every
  // upcoming date `muhurthResults` already holds (same backend response
  // already fetched — no new backend call, no re-sorting: dates are
  // listed in the same order the backend returned them).
  CardModel _buildActivityShareCard() {
    final dateLines = muhurthResults.map((item) {
      final rawDate = item["date"] ?? "--";
      final formattedDate = rawDate != "--"
          ? DateFormat('dd-MM-yyyy').format(DateTime.parse(rawDate))
          : "--";
      final score = int.tryParse(item["score"].toString()) ?? 0;
      return muhurthDateLine(formattedDate, score);
    }).toList();

    return buildMuhurthCardModel(
      activity: selectedActivity,
      dateLines: dateLines,
      image: pickMuhurthCardImage(selectedActivity),
    );
  }

  // MUHURTH CARD
  Widget _buildMuhurthCard(dynamic item, AppLocalizations t, CardModel shareCard) {
    final rawDate = item["date"] ?? "--";
    final formattedDate = rawDate != "--"
        ? DateFormat('dd-MM-yyyy').format(DateTime.parse(rawDate))
        : "--";
    final isHindi = t.localeName.startsWith('hi');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DATE + SCORE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFFBBF24)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${t.muhurthScore}: ${item["score"]}/5",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              "🪔 ${t.muhurthWeekdayLabel}: ${item["weekday"]}  •  "
              "${t.muhurthNakshatraLabel}: ${item["nakshatra"]}  •  "
              "${t.muhurthTithiLabel}: ${item["tithi"]}",
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 10),

            ...List<String>.from(item["reasons"] ?? []).map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "• $r",
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // F6.5.1: the list stays clean — just a text link. The actual
            // shareable CardRenderer (a full 9:16 card, not an inline
            // preview) only appears on demand, inside the modal opened by
            // _showShareCardPreview.
            InkWell(
              onTap: () => _showShareCardPreview(shareCard),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.ios_share_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isHindi ? 'यह मुहूर्त शेयर करें →' : 'Share this Muhurta →',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // F6.5.1: full-size share-card preview, opened on demand from a list
  // row's "Share this Muhurta →" link — never embedded inline in the list.
  // Still the exact same, unmodified CardRenderer/BaseCard/captureAndShare
  // engine; BaseCard's own built-in share icon keeps working exactly as it
  // does in the Cards module. Closing the sheet returns to the list.
  void _showShareCardPreview(CardModel card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: SizedBox(height: 480, child: CardRenderer(card: card)),
        ),
      ),
    );
  }
}
