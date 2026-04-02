import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/love_provider.dart';
import '../enums/love_tool.dart';
import '../widgets/love_premium_cta_card.dart';

class MangalDoshResultPage extends StatelessWidget {
  const MangalDoshResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoveProvider>();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final report = args?['report'];

    // 🔄 Loading
    if (provider.isLoadingFor(LoveTool.mangalDosh)) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Analyzing Mangal Dosh…'),
            ],
          ),
        ),
      );
    }

    // ❌ Error
    if (provider.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mangal Dosh Analysis')),
        body: Center(child: Text(provider.error!)),
      );
    }

    // 📦 Data
    final raw = provider.resultFor(LoveTool.mangalDosh);
    if (raw == null) {
      return const Scaffold(body: Center(child: Text('No Mangal Dosh data')));
    }

    final Map<String, dynamic> data = raw['mangal_dosh'] ?? raw;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mangal Dosh Analysis',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SignalCard(signal: data['signal'], summary: data['summary']),
          const SizedBox(height: 16),

          if (data['boy'] != null) ...[
            _PersonCard(
              title: 'Boy Chart',
              person: Map<String, dynamic>.from(data['boy']),
            ),
            const SizedBox(height: 16),
          ],

          if (data['girl'] != null) ...[
            _PersonCard(
              title: 'Girl Chart',
              person: Map<String, dynamic>.from(data['girl']),
            ),
            const SizedBox(height: 16),
          ],

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

class _SignalCard extends StatelessWidget {
  final String? signal;
  final String? summary;

  const _SignalCard({this.signal, this.summary});

  @override
  Widget build(BuildContext context) {
    final ok = signal == 'GREEN';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ok ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Signal: ${signal ?? '-'}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: ok ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(summary ?? ''),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> person;

  const _PersonCard({required this.title, required this.person});

  @override
  Widget build(BuildContext context) {
    final status = person['status'] ?? {};
    final summaryBlock = person['summary_block'] ?? {};
    final points = summaryBlock['points'] is List
        ? List<String>.from(summaryBlock['points'])
        : <String>[];

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
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            status['is_mangalic'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• $p'),
            ),
          ),
        ],
      ),
    );
  }
}
