import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';

import 'widgets/astrology_profile_card.dart';
import 'package:jyotishasha_app/core/state/firebase_kundali_provider.dart';
import 'package:jyotishasha_app/features/astrology/widgets/astrology_tool_section.dart';

class AstrologyPage extends StatefulWidget {
  const AstrologyPage({super.key});

  @override
  State<AstrologyPage> createState() => _AstrologyPageState();
}

class _AstrologyPageState extends State<AstrologyPage> {
  final GlobalKey _shareKey = GlobalKey();

  /// ⭐ SHARE SCREENSHOT FUNCTION
  Future<void> _shareAstrologyProfile() async {
    try {
      RenderRepaintBoundary boundary =
          _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);

      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/astrology_profile.png");
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: "My Astrology Profile from Jyotishasha ✨");
    } catch (e) {
      debugPrint("❌ Error sharing: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebase = context.watch<FirebaseKundaliProvider>();
    final kundali = firebase.kundaliData ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),

      appBar: AppBar(
        title: const Text(
          "Astrology Tools",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ⭐ SHAREABLE PROFILE SUMMARY CARD
            RepaintBoundary(
              key: _shareKey,
              child: AstrologyProfileCard(kundali: kundali),
            ),

            const SizedBox(height: 20),

            /// ⭐ Share Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
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
                onPressed: _shareAstrologyProfile,
              ),
            ),

            const SizedBox(height: 14),

            /// ⭐ Tools Section
            AstrologyToolSection(kundali: kundali),
          ],
        ),
      ),
    );
  }
}
