import 'package:flutter/material.dart';

class MangalDoshWidget extends StatelessWidget {
  final Map<String, dynamic>? kundaliData;

  const MangalDoshWidget({super.key, required this.kundaliData});

  @override
  Widget build(BuildContext context) {
    // 🧭 Safety check: Agar data hi nahi hai to kuch mat dikhao
    if (kundaliData == null ||
        kundaliData!["yogas"] == null ||
        (kundaliData!["yogas"]["manglik_dosh"] == null &&
            kundaliData!["yogas"]["mangaldosh"] == null)) {
      return const SizedBox.shrink();
    }

    // 🔍 Nested JSON me dono key name handle kar rahe hain
    final mangal =
        kundaliData!["yogas"]["manglik_dosh"] ??
        kundaliData!["yogas"]["mangaldosh"];

    final heading = mangal["heading"] ?? "Mangal Dosh Analysis";
    final language = mangal["language"] ?? "en";
    final reportParagraphs =
        (mangal["report_paragraphs"] as List?)?.join("\n\n") ??
        "No detailed description available.";
    final status =
        mangal["status"]?["is_mangalic"] ?? "Analysis not available.";
    final summaryBlock = mangal["summary_block"];
    final summaryPoints =
        (summaryBlock?["points"] as List?)?.map((e) => "• $e").join("\n") ?? "";

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔶 Heading
          Text(
            heading,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),

          const SizedBox(height: 8),

          // 🔷 Status line
          Text(
            status,
            style: TextStyle(
              fontSize: 14,
              color: Colors.deepPurple.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          // 🪔 Main report text
          Text(
            reportParagraphs,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 14),

          // 📘 Summary block (optional)
          if (summaryPoints.isNotEmpty) ...[
            Text(
              "Summary:",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              summaryPoints,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ],

          const SizedBox(height: 6),

          // 🌐 Language indicator
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              "Language: ${language.toUpperCase()}",
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
