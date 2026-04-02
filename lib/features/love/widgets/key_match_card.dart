import 'package:flutter/material.dart';

class KeyMatchCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const KeyMatchCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;

    // ---------------- RAW DATA ----------------
    final ashta = data['ashtakoot'] ?? {};
    final total = ashta['total_score'];
    final max = ashta['max_score'];

    final verdict = data['verdict'] ?? {};
    final level = verdict['level']?.toString() ?? '';

    final mangal = data['mangal_dosh'] ?? {};
    final signal = mangal['signal']?.toString() ?? 'GREEN';

    // ---------------- UI LOGIC (FRONTEND OWNED) ----------------
    final Color tone = _toneFor(level, signal);

    final String title = lang == 'hi'
        ? 'रिलेशनशिप सारांश'
        : 'Relationship Snapshot';

    final String ashtakootLabel = lang == 'hi'
        ? 'अष्टकूट स्कोर'
        : 'Ashtakoot Score';

    final String verdictLabel = lang == 'hi' ? 'निर्णय' : 'Verdict';

    final String verdictText = _localizedVerdict(level, lang);

    final String mangalText = _localizedMangal(signal, lang);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- HEADER ----------------
          Row(
            children: [
              Icon(Icons.favorite, color: tone),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ---------------- ASHTAKOOT ----------------
          if (total != null && max != null)
            _row(ashtakootLabel, '$total / $max'),

          // ---------------- VERDICT ----------------
          if (verdictText.isNotEmpty) _row(verdictLabel, verdictText),

          // ---------------- MANGAL DOSH (UI SUMMARY ONLY) ----------------
          if (mangalText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    signal == 'GREEN'
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    size: 18,
                    color: signal == 'GREEN' ? Colors.green : Colors.redAccent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      mangalText,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // HELPERS
  // ----------------------------------------------------

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _toneFor(String level, String signal) {
    if (signal == 'RED') return Colors.redAccent;
    if (level == 'Low') return Colors.redAccent;
    if (level == 'Medium') return Colors.orange;
    return Colors.green;
  }

  String _localizedVerdict(String level, String lang) {
    if (level.isEmpty) return '';

    if (lang == 'hi') {
      switch (level) {
        case 'Low':
          return 'कम अनुकूलता';
        case 'Medium':
          return 'मध्यम अनुकूलता';
        case 'High':
          return 'अच्छी अनुकूलता';
        default:
          return level;
      }
    }
    return level;
  }

  String _localizedMangal(String signal, String lang) {
    if (lang == 'hi') {
      return signal == 'GREEN'
          ? 'मंगल दोष का प्रभाव नहीं है'
          : 'मंगल दोष का प्रभाव है';
    }
    return signal == 'GREEN'
        ? 'No effective Mangal Dosh'
        : 'Mangal Dosh is present';
  }
}
