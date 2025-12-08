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
import 'package:jyotishasha_app/core/ads/banner_ad_widget.dart';
import 'package:jyotishasha_app/features/manual_kundali/manual_kundali_form_page.dart';

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

      /// ⭐ NORMAL CLEAN LAYOUT — NO STICKY, NO SCROLL BUGS
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ⭐ PROFILE CARD + SHARE TARGET
            RepaintBoundary(
              key: profileKey, // scrolling ke liye REQUIRED
              child: RepaintBoundary(
                key: _shareKey, // sharing ke liye REQUIRED
                child: AstrologyProfileCard(kundali: kundali),
              ),
            ),

            const SizedBox(height: 20),

            /// ⭐ NEW PREMIUM ACTION ROW — Manual Kundali (Left) + Share (Right)
            Row(
              children: [
                // ⭐ LEFT — Manual Kundali CTA
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orangeAccent.withOpacity(0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManualKundaliFormPage(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.edit_calendar_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Manual Kundali",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // ⭐ RIGHT — Share Button
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurpleAccent.withOpacity(0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: const Color(0xFF7C3AED),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _shareAstrologyProfile,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.share, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            "Share",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ⭐ ADS
            Center(child: BannerAdWidget()),
            const SizedBox(height: 20),

            /// ⭐ TOOL SECTIONS
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
