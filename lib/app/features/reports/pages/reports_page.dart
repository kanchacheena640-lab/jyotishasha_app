import 'package:flutter/material.dart';
import 'package:jyotishasha_app/app/features/reports/pages/report_checkout_page.dart';

/// 🔮 ReportsPage — shows all available reports in grid
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> reports = [
      {
        'title': 'Career Report',
        'description': 'Know your career direction & strengths.',
        'price': 49,
        'image': 'https://cdn-icons-png.flaticon.com/512/2983/2983926.png',
      },
      {
        'title': 'Marriage Compatibility',
        'description': 'Check long-term compatibility & harmony.',
        'price': 59,
        'image': 'https://cdn-icons-png.flaticon.com/512/4359/4359962.png',
      },
      {
        'title': 'Financial Stability',
        'description': 'Understand your wealth & earning potential.',
        'price': 69,
        'image': 'https://cdn-icons-png.flaticon.com/512/2921/2921222.png',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Reports'),
        backgroundColor: Colors.deepPurple,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          return ReportCard(report: reports[index]);
        },
      ),
    );
  }
}

/// 🧩 Single Report Card Widget
class ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;

  const ReportCard({super.key, required this.report});

  void _openDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (_) => _ReportDetailSheet(report: report),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openDetailSheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.network(
              report['image'],
              height: 60,
              width: 60,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            Text(
              report['title'],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              report['description'],
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _openDetailSheet(context),
              child: Text("Buy Now ₹${report['price']}"),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔽 Bottom Sheet Widget
class _ReportDetailSheet extends StatelessWidget {
  final Map<String, dynamic> report;
  const _ReportDetailSheet({required this.report});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          Image.network(report['image'], height: 80),
          const SizedBox(height: 16),
          Text(
            report['title'],
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            report['description'],
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.payment),
              label: Text("Buy Now ₹${report['price']}"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportCheckoutPage(report: report),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
