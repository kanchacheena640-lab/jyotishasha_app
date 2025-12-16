import 'package:flutter/material.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class AppFooterFeedbackWidget extends StatelessWidget {
  const AppFooterFeedbackWidget({super.key});

  Future<void> _openMail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'hr.slcomp@gmail.com',
      queryParameters: {'subject': 'Jyotishasha App Feedback'},
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

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
          Text(
            t.footerFeedbackHint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),

          const SizedBox(height: 16),

          GestureDetector(
            onTap: _openMail,
            child: ShaderMask(
              shaderCallback: (bounds) => jyotishashaGradient.createShader(
                Rect.fromLTWH(0, 0, bounds.width, bounds.height),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mail_outline, size: 22, color: Colors.white),
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

          Text(
            t.footerCopyright,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),

          const SizedBox(height: 4),

          GestureDetector(
            onTap: () {},
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
