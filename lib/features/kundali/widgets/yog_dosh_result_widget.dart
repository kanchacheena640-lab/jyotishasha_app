import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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

class _YogDoshResultWidgetState extends State<YogDoshResultWidget> {
  final GlobalKey _shareKey = GlobalKey();

  Map<String, dynamic> get _data => widget.data;

  String _fallbackText(List<String> keys, {String defaultValue = "-"}) {
    for (final k in keys) {
      final v = _data[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return defaultValue;
  }

  List<String> _stringList(List<String> keys) {
    for (final k in keys) {
      final v = _data[k];
      if (v is List) {
        return v
            .where((e) => e is String && e.trim().isNotEmpty)
            .map((e) => e as String)
            .toList();
      }
    }
    return const [];
  }

  // ------------------------------------------------
  // SHARE HEADER (only header+title+emoji)
  // ------------------------------------------------
  Future<void> _shareYog() async {
    try {
      final boundary =
          _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/yog_${_data["id"] ?? "result"}.png");
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: "✨ ${_data["name"] ?? "Yog Dosh"} — Jyotishasha Analysis");
    } catch (e) {
      // ignore, just log
      // print("❌ Yog share failed: $e");
    }
  }

  // ------------------------------------------------
  // HEADER STRIP (gradient + emoji + heading + share)
  // ------------------------------------------------
  Widget _buildHeader() {
    final String title = _fallbackText([
      "heading",
      "name",
    ], defaultValue: "Yog / Dosh Analysis");

    final String emoji = (_data["emoji"] ?? "✨").toString();

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.share, color: Colors.white, size: 20),
              onPressed: _shareYog,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------
  // STATUS CHIP ROW  (Active / Inactive + Strength etc.)
  // ------------------------------------------------
  Widget _buildStatusRow() {
    final bool isActive = _data["is_active"] == true;

    // strength from multiple possible locations
    String strength = "";
    if (_data["strength"] is String) {
      strength = (_data["strength"] as String).trim();
    } else if (_data["status"] is Map &&
        (_data["status"]["strength"] is String)) {
      strength = (_data["status"]["strength"] as String).trim();
    } else if (_data["evaluation"] is Map &&
        (_data["evaluation"]["final_strength"] is String)) {
      strength = (_data["evaluation"]["final_strength"] as String).trim();
    }

    String statusText = isActive ? "Active" : "Inactive";
    if (_data["status"] is Map && _data["status"]["is_mangalic"] is String) {
      statusText = (_data["status"]["is_mangalic"] as String).trim();
    } else if (_data["status"] is String &&
        (_data["status"] as String).trim().isNotEmpty) {
      statusText = (_data["status"] as String).trim();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Active / Inactive style chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.green.withOpacity(0.12)
                  : Colors.grey.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? Colors.green : Colors.grey,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isActive ? "Active in your chart" : "Not active in chart",
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? Colors.green[800] : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          if (strength.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.indigo.withOpacity(0.6),
                  width: 0.8,
                ),
              ),
              child: Text(
                "Strength: $strength",
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.indigo,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          if (statusText.isNotEmpty &&
              statusText != "Active in your chart" &&
              statusText != "Not active in chart")
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.6),
                  width: 0.8,
                ),
              ),
              child: Text(
                statusText,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------
  // GENERIC CARD
  // ------------------------------------------------
  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
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
          if (title.isNotEmpty) ...[
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

  // ------------------------------------------------
  // DESCRIPTION / GENERAL EXPLANATION
  // ------------------------------------------------
  Widget _buildMainExplanation() {
    final String text = _fallbackText([
      "description",
      "general_explanation",
      "short_description",
      "summary_block",
    ], defaultValue: "");

    if (text.isEmpty) return const SizedBox.shrink();

    return _card(
      title: "What this Yog / Dosh means",
      child: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.45)),
    );
  }

  // ------------------------------------------------
  // POSITIVES SECTION
  // ------------------------------------------------
  Widget _buildPositives() {
    final positives = _stringList(["positives"]);

    if (positives.isEmpty) return const SizedBox.shrink();

    return _card(
      title: "Key blessings & strengths",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: positives.map((p) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "• ",
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: Colors.black87,
                  ),
                ),
                Expanded(
                  child: Text(
                    p,
                    style: const TextStyle(fontSize: 13.5, height: 1.45),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ------------------------------------------------
  // CHALLENGE SECTION
  // ------------------------------------------------
  Widget _buildChallenge() {
    final String challenge = _fallbackText(["challenge"], defaultValue: "");

    if (challenge.isEmpty ||
        challenge.toLowerCase().contains("no challenge") ||
        challenge.toLowerCase().contains("not active")) {
      return const SizedBox.shrink();
    }

    return _card(
      title: "Possible challenges",
      child: Text(
        challenge,
        style: const TextStyle(fontSize: 13.5, height: 1.45),
      ),
    );
  }

  // ------------------------------------------------
  // REASONS SECTION
  // ------------------------------------------------
  Widget _buildReasons() {
    final reasons = _stringList(["reasons"]);

    if (reasons.isEmpty) return const SizedBox.shrink();

    return _card(
      title: "Why this Yog / Dosh is formed",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: reasons.map((r) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "• ",
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: Colors.black87,
                  ),
                ),
                Expanded(
                  child: Text(
                    r,
                    style: const TextStyle(fontSize: 13.5, height: 1.45),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ------------------------------------------------
  // REPORT PARAGRAPHS (Kaalsarp, Mangal, SadeSati etc.)
  // ------------------------------------------------
  Widget _buildReportParagraphs() {
    final paragraphs = _stringList(["report_paragraphs"]);

    if (paragraphs.isEmpty) return const SizedBox.shrink();

    return _card(
      title: "Detailed explanation",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: paragraphs.map((p) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              p,
              style: const TextStyle(fontSize: 13.5, height: 1.45),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ------------------------------------------------
  // SUMMARY BLOCK (for Mangal Dosh, Sade Sati, Kaalsarp etc.)
  // ------------------------------------------------
  Widget _buildSummaryBlock() {
    final summary = _data["summary_block"];

    if (summary is String && summary.trim().isNotEmpty) {
      return _card(
        title: "Summary",
        child: Text(
          summary.trim(),
          style: const TextStyle(fontSize: 13.5, height: 1.45),
        ),
      );
    }

    if (summary is Map<String, dynamic>) {
      final String heading =
          (summary["heading"] is String &&
              summary["heading"].toString().trim().isNotEmpty)
          ? summary["heading"].toString().trim()
          : "Summary";
      final List points = summary["points"] is List
          ? summary["points"]
          : const [];

      return _card(
        title: heading,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (points.isNotEmpty)
              ...points.map((e) {
                final txt = e.toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "• ",
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: Colors.black87,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          txt,
                          style: const TextStyle(fontSize: 13.5, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ------------------------------------------------
  // EVALUATION (for Mangal Dosh etc.)
  // ------------------------------------------------
  Widget _buildEvaluation() {
    final eval = _data["evaluation"];
    if (eval is! Map<String, dynamic>) return const SizedBox.shrink();

    final String finalStrength = (eval["final_strength"] ?? "")
        .toString()
        .trim();
    final mitigations = eval["mitigations"] is List
        ? (eval["mitigations"] as List)
              .where((e) => e is String && e.trim().isNotEmpty)
              .map((e) => e as String)
              .toList()
        : <String>[];

    final triggersMap = eval["triggers"] is Map<String, dynamic>
        ? eval["triggers"] as Map<String, dynamic>
        : const <String, dynamic>{};

    return _card(
      title: "Astrological evaluation",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (finalStrength.isNotEmpty) ...[
            Text(
              "Overall strength: $finalStrength",
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (mitigations.isNotEmpty) ...[
            const Text(
              "Mitigations / Balancing factors:",
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            ...mitigations.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "• ",
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: Colors.black87,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        m,
                        style: const TextStyle(fontSize: 13.5, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (triggersMap.isNotEmpty) ...[
            const SizedBox(height: 4),
            const Text(
              "Trigger status:",
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            ...triggersMap.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  "${e.key}: ${e.value}",
                  style: const TextStyle(fontSize: 13.0, height: 1.4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------
  // CONTEXT (for Mangal Dosh – houses, signs etc.)
  // ------------------------------------------------
  Widget _buildContextBlock() {
    final ctx = _data["context"];
    if (ctx is! Map<String, dynamic>) return const SizedBox.shrink();

    // Hum sirf kuch key highlights dikhayenge
    final String lagnaSign = (ctx["lagna_sign"] ?? "").toString().trim();
    final String marsSign = (ctx["mars_sign"] ?? "").toString().trim();
    final int? marsHouse = ctx["mars_house_from_lagna"] is int
        ? ctx["mars_house_from_lagna"] as int
        : null;
    final String moonSign = (ctx["moon_sign"] ?? "").toString().trim();

    final List<String> lines = [];

    if (lagnaSign.isNotEmpty) {
      lines.add("Lagna sign: $lagnaSign");
    }
    if (marsSign.isNotEmpty) {
      lines.add(
        "Mars sign (from Lagna): $marsSign${marsHouse != null ? " — House $marsHouse" : ""}",
      );
    }
    if (moonSign.isNotEmpty) {
      lines.add("Moon sign: $moonSign");
    }

    if (lines.isEmpty) return const SizedBox.shrink();

    return _card(
      title: "Chart context (for reference)",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  l,
                  style: const TextStyle(fontSize: 13.0, height: 1.4),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ------------------------------------------------
  // REMEDIES (for Kaalsarp, Mangal, Sade Sati, etc.)
  // ------------------------------------------------
  Widget _buildRemedies() {
    final remedies = _stringList(["remedies"]);

    if (remedies.isEmpty) return const SizedBox.shrink();

    return _card(
      title: "Suggested remedies / focus points",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: remedies.map((r) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "• ",
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: Colors.black87,
                  ),
                ),
                Expanded(
                  child: Text(
                    r,
                    style: const TextStyle(fontSize: 13.5, height: 1.45),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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
          _buildStatusRow(),
          _buildMainExplanation(),
          _buildPositives(),
          _buildChallenge(),
          _buildReasons(),
          _buildReportParagraphs(),
          _buildSummaryBlock(),
          _buildEvaluation(),
          _buildContextBlock(),
          _buildRemedies(),
          const SizedBox(height: 8),
          // 🔚 छोटा सा footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "Note: Above points are based on your current Kundali data and Yog/Dosh rules configured in Jyotishasha engine.",
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
