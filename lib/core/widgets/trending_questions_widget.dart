import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/features/asknow/asknow_chat_page.dart';
import 'package:jyotishasha_app/core/state/asknow_provider.dart';

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

    final provider = context.watch<AskNowProvider>();
    final freeLeft = provider.freeAvailable ? 1 : 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AskNowChatPage()),
        );
      },

      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),

          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          ),

          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.22),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),

        child: Stack(
          children: [
            /// ⭐ soft stars
            Positioned(
              right: -10,
              top: -8,
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white.withValues(alpha: 0.08),
                size: 90,
              ),
            ),

            Positioned(
              right: 28,
              bottom: 0,
              child: Icon(
                Icons.star_rounded,
                color: Colors.white.withValues(alpha: 0.10),
                size: 52,
              ),
            ),

            Row(
              children: [
                /// 🔮 LEFT ICON
                Container(
                  width: 58,
                  height: 58,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),

                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 30,
                      ),

                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            "?",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                /// ✨ TEXT AREA
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang == "hi"
                            ? "मन में कोई सवाल है?"
                            : "Question in your mind?",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        lang == "hi"
                            ? "भारत के Best AI Astrologer से पूछें"
                            : "Ask India’s Best AI Astrologer",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: Text(
                              freeLeft > 0
                                  ? (lang == "hi"
                                        ? "1 फ्री प्रश्न ✨"
                                        : "1 FREE Question ✨")
                                  : (lang == "hi"
                                        ? "अभी पूछें ✨"
                                        : "Ask Now ✨"),

                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          const Spacer(),

                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
