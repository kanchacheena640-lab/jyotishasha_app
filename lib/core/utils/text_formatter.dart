import 'package:flutter/material.dart';

class TextFormatter {
  static List<Widget> parseFormattedText(String text, TextStyle style) {
    final lines = text.split("\n");

    return lines.map((line) {
      final l = line.trim();

      if (l.isEmpty) {
        return const SizedBox(height: 8);
      }

      // 🔹 Headings – end with ":" → bold + spacing
      if (l.endsWith(":")) {
        return Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(
            l,
            style: style.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: style.fontSize! + 1.5,
            ),
          ),
        );
      }

      // 🔹 Automatic bullets (if no emoji or symbol)
      final hasBullet = RegExp(r"^[•\-–●⭐🟢🔹➡️👉🧠❤️🪔]").hasMatch(l);

      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          hasBullet ? l : "• $l",
          style: style.copyWith(height: 1.55),
        ),
      );
    }).toList();
  }
}
