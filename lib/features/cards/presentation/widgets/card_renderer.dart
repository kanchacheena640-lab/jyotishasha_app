import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';

import '../../data/card_model.dart';

class CardRenderer extends StatelessWidget {
  final CardModel card;

  const CardRenderer({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return ImageBgCard(card: card);
  }
}

/// ========================
/// 🔥 SHARE FUNCTION (Fixed)
/// ========================
Future<void> captureAndShare(
  BuildContext context,
  CardModel card,
  GlobalKey repaintKey,
) async {
  // 🔒 Context check (early safety)
  if (!context.mounted) return;

  try {
    // ✅ Language पहले capture करो (async से पहले)
    final lang = Localizations.localeOf(context).languageCode == 'hi'
        ? 'hi'
        : 'en';

    // 🎯 Share text prepare
    final shareText = lang == 'hi'
        ? (card.meta?['share_hi']?.toString() ?? "Jyotishasha ऐप देखें ✨")
        : (card.meta?['share_en']?.toString() ?? "Check Jyotishasha ✨");

    // 🎯 Render boundary safely
    final boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) {
      debugPrint("Share Error: Boundary not found");
      return;
    }

    // 🖼️ Convert to image
    final image = await boundary.toImage(pixelRatio: 4.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      debugPrint("Share Error: ByteData null");
      return;
    }

    final pngBytes = byteData.buffer.asUint8List();

    // 📁 Save temp file
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/jyotishasha_card.png");
    await file.writeAsBytes(pngBytes, flush: true);

    // 🔒 Context re-check (async के बाद)
    if (!context.mounted) return;

    // 📤 Share
    await Share.shareXFiles([XFile(file.path)], text: shareText);
  } catch (e) {
    debugPrint("Share Error: $e");
  }
}

/// ========================
/// 🔹 BASE CARD
/// ========================
class BaseCard extends StatelessWidget {
  final Widget child;
  final CardModel card;

  const BaseCard({super.key, required this.child, required this.card});

  @override
  Widget build(BuildContext context) {
    final GlobalKey repaintKey = GlobalKey();

    return Center(
      child: Stack(
        children: [
          RepaintBoundary(
            key: repaintKey,
            child: AspectRatio(aspectRatio: 9 / 16, child: child),
          ),

          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: () => captureAndShare(context, card, repaintKey),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.share_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ========================
/// 🔹 IMAGE BG CARD (FINAL CLEAN VERSION)
/// ========================
class ImageBgCard extends StatelessWidget {
  final CardModel card;

  const ImageBgCard({super.key, required this.card});

  static final Random _random = Random();

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode == 'hi'
        ? 'hi'
        : 'en';

    String safeCta = '';

    safeCta = (card.getCTA(lang)).trim();
    Widget _buildAstroContent(CardModel card, String lang) {
      final text = card.getContent(lang);

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// 🔥 LEFT WHITE LINE
                Container(
                  width: 4,
                  margin: const EdgeInsets.only(right: 14),
                  color: Colors.white,
                ),

                /// 🔥 TEXT BLOCK (center-left → right flow)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        "- Jyotishasha",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildGradientBg(int type) {
      final gradients = [
        [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        [Color(0xFF1D2671), Color(0xFFC33764)],
        [Color(0xFF141E30), Color(0xFF243B55)],
        [Color(0xFF42275A), Color(0xFF734B6D)],
      ];

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradients[type],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    }

    Widget _buildDecor(int type) {
      switch (type) {
        case 0:
          return Opacity(
            opacity: 0.08,
            child: Image.asset("assets/decor/stars.png", fit: BoxFit.cover),
          );

        case 1:
          return Align(
            alignment: Alignment.topRight,
            child: Opacity(
              opacity: 0.15,
              child: Image.asset("assets/decor/moon.png", width: 100),
            ),
          );

        case 2:
          return Opacity(
            opacity: 0.06,
            child: Image.asset("assets/decor/bubbles.png", fit: BoxFit.cover),
          );

        case 3:
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          );

        default:
          return const SizedBox();
      }
    }

    Widget _buildInsightCard(CardModel card, String lang) {
      final text = card.getContent(lang);
      final decorType = _random.nextInt(4);

      return Stack(
        children: [
          /// 🔹 IMAGE BACKGROUND
          Positioned.fill(child: Image.asset(card.image, fit: BoxFit.cover)),

          /// 🔥 DARK OVERLAY (READABILITY FIX)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.65),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),

          /// 🔹 DECOR (subtle)
          Positioned.fill(child: _buildDecor(decorType)),

          /// 🔹 MAIN CONTENT (UNCHANGED POSITION)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// 🔥 LEFT LINE
                    Container(
                      width: 4,
                      margin: const EdgeInsets.only(
                        right: 12,
                        top: 2,
                        bottom: 2,
                      ),
                      color: Colors.white.withValues(alpha: 0.9),
                    ),

                    /// 🔥 TEXT BLOCK
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19, // 👈 slightly balanced
                              height: 1.6,
                              letterSpacing: 0.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            "- Jyotishasha",
                            style: TextStyle(
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                          const SizedBox(height: 6),

                          /// 🔥 CTA
                          if (safeCta.isNotEmpty)
                            Text(
                              safeCta,
                              style: const TextStyle(
                                color: Color(0xFFFFD54F),
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    Widget _buildMuhurthCard(CardModel card, String lang) {
      final title = card.getTitle(lang);

      final raw = lang == 'hi'
          ? (card.contentHi ?? "")
          : (card.contentEn ?? "");

      final lines = raw.split('\n').where((e) => e.trim().isNotEmpty).toList();

      debugPrint(card.getContent(lang));

      return Stack(
        children: [
          /// 🔥 BG
          Positioned.fill(child: Image.asset(card.image, fit: BoxFit.cover)),

          /// 🔥 DARK OVERLAY
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0.62),
                    Colors.black.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(22, 54, 22, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔥 TOP
                Row(
                  children: [
                    const Text("🪔", style: TextStyle(fontSize: 34)),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFFD54F),
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                /// 🔥 DATE LIST
                Expanded(
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: lines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),

                    itemBuilder: (_, index) {
                      final line = lines[index];

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(18),

                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),

                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFD54F),
                                shape: BoxShape.circle,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                line,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (card.type == "insight") {
      return BaseCard(card: card, child: _buildInsightCard(card, lang));
    }

    if (card.type == "muhurth") {
      return BaseCard(card: card, child: _buildMuhurthCard(card, lang));
    }

    return BaseCard(
      card: card,
      child: Stack(
        children: [
          Positioned.fill(child: Image.asset(card.image, fit: BoxFit.cover)),

          /// 🔥 LIGHT GRADIENT (image visible रहे)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: card.type == "astro"
                      ? [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.55),
                          Colors.black.withValues(alpha: 0.85),
                        ]
                      : [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.35),
                        ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                const Text("🙏", style: TextStyle(fontSize: 48)),

                const SizedBox(height: 8),

                /// 🔥 CLASSY TITLE (FIXED)
                Text(
                  card.getTitle(lang),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Color.fromARGB(255, 239, 148, 2),
                    letterSpacing: 1.4,
                    height: 1.1,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                /// 🔥 CONTENT BOX (balanced glass)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                  margin: const EdgeInsets.only(bottom: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (_) {
                          final content = card.getContent(lang);

                          final abhijit =
                              card.meta?['abhijit']?.toString() ?? '';
                          final rahu = card.meta?['rahu']?.toString() ?? '';

                          if (card.type == "astro") {
                            return _buildAstroContent(card, lang);
                          }

                          return RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: card.type == "night"
                                    ? 22
                                    : 16.5, // 👈 FIX
                                height: card.type == "night" ? 1.5 : 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                              children: content.split('\n').map((line) {
                                /// 👉 NIGHT CARD → NO HIGHLIGHT
                                if (card.type == "night") {
                                  return TextSpan(text: "$line\n");
                                }

                                /// 👉 MORNING ONLY → ABHIJIT
                                if (abhijit.isNotEmpty &&
                                    line.contains(abhijit)) {
                                  return TextSpan(
                                    children: [
                                      TextSpan(
                                        text: line.replaceAll(abhijit, ''),
                                      ),
                                      TextSpan(
                                        text: abhijit,
                                        style: const TextStyle(
                                          color: Color(0xFFFFD54F),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const TextSpan(text: '\n'),
                                    ],
                                  );
                                }

                                /// 👉 MORNING ONLY → RAHU
                                if (rahu.isNotEmpty && line.contains(rahu)) {
                                  return TextSpan(
                                    children: [
                                      TextSpan(text: line.replaceAll(rahu, '')),
                                      TextSpan(
                                        text: rahu,
                                        style: const TextStyle(
                                          color: Color(0xFFFF6B6B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const TextSpan(text: '\n'),
                                    ],
                                  );
                                }

                                return TextSpan(text: "$line\n");
                              }).toList(),
                            ),
                          );
                        },
                      ),

                      /// 🔥 CTA
                      if (safeCta.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            safeCta,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 13.8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
