import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SadhesatiWidget extends StatelessWidget {
  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(parsed);
    } catch (e) {
      return dateStr;
    }
  }

  final Map<String, dynamic> data;

  const SadhesatiWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // ✅ Handle nested "yogas" and "sadhesati" paths safely
    final sadeData = (data["yogas"]?["sadhesati"]) ?? data["sadhesati"] ?? data;

    final explanation = sadeData["explanation"]?.toString() ?? "";
    final moonRashi = sadeData["moon_rashi"]?.toString() ?? "";
    final saturnRashi = sadeData["saturn_rashi"]?.toString() ?? "";
    final status = sadeData["status"]?.toString() ?? "";
    final shortDesc = sadeData["short_description"]?.toString() ?? "";

    final paragraphs = (sadeData["report_paragraphs"] is List)
        ? List<String>.from(sadeData["report_paragraphs"])
        : <String>[];

    final summary = sadeData["summary_block"] ?? {};
    final phaseDates = sadeData["phase_dates"] ?? {};

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sade Sati Report",
            style: GoogleFonts.playfairDisplay(
              textStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (shortDesc.isNotEmpty)
            Text(
              shortDesc,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                color: Colors.black87,
                height: 1.5,
              ),
            ),

          const SizedBox(height: 16),

          if (explanation.isNotEmpty)
            Text(
              explanation,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                color: Colors.black87,
                height: 1.5,
              ),
            ),

          const SizedBox(height: 16),

          Text(
            "Moon Rashi: $moonRashi",
            style: GoogleFonts.montserrat(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "Saturn Rashi: $saturnRashi",
            style: GoogleFonts.montserrat(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "Status: $status",
            style: GoogleFonts.montserrat(
              fontSize: 15,
              color: status.toLowerCase() == "active"
                  ? Colors.green
                  : Colors.redAccent,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          if (paragraphs.isNotEmpty)
            ...paragraphs.map(
              (para) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  para,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          if (phaseDates.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Phase Dates",
                    style: GoogleFonts.playfairDisplay(
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...phaseDates.entries.map((entry) {
                    final key = entry.key
                        .toString()
                        .replaceAll("_", " ")
                        .toUpperCase();
                    final val = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        "$key: ${formatDate(val["start"])} → ${formatDate(val["end"])}",
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

          const SizedBox(height: 20),

          if (summary.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade50, Colors.deepPurple.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary["heading"] ?? "Summary",
                    style: GoogleFonts.playfairDisplay(
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List<String>.from(summary["points"] ?? []).map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "• ",
                            style: TextStyle(fontSize: 16, height: 1.4),
                          ),
                          Expanded(
                            child: Text(
                              point,
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
