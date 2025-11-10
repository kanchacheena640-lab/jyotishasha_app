import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jyotishasha_app/features/panchang/panchang_page.dart';
import 'package:jyotishasha_app/core/utils/panchang_event_markup.dart';

/// 🕉️ Smart Panchang Card Widget (Auto-fetches + Suggests Vrat)
class PanchangCardWidget extends StatelessWidget {
  const PanchangCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<http.Response>(
      future: http.post(
        Uri.parse("https://jyotishasha-backend.onrender.com/api/panchang"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "latitude": 26.8467,
          "longitude": 80.9462,
          "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        }),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingCard();
        }

        if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
          return _errorCard();
        }

        final data = jsonDecode(snapshot.data!.body);
        final selected = data["selected_date"];

        final tithi = selected?["tithi"]?["name"] ?? "--";
        final paksha = selected?["tithi"]?["paksha"] ?? "--";
        final nakshatra = selected?["nakshatra"]?["name"] ?? "--";
        final month = selected?["month_name"] ?? "--";
        final weekday = selected?["weekday"] ?? "--";
        final sunrise = selected?["sunrise"] ?? "--:--";
        final sunset = selected?["sunset"] ?? "--:--";
        final rahu = selected?["rahu_kaal"];
        final rahuStart = rahu?["start"] ?? "--:--";
        final rahuEnd = rahu?["end"] ?? "--:--";

        // 🧭 Generate summary + vrat text using markup logic
        final summary = PanchangEventMarkup.buildSummaryLine(data);
        final vratLine = PanchangEventMarkup.buildVratSuggestion(data);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF3E8FF), Color(0xFFEDE9FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "🕉️ Today’s Panchang",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 10),

              // 🗓️ Summary line
              Text(
                summary.isNotEmpty
                    ? summary
                    : "Today is $tithi ($paksha Paksha), Nakshatra $nakshatra. Month: $month.",
                style: GoogleFonts.montserrat(
                  fontSize: 14.5,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),

              // 🙏 Vrat / Event suggestion
              if (vratLine.isNotEmpty)
                Text(
                  vratLine,
                  style: GoogleFonts.montserrat(
                    fontSize: 14.5,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),

              const SizedBox(height: 10),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 6),

              // ☀️ Times row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoTile("🌅 Sunrise", sunrise),
                  _infoTile("🌇 Sunset", sunset),
                  _infoTile("☸ Rahu Kaal", "$rahuStart–$rahuEnd"),
                ],
              ),

              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PanchangPage()),
                  ),
                  child: Text(
                    "View Full Panchang →",
                    style: GoogleFonts.montserrat(
                      fontSize: 13.5,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ⏳ Loading state
  Widget _loadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  // ⚠️ Error fallback
  Widget _errorCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: const Text("⚠️ Unable to fetch Panchang data."),
    );
  }

  // 🪔 Small info tile
  Widget _infoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[700]),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }
}
