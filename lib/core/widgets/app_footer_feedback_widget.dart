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

  Future<void> _openPlayStore() async {
    final Uri url = Uri.parse(
      "https://play.google.com/store/apps/details?id=com.jyotishasha.app",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openPrivacy() async {
    final Uri url = Uri.parse("https://www.jyotishasha.com/privacy-policy");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFFF7F7F7),
      child: Column(
        children: [
          /// feedback hint
          Text(
            t.footerFeedbackHint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),

          const SizedBox(height: 8),

          /// action buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _openMail,
                child: Row(
                  children: const [
                    Icon(Icons.mail_outline, size: 18),
                    SizedBox(width: 4),
                    Text("Feedback", style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              GestureDetector(
                onTap: _openPlayStore,
                child: Row(
                  children: const [
                    Icon(
                      Icons.star_rate_rounded,
                      size: 18,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 4),
                    Text("Rate App", style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              GestureDetector(
                onTap: _openPrivacy,
                child: Row(
                  children: const [
                    Icon(Icons.privacy_tip_outlined, size: 18),
                    SizedBox(width: 4),
                    Text("Privacy", style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          /// bottom line
          const Text(
            "© 2025 Jyotishasha • v1.0.0",
            style: TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
