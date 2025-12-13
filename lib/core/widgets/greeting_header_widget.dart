import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import 'package:jyotishasha_app/core/state/firebase_kundali_provider.dart';
import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/panchang_provider.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

class GreetingHeaderWidget extends StatelessWidget {
  final DailyProvider daily;

  const GreetingHeaderWidget({super.key, required this.daily});

  // -------------------------------------------------------
  // ⭐ TODAY lucky generators
  // -------------------------------------------------------
  String getTodayLuckyColor() {
    final colors = [
      "Red",
      "Blue",
      "Green",
      "Purple",
      "Pink",
      "Yellow",
      "Orange",
      "White",
      "Black",
      "Gold",
      "Silver",
      "Turquoise",
    ];
    final seed = DateTime.now().toIso8601String().substring(0, 10).hashCode;
    return colors[Random(seed).nextInt(colors.length)];
  }

  String getTodayLuckyNumber() {
    final nums = ["1", "2", "3", "4", "5", "6", "7", "8", "9"];
    final seed = (DateTime.now().millisecondsSinceEpoch ~/ 86400000);
    return nums[Random(seed).nextInt(nums.length)];
  }

  String getTodayDirection() {
    final dirs = [
      "North",
      "South",
      "East",
      "West",
      "North-East",
      "South-East",
      "South-West",
      "North-West",
    ];
    final seed = DateTime.now().day * 77;
    return dirs[Random(seed).nextInt(dirs.length)];
  }

  // -------------------------------------------------------
  // ⭐ Color mapping (for dot)
  // -------------------------------------------------------
  Color mapLuckyColor(String color) {
    final colorMap = {
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'pink': Colors.pink,
      'purple': Colors.purple,
      'orange': Colors.orange,
      'white': Colors.white,
      'black': Colors.black,
      'brown': Colors.brown,
      'grey': Colors.grey,
      'gray': Colors.grey,
      'gold': const Color(0xFFFFD700),
      'silver': const Color(0xFFC0C0C0),
      'turquoise': Colors.tealAccent,
    };

    return colorMap[color.toLowerCase()] ?? Colors.deepPurple;
  }

  // -------------------------------------------------------
  // ⭐ Translate Lucky Color
  // -------------------------------------------------------
  String translateLuckyColor(String color, String lang) {
    final map = {
      "red": {"en": "Red", "hi": "लाल"},
      "blue": {"en": "Blue", "hi": "नीला"},
      "green": {"en": "Green", "hi": "हरा"},
      "purple": {"en": "Purple", "hi": "बैंगनी"},
      "pink": {"en": "Pink", "hi": "गुलाबी"},
      "yellow": {"en": "Yellow", "hi": "पीला"},
      "orange": {"en": "Orange", "hi": "नारंगी"},
      "white": {"en": "White", "hi": "सफेद"},
      "black": {"en": "Black", "hi": "काला"},
      "gold": {"en": "Gold", "hi": "सोना"},
      "silver": {"en": "Silver", "hi": "चांदी"},
      "turquoise": {"en": "Turquoise", "hi": "फ़िरोज़ी"},
    };

    final key = color.toLowerCase();
    return map[key]?[lang] ?? color;
  }

  // -------------------------------------------------------
  // ⭐ Translate Lucky Direction
  // -------------------------------------------------------
  String translateDirection(String dir, String lang) {
    final map = {
      "north": {"en": "North", "hi": "उत्तर"},
      "south": {"en": "South", "hi": "दक्षिण"},
      "east": {"en": "East", "hi": "पूर्व"},
      "west": {"en": "West", "hi": "पश्चिम"},
      "north-east": {"en": "North-East", "hi": "उत्तर-पूर्व"},
      "north-west": {"en": "North-West", "hi": "उत्तर-पश्चिम"},
      "south-east": {"en": "South-East", "hi": "दक्षिण-पूर्व"},
      "south-west": {"en": "South-West", "hi": "दक्षिण-पश्चिम"},
    };

    final key = dir.toLowerCase();
    return map[key]?[lang] ?? dir;
  }

  // -------------------------------------------------------
  // ⭐ UI BUILD
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final firebase = context.watch<FirebaseKundaliProvider>();
    final kundali = firebase.kundaliData ?? {};
    final panchang = context.watch<PanchangProvider>();
    final dailyProvider = context.watch<DailyProvider>();
    final t = AppLocalizations.of(context)!;

    final String lang = t.localeName; // "en" or "hi"

    final displayName = kundali["profile"]?["name"] ?? t.greetFriend;
    final birthRashi = kundali["rashi"] ?? "";
    final zodiacAsset = _zodiacAssetForRashi(birthRashi);

    // ⭐ Generate today's lucky values
    final luckyColor = getTodayLuckyColor();
    final luckyNumber = getTodayLuckyNumber();
    final luckyDirection = getTodayDirection();

    // ⭐ Translated for UI
    final luckyColorTranslated = translateLuckyColor(luckyColor, lang);
    final luckyDirectionTranslated = translateDirection(luckyDirection, lang);

    final dotColor = mapLuckyColor(luckyColor);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3E8FF), Color(0xFFEDE9FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------------------------------------------
          // 🌙 Greeting + Rashi Icon
          // ---------------------------------------------------
          Row(
            children: [
              Container(
                height: 54,
                width: 54,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.deepPurple.shade200,
                    width: 1.5,
                  ),
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: Image.asset(zodiacAsset, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "${t.greetNamaste} ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                      TextSpan(
                        text: "$displayName 🙏",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade900,
                        ),
                      ),
                      if (birthRashi.isNotEmpty) ...[
                        const TextSpan(text: " "),
                        TextSpan(
                          text: "($birthRashi Rashi)",
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.deepPurple.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ---------------------------------------------------
          // 🪔 Daily Aspect + Remedy
          // ---------------------------------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.deepPurple.shade100, width: 1),
            ),
            child: dailyProvider.isLoading
                ? Text(
                    t.dailyLoading,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: Colors.deepPurple.shade800,
                      height: 1.5,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dailyProvider.aspectLine != null &&
                          dailyProvider.aspectLine!.trim().isNotEmpty)
                        Text(
                          dailyProvider.aspectLine!,
                          style: TextStyle(
                            fontSize: 14.5,
                            color: Colors.deepPurple.shade800,
                            height: 1.5,
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        t.dailyRemedy,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dailyProvider.remedyLine ?? "—",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.deepPurple.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 16),

          // ---------------------------------------------------
          // ⭐ LUCKY BLOCK (NEW PREMIUM STYLE)
          // ---------------------------------------------------
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFF8F5FF),
                  Color(0xFFEDE7FF),
                ], // Soft Premium Gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.deepPurple.shade100, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🎨 Lucky Color + 🔢 Lucky Number → SIDE-BY-SIDE
                Row(
                  children: [
                    // ⭐ Lucky Color
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black26,
                                width: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "${t.luckyColorLabel}: $luckyColorTranslated",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF5A189A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ⭐ Lucky Number
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.confirmation_num_rounded,
                            size: 18,
                            color: Color(0xFF5A189A),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "${t.luckyNumberLabel}: $luckyNumber",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF5A189A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 🧭 Lucky Direction (FULL WIDTH)
                Row(
                  children: [
                    const Icon(
                      Icons.explore_rounded,
                      size: 18,
                      color: Color(0xFF5A189A),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${t.favourableDirectionLabel}: $luckyDirectionTranslated",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5A189A),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ---------------------------------------------------
          // 📅 Panchang Time Alert
          // ---------------------------------------------------
          Text(
            t.panchangTimeAlert,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade700,
            ),
          ),

          const SizedBox(height: 8),

          panchang.isLoading
              ? Text(
                  t.panchangCalcLoading,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.deepPurple.shade500,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _timeTile(
                      "🕒 ${t.timeToDo}",
                      "${panchang.abhijitStart} – ${panchang.abhijitEnd}",
                    ),
                    _timeTile(
                      "🌑 ${t.timeToHold}",
                      "${panchang.rahukaalStart} – ${panchang.rahukaalEnd}",
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // ♈ Rashi Image
  // -------------------------------------------------------
  String _zodiacAssetForRashi(String? rashi) {
    if (rashi == null || rashi.isEmpty) return 'assets/zodiac/leo.png';
    return 'assets/zodiac/${rashi.toLowerCase()}.png';
  }

  // -------------------------------------------------------
  // ⏳ Time tile
  // -------------------------------------------------------
  Widget _timeTile(String title, String time) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.deepPurple.shade100),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.deepPurple.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.deepPurple.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
