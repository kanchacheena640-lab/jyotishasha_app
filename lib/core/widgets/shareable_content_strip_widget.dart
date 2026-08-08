import 'package:flutter/material.dart';

import 'package:jyotishasha_app/features/cards/presentation/cards_page.dart';

/// "Useful Shareable Content" — a premium horizontal strip (Netflix/Play
/// Store style browsing, not large vertical cards) surfacing the existing
/// shareable-cards feature. Every card — including "View All →" — opens the
/// existing [CardsPage] unfiltered; no new route, no category filtering.
class ShareableContentStripWidget extends StatelessWidget {
  const ShareableContentStripWidget({super.key});

  static const List<_ShareableCategory> _categories = [
    _ShareableCategory(
      icon: Icons.celebration_outlined,
      titleEn: 'Festival Cards',
      titleHi: 'त्योहार कार्ड्स',
      subtitleEn: 'Wish your loved ones',
      subtitleHi: 'अपनों को शुभकामनाएं दें',
    ),
    _ShareableCategory(
      icon: Icons.calendar_today_outlined,
      titleEn: 'Daily Panchang',
      titleHi: 'दैनिक पंचांग',
      subtitleEn: "Today's auspicious details",
      subtitleHi: 'आज की शुभ जानकारी',
    ),
    _ShareableCategory(
      icon: Icons.public_outlined,
      titleEn: 'Planetary Updates',
      titleHi: 'ग्रह अपडेट्स',
      subtitleEn: 'Share live transit news',
      subtitleHi: 'ग्रह गोचर की जानकारी',
    ),
    _ShareableCategory(
      icon: Icons.format_quote_outlined,
      titleEn: 'Motivational Quotes',
      titleHi: 'प्रेरक विचार',
      subtitleEn: 'Inspire your circle',
      subtitleHi: 'अपनों को प्रेरित करें',
    ),
  ];

  void _openCardsPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CardsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isHindi ? 'शेयर करने योग्य उपयोगी सामग्री' : 'Useful Shareable Content',
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
              ? 'अपने परिवार और दोस्तों के साथ सुंदर ज्योतिष सामग्री साझा करें।'
              : 'Share beautiful astrology content with your family and friends.',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == _categories.length) {
                return _ViewAllCard(
                  isHindi: isHindi,
                  onTap: () => _openCardsPage(context),
                );
              }
              return _ShareableCategoryCard(
                category: _categories[index],
                isHindi: isHindi,
                onTap: () => _openCardsPage(context),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShareableCategory {
  const _ShareableCategory({
    required this.icon,
    required this.titleEn,
    required this.titleHi,
    required this.subtitleEn,
    required this.subtitleHi,
  });

  final IconData icon;
  final String titleEn;
  final String titleHi;
  final String subtitleEn;
  final String subtitleHi;
}

class _ShareableCategoryCard extends StatelessWidget {
  const _ShareableCategoryCard({
    required this.category,
    required this.isHindi,
    required this.onTap,
  });

  final _ShareableCategory category;
  final bool isHindi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = isHindi ? category.titleHi : category.titleEn;
    final subtitle = isHindi ? category.subtitleHi : category.subtitleEn;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 168,
          padding: const EdgeInsets.all(12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF3F1FF),
                    ),
                    child: Icon(
                      category.icon,
                      size: 15,
                      color: const Color(0xFF4F46E5),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: Color(0xFFBBBBBB),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewAllCard extends StatelessWidget {
  const _ViewAllCard({required this.isHindi, required this.onTap});

  final bool isHindi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 96,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEDEDF2)),
          ),
          child: Center(
            child: Text(
              isHindi ? 'सभी देखें →' : 'View All →',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4F46E5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
