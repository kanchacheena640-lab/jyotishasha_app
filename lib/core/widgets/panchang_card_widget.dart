import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/panchang_provider.dart';
import 'package:jyotishasha_app/core/utils/panchang_event_markup.dart';
import 'package:jyotishasha_app/features/panchang/panchang_page.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

class PanchangCardWidget extends StatelessWidget {
  const PanchangCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = context.watch<PanchangProvider>();
    final lang = context.watch<LanguageProvider>().currentLang;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PanchangProvider>().loadPanchang(lang: lang);
    });

    if (p.isLoading || p.fullPanchang == null) {
      return _loadingCard(t);
    }

    final data = p.fullPanchang!;
    final bool panchakActive = data["panchak"]?["active"] == true;
    final String panchakLabel = panchakActive ? t.panchang_yes : t.panchang_no;

    final String vratLine = PanchangEventMarkup.buildVratSuggestion({
      "selected_date": data,
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black..withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          /// HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFEAF2FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                Text(
                  t.panchang_today.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 1.1,
                    color: Color(0xFF2563EB),
                  ),
                ),

                const SizedBox(width: 12),
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 3),
                const Text(
                  "Lucknow",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                /// PANCHANG GRID
                _gridRow(
                  _tile(
                    Icons.calendar_today_outlined,
                    t.panchang_tithi,
                    p.tithiName,
                  ),
                  _tile(Icons.star_outline, t.panchang_nakshatra, p.nakshatra),
                  _tile(
                    Icons.filter_vintage_outlined,
                    t.panchang_month,
                    p.monthName,
                  ),
                ),

                const SizedBox(height: 18),

                _gridRow(
                  _tile(
                    Icons.wb_sunny_outlined,
                    t.panchang_abhijit,
                    p.abhijitStart,
                    highlight: true,
                  ),
                  _tile(Icons.schedule, t.panchang_rahu, p.rahukaalStart),
                  _tile(
                    Icons.warning_amber_rounded,
                    t.panchang_panchak,
                    panchakLabel,
                    warning: panchakActive,
                  ),
                ),

                const SizedBox(height: 18),

                _gridRow(
                  _tile(Icons.auto_awesome, t.panchang_yoga, p.yoga),
                  _tile(Icons.brightness_6_outlined, t.panchang_karan, p.karan),
                  _tile(Icons.wb_twilight, t.panchang_sunrise, p.sunrise),
                ),

                /// FESTIVAL
                if (vratLine.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_available,
                          color: Color(0xFF7C3AED),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            vratLine,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 22),

                /// CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PanchangPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      t.panchang_view_full,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// GRID ROW
  Widget _gridRow(Widget a, Widget b, Widget c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [a, b, c],
    );
  }

  /// TILE
  Widget _tile(
    IconData icon,
    String label,
    String value, {
    bool warning = false,
    bool highlight = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: warning
                ? Colors.amber.withValues(alpha: .15)
                : highlight
                ? const Color(0xFFEAF2FF)
                : const Color(0xFFF5F7FA),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: warning
                ? Colors.orange[800]
                : highlight
                ? const Color(0xFF2563EB)
                : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _loadingCard(AppLocalizations t) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
