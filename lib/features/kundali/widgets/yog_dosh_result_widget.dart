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

  // TITLE RESOLVER
  String _title() {
    final profile = widget.kundali["profile"] ?? {};
    final lang = profile["language"] == "Hindi" ? "hi" : "en";

    if (lang == "hi") {
      if (_data["heading_hi"] != null &&
          _data["heading_hi"].toString().trim().isNotEmpty) {
        return _data["heading_hi"];
      }
    }

    if (_data["heading"] != null &&
        _data["heading"].toString().trim().isNotEmpty) {
      return _data["heading"];
    }

    return _data["name"] ?? "Yog / Dosh Analysis";
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
            child: Text(
              isActive ? t.yogDoshActive : t.yogDoshInactive,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? Colors.green[800] : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
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
                "${t.yogDoshStrength}: $strength",
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

    final txt = _pick(_data["summary_block"]);
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
          _meaning(),
          _positives(),
          _challenge(),
          _reasons(),
          _details(),
          _summary(),
          _remedies(),
          const SizedBox(height: 8),
          _footer(),
        ],
      ),
    );
  }
}
