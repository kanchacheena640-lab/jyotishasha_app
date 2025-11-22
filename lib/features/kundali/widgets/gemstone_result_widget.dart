import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';

class GemstoneResultWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const GemstoneResultWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final gemstone = data["gemstone"] ?? "-";
    final substone = data["substone"] ?? "";
    final planet = data["planet"] ?? "-";
    final paragraph = data["paragraph"] ?? "";

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recommended Gemstone",
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Icon(Icons.diamond, color: AppColors.primary, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "$gemstone",
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          if (substone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Alternative: $substone",
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],

          const SizedBox(height: 18),

          Text(
            "Planetary Support: $planet",
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            paragraph,
            style: GoogleFonts.montserrat(fontSize: 15, height: 1.55),
          ),
        ],
      ),
    );
  }
}
