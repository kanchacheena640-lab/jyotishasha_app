import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart'; // ✅ Added for routing

class ShubhMuhurthPreviewWidget extends StatelessWidget {
  final List<Map<String, String>> muhurthList;
  final VoidCallback? onSeeMore;

  const ShubhMuhurthPreviewWidget({
    super.key,
    required this.muhurthList,
    this.onSeeMore,
  });

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
                onTap: onSeeMore ?? () => context.go('/muhurth'), // ✅ fallback
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
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: muhurthList.length,
              itemBuilder: (context, index) {
                final item = muhurthList[index];
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFEEBD0), Color(0xFFFDE68A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
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
                        item['date'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4B0082),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['event'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            "${item['score'] ?? ''}/10",
                            style: const TextStyle(
                              fontSize: 12,
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
