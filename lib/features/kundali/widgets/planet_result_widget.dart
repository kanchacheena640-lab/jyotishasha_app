import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:jyotishasha_app/core/constants/planet_meta.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';

class PlanetResultWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic> kundali;

  const PlanetResultWidget({
    super.key,
    required this.data,
    required this.kundali,
  });

  @override
  State<PlanetResultWidget> createState() => _PlanetResultWidgetState();
}

class _PlanetResultWidgetState extends State<PlanetResultWidget> {
  final GlobalKey _shareKey = GlobalKey();

  // SAFE META LOOKUP (Hindi → English mapping)
  Map<String, dynamic> getPlanetMeta(String planet) {
    // Hindi names se match nahi hota → English planet use karo
    final englishName = widget.data["planet"]?.toString() ?? planet;

    try {
      return PlanetMeta.allPlanets.firstWhere(
        (p) => p["name"].toString().toLowerCase() == englishName.toLowerCase(),
        orElse: () => {},
      );
    } catch (_) {
      return {};
    }
  }

  // SAFETY PICKER FOR ALL TEXTS
  String safePick(dynamic hi, dynamic en) {
    if (hi is String && hi.trim().isNotEmpty) return hi;
    if (en is String && en.trim().isNotEmpty) return en;
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final lang = Provider.of<LanguageProvider>(context).currentLang;
    final p = widget.data;

    // ⭐ Always use safePick for non-crashing fallback
    final planet = lang == "hi"
        ? safePick(p["planet_hi"], p["planet"])
        : (p["planet"] ?? "");

    final benefitArea = lang == "hi"
        ? safePick(p["benefit_area_hi"], p["benefit_area"])
        : (p["benefit_area"] ?? "");

    final remedy = lang == "hi"
        ? safePick(p["remedy_hi"], p["remedy"])
        : (p["remedy"] ?? "");

    final summary = lang == "hi"
        ? safePick(p["summary_hi"], p["summary"])
        : (p["summary"] ?? "");

    final text = lang == "hi"
        ? safePick(p["text_hi"], p["text"])
        : (p["text"] ?? "");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(planet),

        const SizedBox(height: 20),

        RepaintBoundary(
          key: _shareKey,
          child: Column(
            children: [
              _sectionCard(t.planetOverview, summary),

              if (benefitArea.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionCard(t.benefitArea, benefitArea),
              ],

              if (remedy.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionCard(t.recommendedRemedy, remedy),
              ],

              const SizedBox(height: 20),

              _sectionCard(t.detailedInterpretation, text),
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
  Widget _header(String planet) {
    final meta = getPlanetMeta(planet);

    final emoji = meta["emoji"] ?? "⭐";
    final symbol = meta["symbol"] ?? "";
    final colorHex = meta["color"] ?? 0xFF7C3AED;
    final Color planetColor = Color(colorHex);

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                planetColor.withOpacity(0.9),
                planetColor.withOpacity(0.7),
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: Text(
                  symbol.isNotEmpty ? symbol : emoji,
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  planet,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _sharePlanet,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // CARD
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
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
  Future<void> _sharePlanet() async {
    try {
      final boundary =
          _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/planet_${widget.data["planet"]}.png");
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: "✨ ${widget.data["planet"]} — Generated by Jyotishasha App");
    } catch (e) {
      print("❌ Share failed: $e");
    }
  }
}
