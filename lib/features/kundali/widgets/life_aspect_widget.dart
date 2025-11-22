// lib/features/kundali/widgets/life_aspect_widget.dart

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import 'package:jyotishasha_app/core/constants/life_aspect_meta.dart';
import 'package:jyotishasha_app/core/utils/share_utils.dart';

class LifeAspectWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic> kundali;

  const LifeAspectWidget({
    super.key,
    required this.data,
    required this.kundali,
  });

  @override
  State<LifeAspectWidget> createState() => _LifeAspectWidgetState();
}

class _LifeAspectWidgetState extends State<LifeAspectWidget> {
  final GlobalKey _shareKey = GlobalKey();

  String _pickLang(String en, String hi, String lang) {
    if (lang == "hi" && hi.trim().isNotEmpty) return hi;
    return en;
  }

  Map<String, dynamic> _getAspectMeta(String name) {
    try {
      return LifeAspectMeta.allAspects.firstWhere(
        (m) => m["name"] == name,
        orElse: () => <String, dynamic>{},
      );
    } catch (e) {
      return <String, dynamic>{};
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Manual Kundali Language
    final String lang =
        widget.kundali["language"]?.toString().substring(0, 2) ?? "en";

    final data = widget.data;

    final aspect = _pickLang(
      (data["aspect"] ?? "").toString(),
      (data["aspect_hi"] ?? "").toString(),
      lang,
    );

    final summary = _pickLang(
      (data["summary"] ?? "").toString(),
      (data["summary_hi"] ?? "").toString(),
      lang,
    );

    final example = _pickLang(
      (data["example"] ?? "").toString(),
      (data["example_hi"] ?? "").toString(),
      lang,
    );

    final houses = (data["houses"] ?? "").toString();
    final planets = (data["planets"] ?? "").toString();
    final yogas = (data["yogas"] ?? "").toString();

    final meta = _getAspectMeta((data["aspect"] ?? "").toString());
    final emoji = (meta["emoji"] ?? "✨").toString();
    final colorHex = meta["color"] is int ? meta["color"] as int : 0xFF7C3AED;
    final Color baseColor = Color(colorHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(aspect, emoji, baseColor, houses, planets),

        const SizedBox(height: 20),

        // 🖼 SHAREABLE CONTENT
        RepaintBoundary(
          key: _shareKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionCard("Overview", summary),
              if (example.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionCard("Example", example),
              ],
              if (houses.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionCard("Key Houses", houses),
              ],
              if (planets.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionCard("Key Planets", planets),
              ],
              if (yogas.trim().isNotEmpty && yogas.trim() != "—") ...[
                const SizedBox(height: 16),
                _sectionCard("Important Yogas", yogas),
              ],
            ],
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  // ----------------------------------------------------
  // HEADER
  // ----------------------------------------------------
  Widget _buildHeader(
    String aspect,
    String emoji,
    Color baseColor,
    String houses,
    String planets,
  ) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                baseColor.withOpacity(0.95),
                baseColor.withOpacity(0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      aspect,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (houses.trim().isNotEmpty)
                Text(
                  "Houses: $houses",
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),

              if (planets.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  "Planets: $planets",
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),

        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareAspect,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // CARD UI
  // ----------------------------------------------------
  Widget _sectionCard(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.montserrat(
              fontSize: 13.5,
              height: 1.55,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // SHARE LOGIC
  // ----------------------------------------------------
  Future<void> _shareAspect() async {
    try {
      final boundary =
          _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/life_aspect.png");
      await file.writeAsBytes(pngBytes);

      await ShareUtils.shareImage(
        file.path,
        text: "✨ Life Aspect Insight — Generated by Jyotishasha App",
      );
    } catch (e) {
      // optional debug
    }
  }
}
