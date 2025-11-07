import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';

class MuhurthPage extends StatefulWidget {
  const MuhurthPage({super.key});

  @override
  State<MuhurthPage> createState() => _MuhurthPageState();
}

class _MuhurthPageState extends State<MuhurthPage> {
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

  // 🗺️ Location state
  String cityName = "New Delhi, India";
  double latitude = 28.6139;
  double longitude = 77.2090;

  @override
  void initState() {
    super.initState();
    _fetchMuhurth();
  }

  Future<void> _fetchMuhurth() async {
    setState(() => isLoading = true);
    const baseUrl = "https://jyotishasha-backend.onrender.com/api/muhurth/list";

    final body = {
      "activity": selectedActivity,
      "latitude": latitude,
      "longitude": longitude,
      "days": 45,
      "top_k": 5,
    };

    try {
      final res = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          muhurthResults = data["results"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching muhurth: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        title: Text(
          "🕉️ Shubh Muhurth",
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌍 Location and Change Button
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
                  onPressed: () async {
                    // TODO: integrate PlaceAutocomplete
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Location picker coming soon"),
                      ),
                    );
                  },
                  icon: const Icon(Icons.location_on_outlined, size: 18),
                  label: const Text("Change"),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              "Select Occasion",
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),

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
                    _fetchMuhurth();
                  },
                  items: activities.map((a) {
                    final title = a
                        .replaceAll("_", " ")
                        .replaceAllMapped(
                          RegExp(r'(^|\s)([a-z])'),
                          (m) => m.group(0)!.toUpperCase(),
                        );
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

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : muhurthResults.isEmpty
                  ? Center(
                      child: Text(
                        "No Shubh Muhurth found 😔",
                        style: GoogleFonts.montserrat(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: muhurthResults.length,
                      itemBuilder: (context, index) {
                        final item = muhurthResults[index];
                        return _buildMuhurthCard(item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuhurthCard(dynamic item) {
    final rawDate = item["date"] ?? "--";
    final formattedDate = rawDate != "--"
        ? DateFormat('dd-MM-yyyy').format(DateTime.parse(rawDate))
        : "--";
    final weekday = item["weekday"] ?? "--";
    final nakshatra = item["nakshatra"] ?? "--";
    final tithi = item["tithi"] ?? "--";
    final score = item["score"]?.toString() ?? "--";
    final reasons = List<String>.from(item["reasons"] ?? []);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    "Score: $score/5",
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
              "🪔 $weekday  •  Nakshatra: $nakshatra  •  Tithi: $tithi",
              style: GoogleFonts.montserrat(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            ...reasons.map(
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
