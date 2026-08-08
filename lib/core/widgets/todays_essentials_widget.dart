// lib/core/widgets/todays_essentials_widget.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/features/horoscope/horoscope_page.dart';

/// "Today's Essentials" — a premium 2-card section (Today's Horoscope,
/// `"<Deity> Darshan"`) replacing the old 3-card Mantra/Horoscope/Panchang
/// idea. Panchang is already covered by the "Current Timing" section and
/// is intentionally not duplicated here.
///
/// F5.4 polish: card content is strictly icon → title → CTA, nothing else
/// (no subtitle row) — the Darshan card's today's-deity name is folded
/// directly into its title ("Shani Darshan", "Surya Darshan", ...) instead
/// of a separate line. Reuses existing navigation only:
/// - Horoscope: navigates to the existing [HoroscopePage].
/// - Darshan: the same day-of-week → deity mapping already used by
///   `DarshanPage._setDayData()` (duplicated here as a small static map,
///   since it isn't exposed anywhere for reuse) — real, not hardcoded,
///   content — navigating via the existing `context.push('/darshan')`
///   route.
class TodaysEssentialsWidget extends StatelessWidget {
  const TodaysEssentialsWidget({super.key});

  static const Map<String, String> _deityByDay = {
    'monday': 'shiva',
    'tuesday': 'hanuman',
    'wednesday': 'ganesha',
    'thursday': 'vishnu',
    'friday': 'lakshmi',
    'saturday': 'shani',
    'sunday': 'surya',
  };

  static const Map<String, String> _deityEnglishNames = {
    'shiva': 'Shiva',
    'hanuman': 'Hanuman',
    'ganesha': 'Ganesha',
    'vishnu': 'Vishnu',
    'lakshmi': 'Lakshmi',
    'shani': 'Shani',
    'surya': 'Surya',
  };

  static const Map<String, String> _deityHindiNames = {
    'shiva': 'शिव',
    'hanuman': 'हनुमान',
    'ganesha': 'गणेश',
    'vishnu': 'विष्णु',
    'lakshmi': 'लक्ष्मी',
    'shani': 'शनि',
    'surya': 'सूर्य',
  };

  String _todaysDeitySlug() {
    final weekday = DateFormat('EEEE').format(DateTime.now()).toLowerCase();
    return _deityByDay[weekday] ?? 'shiva';
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().currentLang;
    final isHi = lang == 'hi';

    final deitySlug = _todaysDeitySlug();
    final deityName = isHi
        ? (_deityHindiNames[deitySlug] ?? _deityHindiNames['shiva']!)
        : (_deityEnglishNames[deitySlug] ?? _deityEnglishNames['shiva']!);

    // F5.4 polish: the deity name is folded directly into the Darshan
    // card's title ("Shani Darshan"), generated from the same existing
    // day→deity mapping — not hardcoded.
    final darshanTitle = isHi ? '$deityName दर्शन' : '$deityName Darshan';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // F6.6 visual audit: leading margin removed entirely (was 10dp).
        // dashboard_home_section.dart already places an explicit 16dp
        // SizedBox above this widget; that internal +10dp on top of it
        // made the gap below Share Banner 26dp — the only inter-section
        // gap on Home that wasn't a clean, consistent 16dp.
        _buildHeading(isHi),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _EssentialCard(
                icon: const Text('☀', style: TextStyle(fontSize: 18)),
                title: isHi ? 'आज का राशिफल' : "Today's Horoscope",
                ctaLabel: isHi ? 'अभी पढ़ें →' : 'Read Now →',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HoroscopePage(initialTab: 0),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _EssentialCard(
                icon: const Text('🛕', style: TextStyle(fontSize: 18)),
                title: darshanTitle,
                ctaLabel: isHi ? 'खोलें →' : 'Open →',
                onTap: () => context.push('/darshan'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Centered heading with small purple divider lines — same style as the
  /// "Current Timing" section heading.
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
          isHi ? "आज की ज़रूरी बातें" : "Today's Essentials",
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
}

/// F5.4 polish: card height cut further (115→100, within the requested
/// 95–105dp) and content is strictly icon → title → CTA — no subtitle row
/// anymore (the Darshan card's deity name is now part of its title
/// instead). Width is unchanged (still one of two `Expanded` columns in
/// the parent `Row`).
class _EssentialCard extends StatelessWidget {
  const _EssentialCard({
    required this.icon,
    required this.title,
    required this.ctaLabel,
    required this.onTap,
  });

  final Widget icon;
  final String title;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE4D9FA)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1B2E),
                ),
              ),
              const Expanded(child: SizedBox.shrink()),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  ctaLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B21A8),
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
