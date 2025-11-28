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
import 'package:jyotishasha_app/l10n/app_localizations.dart';

class AstrologyPage extends StatefulWidget {
  final String? selectedSection;
  const AstrologyPage({super.key, this.selectedSection});

  @override
  State<AstrologyPage> createState() => _AstrologyPageState();
}

class _AstrologyPageState extends State<AstrologyPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _shareKey = GlobalKey();

  final profileKey = GlobalKey();
  final planetsKey = GlobalKey();
  final bhavaKey = GlobalKey();
  final dashaKey = GlobalKey();
  final lifeKey = GlobalKey();
  final yogKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    if (widget.selectedSection != null) {
      Future.delayed(const Duration(milliseconds: 400), () {
        _scrollToSection(widget.selectedSection!);
      });
    }
  }

  void _scrollToSection(String section) {
    BuildContext? targetContext;

    switch (section) {
      case "profile":
        targetContext = profileKey.currentContext;
        break;
      case "planets":
        targetContext = planetsKey.currentContext;
        break;
      case "bhava":
        targetContext = bhavaKey.currentContext;
        break;
      case "dasha":
        targetContext = dashaKey.currentContext;
        break;
      case "life":
        targetContext = lifeKey.currentContext;
        break;
      case "yog":
        targetContext = yogKey.currentContext;
        break;
    }

    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        alignment: 0.1,
      );
    }
  }

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

      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      debugPrint("❌ Error sharing: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final firebase = context.watch<FirebaseKundaliProvider>();

    if (firebase.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (firebase.kundaliData == null) {
      return Scaffold(
        body: Center(
          child: Text(
            t.astro_loading_error,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    final kundali = firebase.kundaliData!;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      appBar: AppBar(
        title: Text(
          t.astro_insights_title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ⭐ PROFILE CARD
            RepaintBoundary(
              key: profileKey,
              child: AstrologyProfileCard(kundali: kundali),
            ),

            const SizedBox(height: 20),

            /// ⭐ SHARE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.share, color: Colors.white),
                label: Text(
                  t.astro_share_button,
                  style: const TextStyle(color: Colors.white),
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

            AstrologyToolSection(
              kundali: kundali,
              initialSection: widget.selectedSection,
            ),
          ],
        ),
      ),
    );
  }
}
