import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 💎 Gemstone Suggestion Tool Widget
class GemstoneSuggestionWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  const GemstoneSuggestionWidget(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g = data["gemstone_suggestion"] ?? {};

    if (g.isEmpty) {
      return _emptyBlock("No gemstone data found");
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "💎 Gemstone Recommendation",
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),

          // 🌟 Main gemstone
          _buildLine("Planet", g["planet"]),
          _buildLine("Main Gemstone", g["gemstone"]),
          _buildLine("Substitute", g["substone"]),
          const Divider(height: 20),

          // 📜 Explanation
          Text(
            g["paragraph"] ?? "",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.black87,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          // 🔮 CTA Sections
          //if (g["cta"] != null) _buildCTASection(context, g["cta"]),
        ],
      ),
    );
  }

  Widget _buildLine(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        "$title: ${value ?? '--'}",
        style: GoogleFonts.montserrat(
          fontSize: 15,
          color: Colors.deepPurple,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCTASection(BuildContext context, Map<String, dynamic> cta) {
    final sections = cta["sections"] as List? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cta["heading"] ?? "Explore Personalized Reports",
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        ...sections.map((s) => _ctaCard(context, s)),
      ],
    );
  }

  Widget _ctaCard(BuildContext context, Map<String, dynamic> s) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3E8FF), Color(0xFFEDE9FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s["title"] ?? "",
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s["description"] ?? "",
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(s["button_text"] ?? "Buy"),
          ),
        ],
      ),
    );
  }

  Widget _emptyBlock(String msg) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Center(child: Text(msg, textAlign: TextAlign.center)),
    );
  }
}
