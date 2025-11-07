import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/features/panchang/panchang_page.dart'; // 👈 import the page

class PanchangCardWidget extends StatelessWidget {
  final String tithi;
  final String nakshatra;
  final String sunrise;
  final String sunset;

  const PanchangCardWidget({
    super.key,
    required this.tithi,
    required this.nakshatra,
    required this.sunrise,
    required this.sunset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today’s Panchang",
            style: GoogleFonts.playfairDisplay(
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B0082),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildRow("Tithi", tithi),
          _buildRow("Nakshatra", nakshatra),
          _buildRow("Sunrise", sunrise),
          _buildRow("Sunset", sunset),
          const SizedBox(height: 12),

          // 👇 CTA Button (navigation to PanchangPage)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PanchangPage()),
              );
            },
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFFBBF24)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  "View Full Panchang →",
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B0082),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
