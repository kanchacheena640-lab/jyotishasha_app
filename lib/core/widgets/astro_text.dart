import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AstroText:
/// - Normal text ko RichText me convert karta hai
/// - Planet / Rashi / Nakshatra names ko auto-bold karta hai
class AstroText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color? color;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final double height;

  const AstroText(
    this.text, {
    super.key,
    this.fontSize = 15,
    this.color,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.left,
    this.height = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    final baseStyle = GoogleFonts.montserrat(
      fontSize: fontSize,
      color: color ?? Colors.black87,
      fontWeight: fontWeight,
      height: height,
    );

    // Keywords: Planets + Rashis + popular spellings + Nakshatras
    const keywords = [
      // Planets
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
      'Rahu',
      'Ketu',

      // Rashis (English)
      'Aries',
      'Taurus',
      'Gemini',
      'Cancer',
      'Leo',
      'Virgo',
      'Libra',
      'Scorpio',
      'Sagittarius',
      'Capricorn',
      'Aquarius',
      'Pisces',

      // Rashis (Hindi script common)
      'मेष',
      'वृषभ',
      'मिथुन',
      'कर्क',
      'सिंह',
      'कन्या',
      'तुला',
      'वृश्चिक',
      'धनु',
      'मकर',
      'कुम्भ',
      'मीन',

      // Sample Nakshatras (can extend more)
      'Ashwini',
      'Bharani',
      'Krittika',
      'Rohini',
      'Mrigashira',
      'Ardra',
      'Punarvasu',
      'Pushya',
      'Ashlesha',
      'Magha',
      'Purva Phalguni',
      'Uttara Phalguni',
      'Hasta',
      'Chitra',
      'Swati',
      'Vishakha',
      'Anuradha',
      'Jyeshtha',
      'Mula',
      'Purva Ashadha',
      'Uttara Ashadha',
      'Shravana',
      'Dhanishta',
      'Shatabhisha',
      'Purva Bhadrapada',
      'Uttara Bhadrapada',
      'Revati',
    ];

    final spans = <TextSpan>[];
    final regex = RegExp(r'(\s+)'); // split by spaces but preserve gaps
    final parts = text.split(regex);

    for (final part in parts) {
      if (part.trim().isEmpty) {
        spans.add(TextSpan(text: part, style: baseStyle));
        continue;
      }

      // strip basic punctuation for matching
      final cleaned = part.replaceAll(RegExp(r'[.,:;!?()\[\]]'), '');

      final isKeyword = keywords.contains(cleaned);

      spans.add(
        TextSpan(
          text: part,
          style: baseStyle.copyWith(
            fontWeight: isKeyword ? FontWeight.w700 : baseStyle.fontWeight,
          ),
        ),
      );
    }

    return RichText(
      textAlign: textAlign,
      text: TextSpan(children: spans),
    );
  }
}
