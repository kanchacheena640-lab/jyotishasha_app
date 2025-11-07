import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SadeSatiWidget extends StatelessWidget {
  final Map<String, dynamic>? kundaliData;

  const SadeSatiWidget({super.key, required this.kundaliData});

  @override
  Widget build(BuildContext context) {
    // 🔍 Null & structure check
    if (kundaliData == null ||
        kundaliData!["yogas"] == null ||
        kundaliData!["yogas"]["sadhesati"] == null) {
      return const SizedBox.shrink();
    }

    // 🪔 Extract data safely
    final data = kundaliData!["yogas"]["sadhesati"] as Map<String, dynamic>;
    final explanation = data["explanation"]?.toString() ?? "";
    final shortDescription = data["short_description"]?.toString() ?? "";
    final status = data["status"]?.toString() ?? "Inactive";
    final moonRashi = data["moon_rashi"]?.toString() ?? "";
    final saturnRashi = data["saturn_rashi"]?.toString() ?? "";

    final reportParagraphsList = data["report_paragraphs"];
    final reportParagraphs = (reportParagraphsList is List)
        ? reportParagraphsList.map((e) => e.toString()).join("\n\n")
        : "";

    final summary = (data["summary_block"] is Map)
        ? data["summary_block"] as Map<String, dynamic>
        : {};

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),

      // 🧩 Main layout
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌕 Heading
          Text(
            "Sade Sati Analysis",
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 10),

          // 🌙 Status line
          Text(
            "Status: $status",
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.deepPurple.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            "Moon Sign: $moonRashi | Saturn Sign: $saturnRashi",
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 12),

          // 📜 Explanation
          if (explanation.isNotEmpty)
            Text(
              explanation,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),

          const SizedBox(height: 12),

          // 🔹 Report Paragraphs
          if (reportParagraphs.isNotEmpty)
            Text(
              reportParagraphs,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),

          const SizedBox(height: 14),

          // 📘 Summary Block
          if (summary.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade50, Colors.purple.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary["heading"]?.toString() ?? "Sade Sati Summary",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (summary["points"] is List)
                    ...List<String>.from(summary["points"])
                        .map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              "• $p",
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // ✨ Short Description
          if (shortDescription.isNotEmpty)
            Text(
              "🪄 $shortDescription",
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.deepPurple,
              ),
            ),
        ],
      ),
    );
  }
}
