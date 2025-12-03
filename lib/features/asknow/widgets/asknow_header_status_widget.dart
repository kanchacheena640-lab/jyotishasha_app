import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AskNowHeaderStatusWidget extends StatelessWidget {
  final int freeQ; // 0 or 1
  final int earnedQ; // 0–8
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LEFT → FREE Q
          Row(
            children: [
              Text(
                "Free Q = ",
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: freeQ > 0 ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(8),
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

          // RIGHT → EARNED Q + BUY BUTTON IF ZERO
          Row(
            children: [
              Text(
                "Earned Q = ",
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              earnedQ > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$earnedQ",
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: onBuy,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Get 8 Q @ ₹51",
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
