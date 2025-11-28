import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';
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
    final t = AppLocalizations.of(context)!;

    final chart = kundali["chart_data"] ?? {};
    final lords = chart["lords"] ?? {};

    final lord = lords["${house}_house_lord"] ?? "-";

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(t),

          const SizedBox(height: 18),
          _sectionCard(t.house_meaning_title, _buildMeaning(context, t)),

          const SizedBox(height: 18),
          _sectionCard(t.house_placements_title, _buildPlacements(context, t)),

          const SizedBox(height: 18),
          _sectionCard(t.house_lord_title, _buildLord(t, lord)),

          const SizedBox(height: 18),
          _sectionCard(t.house_activate_title, _buildRemedy(context, t)),
        ],
      ),
    );
  }

  // ---------------------------------------------------
  // HEADER
  // ---------------------------------------------------
  Widget _header(AppLocalizations t) {
    return Text(
      t.house_header(house.toString()),
      style: GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
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
  // MEANING
  // ---------------------------------------------------
  Widget _buildMeaning(BuildContext context, AppLocalizations t) {
    String? focus = data["focus"]?.toString();

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
        t.house_meaning_not_available,
        style: GoogleFonts.montserrat(fontSize: 15, height: 1.55),
      );
    }

    final parts = focus
        .split(",")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final formatted = parts
        .map((e) => e[0].toLowerCase() + e.substring(1))
        .join(", ");

    return Text(
      t.house_deals_with(formatted),
      style: GoogleFonts.montserrat(fontSize: 15, height: 1.55),
    );
  }

  // ---------------------------------------------------
  // NOTABLE PLACEMENTS
  // ---------------------------------------------------
  Widget _buildPlacements(BuildContext context, AppLocalizations t) {
    final placements = data["notable_placements"] as List<dynamic>? ?? [];

    if (placements.isEmpty) {
      return Text(
        t.house_no_placements,
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
  Widget _buildLord(AppLocalizations t, String lord) {
    return Text(
      t.house_lord_line(house.toString(), lord),
      style: GoogleFonts.montserrat(fontSize: 14, height: 1.55),
    );
  }

  // ---------------------------------------------------
  // REMEDY
  // ---------------------------------------------------
  Widget _buildRemedy(BuildContext context, AppLocalizations t) {
    final r = HouseRemedies.remedies[house];
    final text =
        r?[Provider.of<LanguageProvider>(context).currentLang] ??
        t.house_remedy_default;

    return Text(
      text,
      style: GoogleFonts.montserrat(fontSize: 14, height: 1.55),
    );
  }
}
