// lib/features/kundali/widgets/gemstone_result_widget.dart

import 'package:flutter/material.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

class GemstoneResultWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const GemstoneResultWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final gemstone = data["gemstone"]?.toString() ?? "-";
    final substone = data["substone"]?.toString() ?? "-";
    final planet = data["planet"]?.toString() ?? "-";

    /// 🟢 No more _hi logic.
    /// We ONLY use English paragraph because backend is not sending paragraph_hi.
    final paragraph = data["paragraph"]?.toString() ?? "-";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
          Text(
            t.gemstoneSuggestion,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 16),

          /// LINES
          _line(t.gemstoneLabel, gemstone),
          _line(t.substoneLabel, substone),
          _line(t.planetLabel, planet),

          const SizedBox(height: 16),

          /// FINAL PARAGRAPH (English Always)
          Text(
            paragraph,
            style: const TextStyle(
              fontSize: 15,
              height: 1.55,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        "$label: $value",
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}
