import 'package:flutter/material.dart';

class LagnaFinderWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const LagnaFinderWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final lagnaSign = data["lagna_sign"] ?? "Unknown";
    final lagnaTrait = data["lagna_trait"] ?? "";
    final planetOverview = (data["planet_overview"] as List?) ?? [];

    final lagnaPlanet = planetOverview.firstWhere(
      (p) => p["planet"] == "Ascendant (Lagna)",
      orElse: () => null,
    );

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
            "Your Ascendant (Lagna)",
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            lagnaSign,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (lagnaPlanet != null) ...[
            const SizedBox(height: 8),
            Text(
              lagnaPlanet["summary"] ?? "",
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if ((lagnaTrait as String).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              lagnaTrait,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
