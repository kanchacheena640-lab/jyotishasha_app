import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/features/panchang/panchang_page.dart';
import 'package:jyotishasha_app/core/state/panchang_provider.dart';
import 'package:jyotishasha_app/core/utils/panchang_event_markup.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

class PanchangCardWidget extends StatelessWidget {
  const PanchangCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = context.watch<PanchangProvider>();

    // 🔄 Loading
    if (p.isLoading || p.fullPanchang == null) {
      return _loadingCard(t);
    }

    // 🌞 Panchang Data
    final data = p.fullPanchang!;
    final tithi = p.tithiName;
    final paksha = p.tithiPaksha;
    final nakshatra = p.nakshatra;
    final month = p.monthName;

    final sunrise = p.sunrise;
    final sunset = p.sunset;

    // 🟣 Panchak
    final panchakMessage = p.panchakMessage.toString().toLowerCase();
    final bool panchakActive = !panchakMessage.contains("no");

    final String panchakLabel = panchakActive ? t.panchang_yes : t.panchang_no;

    // 🧭 summary + vrat (markup functions)
    final summary = PanchangEventMarkup.buildSummaryLine({
      "selected_date": data,
    });
    final vratLine = PanchangEventMarkup.buildVratSuggestion({
      "selected_date": data,
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3E8FF), Color(0xFFEDE9FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🕉️ ${t.panchang_today}",
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            summary.isNotEmpty
                ? summary
                : "$tithi ($paksha), Nakshatra: $nakshatra • Month: $month",
            style: GoogleFonts.montserrat(
              fontSize: 14.5,
              height: 1.5,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 6),

          if (vratLine.isNotEmpty)
            Text(
              vratLine,
              style: GoogleFonts.montserrat(
                fontSize: 14.5,
                color: Colors.deepPurple,
                fontWeight: FontWeight.w600,
              ),
            ),

          const SizedBox(height: 10),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 6),

          // 🌞 SUNRISE | SUNSET | PANCHAK YES/NO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoTile(t.panchang_sunrise, sunrise),
              _infoTile(t.panchang_sunset, sunset),
              _infoTile(t.panchang_panchak, panchakLabel),
            ],
          ),

          const SizedBox(height: 10),

          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PanchangPage()),
              ),
              child: Text(
                t.panchang_viewFull,
                style: GoogleFonts.montserrat(
                  fontSize: 13.5,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // LOADING
  Widget _loadingCard(AppLocalizations t) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Center(child: Text(t.panchang_loading)),
    );
  }

  // ERROR
  Widget _errorCard(AppLocalizations t) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Text("⚠️ ${t.panchang_error}"),
    );
  }

  // INFO TILE
  Widget _infoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[700]),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }
}
