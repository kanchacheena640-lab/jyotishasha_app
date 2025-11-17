import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/widgets/app_footer_feedback_widget.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

// 🔑 Your Google API Key (keep in .env ideally)
const String kGoogleApiKey = "YOUR_GOOGLE_API_KEY";

class PanchangPage extends StatefulWidget {
  const PanchangPage({super.key});

  @override
  State<PanchangPage> createState() => _PanchangPageState();
}

class _PanchangPageState extends State<PanchangPage> {
  Map<String, dynamic>? panchangData;
  bool isLoading = true;
  String currentLocation = "Lucknow, India";
  double currentLat = 26.8467;
  double currentLng = 80.9462;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPanchang(); // Load Lucknow initially
  }

  Future<void> _fetchPanchang() async {
    await _fetchPanchangWithLocation(currentLat, currentLng);
  }

  Future<void> _fetchPanchangWithLocation(double lat, double lng) async {
    const url = "https://jyotishasha-backend.onrender.com/api/panchang";

    final body = {
      "latitude": lat,
      "longitude": lng,
      "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
    };

    setState(() => isLoading = true);

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        setState(() {
          panchangData = decoded["selected_date"];
          isLoading = false;
          currentLat = lat;
          currentLng = lng;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Panchang fetch error: $e");
      setState(() => isLoading = false);
    }
  }

  void _openPlacePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Location"),
        content: GooglePlaceAutoCompleteTextField(
          textEditingController: _searchController,
          googleAPIKey: kGoogleApiKey,
          debounceTime: 800,
          countries: const ["in"],
          isLatLngRequired: true,
          getPlaceDetailWithLatLng: (Prediction prediction) {
            final lat = double.tryParse(prediction.lat ?? '') ?? currentLat;
            final lng = double.tryParse(prediction.lng ?? '') ?? currentLng;
            setState(() {
              currentLocation = prediction.description ?? "Selected Place";
            });
            Navigator.pop(context);
            _fetchPanchangWithLocation(lat, lng);
          },
          itemClick: (Prediction prediction) {
            _searchController.text = prediction.description ?? "";
          },
          itemBuilder: (context, index, Prediction prediction) {
            return ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(prediction.description ?? ""),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Today’s Panchang",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : panchangData == null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  Widget _buildErrorState() => Center(
    child: Text(
      "⚠️ Unable to load Panchang data",
      style: GoogleFonts.montserrat(color: AppColors.textSecondary),
    ),
  );

  Widget _buildContent() {
    final d = panchangData!;
    final formattedDate = DateFormat(
      'dd-MM-yyyy',
    ).format(DateTime.parse(d['date'] ?? DateTime.now().toString()));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌞 Date + Location Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "📍 $currentLocation",
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _openPlacePickerDialog,
                icon: const Icon(Icons.location_on_outlined, size: 18),
                label: const Text("Change"),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ☀️ Sunrise & Sunset Card
          Card(
            color: AppColors.surface,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoTile(
                    icon: Icons.wb_sunny_outlined,
                    title: "Sunrise",
                    value: d['sunrise'] ?? '--',
                  ),
                  _InfoTile(
                    icon: Icons.nights_stay_outlined,
                    title: "Sunset",
                    value: d['sunset'] ?? '--',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            "Main Panchang Elements",
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _dataRow(
            "Tithi",
            "${d['tithi']?['name']} (${d['tithi']?['paksha']})",
          ),
          _dataRow(
            "Nakshatra",
            "${d['nakshatra']?['name']} (Pada ${d['nakshatra']?['pada']})",
          ),
          _dataRow("Yoga", d['yoga']?['name']),
          _dataRow("Karana", d['karan']?['name']),
          _dataRow("Vaar", d['weekday']),
          _dataRow("Panchak", d['panchak']?['message']),

          const SizedBox(height: 24),

          Text(
            "Highlights",
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _highlightCard(
            "Abhijit Muhurta",
            "${d['abhijit_muhurta']?['start']} – ${d['abhijit_muhurta']?['end']}",
          ),
          _highlightCard(
            "Rahu Kaal",
            "${d['rahu_kaal']?['start']} – ${d['rahu_kaal']?['end']}",
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              "✨ Data synced from Jyotishasha API ✨",
              style: GoogleFonts.montserrat(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 20),
          AppFooterFeedbackWidget(),
        ],
      ),
    );
  }

  Widget _dataRow(String key, String? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          key,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        Flexible(
          child: Text(
            value ?? '--',
            textAlign: TextAlign.end,
            style: GoogleFonts.montserrat(color: AppColors.textSecondary),
          ),
        ),
      ],
    ),
  );

  Widget _highlightCard(String title, String value) => Card(
    color: AppColors.surface,
    elevation: 1.5,
    margin: const EdgeInsets.symmetric(vertical: 6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: Icon(
        Icons.star_border_outlined,
        color: AppColors.primary.withOpacity(0.9),
      ),
      title: Text(
        title,
        style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        value,
        style: GoogleFonts.montserrat(color: AppColors.textSecondary),
      ),
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 6),
        Text(title, style: GoogleFonts.montserrat(fontWeight: FontWeight.w500)),
        Text(
          value,
          style: GoogleFonts.montserrat(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
