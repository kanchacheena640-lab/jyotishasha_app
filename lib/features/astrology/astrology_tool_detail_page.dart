// lib/features/astrology/pages/astrology_tool_detail_page.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/widgets/kundali_chart_north_widget.dart';

// RESULT WIDGETS
import 'package:jyotishasha_app/features/kundali/widgets/mahadasha_result_widget.dart';
import 'package:jyotishasha_app/features/kundali/widgets/house_result_widget.dart';
import 'package:jyotishasha_app/features/kundali/widgets/planet_result_widget.dart';
import 'package:jyotishasha_app/features/kundali/widgets/life_aspect_widget.dart';
import 'package:jyotishasha_app/features/kundali/widgets/yog_dosh_result_widget.dart';
import 'package:jyotishasha_app/features/kundali/widgets/gemstone_result_widget.dart';
import 'package:jyotishasha_app/features/kundali/widgets/saturn_today_widget.dart';

class AstrologyToolDetailPage extends StatefulWidget {
  final String title;
  final dynamic data;
  final Map<String, dynamic> kundaliData;

  const AstrologyToolDetailPage({
    super.key,
    required this.title,
    required this.data,
    required this.kundaliData,
  });

  @override
  State<AstrologyToolDetailPage> createState() =>
      _AstrologyToolDetailPageState();
}

class _AstrologyToolDetailPageState extends State<AstrologyToolDetailPage> {
  // FULL PAGE SHARE KEY
  final GlobalKey _fullPageKey = GlobalKey();

  // TOP BLOCK SHARE KEY (optional)
  final GlobalKey _shareKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final k = widget.kundaliData;
    final profile = k["profile"] ?? {};
    final planets = k["chart_data"]?["planets"] ?? [];

    final name = _cap(profile["name"]);
    final dob = _formatDob(profile["dob"]);
    final tob = profile["tob"] ?? "-";
    final pob = (profile["place"] ?? "-").toString().split(",").first.trim();
    final lagna = k["lagna_sign"] ?? "-";
    final rashi = k["rashi"] ?? "-";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          widget.title,
          style: GoogleFonts.playfairDisplay(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: _shareImage,
          ),
        ],
      ),

      backgroundColor: Colors.white,

      body: RepaintBoundary(
        key: _fullPageKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // TOP HEADER BLOCK
                    RepaintBoundary(
                      key: _shareKey,
                      child: Container(
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

                            _kundaliBox(planets, lagna),

                            const SizedBox(height: 10),

                            Text(
                              "• Name: $name • Rashi: $rashi • Lagna: $lagna",
                              style: GoogleFonts.montserrat(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _buildContent(),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _shareButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // KUNDALI BOX
  // ---------------------------------------------------------------------------
  Widget _kundaliBox(List planets, String lagna) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [Color(0xFFF5EAFE), Color(0xFF6D28D9), Color(0xFF4C1D95)],
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
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN CONTENT BUILDER
  // ---------------------------------------------------------------------------
  Widget _buildContent() {
    final title = widget.title;
    final data = widget.data;
    final kundali = widget.kundaliData;

    if (data == null) return _empty("No data found");

    print("🔎 TITLE: $title");
    print("🔎 DATA RECEIVED: $data");

    // ⭐ 0) SPECIAL CLEAN WIDGET OVERRIDES
    if (title.contains("Gemstone")) {
      return GemstoneResultWidget(data: data);
    }

    if (title.contains("Saturn Today")) {
      return SaturnTodayWidget(data: data);
    }

    if (title.contains("Lagna Finder")) {
      return _simpleCard(data);
    }

    if (title.contains("Rashi Finder")) {
      return _simpleCard(data);
    }

    // ⭐ 1) HOUSE
    if (data is Map && data.containsKey("house")) {
      final hn = int.tryParse(data["house"].toString()) ?? 0;
      return HouseResultWidget(
        house: hn,
        data: Map<String, dynamic>.from(data),
        kundali: kundali,
      );
    }

    // ⭐ 2) MAHADASHA
    if (title.toLowerCase().contains("mahadasha")) {
      Map<String, dynamic> cleanMaha = {};

      if (data is Map && data.containsKey("antardashas")) {
        cleanMaha = Map<String, dynamic>.from(data);
      } else if (kundali["dasha_summary"]?["current_mahadasha"] != null) {
        cleanMaha = Map<String, dynamic>.from(
          kundali["dasha_summary"]["current_mahadasha"],
        );
      }

      return MahadashaResultWidget(data: cleanMaha, kundali: kundali);
    }

    // ⭐ 3) PLANET
    if (data is Map && data["planet"] != null) {
      return PlanetResultWidget(
        data: Map<String, dynamic>.from(data),
        kundali: kundali,
      );
    }

    // ⭐ 4) LIFE ASPECT
    if (data is Map && data["aspect"] != null) {
      return LifeAspectWidget(
        data: Map<String, dynamic>.from(data),
        kundali: kundali,
      );
    }

    // ⭐ 5) YOG DOSH
    if (data is Map && data["id"] != null) {
      final yogas = (kundali["yogas"] ?? {}) as Map;
      final resolved = yogas[data["id"]] ?? data;

      return YogDoshResultWidget(
        data: Map<String, dynamic>.from(resolved),
        kundali: kundali,
      );
    }

    // FALLBACK
    return _defaultViewer(data);
  }

  // ---------------------------------------------------------------------------
  // SIMPLE CARD
  // ---------------------------------------------------------------------------
  Widget _simpleCard(dynamic data) {
    final result = data["result"] ?? "-";
    final text = data["text"] ?? "";

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _decor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result,
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(text, style: GoogleFonts.montserrat(fontSize: 15, height: 1.55)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DEFAULT VIEW
  // ---------------------------------------------------------------------------
  Widget _defaultViewer(dynamic data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _decor(),
      child: Text(data.toString(), style: GoogleFonts.montserrat(fontSize: 14)),
    );
  }

  // SHARE BUTTON
  Widget _shareButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _shareImage,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          minimumSize: const Size(double.infinity, 54),
        ),
        icon: const Icon(Icons.share, color: Colors.white),
        label: const Text(
          "Share Result",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // SHARE IMAGE
  Future<void> _shareImage() async {
    try {
      final boundary =
          _fullPageKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      final img = await boundary.toImage(pixelRatio: 3);
      final bytes = (await img.toByteData(
        format: ImageByteFormat.png,
      ))!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/tool_result.png");
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      print("❌ Share failed: $e");
    }
  }

  // UTILS
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

  BoxDecoration _decor() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 3)),
      ],
    );
  }

  Widget _empty(String msg) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Text(msg, style: GoogleFonts.montserrat(color: Colors.grey)),
    );
  }
}
