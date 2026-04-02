import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/monthly_provider.dart';
import 'package:jyotishasha_app/core/state/yearly_provider.dart';

enum HoroscopePeriod { today, monthly, yearly }

class HoroscopeCardWidget extends StatelessWidget {
  final HoroscopePeriod period;

  const HoroscopeCardWidget({super.key, required this.period});

  @override
  Widget build(BuildContext context) {
    switch (period) {
      case HoroscopePeriod.today:
        return _todayCard(context);

      case HoroscopePeriod.monthly:
        return _monthlyCard(context);

      case HoroscopePeriod.yearly:
        return _yearlyCard(context);
    }
  }
}

// ================= TODAY =================
Widget _todayCard(BuildContext context) {
  final d = context.watch<DailyProvider>();

  if (d.isLoading) {
    return const SizedBox();
  }

  if (d.errorMessage != null) {
    return Text(d.errorMessage!, style: const TextStyle(color: Colors.red));
  }

  return _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(d.dailyTitle ?? "Today's Horoscope"),

        _para(d.intro),

        _para(d.paragraph),

        /// Lucky indicators
        if (d.luckyColor != null || d.luckyNumber != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 10),
            child: Row(
              children: [
                if (d.luckyColor != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Lucky Color: ${d.luckyColor}",
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                if (d.luckyColor != null && d.luckyNumber != null)
                  const SizedBox(width: 10),

                if (d.luckyNumber != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Lucky Number: ${d.luckyNumber}",
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

        /// Remedy highlight
        if (d.tips != null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "Remedy: ${d.tips!}",
              style: const TextStyle(fontSize: 13.5, height: 1.5),
            ),
          ),
      ],
    ),
  );
}

// ================= MONTHLY =================
Widget _monthlyCard(BuildContext context) {
  final m = context.watch<MonthlyProvider>();

  if (m.isLoading) {
    return const SizedBox();
  }
  if (m.errorMessage != null) {
    return Text(m.errorMessage!, style: const TextStyle(color: Colors.red));
  }

  return _card(
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(m.title ?? "Monthly Horoscope"),
          _para(m.theme),
          _para(m.careerMoney),
          _para(m.loveRelationships),
          _para(m.healthLifestyle),
          _para(m.monthlyAdvice),
        ],
      ),
    ),
  );
}

// ================= YEARLY =================
Widget _yearlyCard(BuildContext context) {
  final y = context.watch<YearlyProvider>();

  if (y.isLoading) {
    return const SizedBox(); // Home/scroll UI के लिए loader avoid
  }

  if (y.errorMessage != null) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        y.errorMessage!,
        style: const TextStyle(color: Colors.red, fontSize: 13.5),
      ),
    );
  }

  if (y.data == null) {
    return const SizedBox(); // empty state silently hide
  }

  // ---------- SAFE YEARLY DATA HANDLING ----------
  final raw = y.data;

  late final Map<String, dynamic> data;

  if (raw is Map<String, dynamic>) {
    data = raw;
  } else {
    return const SizedBox();
  }

  // 🔒 SAFE SECTION EXTRACTOR
  Map<String, dynamic>? getSection(String key) {
    final s = data[key];
    if (s is Map<String, dynamic>) {
      return s;
    }
    return null;
  }

  // 🔒 CONTENT NORMALIZER (NO CRASH)
  List<String>? normalizeContent(dynamic raw) {
    if (raw == null) return null;
    if (raw is List<String>) return raw;
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String) return [raw];
    return null;
  }

  Widget section(String? title, dynamic content) {
    final lines = normalizeContent(content);

    if (title == null || lines == null || lines.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(
            title,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
          ),
        ),
        for (final p in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(p, style: const TextStyle(fontSize: 14, height: 1.6)),
          ),
      ],
    );
  }

  final intro = getSection("introduction");
  final planet = getSection("planetary_overview");
  final career = getSection("career_finance");
  final love = getSection("love_relationships");
  final health = getSection("health_wellness");
  final spiritual = getSection("spirituality_remedies");
  final summary = getSection("final_summary");

  return _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(y.title ?? "Yearly Horoscope"),

        section(intro?["heading"] as String?, intro?["content"]),
        section(planet?["heading"] as String?, planet?["content"]),
        section(career?["heading"] as String?, career?["content"]),
        section(love?["heading"] as String?, love?["content"]),
        section(health?["heading"] as String?, health?["content"]),
        section(spiritual?["heading"] as String?, spiritual?["content"]),
        section(summary?["heading"] as String?, summary?["content"]),
      ],
    ),
  );
}

// ================= COMMON CARD =================
Widget _card({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

// ================= UI HELPERS =================
const TextStyle _titleStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
);

const TextStyle _paraStyle = TextStyle(fontSize: 14, height: 1.6);

Widget _title(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: _titleStyle),
  );
}

Widget _para(String? text) {
  if (text == null || text.trim().isEmpty) {
    return const SizedBox();
  }

  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: _paraStyle),
  );
}
