import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/love_provider.dart';
import '../enums/love_tool.dart';
import '../widgets/love_premium_cta_card.dart';

class MatchMakingResultPage extends StatefulWidget {
  const MatchMakingResultPage({super.key});

  @override
  State<MatchMakingResultPage> createState() => _MatchMakingResultPageState();
}

class _MatchMakingResultPageState extends State<MatchMakingResultPage> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoveProvider>();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final report = args?['report'];

    if (provider.isLoadingFor(LoveTool.matchMaking)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (provider.error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Match Making',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        body: Center(child: Text(provider.error!)),
      );
    }

    final raw = provider.resultFor(LoveTool.matchMaking);
    if (raw == null) {
      return const Scaffold(body: Center(child: Text('No Match Making data')));
    }

    final data = Map<String, dynamic>.from(raw);

    // sections helper
    final ashtTop = _findSection(data, 'ashtakoot_top');
    final kootaNotes = _findSection(data, 'koota_notes');
    final flow = _findSection(data, 'love_to_marriage_flow');
    final strengthsRisks = _findSection(data, 'strengths_risks');
    final remedies = _findSection(data, 'remedies');
    final disclaimers = _findSection(data, 'disclaimers');

    // core fields
    final ashta = data['ashtakoot'] is Map
        ? Map<String, dynamic>.from(data['ashtakoot'])
        : <String, dynamic>{};
    final totalScore = ashta['total_score'];
    final maxScore = ashta['max_score'];

    final verdict = data['verdict'] is Map
        ? Map<String, dynamic>.from(data['verdict'])
        : <String, dynamic>{};
    final level = (verdict['level'] ?? '').toString();
    final reasonLine = (verdict['reason_line'] ?? '').toString();
    final scorePct = verdict['score_pct'];

    final tone = _toneForLevel(level);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Match Making',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), // bottom buffer
          children: [
            // ✅ Snapshot Card
            _SnapshotCard(
              tone: tone,
              total: totalScore?.toString(),
              max: maxScore?.toString(),
              level: level,
              pct: scorePct,
              reason: reasonLine,
              fallbackSummary: (ashtTop?['summary'] ?? '').toString(),
            ),
            const SizedBox(height: 16),

            // ✅ Koota Notes
            if (kootaNotes != null) ...[
              _KootaNotesCard(section: kootaNotes),
              const SizedBox(height: 16),
            ],

            // ✅ Flow
            if (flow != null) ...[
              _GenericSectionCard(section: flow),
              const SizedBox(height: 16),
            ],

            // ✅ Strengths & Risks
            if (strengthsRisks != null) ...[
              _StrengthRiskCard(section: strengthsRisks),
              const SizedBox(height: 16),
            ],

            // ✅ Remedies
            if (remedies != null) ...[
              _GenericSectionCard(section: remedies),
              const SizedBox(height: 16),
            ],

            // ✅ Disclaimers
            if (disclaimers != null) ...[_DisclaimerCard(section: disclaimers)],

            // ✅ PREMIUM CTA — ONLY ONCE, ONLY AT END
            if (report != null) ...[
              const SizedBox(height: 24),
              LovePremiumCtaCard(report: report),
              const SizedBox(height: 32), // nav bar se gap
            ],
          ],
        ),
      ),
    );
  }
}

/* ===================== UI ===================== */

class _SnapshotCard extends StatelessWidget {
  final Color tone;
  final String? total;
  final String? max;
  final String level;
  final dynamic pct;
  final String reason;
  final String fallbackSummary;

  const _SnapshotCard({
    required this.tone,
    required this.total,
    required this.max,
    required this.level,
    required this.pct,
    required this.reason,
    required this.fallbackSummary,
  });

  @override
  Widget build(BuildContext context) {
    final pctText = (pct == null) ? '' : '${(pct as num).toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Relationship Snapshot',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: tone,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _kv(
                  'Ashtakoot',
                  (total != null && max != null) ? '$total / $max' : '—',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _kv('Verdict', level.isNotEmpty ? level : '—')),
            ],
          ),

          const SizedBox(height: 10),

          if (pctText.isNotEmpty)
            Text(
              'Score %: $pctText',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

          const SizedBox(height: 10),

          Text(
            reason.isNotEmpty ? reason : fallbackSummary,
            style: const TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _KootaNotesCard extends StatelessWidget {
  final Map<String, dynamic> section;

  const _KootaNotesCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final title = (section['title'] ?? 'Koota Notes').toString();
    final data = section['data'] is Map
        ? Map<String, dynamic>.from(section['data'])
        : <String, dynamic>{};
    final notes = data['koota_notes'] is List
        ? List.from(data['koota_notes'])
        : <dynamic>[];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),

          ...notes.map((n) {
            final m = n is Map
                ? Map<String, dynamic>.from(n)
                : <String, dynamic>{};
            final key = (m['key'] ?? '').toString();
            final score = (m['score'] ?? '').toString();
            final max = (m['max'] ?? '').toString();
            final status = (m['status'] ?? '').toString();
            final dosha = (m['dosha'] ?? '').toString();
            final note = (m['note'] ?? '').toString();

            final tone = _toneForStatus(status);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tone.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tone.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _prettyKey(key),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: tone,
                          ),
                        ),
                      ),
                      Text(
                        '$score / $max',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      _chip(status.toUpperCase(), tone),
                      if (dosha.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _chip(dosha, Colors.redAccent),
                      ],
                    ],
                  ),

                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(note),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _chip(String text, Color tone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: tone,
        ),
      ),
    );
  }

  String _prettyKey(String k) {
    if (k.isEmpty) return '—';
    return k
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class _StrengthRiskCard extends StatelessWidget {
  final Map<String, dynamic> section;

  const _StrengthRiskCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final title = (section['title'] ?? 'Strengths & Risks').toString();
    final data = section['data'] is Map
        ? Map<String, dynamic>.from(section['data'])
        : <String, dynamic>{};

    final strengths = data['strengths'] is List
        ? List<String>.from(data['strengths'])
        : <String>[];
    final risks = data['risks'] is List
        ? List<String>.from(data['risks'])
        : <String>[];
    final stability = data['stability_score'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),

          if (stability != null)
            Text(
              'Stability Score: $stability',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),

          if (strengths.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Strengths',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...strengths.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $s'),
              ),
            ),
          ],

          if (risks.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Risks', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...risks.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $r'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GenericSectionCard extends StatelessWidget {
  final Map<String, dynamic> section;

  const _GenericSectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final title = (section['title'] ?? '').toString();
    final summary = (section['summary'] ?? '').toString();
    final bullets = section['bullets'] is List
        ? List.from(section['bullets'])
        : <dynamic>[];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          if (summary.isNotEmpty) ...[const SizedBox(height: 8), Text(summary)],
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...bullets.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• ${b.toString()}'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  final Map<String, dynamic> section;

  const _DisclaimerCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final title = (section['title'] ?? 'Notes & Disclaimers').toString();
    final data = section['data'] is Map
        ? Map<String, dynamic>.from(section['data'])
        : <String, dynamic>{};
    final list = data['disclaimers'] is List
        ? List.from(data['disclaimers'])
        : <dynamic>[];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...list.map((d) {
            final m = d is Map
                ? Map<String, dynamic>.from(d)
                : <String, dynamic>{};
            final sev = (m['severity'] ?? '').toString();
            final text = (m['text'] ?? '').toString();
            final tone = (sev == 'info') ? Colors.indigo : Colors.grey;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tone.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tone.withOpacity(0.25)),
              ),
              child: Text(text),
            );
          }),
        ],
      ),
    );
  }
}

/* ===================== HELPERS ===================== */

Map<String, dynamic>? _findSection(Map<String, dynamic> data, String id) {
  final sections = data['sections'];
  if (sections is! List) return null;

  for (final s in sections) {
    if (s is Map && s['id'] == id) {
      return Map<String, dynamic>.from(s);
    }
  }
  return null;
}

Color _toneForLevel(String level) {
  if (level == 'Low') return Colors.redAccent;
  if (level == 'Medium') return Colors.orange;
  return Colors.green;
}

Color _toneForStatus(String status) {
  switch (status) {
    case 'pass':
      return Colors.green;
    case 'partial':
      return Colors.orange;
    case 'dosha':
    case 'fail':
      return Colors.redAccent;
    default:
      return Colors.grey;
  }
}
