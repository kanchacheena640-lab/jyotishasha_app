import 'package:flutter/material.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

class AppFooterFeedbackWidget extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  AppFooterFeedbackWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // 🌈 Jyotishasha gradient (saffron → purple)
    const jyotishashaGradient = LinearGradient(
      colors: [Color(0xFFFF9933), Color(0xFF8E2DE2)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 💬 Feedback input box
          SizedBox(
            width: 300,
            child: TextField(
              controller: _controller,
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: t.footerFeedbackHint,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ✨ Gradient Send Button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(t.footerFeedbackThanks)));
              _controller.clear();
            },
            child: ShaderMask(
              shaderCallback: (bounds) => jyotishashaGradient.createShader(
                Rect.fromLTWH(0, 0, bounds.width, bounds.height),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.send_rounded, size: 22, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    t.footerFeedbackSend,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ⚖️ Copyright
          Text(
            t.footerCopyright,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),

          const SizedBox(height: 4),

          GestureDetector(
            onTap: () {}, // TODO: open Privacy/Terms page
            child: Text(
              t.footerPrivacyTerms,
              style: const TextStyle(
                fontSize: 12,
                decoration: TextDecoration.underline,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
