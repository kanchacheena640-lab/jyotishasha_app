import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/features/asknow/asknow_chat_page.dart';

/// "Ask Now" hero — premium, minimal Royal Purple card, the primary
/// conversion component of the Home screen. Same navigation
/// (`Navigator.push(... AskNowChatPage())`) as before — only the
/// presentation was redesigned.
///
/// F5.4 polish: the person/badge avatar illustration is removed entirely
/// (cleaner card, no floating icon); content is a single row —
/// heading+subtitle on the left, the "Ask Now →" button vertically
/// centered against that text block on the right (previously the button
/// sat in its own row, bottom-right).
///
/// F5.5 polish: height cut a further ~8% (98→90) with vertical padding
/// trimmed 20→10 (near-zero empty top/bottom space) for a tighter, more
/// compact card.
///
/// F5.6 polish: height cut another ~8dp (90→82), vertical padding trimmed
/// further (10→8), horizontal padding increased (24→28) for more
/// side-to-side breathing room, heading bumped to 20sp / subtitle to
/// 13sp. Height (82), radius (22), horizontal padding (28), and the
/// gradient/shadow are intentionally identical to [ShareStripWidget] so
/// the two banners read as one unified design system, not two separately
/// designed widgets.
///
/// F5.7 copy polish: heading/subtitle text updated to "Question in your
/// mind?" / "One free question every day." — UI text only, no structural
/// change.
class TrendingQuestionsWidget extends StatefulWidget {
  const TrendingQuestionsWidget({super.key});

  @override
  State<TrendingQuestionsWidget> createState() =>
      _TrendingQuestionsWidgetState();
}

class _TrendingQuestionsWidgetState extends State<TrendingQuestionsWidget> {
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().currentLang;
    final isHi = lang == 'hi';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AskNowChatPage()),
        );
      },
      child: Container(
        width: double.infinity,
        height: 82,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          // Subtle, same-hue Royal Purple gradient — no flashy colors.
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// LEFT — heading + subtitle only.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isHi ? 'मन में कोई सवाल..' : 'Question in mind..',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isHi
                        ? 'हर दिन एक सवाल मुफ़्त।'
                        : 'One free question every day.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            /// RIGHT — the one CTA, vertically centered with the text
            /// block via the shared Row. The whole card is already one
            /// tap target, so the button doesn't need its own onTap.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isHi ? 'अभी पूछें →' : 'Ask Now →',
                style: const TextStyle(
                  color: Color(0xFF6B21A8),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
