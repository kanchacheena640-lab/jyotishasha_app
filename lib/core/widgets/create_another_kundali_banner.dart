// lib/core/widgets/create_another_kundali_banner.dart

import 'package:flutter/material.dart';

import 'package:jyotishasha_app/features/manual_kundali/manual_kundali_form_page.dart';

/// F8.7.3 — premium full-width CTA banner as the VERY LAST section on
/// Home, encouraging users to generate a Kundali for someone else.
///
/// Visual language is reused, not reinvented: same 22dp corner radius,
/// same purple gradient (`0xFF6B21A8` → `0xFF7C3AED`), same shadow, and
/// the same watermark-icon-in-the-corner motif already established by
/// [ShareStripWidget] ("Ask Now"/"Share Now" banners), which are
/// themselves documented as sister components of one shared premium-
/// banner design system already live on Home — this banner is one more
/// member of that family, not a new one-off design.
///
/// Tapping the banner (or its button) reuses the existing, unmodified
/// [ManualKundaliFormPage] via a plain `Navigator.push` — the exact same
/// navigation pattern already used to reach this page from
/// `KundaliOverviewPage`'s own "Create Another Kundali" CTA (F8.7). No
/// new route, no new provider, no duplicated form.
class CreateAnotherKundaliBanner extends StatelessWidget {
  const CreateAnotherKundaliBanner({super.key});

  void _openManualKundaliForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManualKundaliFormPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openManualKundaliForm(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            // Same gradient + shadow as ShareStripWidget/TrendingQuestions'
            // "Ask Now" banner — sister components, one design system.
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6B21A8), Color(0xFF7C3AED)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B21A8).withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Large faded watermark icon — decoration only, never
              // competes with the foreground text.
              Positioned(
                right: -24,
                top: -18,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 110,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHindi ? 'एक और कुंडली चाहिए?' : 'Need Another Kundali?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isHindi
                        ? 'अपने परिवार, दोस्तों या किसी और के लिए कुछ ही '
                              'आसान चरणों में विस्तृत जन्म कुंडली बनाएं।'
                        : 'Generate a detailed birth chart for your family, '
                              'friends or anyone else in just a few simple '
                              'steps.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () => _openManualKundaliForm(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6B21A8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isHindi
                          ? 'एक और कुंडली बनाएं'
                          : 'Create Another Kundali',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
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
