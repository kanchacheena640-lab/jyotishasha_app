import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShubhMuhurthPreviewWidget extends StatelessWidget {
  final List<Map<String, String>> muhurthList;
  final VoidCallback? onSeeMore;

  const ShubhMuhurthPreviewWidget({
    super.key,
    required this.muhurthList,
    this.onSeeMore,
  });

  String _getEmoji(String event) {
    event = event.toLowerCase();
    if (event.contains('marriage')) return '💍';
    if (event.contains('griha')) return '🏠';
    if (event.contains('vehicle')) return '🚗';
    if (event.contains('naam') || event.contains('naming')) return '👶';
    return '🌸';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Upcoming Shubh Muhurth",
                style: GoogleFonts.playfairDisplay(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B0082),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onSeeMore,
                child: Text(
                  "See More →",
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7E22CE),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 🔹 Horizontal Cards
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: muhurthList.length,
              itemBuilder: (context, index) {
                final item = muhurthList[index];
                final emoji = _getEmoji(item['event'] ?? '');
                return Container(
                  width: 170,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF4DA), Color(0xFFFFE8B3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(1, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$emoji  ${item['date'] ?? ''}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4B0082),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['event'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 15, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            "${item['score'] ?? ''}/10",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
