import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';

import 'package:jyotishasha_app/features/astrology/widgets/astrology_profile_card.dart';
import 'package:jyotishasha_app/core/state/manual_kundali_provider.dart';
import 'package:jyotishasha_app/features/astrology/widgets/astrology_tool_section.dart';

class ManualKundaliResultPage extends StatefulWidget {
  const ManualKundaliResultPage({super.key});

  @override
  State<ManualKundaliResultPage> createState() =>
      _ManualKundaliResultPageState();
}

class _ManualKundaliResultPageState extends State<ManualKundaliResultPage> {
  final GlobalKey _shareKey = GlobalKey();

  /// ⭐ SHARE SCREENSHOT
  Future<void> _shareAstrologyProfile() async {
    try {
      RenderRepaintBoundary boundary =
          _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/manual_kundali_profile.png");
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: "My Kundali Profile from Jyotishasha ✨");
    } catch (e) {
      debugPrint("❌ Share Failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManualKundaliProvider>();
    final kundali = provider.kundali ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),

      appBar: AppBar(
        title: const Text(
          "Your Kundali",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ⭐ Top Profile Card (Same as AstrologyPage)
            RepaintBoundary(
              key: _shareKey,
              child: AstrologyProfileCard(kundali: kundali),
            ),

            const SizedBox(height: 20),

            /// ⭐ Share Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _shareAstrologyProfile,
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text(
                  "Share With Friends",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            /// ⭐ Tools Section (Same as AstrologyPage)
            AstrologyToolSection(kundali: kundali),
          ],
        ),
      ),
    );
  }
}
