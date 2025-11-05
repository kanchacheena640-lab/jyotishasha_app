import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HoroscopeCardWidget extends StatelessWidget {
  final String title; // e.g. "Today", "Tomorrow", "Weekly"
  final String summary;
  final String luckyColor;
  final String luckyNumber;
  final VoidCallback? onTap;

  const HoroscopeCardWidget({
    super.key,
    required this.title,
    required this.summary,
    required this.luckyColor,
    required this.luckyNumber,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, // ✅ full width of screen
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7E22CE), Color(0xFF9333EA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(2, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // ✅ expand only as needed
          children: [
            // 🔹 Title
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 🔹 Summary text (auto-height, no scroll)
            Text(
              summary,
              style: GoogleFonts.montserrat(
                textStyle: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 🔹 Tags Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTag("Color", luckyColor),
                _buildTag("Number", luckyNumber),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white60),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
