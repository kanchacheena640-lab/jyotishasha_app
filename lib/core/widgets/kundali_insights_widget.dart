import 'package:flutter/material.dart';

/// "From Your Kundali" — a visual-only preview grid of six future insight
/// destinations (Raj Yoga, Dosha, Strengths, Weaknesses, Career, Marriage).
/// No navigation, no routes, no astrology content — cards show a neutral
/// placeholder teaser only and acknowledge taps with a "Coming Soon"
/// message. Intentionally has no dependency on any provider/repository.
class KundaliInsightsWidget extends StatelessWidget {
  const KundaliInsightsWidget({super.key});

  static const List<_KundaliInsightItem> _items = [
    _KundaliInsightItem(
      icon: Icons.auto_awesome_outlined,
      titleEn: 'Raj Yoga',
      titleHi: 'राज योग',
      teaserEn: 'See the powerful combinations present in your birth chart.',
      teaserHi: 'अपनी कुंडली में मौजूद शक्तिशाली संयोगों को देखें।',
    ),
    _KundaliInsightItem(
      icon: Icons.shield_outlined,
      titleEn: 'Dosha',
      titleHi: 'दोष',
      teaserEn: 'Understand the doshas and their influence in your chart.',
      teaserHi: 'अपनी कुंडली में दोषों और उनके प्रभाव को समझें।',
    ),
    _KundaliInsightItem(
      icon: Icons.trending_up_rounded,
      titleEn: 'Strengths',
      titleHi: 'शक्तियां',
      teaserEn: 'Know the key strengths shown in your birth chart.',
      teaserHi: 'अपनी कुंडली में दिखाई देने वाली मुख्य शक्तियों को जानें।',
    ),
    _KundaliInsightItem(
      icon: Icons.balance_outlined,
      titleEn: 'Weaknesses',
      titleHi: 'कमजोरियां',
      teaserEn: 'Understand the areas that may need your attention.',
      teaserHi: 'उन क्षेत्रों को समझें जिन पर ध्यान देने की आवश्यकता है।',
    ),
    _KundaliInsightItem(
      icon: Icons.work_outline_rounded,
      titleEn: 'Career',
      titleHi: 'करियर',
      teaserEn: 'Understand the strengths influencing your professional journey.',
      teaserHi: 'अपनी व्यावसायिक यात्रा को प्रभावित करने वाली शक्तियों को समझें।',
    ),
    _KundaliInsightItem(
      icon: Icons.favorite_border_rounded,
      titleEn: 'Marriage',
      titleHi: 'विवाह',
      teaserEn: 'Discover the relationship tendencies reflected in your birth chart.',
      teaserHi: 'अपनी कुंडली में प्रतिबिंबित संबंधों की प्रवृत्तियों को जानें।',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final isHindi = lang == 'hi';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isHindi ? 'आपकी कुंडली से' : 'From Your Kundali',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isHindi
              ? 'जानें आपकी जन्म कुंडली आपके जीवन के महत्वपूर्ण पहलुओं के बारे में क्या कहती है।'
              : 'Discover what your birth chart says about the important areas of your life.',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            return _KundaliInsightCard(item: _items[index], isHindi: isHindi);
          },
        ),
      ],
    );
  }
}

class _KundaliInsightItem {
  const _KundaliInsightItem({
    required this.icon,
    required this.titleEn,
    required this.titleHi,
    required this.teaserEn,
    required this.teaserHi,
  });

  final IconData icon;
  final String titleEn;
  final String titleHi;
  final String teaserEn;
  final String teaserHi;
}

class _KundaliInsightCard extends StatelessWidget {
  const _KundaliInsightCard({required this.item, required this.isHindi});

  final _KundaliInsightItem item;
  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    final title = isHindi ? item.titleHi : item.titleEn;
    final teaser = isHindi ? item.teaserHi : item.teaserEn;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isHindi ? 'जल्द आ रहा है' : 'Coming Soon'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEDEDF2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF3F1FF),
                    ),
                    child: Icon(
                      item.icon,
                      size: 16,
                      color: const Color(0xFF4F46E5),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Color(0xFFBBBBBB),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  teaser,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
