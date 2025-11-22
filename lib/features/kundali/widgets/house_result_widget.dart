import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';
import '/data/house_remedies.dart';

class HouseResultWidget extends StatelessWidget {
  final int house;
  final Map<String, dynamic> data;
  final Map<String, dynamic> kundali;

  const HouseResultWidget({
    super.key,
    required this.house,
    required this.data,
    required this.kundali,
  });

  @override
  Widget build(BuildContext context) {
    final chart = kundali["chart_data"] ?? {};
    final lords = chart["lords"] ?? {};

    final lord = lords["${house}_house_lord"] ?? "-";
    final meaningWidget = _buildMeaning(data);
    final placements = _buildPlacements(data);
    final remedy = _buildRemedy(house);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),

          const SizedBox(height: 18),
          _sectionCard("House Meaning", meaningWidget),

          const SizedBox(height: 18),
          _sectionCard("Notable Placements", placements),

          const SizedBox(height: 18),
          _sectionCard("House Lord", _buildLord(lord)),

          const SizedBox(height: 18),
          _sectionCard("Activate Now", remedy),
        ],
      ),
    );
  }

  // ---------------------------------------------------
  // HEADER
  // ---------------------------------------------------
  Widget _header() {
    return Row(
      children: [
        Text(
          "🏠 House $house",
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------
  // SECTION CARD WRAPPER
  // ---------------------------------------------------
  Widget _sectionCard(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(2, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  // ---------------------------------------------------
  // MEANING — focus → paragraph
  // ---------------------------------------------------
  Widget _buildMeaning(Map<String, dynamic> data) {
    // Priority 1 → direct focus
    String? focus = data["focus"]?.toString();

    // Priority 2 → summary se extract
    if (focus == null || focus.trim().isEmpty) {
      final summary = data["summary"]?.toString() ?? "";
      if (summary.toLowerCase().contains("focus:")) {
        final part = summary.split("Focus:").last;
        final end = part.split(".").first;
        focus = end.trim();
      }
    }

    if (focus == null || focus.trim().isEmpty) {
      return Text(
        "Meaning not available.",
        style: GoogleFonts.montserrat(fontSize: 15, height: 1.55),
      );
    }

    final parts = focus
        .split(",")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final formatted = parts
        .map((e) {
          if (e.isEmpty) return e;
          return e[0].toLowerCase() + e.substring(1);
        })
        .join(", ");

    return Text(
      "This house deals with $formatted.",
      style: GoogleFonts.montserrat(fontSize: 15, height: 1.55),
    );
  }

  // ---------------------------------------------------
  // NOTABLE PLACEMENTS — paragraph form
  // ---------------------------------------------------
  Widget _buildPlacements(Map<String, dynamic> data) {
    final placements = data["notable_placements"] as List<dynamic>? ?? [];

    if (placements.isEmpty) {
      return Text(
        "No major planetary placements here.",
        style: GoogleFonts.montserrat(color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: placements.map((p) {
        final planet = p["planet"] ?? "-";
        final sign = p["sign"] ?? "-";
        final deg = p["degree"] ?? "-";
        final nak = p["nakshatra"] ?? "-";
        final pada = p["pada"] ?? "-";

        final line =
            "$planet is placed in $sign at $deg° (Nakshatra: $nak, Pada: $pada).";

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line,
            style: GoogleFonts.montserrat(fontSize: 14, height: 1.55),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------
  // HOUSE LORD
  // ---------------------------------------------------
  Widget _buildLord(String lord) {
    return Text(
      "The Lord of House $house is $lord.",
      style: GoogleFonts.montserrat(fontSize: 14, height: 1.55),
    );
  }

  // ---------------------------------------------------
  // REMEDY BLOCK
  // ---------------------------------------------------
  Widget _buildRemedy(int house) {
    final r = HouseRemedies.remedies[house];
    final text =
        r?["en"] ?? "Do small consistent actions to activate this house.";

    return Text(
      text,
      style: GoogleFonts.montserrat(fontSize: 14, height: 1.55),
    );
  }
}
