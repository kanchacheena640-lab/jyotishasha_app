// lib/core/widgets/chaughadiya_alert_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/panchang_provider.dart';
import '../state/language_provider.dart';
import 'package:jyotishasha_app/features/panchang/panchang_page.dart';

/// "Current Timing" — premium redesign (F4.2.1) of the old inline-"ALERT"
/// ticker. All backend data, the auto-scroll animation/timer, and the
/// Panchang navigation are unchanged; only the surrounding presentation
/// (heading above, container style, footer link below) was redesigned.
class ChaughadiyaAlertWidget extends StatefulWidget {
  const ChaughadiyaAlertWidget({super.key});

  @override
  State<ChaughadiyaAlertWidget> createState() => _ChaughadiyaAlertWidgetState();
}

class _ChaughadiyaAlertWidgetState extends State<ChaughadiyaAlertWidget> {
  late ScrollController _scrollController;
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

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
    _scrollController.dispose();
    super.dispose();
  }

  static const _tickerDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(22)),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0xFFE4D9FA), width: 1),
    ),
    boxShadow: [
      BoxShadow(
        color: Color(0x0A000000), // ~4% black — very subtle
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PanchangProvider>();
    final slot = p.getCurrentChaughadiya();
    final lang = context.watch<LanguageProvider>().currentLang;
    final isHi = lang == "hi";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24), // Header → Current Timing
        _buildHeading(isHi),
        const SizedBox(height: 12), // Heading → Ticker
        if (p.isLoading || slot == null)
          Container(
            height: 44,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: _tickerDecoration,
            child: Text(
              isHi ? "पंचांग गणना जारी है..." : "Calculating Panchang...",
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          )
        else
          _buildTicker(p, slot, lang, isHi),
        const SizedBox(height: 8), // Ticker → Footer
        _buildFooterLink(context, isHi),
        // F6.6 visual audit: 24→16dp. This section's neighbor below is now
        // Share Banner (not Ask Now — Share Banner was inserted between
        // them in F5.4), and every other inter-section gap on Home is a
        // clean 16dp; this stale 24dp left a visibly larger gap here than
        // anywhere else on the page.
        const SizedBox(height: 16), // Footer → Share Banner
      ],
    );
  }

  /// Centered "Current Timing" heading with small purple divider lines on
  /// both sides.
  Widget _buildHeading(bool isHi) {
    Widget divider() => Container(
      width: 24,
      height: 1,
      color: const Color(0xFF6B21A8).withValues(alpha: 0.3),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        divider(),
        const SizedBox(width: 10),
        Text(
          isHi ? "अभी का समय" : "Current Timing",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F1B2E),
          ),
        ),
        const SizedBox(width: 10),
        divider(),
      ],
    );
  }

  Widget _buildTicker(
    PanchangProvider p,
    Map<String, dynamic> slot,
    String lang,
    bool isHi,
  ) {
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
      height: 44,
      decoration: _tickerDecoration,
      // Insets the scrolling content so it never visually touches the
      // border — the ticker data/animation inside is unchanged.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: ClipRect(
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 20,
            itemBuilder: (_, __) {
              return Row(
                children: [
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
                  const SizedBox(width: 80),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLink(BuildContext context, bool isHi) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PanchangPage()),
        );
      },
      child: Text(
        isHi
            ? "पूरा पंचांग व चौघड़िया देखें →"
            : "View Full Panchang & Chaughadiya →",
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6B21A8),
        ),
      ),
    );
  }
}
