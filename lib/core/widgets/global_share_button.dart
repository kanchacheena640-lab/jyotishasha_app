import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/utils/share_templates.dart';

class GlobalShareButton extends StatelessWidget {
  final String currentPage; // panchang, darshan, horoscope, etc.

  const GlobalShareButton({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().currentLang; // "en" / "hi"
    final isHindi = lang == "hi";

    return IconButton(
      icon: const Icon(Icons.share),
      onPressed: () {
        String text;

        switch (currentPage) {
          case "panchang":
            text = isHindi
                ? ShareTemplates.muhurthaHi
                : ShareTemplates.muhurthaEn;
            break;

          case "darshan":
            text = isHindi
                ? ShareTemplates.darshanHi
                : ShareTemplates.darshanEn;
            break;

          case "daily_horoscope":
            text = isHindi
                ? ShareTemplates.dailyHoroscopeHi
                : ShareTemplates.dailyHoroscopeEn;
            break;

          case "asknow":
            text = isHindi ? ShareTemplates.askNowHi : ShareTemplates.askNowEn;
            break;

          default:
            text = isHindi
                ? ShareTemplates.defaultHi
                : ShareTemplates.defaultEn;
        }

        Share.share(text);
      },
    );
  }
}
