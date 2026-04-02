import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/love_provider.dart';
import '../enums/love_tool.dart';
import '../widgets/love_premium_cta_card.dart';

class TruthOrDareResultPage extends StatelessWidget {
  const TruthOrDareResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoveProvider>();
    final report =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // 🔄 Loading
    if (provider.isLoadingFor(LoveTool.truthOrDare)) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Analyzing relationship risk…'),
            ],
          ),
        ),
      );
    }

    // ❌ Error
    if (provider.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Truth or Dare')),
        body: Center(child: Text(provider.error!)),
      );
    }

    // 📦 Data
    final raw = provider.resultFor(LoveTool.truthOrDare);
    if (raw == null) {
      return const Scaffold(body: Center(child: Text('No Truth or Dare data')));
    }

    final data = Map<String, dynamic>.from(raw);
    final verdict = data['verdict'] ?? '';
    final verdictLine = data['verdict_line'] ?? '';
    final blocks = data['blocks'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Truth or Dare',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _VerdictCard(verdict: verdict, line: verdictLine),
          const SizedBox(height: 16),

          if (blocks is List)
            ...blocks.map((b) {
              final m = Map<String, dynamic>.from(b);
              return _InsightCard(
                title: m['title'] ?? '',
                text: m['text'] ?? '',
              );
            }),

          const SizedBox(height: 16),
          const _DisclaimerCard(
            text:
                'This tool evaluates emotional risk, not guarantees future outcomes.',
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

class _VerdictCard extends StatelessWidget {
  final String verdict;
  final String line;

  const _VerdictCard({required this.verdict, required this.line});

  @override
  Widget build(BuildContext context) {
    final isTruth = verdict == 'TRUTH';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isTruth ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            verdict,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isTruth ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            line,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String text;

  const _InsightCard({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(text),
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
        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
      ),
    );
  }
}
