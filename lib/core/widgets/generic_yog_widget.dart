import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GenericYogWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final String title;

  const GenericYogWidget({super.key, required this.data, required this.title});

  @override
  Widget build(BuildContext context) {
    final heading = data["heading"] ?? title;
    final description =
        data["description"] ?? data["general_explanation"] ?? "";
    final positives = List<String>.from(data["positives"] ?? []);
    final reasons = List<String>.from(data["reasons"] ?? []);
    final challenge = data["challenge"] ?? "";
    final summary = data["summary_block"];
    final isActive = data["is_active"] ?? true;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🪔 Heading
          Text(
            heading,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.deepPurple : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),

          // ⚠️ Challenge
          if (challenge.isNotEmpty)
            Text(
              "⚠️ $challenge",
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.deepPurple,
              ),
            ),

          const SizedBox(height: 10),

          // 📜 Description
          if (description.isNotEmpty)
            Text(
              description,
              style: GoogleFonts.montserrat(fontSize: 14, height: 1.5),
            ),

          const SizedBox(height: 10),

          // ✅ Positives
          if (positives.isNotEmpty)
            ...positives.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "✔️ $e",
                  style: GoogleFonts.montserrat(fontSize: 14, height: 1.5),
                ),
              ),
            ),

          // 📍 Reasons
          if (reasons.isNotEmpty) const SizedBox(height: 8),
          if (reasons.isNotEmpty)
            ...reasons.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "📍 $e",
                  style: GoogleFonts.montserrat(fontSize: 14, height: 1.5),
                ),
              ),
            ),

          const SizedBox(height: 10),

          // 📘 Summary Block
          if (summary != null && summary["points"] != null)
            Container(
              padding: const EdgeInsets.all(12),
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
                    summary["heading"]?.toString() ?? "Summary",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...List<String>.from(summary["points"])
                      .map(
                        (p) => Text(
                          "• $p",
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
