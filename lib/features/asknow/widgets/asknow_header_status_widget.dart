import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AskNowHeaderStatusWidget extends StatelessWidget {
  final int freeQ; // 0 or 1
  final int earnedQ; // pack + reward combined
  final VoidCallback onBuy;

  const AskNowHeaderStatusWidget({
    super.key,
    required this.freeQ,
    required this.earnedQ,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ---------------- LEFT: FREE QUESTION ----------------
          Row(
            children: [
              Text(
                "Free Q",
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),

              // Free Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: freeQ > 0
                      ? Colors.green.shade600
                      : Colors.grey.shade500,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$freeQ",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // ---------------- RIGHT: EARNED / PACK TOKEN SECTION ----------------
          Row(
            children: [
              Text(
                "Earned Q",
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),

              // Tokens available → purple badge
              if (earnedQ > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED), // Jyotishasha purple
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "$earnedQ",
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                // No tokens → buy pack button
                GestureDetector(
                  onTap: onBuy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "8Q @ ₹51",
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
