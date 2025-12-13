import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:jyotishasha_app/core/state/daily_provider.dart';

// ======================================================
// 🔮 Helper functions — deterministic daily + tomorrow
// ======================================================

// ⭐ TODAY lucky values
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

// ⭐ TOMORROW lucky values
String getTomorrowLuckyColor() {
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
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final seed = tomorrow.toIso8601String().substring(0, 10).hashCode;
  return colors[Random(seed).nextInt(colors.length)];
}

String getTomorrowLuckyNumber() {
  final nums = ["1", "2", "3", "4", "5", "6", "7", "8", "9"];
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final seed = tomorrow.millisecondsSinceEpoch ~/ 86400000;
  return nums[Random(seed).nextInt(nums.length)];
}

String getTomorrowDirection() {
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
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final seed = tomorrow.day * 77;
  return dirs[Random(seed).nextInt(dirs.length)];
}

// ======================================================
// 🔮 Horoscope Card Widget
// ======================================================
class HoroscopeCardWidget extends StatelessWidget {
  final String title; // Today or Tomorrow

  const HoroscopeCardWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final daily = context.watch<DailyProvider>();

    final isToday = title.toLowerCase() == "today";
    final isTomorrow = title.toLowerCase() == "tomorrow";

    // ⭐ Provider-based text
    final mainLine = daily.mainLine ?? "Loading...";
    final aspect = daily.aspectLine ?? "";
    final remedy = daily.remedyLine ?? "";

    // ⭐ Lucky Logic
    final luckyColor = isToday ? getTodayLuckyColor() : getTomorrowLuckyColor();

    final luckyNumber = isToday
        ? getTodayLuckyNumber()
        : getTomorrowLuckyNumber();

    final direction = isToday ? getTodayDirection() : getTomorrowDirection();

    // ⭐ Convert lucky color → dot color
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
      'gold': Color(0xFFFFD700),
      'silver': Color(0xFFC0C0C0),
      'turquoise': Colors.tealAccent,
    };

    final dotColor = colorMap[luckyColor.toLowerCase()] ?? Colors.deepPurple;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF5F8), Color(0xFFFCEFF9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌟 Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$title’s Horoscope",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A189A),
                ),
              ),
              const Icon(Icons.auto_awesome, color: Color(0xFF5A189A)),
            ],
          ),

          const SizedBox(height: 10),

          // -----------------------
          // ⭐ TODAY → Main line only
          // -----------------------
          if (isToday)
            Text(
              mainLine,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey[900],
              ),
            ),

          // ------------------------------------
          // ⭐ TOMORROW → Full content (3 lines)
          // ------------------------------------
          if (isTomorrow) ...[
            Text(
              mainLine,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              aspect,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              remedy,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey[900],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // 🌈 Lucky info line
          Row(
            children: [
              // Dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26, width: 0.5),
                ),
              ),
              const SizedBox(width: 8),

              Text(
                "Lucky Color: $luckyColor",
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF5A189A),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(width: 20),

              Text(
                "Lucky Number: $luckyNumber",
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF5A189A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 🧭 Direction
          Text(
            "Favourable Direction: $direction",
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5A189A),
            ),
          ),
        ],
      ),
    );
  }
}
