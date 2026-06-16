import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/panchang_provider.dart';
import '../provider/cards_provider.dart';
import '../presentation/widgets/card_renderer.dart';
import '../data/card_model.dart';

class CardsPage extends StatefulWidget {
  final String? initialType;

  const CardsPage({super.key, this.initialType});

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  @override
  void initState() {
    super.initState();

    final cardsProvider = context.read<CardsProvider>();
    final panchang = context.read<PanchangProvider>();

    Future.microtask(() async {
      final lang = Localizations.localeOf(context).languageCode;

      if (panchang.fullPanchang == null) {
        await panchang.loadPanchang(lat: 26.8467, lng: 80.9462, lang: lang);
      }

      if (!mounted) return;

      await cardsProvider.loadCards(panchang: panchang, isHindi: lang == 'hi');
    });
  }

  /// 🔥 TIME CONTROL
  bool _isMorning() {
    final h = DateTime.now().hour;
    return h >= 4 && h < 12;
  }

  bool _isNight() {
    final h = DateTime.now().hour;
    return h >= 18 && h <= 23;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardsProvider>();
    final lang = Localizations.localeOf(context).languageCode;

    if (provider.loading) {
      return Scaffold(
        backgroundColor: Colors.black,

        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.4, end: 1),

                  duration: const Duration(milliseconds: 1200),

                  curve: Curves.easeInOut,

                  builder: (context, value, child) {
                    return Opacity(opacity: value, child: child);
                  },

                  child: const Icon(
                    Icons.auto_awesome_outlined,
                    size: 54,
                    color: Color(0xFFB388FF),
                  ),
                ),

                const SizedBox(height: 26),

                Text(
                  lang == 'hi'
                      ? "आपके मुहुर्थ कार्ड तैयार हो रहे हैं"
                      : "Preparing Your Divine Cards",

                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  "Personalized Muhurth timings,\nremedies and spiritual insights\nare being arranged for you...",
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),

                    child: const LinearProgressIndicator(
                      minHeight: 6,
                      backgroundColor: Color(0xFF2A2A2A),
                      valueColor: AlwaysStoppedAnimation(Color(0xFFB388FF)),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  lang == 'hi'
                      ? "✨ कृपया कुछ क्षण प्रतीक्षा करें"
                      : "✨ Please wait a moment",

                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (provider.error != null) {
      return Scaffold(body: Center(child: Text("Error: ${provider.error}")));
    }

    if (provider.cards.isEmpty) {
      return const Scaffold(body: Center(child: Text("No cards available")));
    }

    /// 🔥 ORDER CONTROL (FINAL)
    final List<CardModel> sortedCards = [];
    if (widget.initialType != null) {
      sortedCards.addAll(
        provider.cards.where(
          (c) => c.type == "muhurth" && c.muhurthType == widget.initialType,
        ),
      );
    }

    final isMorning = _isMorning();
    final isNight = _isNight();

    /// 🌅 / 🌙 Priority (only one)
    if (isMorning) {
      sortedCards.addAll(provider.cards.where((c) => c.type == "morning"));
    } else if (isNight) {
      sortedCards.addAll(provider.cards.where((c) => c.type == "night"));
    }

    /// 🔥 Remaining cards after priority

    final remaining = provider.cards.where((c) {
      if (widget.initialType == null) return true;

      return !(c.type == "muhurth" && c.muhurthType == widget.initialType);
    }).toList();

    remaining.shuffle();

    sortedCards.addAll(remaining);

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: null,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final card = sortedCards[index % sortedCards.length];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: CardRenderer(card: card),
              ),
            ),
          );
        },
      ),
    );
  }
}
