import 'package:flutter/material.dart';

class DashaFinderWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const DashaFinderWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final grahBlock = data["grah_dasha_block"] as Map<String, dynamic>?;
    final dashaSummary = data["dasha_summary"] as Map<String, dynamic>?;

    if (grahBlock == null && dashaSummary == null) {
      return _empty("No Dasha data found.");
    }

    final currentBlock =
        dashaSummary?["current_block"] as Map<String, dynamic>?;

    final heading = "Current Dasha Period";
    final text =
        grahBlock?["grah_dasha_text"] ??
        currentBlock?["impact_snippet"] ??
        currentBlock?["impact_snippet_hi"] ??
        "";

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
            heading,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(String msg) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(msg, textAlign: TextAlign.center),
    );
  }
}
