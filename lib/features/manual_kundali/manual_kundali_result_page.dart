// lib/features/manual_kundali/manual_kundali_result_page.dart

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:jyotishasha_app/core/widgets/kundali_chart_north_widget.dart';
import 'package:jyotishasha_app/features/astrology/widgets/astrology_profile_card.dart';

class ManualKundaliResultPage extends StatelessWidget {
  final Map<String, dynamic> kundali;

  const ManualKundaliResultPage({super.key, required this.kundali});

  @override
  Widget build(BuildContext context) {
    final profile = kundali["profile"] ?? {};
    final planets = kundali["chart_data"]?["planets"] ?? [];

    final name = _cap(profile["name"]);
    final dob = _formatDob(profile["dob"]);
    final tob = profile["tob"] ?? "-";
    final pob = (profile["place"] ?? "-").toString().split(",").first.trim();
    final lagna = kundali["lagna_sign"] ?? "-";
    final rashi = kundali["rashi"] ?? "-";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manual Kundali",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      backgroundColor: const Color(0xFFF7F3FF),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ⭐ TOP PURPLE HEADER BLOCK
            Container(
              padding: const EdgeInsets.all(18),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white30, width: 1.3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x552D1B69),
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "DOB: $dob • TOB: $tob • POB: $pob",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 13.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ⭐ Kundali Chart Box EXACT from Astrology Tools page
                  Container(
                    height: 240,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFF5EAFE),
                          Color(0xFF6D28D9),
                          Color(0xFF4C1D95),
                        ],
                        stops: [0.15, 0.55, 1],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Center(
                      child: KundaliChartNorthWidget(
                        planets: planets,
                        lagnaSign: lagna,
                        size: 220,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "• Name: $name   • Rashi: $rashi   • Lagna: $lagna",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ⭐ SAME Astrology Profile Card (NO CHANGE)
            AstrologyProfileCard(kundali: kundali),

            const SizedBox(height: 20),

            // ⭐ Optional More Data in Future
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: const Text(
                "✨ Manual Kundali generated successfully!",
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helpers
  String _cap(String? t) {
    if (t == null || t.isEmpty) return "-";
    return t
        .split(" ")
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(" ");
  }

  String _formatDob(String? d) {
    if (d == null) return "-";
    try {
      final p = DateTime.parse(d);
      return "${p.day.toString().padLeft(2, '0')}-"
          "${p.month.toString().padLeft(2, '0')}-"
          "${p.year}";
    } catch (_) {
      return d;
    }
  }
}
