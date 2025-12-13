// lib/features/kundali/widgets/life_aspect_widget.dart

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/constants/life_aspect_meta.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/utils/share_utils.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

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

  Map<String, dynamic> _getAspectMeta(String nameEN) {
    try {
      return LifeAspectMeta.allAspects.firstWhere(
        (m) => m["name"] == nameEN,
        orElse: () => <String, dynamic>{},
      );
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLang;
    final t = AppLocalizations.of(context)!;
    final d = widget.data;

    // --------------------------
    // PERFECT LANGUAGE PICKING
    // --------------------------
    String pick(String enKey, String hiKey) {
      if (lang == "hi" && (d[hiKey]?.toString().isNotEmpty ?? false)) {
        return d[hiKey];
      }
      return d[enKey] ?? "";
    }

    final aspect = pick("aspect", "aspect_hi");
    final summary = pick("summary", "summary_hi");
    final example = pick("example", "example_hi");
    final houses = pick("houses", "houses_hi");
    final planets = pick("planets", "planets_hi");
    final yogas = pick("yogas", "yogas_hi");

    // -----------------------
    // META DATA (emoji/color)
    // -----------------------
    final meta = _getAspectMeta(d["aspect"] ?? "");
    final emoji = (meta["emoji"] ?? "✨").toString();
    final colorHex = meta["color"] is int ? meta["color"] as int : 0xFF7C3AED;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(aspect, emoji, Color(colorHex), houses, planets),
        const SizedBox(height: 20),

        RepaintBoundary(
          key: _shareKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionCard(t.overview, summary),

              if (example.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionCard(t.example, example),
              ],

              if (houses.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionCard(t.keyHouses, houses),
              ],

              if (planets.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionCard(t.keyPlanets, planets),
              ],

              if (yogas.trim().isNotEmpty && yogas != "—") ...[
                const SizedBox(height: 16),
                _sectionCard(t.importantYogas, yogas),
              ],
            ],
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  // HEADER
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
                baseColor.withOpacity(0.98),
                baseColor.withOpacity(0.78),
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
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      aspect,
                      style: const TextStyle(
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
                  AppLocalizations.of(context)!.housesPrefix(houses),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),

              if (planets.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.planetsPrefix(planets),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
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

  // CARD
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
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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

  // SHARE
  Future<void> _shareAspect() async {
    try {
      final boundary =
          _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3.2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/life_aspect_share.png");
      await file.writeAsBytes(pngBytes);

      await ShareUtils.shareImage(
        file.path,
        text: AppLocalizations.of(context)!.shareLifeAspectText,
      );
    } catch (_) {}
  }
}
