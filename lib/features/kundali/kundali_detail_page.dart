import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/core/widgets/kundali_chart_north_widget.dart';
import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';

class KundaliDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const KundaliDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final profile = Map<String, dynamic>.from(data["profile"] ?? {});
    final location = Map<String, dynamic>.from(data["location"] ?? {});
    final dasha = Map<String, dynamic>.from(
      data["dasha_summary"]?["current_block"] ?? {},
    );
    final List<dynamic> planets = List<dynamic>.from(
      data["chart_data"]?["planets"] ?? [],
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _HeaderSection(
              profile: profile,
              location: location,
              lagna: data["lagna_sign"] ?? "-",
              rashi: data["rashi"] ?? "-",
              mahadasha: dasha["mahadasha"] ?? "-",
              antardasha: dasha["antardasha"] ?? "-",
              planets: planets,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------

class _HeaderSection extends StatelessWidget {
  final Map<String, dynamic> profile;
  final Map<String, dynamic> location;
  final String lagna;
  final String rashi;
  final String mahadasha;
  final String antardasha;
  final List<dynamic> planets;

  _HeaderSection({
    required this.profile,
    required this.location,
    required this.lagna,
    required this.rashi,
    required this.mahadasha,
    required this.antardasha,
    required this.planets,
  });

  final GlobalKey _shareKey = GlobalKey();

  String _cap(String? text) {
    if (text == null || text.isEmpty) return "-";
    return text
        .trim()
        .split(" ")
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(" ");
  }

  String _formatDob(String? dob) {
    if (dob == null || dob.isEmpty) return "-";
    if (dob.contains("-")) {
      final p = dob.split("-");
      if (p.length == 3 && p[0].length == 4) {
        return "${p[2]}-${p[1]}-${p[0]}";
      }
    }
    return dob;
  }

  @override
  Widget build(BuildContext context) {
    final String name = _cap(profile["name"]);
    final String dob = _formatDob(profile["dob"]);
    final String tob = profile["tob"] ?? "-";
    final String pob = profile["pob"] ?? "-";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),

          RepaintBoundary(
            key: _shareKey,
            child: Column(
              children: [
                Text(
                  "Name: $name  |  DOB: $dob  |  TOB: $tob  |  POB: $pob",
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                Container(
                  height: 260,
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFF5EAFE),
                        Color(0xFF6D28D9),
                        Color(0xFF4C1D95),
                      ],
                      stops: [0.15, 0.55, 1.0],
                      radius: 1.1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x805B21B6),
                        blurRadius: 24,
                        spreadRadius: 6,
                        offset: Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.white30,
                        blurRadius: 12,
                        spreadRadius: -2,
                        offset: Offset(0, -4),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white24, width: 1.2),
                  ),
                  child: Center(
                    child: KundaliChartNorthWidget(
                      planets: planets,
                      lagnaSign: lagna,
                      size: 240,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Lagna: $lagna  |  Rashi: $rashi  |  Current Dasha: $mahadasha",
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  "✨ Generated by Jyotishasha",
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 6),
              ],
            ),
          ),

          const SizedBox(height: 12),

          TextButton.icon(
            onPressed: () => _shareKundali(),
            icon: const Icon(Icons.share, color: Colors.white),
            label: const Text(
              "Share Kundali",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareKundali() async {
    try {
      final boundary =
          _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File("${tempDir.path}/kundali_share.png");
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: "✨ My Kundali generated by Jyotishasha App");
    } catch (e) {
      print("❌ Sharing failed: $e");
    }
  }
}
