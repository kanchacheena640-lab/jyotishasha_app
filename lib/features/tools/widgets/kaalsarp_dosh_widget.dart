import 'package:flutter/material.dart';

class KaalsarpDoshWidget extends StatelessWidget {
  final Map<String, dynamic>? kundaliData;

  const KaalsarpDoshWidget({super.key, required this.kundaliData});

  @override
  Widget build(BuildContext context) {
    if (kundaliData == null ||
        kundaliData!["yogas"] == null ||
        kundaliData!["yogas"]["kaalsarp_dosh"] == null) {
      return const SizedBox.shrink();
    }

    final data = kundaliData!["yogas"]["kaalsarp_dosh"];
    final heading = data["heading"] ?? "Kaalsarp Dosh Analysis";
    final explanation = data["general_explanation"] ?? "";
    final reportParagraphs =
        (data["report_paragraphs"] as List?)?.join("\n\n") ?? "";
    final summary = data["summary_block"] ?? "";

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
          // 🟣 Heading
          Text(
            heading,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),

          // 📜 General Explanation
          Text(
            explanation,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // 🔹 Report Paragraphs
          Text(
            reportParagraphs,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),

          // 📘 Summary Block
          if (summary.isNotEmpty) ...[
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
              summary,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
