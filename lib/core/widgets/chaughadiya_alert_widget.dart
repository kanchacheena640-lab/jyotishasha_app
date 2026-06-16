// lib/core/widgets/chaughadiya_alert_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/panchang_provider.dart';
import '../state/language_provider.dart';

class ChaughadiyaAlertWidget extends StatefulWidget {
  const ChaughadiyaAlertWidget({super.key});

  @override
  State<ChaughadiyaAlertWidget> createState() => _ChaughadiyaAlertWidgetState();
}

class _ChaughadiyaAlertWidgetState extends State<ChaughadiyaAlertWidget>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _blinkController;
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  void _startAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients) {
        if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.animateTo(
            _scrollController.offset + 1.2,
            duration: const Duration(milliseconds: 50),
            curve: Curves.linear,
          );
        }
      }
    });
  }

  String _getAdvice(String nature, String lang) {
    nature = nature.toLowerCase();
    bool isHi = lang == "hi";

    if (nature.contains("amrit")) {
      return isHi ? " • अत्यंत शुभ समय" : " • Best time for important work";
    }

    if (nature.contains("shubh")) {
      return isHi ? " • शुभ कार्य शुरू करें" : " • Good time to start work";
    }

    if (nature.contains("labh")) {
      return isHi
          ? " • व्यापार और लाभ के लिए अच्छा"
          : " • Good for business and gains";
    }

    if (nature.contains("chal")) {
      return isHi ? " • सामान्य कार्य करें" : " • Suitable for routine work";
    }

    if (nature.contains("udveg")) {
      return isHi
          ? " • यात्रा और निर्णय टालें"
          : " • Avoid travel and decisions";
    }

    if (nature.contains("rog")) {
      return isHi
          ? " • स्वास्थ्य और विवाद से सावधान"
          : " • Avoid health risk and disputes";
    }

    if (nature.contains("kaal")) {
      return isHi
          ? " • महत्वपूर्ण कार्य बिल्कुल न करें"
          : " • Avoid important work";
    }

    return isHi ? " • सामान्य समय" : " • Neutral time";
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _blinkController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PanchangProvider>();
    final slot = p.getCurrentChaughadiya();
    final lang = context.watch<LanguageProvider>().currentLang;
    final isHi = lang == "hi";

    if (p.isLoading || slot == null) {
      return Container(
        height: 40,
        alignment: Alignment.center,
        color: Colors.grey.withValues(alpha: 0.05),
        child: Text(
          isHi ? "पंचांग गणना जारी है..." : "Calculating Panchang...",
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      );
    }

    final nature = (slot["nature"] ?? "").toString().toLowerCase();

    final name = isHi
        ? (slot["name"] ?? "चोघड़िया")
        : (slot["name_en"] ?? "Chaughadiya");

    bool isShubh = nature == "shubh";
    bool isAshubh = nature == "ashubh";

    final slotName = (slot["name_en"] ?? slot["name"] ?? "")
        .toString()
        .toLowerCase();
    final String advice = _getAdvice(slotName, lang);

    Color statusColor = Colors.blue;

    if (isShubh) {
      statusColor = Colors.green;
    } else if (isAshubh) {
      statusColor = Colors.red;
    }

    final displayName = isShubh
        ? "✅ ${name.toUpperCase()}"
        : isAshubh
        ? (isHi
              ? "❌ ${name.toUpperCase()} (अशुभ)"
              : "❌ ${name.toUpperCase()} (Inauspicious)")
        : "⚪ ${name.toUpperCase()}";

    final tickerText =
        " ⏰ $displayName (${slot['start']} - ${slot['end']}) $advice  •  🌙 ${p.tithiName}  •  🌅 Sun: ${p.sunrise}-${p.sunset}       ";

    return Container(
      width: double.infinity,
      height: 64,
      margin: const EdgeInsets.symmetric(vertical: 10),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        /// 🔵 BLUE BORDER
        border: Border.all(color: const Color(0xFF4F46E5), width: 1.2),

        /// 🔥 SOFT SHADOW
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          /// 🔥 FIXED ALERT SECTION
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: FadeTransition(
              opacity: _blinkController,
              child: Row(
                children: const [
                  Icon(Icons.auto_awesome, color: Color(0xFF4F46E5), size: 18),
                  SizedBox(width: 4),
                  Text(
                    "ALERT",
                    style: TextStyle(
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// 🔥 FULL WIDTH TICKER
          Expanded(
            child: ClipRect(
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 20,
                itemBuilder: (_, __) {
                  return Row(
                    children: [
                      /// 👈 START GAP REMOVE
                      const SizedBox(width: 8),

                      Text(
                        tickerText,
                        style: const TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),

                      /// 👉 END GAP CONTROL
                      const SizedBox(width: 80),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
