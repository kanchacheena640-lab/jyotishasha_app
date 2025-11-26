// lib/features/kundali/widgets/gemstone_result_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/utils/translator.dart';

class GemstoneResultWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const GemstoneResultWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).currentLang;

    // SAFE FETCH
    final gemstone = data["gemstone"]?.toString() ?? "-";
    final substone = data["substone"]?.toString() ?? "-";
    final planet = data["planet"]?.toString() ?? "-";

    // paragraph_hi supported
    final paragraph = tr(context, data, "paragraph");

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
          // TITLE
          Text(
            lang == "hi" ? "रत्न सुझाव" : "Gemstone Suggestion",
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 16),

          _line("Gemstone", gemstone),
          _line("Sub-stone", substone),
          _line("Planet", planet),

          const SizedBox(height: 16),

          Text(
            paragraph,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              height: 1.55,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        "$label: $value",
        style: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
