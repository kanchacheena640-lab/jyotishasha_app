// lib/features/kundali/widgets/yog_dosh_result_widget.dart

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

class YogDoshResultWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic> kundali;

  const YogDoshResultWidget({
    super.key,
    required this.data,
    required this.kundali,
  });

  @override
  State<YogDoshResultWidget> createState() => _YogDoshResultWidgetState();
}

Widget _dot(bool active) {
  return Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: active ? Colors.green : Colors.red,
      shape: BoxShape.circle,
    ),
  );
}

class _YogDoshResultWidgetState extends State<YogDoshResultWidget> {
  final GlobalKey _shareKey = GlobalKey();

  // PICK LIST (Hindi/English → backend driven)
  List<String> _pickList(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    return [];
  }

  // PICK SIMPLE TEXT (Hindi/English → backend driven)
  String _pick(dynamic value) {
    if (value == null) return "";
    return value.toString().trim();
  }

  Map<String, dynamic> get _data => widget.data;

  // TITLE RESOLVER (Handles Sadhesati + Manglik Dosh)
  String _title() {
    final profile = widget.kundali["profile"] ?? {};
    final lang = profile["language"] == "Hindi" ? "hi" : "en";

    // RAW KEYS
    final heading = _data["heading"]?.toString().trim();
    final name = _data["name"]?.toString().trim();

    // ⭐ SPECIAL: SADHESATI (no heading or name)
    if ((_data["id"] == "sadhesati") || (_data["tool"] == "sadhesati")) {
      return lang == "hi" ? "साढ़े साती" : "Sadhesati";
    }

    // ⭐ SPECIAL: MANGLIK DOSH (backend lacks Hindi)
    if ((_data["id"] == "manglik_dosh") || (_data["tool"] == "manglik-dosh")) {
      return lang == "hi" ? "मांगलिक दोष" : "Mangal Dosh";
    }

    // ⭐ NORMAL (title from backend)
    if (lang == "hi" &&
        _data["heading_hi"] != null &&
        _data["heading_hi"].toString().trim().isNotEmpty) {
      return _data["heading_hi"];
    }

    if (heading != null && heading.isNotEmpty) return heading;
    if (name != null && name.isNotEmpty) return name;

    return lang == "hi" ? "योग / दोष विश्लेषण" : "Yog / Dosh Analysis";
  }

  // SHARE HEADER
  Future<void> _shareYog() async {
    try {
      final boundary =
          _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3.2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/yog_${_data["id"] ?? "analysis"}.png");
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: "✨ ${_data["name"] ?? "Yog Dosh"} — Jyotishasha Analysis");
    } catch (_) {}
  }

  // HEADER
  Widget _buildHeader() {
    final title = _title();
    final emoji = (_data["emoji"] ?? "✨").toString();

    return RepaintBoundary(
      key: _shareKey,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
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
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 3,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white, size: 20),
              onPressed: _shareYog,
            ),
          ],
        ),
      ),
    );
  }

  // STATUS ROW
  Widget _buildStatus() {
    final t = AppLocalizations.of(context)!;

    final bool isActive = _data["is_active"] == true;

    String strength = "";
    if (_data["strength"] is String) {
      strength = _data["strength"];
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          // ACTIVE / INACTIVE CHIP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isActive ? Colors.green[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isActive ? Colors.green : Colors.grey),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(isActive), // 🔴🟢 Dot added
                const SizedBox(width: 6),
                Text(
                  isActive ? t.yogDoshActive : t.yogDoshInactive,
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? Colors.green[800] : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // STRENGTH CHIP
          if (strength.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.indigo),
              ),
              child: Text(
                t.yogDoshStrength(strength),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.indigo,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // UNIVERSAL CARD
  Widget _card(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(1, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.trim().isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }

  // EXPLANATION (meaning)
  Widget _meaning() {
    final t = AppLocalizations.of(context)!;

    final text = _pick(_data["description"]);
    if (text.isEmpty) return const SizedBox.shrink();

    return _card(
      t.yogDoshMeaning,
      Text(text, style: const TextStyle(fontSize: 13.5, height: 1.45)),
    );
  }

  // POSITIVES
  Widget _positives() {
    final t = AppLocalizations.of(context)!;

    final list = _pickList(_data["positives"]);
    if (list.isEmpty) return const SizedBox.shrink();

    return _card(
      t.yogDoshBlessings,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text("• $p", style: const TextStyle(fontSize: 13.5)),
              ),
            )
            .toList(),
      ),
    );
  }

  // CHALLENGE
  Widget _challenge() {
    final t = AppLocalizations.of(context)!;

    final txt = _pick(_data["challenge"]);
    if (txt.isEmpty) return const SizedBox.shrink();

    return _card(
      t.yogDoshChallenge,
      Text(txt, style: const TextStyle(fontSize: 13.5, height: 1.45)),
    );
  }

  // REASONS
  Widget _reasons() {
    final t = AppLocalizations.of(context)!;

    final list = _pickList(_data["reasons"]);
    if (list.isEmpty) return const SizedBox.shrink();

    return _card(
      t.yogDoshReasons,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text("• $e", style: const TextStyle(fontSize: 13.5)),
              ),
            )
            .toList(),
      ),
    );
  }

  // REPORT PARAGRAPHS
  Widget _details() {
    final t = AppLocalizations.of(context)!;

    final list = _pickList(_data["report_paragraphs"]);
    if (list.isEmpty) return const SizedBox.shrink();

    return _card(
      t.yogDoshDetails,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(p, style: const TextStyle(fontSize: 13.5)),
              ),
            )
            .toList(),
      ),
    );
  }

  // SUMMARY
  Widget _summary() {
    final t = AppLocalizations.of(context)!;

    final sb = _data["summary_block"];

    // ❌ If NULL → hide
    if (sb == null) return const SizedBox.shrink();

    // ❌ If Map (Sadhesati / Manglik style) → hide (we render separately)
    if (sb is Map) return const SizedBox.shrink();

    // ✔️ If string → show summary
    final txt = sb.toString().trim();
    if (txt.isEmpty) return const SizedBox.shrink();

    return _card(
      t.yogDoshSummary,
      Text(txt, style: const TextStyle(fontSize: 13.5, height: 1.45)),
    );
  }

  // REMEDIES
  Widget _remedies() {
    final t = AppLocalizations.of(context)!;

    final list = _pickList(_data["remedies"]);
    if (list.isEmpty) return const SizedBox.shrink();

    return _card(
      t.yogDoshRemedies,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text("• $e", style: const TextStyle(fontSize: 13.5)),
              ),
            )
            .toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ⭐ SPECIAL BLOCK FOR MANGLIK DOSH
  // ---------------------------------------------------------------------------
  Widget _manglikSpecial() {
    if (_data["tool"] != "mangal-dosh" && _data["id"] != "manglik_dosh") {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_data["general_explanation"] != null)
          _card(
            "General Explanation",
            Text(
              _data["general_explanation"],
              style: const TextStyle(fontSize: 13.5, height: 1.45),
            ),
          ),

        _card(
          "Manglik Status",
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Status: ${_data["status"]?["is_mangalic"] ?? "-"}",
                style: const TextStyle(fontSize: 13.5),
              ),
              const SizedBox(height: 6),
              Text(
                "Strength: ${_data["evaluation"]?["final_strength"] ?? "-"}",
                style: const TextStyle(fontSize: 13.5),
              ),
            ],
          ),
        ),

        if (_data["summary_block"]?["points"] != null)
          _card(
            _data["summary_block"]["heading"] ?? "Summary",
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (_data["summary_block"]["points"] as List)
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        "• $e",
                        style: const TextStyle(fontSize: 13.5),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ⭐ SPECIAL BLOCK FOR SADHESATI
  // ---------------------------------------------------------------------------
  Widget _sadhesatiSpecial() {
    if (_data["id"] != "sadhesati" && _data["tool"] != "sadhesati") {
      return const SizedBox.shrink();
    }

    final summary = _data["summary_block"];
    final phases = _data["phase_dates"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_data["explanation"] != null)
          _card(
            "Explanation",
            Text(
              _data["explanation"],
              style: const TextStyle(fontSize: 13.5, height: 1.45),
            ),
          ),

        // ⭐ CLEAN SUMMARY BLOCK (beautiful + correct)
        if (summary != null &&
            summary is Map &&
            summary["points"] is List &&
            (summary["points"] as List).isNotEmpty)
          _card(
            summary["heading"] ?? "Summary",
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (summary["points"] as List)
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        "• $e",
                        style: const TextStyle(fontSize: 13.5),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

        // ⭐ CLEAN PHASE BLOCK
        if (phases != null)
          _card(
            "Sadhesati Phases",
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _phaseTile("First Phase", phases["first_phase"]),
                const SizedBox(height: 8),
                _phaseTile("Second Phase", phases["second_phase"]),
                const SizedBox(height: 8),
                _phaseTile("Third Phase", phases["third_phase"]),
              ],
            ),
          ),
      ],
    );
  }

  // Helper for sadhesati phases
  Widget _phaseTile(String title, Map? data) {
    if (data == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text("Start: ${data["start"]}"),
          Text("End: ${data["end"]}"),
        ],
      ),
    );
  }

  // FILTERED SUMMARY HANDLER
  Widget _filteredSummary() {
    final name = (_data["name"] ?? "").toString().toLowerCase();
    final heading = (_data["heading"] ?? "").toString().toLowerCase();

    // Detect Sadhesati (backend lacks id/tool)
    final isSadhesati =
        name.contains("sadhesati") ||
        heading.contains("sadhesati") ||
        _data.containsKey("phase_dates");

    // Detect Manglik Dosh
    final isManglik =
        name.contains("manglik") ||
        heading.contains("manglik") ||
        _data["tool"] == "mangal-dosh" ||
        _data["id"] == "manglik_dosh";

    if (isSadhesati || isManglik) {
      return const SizedBox.shrink();
    }

    return _summary();
  }

  // FOOTER
  Widget _footer() {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        t.yogDoshFooter,
        style: TextStyle(fontSize: 11, height: 1.4, color: Colors.grey[600]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildStatus(),
          _manglikSpecial(),
          _sadhesatiSpecial(),
          _meaning(),
          _positives(),
          _challenge(),
          _reasons(),
          _details(),
          _filteredSummary(),
          _remedies(),
          const SizedBox(height: 8),
          _footer(),
        ],
      ),
    );
  }
}
