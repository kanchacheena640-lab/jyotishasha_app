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
    Color? colorDot;
    try {
      // 🟣 Try to parse known color names (basic set)
      final colorMap = {
        'red': Colors.red,
        'blue': Colors.blue,
        'green': Colors.green,
        'yellow': Colors.yellow,
        'pink': Colors.pink,
        'purple': Colors.purple,
        'orange': Colors.orange,
        'white': Colors.white,
        'black': Colors.black,
        'brown': Colors.brown,
        'grey': Colors.grey,
        'gray': Colors.grey,
        'gold': const Color(0xFFFFD700),
        'silver': const Color(0xFFC0C0C0),
      };
      colorDot = colorMap[luckyColor.toLowerCase().trim()];
    } catch (_) {
      colorDot = Colors.purpleAccent;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF5F8), Color(0xFFFCEFF9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 Title — e.g. "Today’s Horoscope"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$title’s Horoscope",
                  style: GoogleFonts.playfairDisplay(
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A189A),
                    ),
                  ),
                ),
                const Icon(Icons.auto_awesome, color: Color(0xFF5A189A)),
              ],
            ),
            const SizedBox(height: 8),

            // 📝 Summary text
            Text(
              summary,
              style: GoogleFonts.montserrat(
                textStyle: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey[800],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 🎨 Simple Lucky info text
            Row(
              children: [
                // 🟢 Lucky Color
                if (colorDot != null)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorDot,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26, width: 0.5),
                    ),
                  ),
                const SizedBox(width: 6),
                Text(
                  "Lucky Color: $luckyColor",
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF5A189A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  "Lucky Number: $luckyNumber",
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF5A189A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
