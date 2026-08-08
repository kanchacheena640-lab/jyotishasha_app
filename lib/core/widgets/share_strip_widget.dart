import 'package:flutter/material.dart';

import 'package:jyotishasha_app/features/cards/presentation/cards_page.dart';

/// A "Share" hero, built as a true sister component to
/// [TrendingQuestionsWidget]'s "Ask Now" banner — same corner radius (22),
/// horizontal padding (28), gradient, and shadow, so the two read as one
/// unified design system rather than two separately designed widgets.
/// Tapping anywhere (including "Share Now →") reuses the existing,
/// unfiltered [CardsPage] — no new route, no backend.
///
/// The WhatsApp/Instagram/Facebook glyphs are Material Icons tinted with
/// each platform's brand color, not the official logos — no brand asset
/// files exist in this project to reuse, and none were added for this.
///
/// F5.7 copy polish: the heading/subtitle pair was collapsed into a single
/// dominant line, "Someone you love may find this helpful." — UI text
/// only, no structural change.
///
/// F5.7.1 layout fix: height 82→90 (as a `minHeight`, not a fixed height —
/// the Hindi copy wraps to 2 lines and would overflow a fixed 90dp box;
/// English still renders at exactly 90dp since its content is shorter);
/// background watermark icon enlarged and further muted (size 84→110,
/// opacity 0.08→0.06, repositioned); heading centered full-width; vertical
/// rhythm tightened to heading→8dp→CTA→6dp→icon row.
class ShareStripWidget extends StatelessWidget {
  const ShareStripWidget({super.key});

  void _openCardsPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CardsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openCardsPage(context),
        child: Container(
          width: double.infinity,
          // minHeight (not a fixed height): 90dp fits the English copy
          // exactly, but the longer Hindi line wraps to 2 lines and needs
          // slightly more room — a fixed height would clip it.
          constraints: const BoxConstraints(minHeight: 90),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            // Same gradient + shadow as Ask Now — sister components.
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6B21A8), Color(0xFF7C3AED)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B21A8).withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Large faded share icon — watermark-only background
              // decoration, never competes with the foreground text.
              Positioned(
                left: -20,
                top: -12,
                child: Icon(
                  Icons.share_rounded,
                  size: 110,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      isHindi
                          ? 'किसी के लिए यह मददगार है।'
                          : 'Someone find this helpful.',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    isHindi ? 'अभी शेयर करें →' : 'Share Now →',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PlatformIcon(
                        icon: Icons.chat_bubble_rounded,
                        color: Color(0xFF25D366),
                      ),
                      SizedBox(width: 18),
                      _PlatformIcon(
                        icon: Icons.camera_alt_rounded,
                        color: Color(0xFFE1306C),
                      ),
                      SizedBox(width: 18),
                      _PlatformIcon(
                        icon: Icons.facebook,
                        color: Color(0xFF1877F2),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A social-platform glyph — every instance uses the identical `size`
/// (18dp), so all three sit on the same baseline with no icon feeling
/// larger than another.
class _PlatformIcon extends StatelessWidget {
  const _PlatformIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  static const double size = 18;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: size, color: color);
  }
}
