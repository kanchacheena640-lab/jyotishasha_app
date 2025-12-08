import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/widgets/keyboard_dismiss.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';
import 'package:jyotishasha_app/core/ads/banner_ad_widget.dart';
import 'package:jyotishasha_app/core/widgets/global_share_button.dart';

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
  const MuhurthPage({super.key});

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

  String selectedActivity = "naamkaran";
  bool isLoading = false;
  List<dynamic> muhurthResults = [];

  // First load guard
  bool _initialLoad = false;

  // Default Location
  String cityName = "New Delhi, India";
  double latitude = 28.6139;
  double longitude = 77.2090;

  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMuhurth(); // Only once, after page fully builds
    });
  }

  // MAIN API with CACHE
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
      }
    } catch (e) {
      debugPrint("Error fetching muhurth: $e");
    }

    setState(() => isLoading = false);
  }

  // LOCATION PICKER
  Future<void> _openLocationPicker() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.40,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.muhurthChange,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),

                      GooglePlaceAutoCompleteTextField(
                        textEditingController: _locationController,
                        googleAPIKey: dotenv.env["GOOGLE_MAPS_API_KEY"]!,
                        inputDecoration: InputDecoration(
                          hintText: "Search location",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        debounceTime: 600,
                        isLatLngRequired: true,

                        getPlaceDetailWithLatLng: (Prediction prediction) {
                          try {
                            final lat = double.parse(prediction.lat!);
                            final lng = double.parse(prediction.lng!);

                            setState(() {
                              cityName = prediction.description ?? "Location";
                              latitude = lat;
                              longitude = lng;
                            });

                            Navigator.pop(context);
                            _initialLoad = false; // reset guard
                            _fetchMuhurth();
                          } catch (e) {
                            debugPrint("Location parse error: $e");
                          }
                        },

                        itemClick: (Prediction prediction) {
                          _locationController.text = prediction.description!;
                        },
                      ),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

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
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: const [
            GlobalShareButton(
              currentPage: "panchang",
            ), // ⭐ Muhurtha = Panchang category
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
                    style: GoogleFonts.montserrat(
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
                style: GoogleFonts.montserrat(
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
                      setState(() => selectedActivity = val!);

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
                          style: GoogleFonts.montserrat(
                            color: AppColors.textPrimary,
                          ),
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
                          style: GoogleFonts.montserrat(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount:
                            muhurthResults.length +
                            (muhurthResults.length ~/ 3),
                        itemBuilder: (context, index) {
                          // after every 3rd item → insert ad
                          if ((index + 1) % 3 == 0) {
                            return adCard();
                          }

                          // map actual data index
                          final dataIndex = index - (index ~/ 4);
                          final item = muhurthResults[dataIndex];

                          return _buildMuhurthCard(item, t);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MUHURTH CARD
  Widget _buildMuhurthCard(dynamic item, AppLocalizations t) {
    final rawDate = item["date"] ?? "--";
    final formattedDate = rawDate != "--"
        ? DateFormat('dd-MM-yyyy').format(DateTime.parse(rawDate))
        : "--";

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
                  style: GoogleFonts.playfairDisplay(
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
              style: GoogleFonts.montserrat(
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
                  style: GoogleFonts.montserrat(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
