import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';

class ShubhMuhurthBannerWidget extends StatefulWidget {
  final VoidCallback? onTap;

  const ShubhMuhurthBannerWidget({super.key, this.onTap});

  @override
  State<ShubhMuhurthBannerWidget> createState() =>
      _ShubhMuhurthBannerWidgetState();
}

class _ShubhMuhurthBannerWidgetState extends State<ShubhMuhurthBannerWidget> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % 4;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final lang = t.localeName;

    final slides = [
      {"emoji": "👶", "label": t.muhurthBannerNamkaran},
      {"emoji": "💍", "label": t.muhurthBannerMarriage},
      {"emoji": "🚗", "label": t.muhurthBannerVehicle},
      {"emoji": "🪙", "label": t.muhurthBannerGold},
    ];

    final active = slides[_currentIndex];

    return Column(
      children: [
        /// ⭐ Stable Heading — not animated
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Center(
            // 👈 Add this
            child: Text(
              t.muhurthBannerTitle,
              textAlign: TextAlign.center, // 👈 Add this
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),

        /// ⭐ Clean White Card
        GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            height: 95,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                // Left animated text
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.4),
                          end: Offset.zero,
                        ).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      );
                    },
                    child: Text(
                      "${active["emoji"]}  ${active["label"]}",
                      key: ValueKey(active["label"]),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Circular soft badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.purple.withOpacity(0.08),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      active["emoji"] as String,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
