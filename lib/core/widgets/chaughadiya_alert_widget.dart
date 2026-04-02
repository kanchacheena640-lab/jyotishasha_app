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
      height: 40,
      width: double.infinity,
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        border: Border.symmetric(
          horizontal: BorderSide(
            color: statusColor.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FadeTransition(
              opacity: _blinkController,
              child: Icon(Icons.circle, color: statusColor, size: 8),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: 20,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 60),
                  child: Text(
                    tickerText,
                    style: TextStyle(
                      color: isAshubh ? Colors.red : statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
