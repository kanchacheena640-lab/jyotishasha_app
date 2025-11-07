import 'package:flutter/material.dart';

class RashiFinderWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const RashiFinderWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moonTraits = data["moon_traits"] as Map<String, dynamic>?;

    if (moonTraits == null) {
      return _empty(theme, "No Rashi data found.");
    }

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
            moonTraits["title"] ?? "Your Moon Sign",
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text("Ruling Planet: ${moonTraits["ruling_planet"] ?? '--'}"),
          Text("Element: ${moonTraits["element"] ?? '--'}"),
          const Divider(height: 20),
          Text(
            moonTraits["personality"] ?? "",
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _empty(ThemeData theme, String msg) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Text(msg, textAlign: TextAlign.center),
    );
  }
}
