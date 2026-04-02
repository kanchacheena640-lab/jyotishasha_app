import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/love_provider.dart';
import '../enums/love_tool.dart';
import '../widgets/love_premium_cta_card.dart';

class MarriageProbabilityResultPage extends StatelessWidget {
  const MarriageProbabilityResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoveProvider>();
    final report =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // 🔄 Loading
    if (provider.isLoadingFor(LoveTool.marriageProbability)) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Calculating probability…'),
            ],
          ),
        ),
      );
    }

    // ❌ Error
    if (provider.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Marriage Probability')),
        body: Center(child: Text(provider.error!)),
      );
    }

    // 📦 Data
    final raw = provider.resultFor(LoveTool.marriageProbability);
    if (raw == null) {
      return const Scaffold(
        body: Center(child: Text('No marriage probability data')),
      );
    }

    final data = Map<String, dynamic>.from(raw);
    final user = Map<String, dynamic>.from(data['user_result']);
    final partner = Map<String, dynamic>.from(data['partner_result']);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Marriage Probability',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OverallCard(line: data['overall_line']),
          const SizedBox(height: 16),

          _PersonProbabilityCard(
            title: 'You',
            name: user['name'],
            pct: user['pct'],
            band: user['band'],
            reasons: List<String>.from(user['reasons'] ?? []),
          ),

          const SizedBox(height: 16),

          _PersonProbabilityCard(
            title: 'Partner',
            name: partner['name'],
            pct: partner['pct'],
            band: partner['band'],
            reasons: List<String>.from(partner['reasons'] ?? []),
          ),

          const SizedBox(height: 16),

          const _DisclaimerCard(
            text:
                'Probability is based on 5th–7th house indicators, not a guarantee.',
          ),

          if (report != null) ...[
            const SizedBox(height: 24),
            LovePremiumCtaCard(report: report),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }
}

/* ================= UI ================= */

class _OverallCard extends StatelessWidget {
  final String line;

  const _OverallCard({required this.line});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        line,
        style: const TextStyle(fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _PersonProbabilityCard extends StatelessWidget {
  final String title;
  final String name;
  final int pct;
  final String band;
  final List<String> reasons;

  const _PersonProbabilityCard({
    required this.title,
    required this.name,
    required this.pct,
    required this.band,
    required this.reasons,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: $name',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '$pct% • $band',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ...reasons.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• $r'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  final String text;

  const _DisclaimerCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
      ),
    );
  }
}
